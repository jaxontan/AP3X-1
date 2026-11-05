CREATE OR REPLACE PACKAGE BODY fc_ai_agent_api AS

    FUNCTION escape_json(p_str IN CLOB) RETURN CLOB IS
        l_res CLOB := p_str;
    BEGIN
        IF l_res IS NULL THEN RETURN '""'; END IF;
        l_res := REPLACE(l_res, '\', '\\');
        l_res := REPLACE(l_res, '"', '\"');
        l_res := REPLACE(l_res, CHR(10), '\n');
        l_res := REPLACE(l_res, CHR(13), '');
        l_res := REPLACE(l_res, CHR(9), '\t');
        RETURN l_res;
    END escape_json;

    PROCEDURE save_config(
        p_api_key       IN VARCHAR2,
        p_model_name    IN VARCHAR2 DEFAULT 'google/gemini-flash-1.5',
        p_endpoint_url  IN VARCHAR2 DEFAULT 'https://openrouter.ai/api/v1/chat/completions',
        p_user_name     IN VARCHAR2 DEFAULT USER
    ) IS
    BEGIN
        MERGE INTO fc_ai_settings t
        USING (SELECT 1 AS id FROM dual) s
        ON (t.setting_id = 1)
        WHEN MATCHED THEN
            UPDATE SET api_key = NVL(TRIM(p_api_key), t.api_key),  -- blank keeps the stored key
                       model_name = NVL(p_model_name, 'google/gemini-flash-1.5'),
                       endpoint_url = NVL(p_endpoint_url, 'https://openrouter.ai/api/v1/chat/completions'),
                       updated_at = CURRENT_TIMESTAMP,
                       updated_by = p_user_name
        WHEN NOT MATCHED THEN
            INSERT (setting_id, provider_name, api_key, model_name, endpoint_url, updated_by)
            VALUES (1, 'OPENROUTER', TRIM(p_api_key), NVL(p_model_name, 'google/gemini-flash-1.5'), NVL(p_endpoint_url, 'https://openrouter.ai/api/v1/chat/completions'), p_user_name);
        COMMIT;
    END save_config;


    -- Status line on the settings row, written in its own transaction so a
    -- failed call never commits (or rolls back) the caller's work.
    PROCEDURE set_status(p_status IN VARCHAR2) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        UPDATE fc_ai_settings
           SET last_test_status = SUBSTR(p_status, 1, 400),
               last_test_date = CURRENT_TIMESTAMP
         WHERE setting_id = 1;
        COMMIT;
    END set_status;

    PROCEDURE log_call(
        p_tender_id   IN NUMBER,
        p_agent       IN VARCHAR2,
        p_model       IN VARCHAR2,
        p_prompt_tok  IN NUMBER,
        p_compl_tok   IN NUMBER,
        p_cost        IN NUMBER,
        p_currency    IN VARCHAR2,
        p_latency_ms  IN NUMBER,
        p_outcome     IN VARCHAR2,
        p_error       IN VARCHAR2,
        p_response    IN CLOB DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO fc_ai_calls (
            tender_id, agent, model_name, prompt_tokens, completion_tokens,
            cost_amount, cost_currency, latency_ms, outcome, error_message, response_text, created_by
        ) VALUES (
            p_tender_id, SUBSTR(p_agent, 1, 50), SUBSTR(p_model, 1, 100), p_prompt_tok, p_compl_tok,
            p_cost, p_currency, p_latency_ms, p_outcome, SUBSTR(p_error, 1, 1000), p_response,
            NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER)
        );
        COMMIT;
    END log_call;

    FUNCTION call_openrouter(
        p_system_prompt IN CLOB,
        p_user_prompt   IN CLOB,
        p_model         IN VARCHAR2 DEFAULT NULL,
        p_temperature   IN NUMBER DEFAULT 0.7,
        p_max_tokens    IN NUMBER DEFAULT 1800,
        p_tender_id     IN NUMBER DEFAULT NULL,
        p_agent         IN VARCHAR2 DEFAULT 'GENERAL',
        p_json_mode     IN VARCHAR2 DEFAULT 'N'
    ) RETURN CLOB IS
        l_set       fc_ai_settings%ROWTYPE;
        l_model     VARCHAR2(100);
        l_body      CLOB;
        l_response  CLOB;
        l_content   CLOB;
        l_started   TIMESTAMP WITH TIME ZONE := SYSTIMESTAMP;
        l_elapsed   INTERVAL DAY TO SECOND;
        l_latency   NUMBER;
        l_in_tok    NUMBER;
        l_out_tok   NUMBER;
        l_cost      NUMBER;
        l_errm      VARCHAR2(1000);
        l_json_mode VARCHAR2(1) := NVL(p_json_mode, 'N');

        FUNCTION build_body(p_json VARCHAR2) RETURN CLOB IS
            l_obj json_object_t := json_object_t();
            l_msgs json_array_t := json_array_t();
            l_m json_object_t;
        BEGIN
            l_m := json_object_t(); l_m.put('role', 'system'); l_m.put('content', p_system_prompt); l_msgs.append(l_m);
            l_m := json_object_t(); l_m.put('role', 'user'); l_m.put('content', p_user_prompt); l_msgs.append(l_m);
            l_obj.put('model', l_model);
            l_obj.put('messages', l_msgs);
            l_obj.put('temperature', p_temperature);
            l_obj.put('max_tokens', p_max_tokens);
            IF p_json = 'Y' THEN
                l_obj.put('response_format', json_object_t('{"type":"json_object"}'));
            END IF;
            -- OpenRouter reports the real cost when asked; other endpoints don't need it.
            IF LOWER(l_set.endpoint_url) LIKE '%openrouter.ai%' THEN
                l_obj.put('usage', json_object_t('{"include":true}'));
                -- Reasoning models spend completion tokens thinking; keep that short
                -- so the answer itself fits in max_tokens.
                l_obj.put('reasoning', json_object_t('{"enabled":false,"exclude":true}'));
            END IF;
            RETURN l_obj.to_clob;
        END build_body;

        PROCEDURE send(p_json VARCHAR2) IS
        BEGIN
            apex_web_service.g_request_headers.DELETE;
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || TRIM(l_set.api_key);
            apex_web_service.g_request_headers(2).name := 'Content-Type';
            apex_web_service.g_request_headers(2).value := 'application/json';
            apex_web_service.g_request_headers(3).name := 'X-Title';
            apex_web_service.g_request_headers(3).value := NVL(l_set.app_name, 'Flash Concepts Proposal Engine');
            IF l_set.site_url IS NOT NULL THEN
                apex_web_service.g_request_headers(4).name := 'HTTP-Referer';
                apex_web_service.g_request_headers(4).value := l_set.site_url;
            END IF;
            l_body := build_body(p_json);
            -- Network drops and rate limits (429/5xx) are usually transient: try once more.
            FOR l_try IN 1 .. 2 LOOP
                BEGIN
                    l_response := apex_web_service.make_rest_request(
                        p_url              => l_set.endpoint_url,
                        p_http_method      => 'POST',
                        p_body             => l_body,
                        p_transfer_timeout => 300
                    );
                    EXIT WHEN apex_web_service.g_status_code NOT IN (429, 500, 502, 503, 504) OR l_try = 2;
                EXCEPTION
                    WHEN OTHERS THEN
                        IF l_try = 2 THEN RAISE; END IF;
                END;
                dbms_session.sleep(3);
            END LOOP;
        END send;
    BEGIN
        SELECT * INTO l_set FROM fc_ai_settings WHERE setting_id = 1;
        l_model := NVL(p_model, l_set.model_name);

        IF l_set.api_key IS NULL OR LENGTH(TRIM(l_set.api_key)) < 10 OR NVL(l_set.is_active, 'Y') = 'N' THEN
            log_call(p_tender_id, p_agent, l_model, NULL, NULL, NULL, NULL, 0, 'OFFLINE', 'No API key configured or AI disabled');
            RETURN NULL;
        END IF;

        send(l_json_mode);
        -- Some models reject response_format; retry once as plain text.
        IF apex_web_service.g_status_code = 400 AND l_json_mode = 'Y' THEN
            send('N');
        END IF;

        l_elapsed := SYSTIMESTAMP - l_started;
        l_latency := ROUND(EXTRACT(DAY FROM l_elapsed) * 86400000 + EXTRACT(HOUR FROM l_elapsed) * 3600000
                         + EXTRACT(MINUTE FROM l_elapsed) * 60000 + EXTRACT(SECOND FROM l_elapsed) * 1000);

        IF apex_web_service.g_status_code = 200 THEN
            apex_json.parse(l_response);
            l_content := apex_json.get_clob(p_path => 'choices[1].message.content');
            IF l_content IS NULL OR LENGTH(TRIM(l_content)) = 0 THEN
                l_content := apex_json.get_clob(p_path => 'choices[1].message.reasoning');
            END IF;
            l_in_tok  := apex_json.get_number(p_path => 'usage.prompt_tokens');
            l_out_tok := apex_json.get_number(p_path => 'usage.completion_tokens');
            l_cost    := apex_json.get_number(p_path => 'usage.cost');
            IF l_cost IS NULL OR l_cost = 0 THEN
                -- Our own price list (per million tokens) for endpoints that don't report cost.
                l_cost := (NVL(l_in_tok, 0) * NVL(l_set.input_cost_per_mtok, 0)
                         + NVL(l_out_tok, 0) * NVL(l_set.output_cost_per_mtok, 0)) / 1000000;
            END IF;
            log_call(p_tender_id, p_agent, l_model, l_in_tok, l_out_tok, l_cost,
                     NVL(l_set.cost_currency, 'USD'), l_latency, 'OK', NULL, l_content);
            RETURN l_content;
        ELSE
            l_errm := 'HTTP ' || apex_web_service.g_status_code || ': ' || SUBSTR(l_response, 1, 300);
            log_call(p_tender_id, p_agent, l_model, NULL, NULL, NULL, NULL, l_latency, 'ERROR', l_errm);
            set_status('ERROR ' || l_errm);
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            l_errm := SUBSTR(SQLERRM, 1, 900);
            log_call(p_tender_id, p_agent, l_model, NULL, NULL, NULL, NULL, NULL, 'ERROR', l_errm);
            set_status('EXCEPTION: ' || l_errm);
            RETURN NULL;
    END call_openrouter;

    FUNCTION extract_json(p_text IN CLOB) RETURN CLOB IS
        l_start PLS_INTEGER;
        l_end   PLS_INTEGER := 0;
        l_len   PLS_INTEGER;
        l_tail  VARCHAR2(4000);
        l_json  CLOB;
    BEGIN
        IF p_text IS NULL THEN
            RETURN NULL;
        END IF;
        l_len := DBMS_LOB.GETLENGTH(p_text);
        l_start := DBMS_LOB.INSTR(p_text, '{');
        -- DBMS_LOB.INSTR cannot search backwards, so look for the last '}' in the
        -- final chunk of the reply (a model's closing chatter is short).
        l_tail := DBMS_LOB.SUBSTR(p_text, LEAST(l_len, 4000), GREATEST(l_len - 3999, 1));
        IF INSTR(l_tail, '}', -1) > 0 THEN
            l_end := GREATEST(l_len - 3999, 1) + INSTR(l_tail, '}', -1) - 1;
        END IF;
        IF l_start = 0 OR l_end <= l_start THEN
            RETURN NULL;
        END IF;
        DBMS_LOB.CREATETEMPORARY(l_json, TRUE);
        DBMS_LOB.COPY(l_json, p_text, l_end - l_start + 1, 1, l_start);
        IF json_object_t.parse(l_json) IS NOT NULL THEN
            RETURN l_json;
        END IF;
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END extract_json;

    FUNCTION test_connection RETURN VARCHAR2 IS
        l_res CLOB;
    BEGIN
        l_res := call_openrouter(
            p_system_prompt => 'You are an AI diagnostic assistant. Reply with exact text "PONG: FLASH_CONCEPTS_ONLINE".',
            p_user_prompt   => 'PING',
            p_max_tokens    => 50,
            p_agent         => 'CONNECTION_TEST'
        );

        IF l_res IS NOT NULL AND INSTR(l_res, 'PONG') > 0 THEN
            set_status('CONNECTED: ' || SUBSTR(l_res, 1, 200));
            RETURN 'SUCCESS: Connected to the AI service. Response: ' || SUBSTR(l_res, 1, 80);
        ELSE
            RETURN 'FAILED: Could not reach the AI service. Check the API key, endpoint and model in AI settings.';
        END IF;
    END test_connection;

    PROCEDURE analyse_brief(
        p_tender_id     IN NUMBER,
        p_document_id   IN NUMBER,
        p_user_name     IN VARCHAR2,
        x_message       OUT VARCHAR2
    ) IS
        l_text     CLOB;
        l_fname    VARCHAR2(255);
        l_client   VARCHAR2(150);
        l_title    VARCHAR2(250);
        l_office   VARCHAR2(10);
        l_reply    CLOB;
        l_json     CLOB;
        l_summary  VARCHAR2(4000);
        l_req_cnt  PLS_INTEGER := 0;
        l_risk_cnt PLS_INTEGER := 0;
        l_q_cnt    PLS_INTEGER := 0;
        l_trimmed  CLOB;
        c_max_chars CONSTANT PLS_INTEGER := 60000;
    BEGIN
        SELECT d.extracted_text, d.file_name, t.client_name, t.project_title, t.office
          INTO l_text, l_fname, l_client, l_title, l_office
          FROM fc_tender_documents d
          JOIN fc_tenders t ON t.tender_id = d.tender_id
         WHERE d.document_id = p_document_id
           AND d.tender_id = p_tender_id;

        -- Keep the prompt within the model's context window. (DBMS_LOB.SUBSTR returns
        -- NULL above 32767 characters, so trim with DBMS_LOB.TRIM on a copy instead.)
        IF DBMS_LOB.GETLENGTH(l_text) > c_max_chars THEN
            DBMS_LOB.CREATETEMPORARY(l_trimmed, TRUE);
            DBMS_LOB.COPY(l_trimmed, l_text, c_max_chars, 1, 1);
            l_text := l_trimmed;
        END IF;

        IF l_text IS NULL OR DBMS_LOB.GETLENGTH(l_text) < 50 THEN
            UPDATE fc_tender_documents SET analysis_status = 'NO_TEXT' WHERE document_id = p_document_id;
            x_message := 'No readable text was found in ' || l_fname || '. Upload a text-based PDF or Word file.';
            RETURN;
        END IF;

        -- Retry once if the model breaks the JSON.
        FOR l_attempt IN 1 .. 2 LOOP
            l_reply := call_openrouter(
                p_system_prompt =>
                    'You analyse client briefs and tender documents for Flash Concepts, a B2B event agency in Singapore and Jakarta '
                 || 'that designs corporate events, exhibition booths and stages for financial-sector clients. '
                 || 'Read the document and reply with ONE JSON object only, no other text, in this shape: '
                 || '{"summary": "3-4 sentence summary of what the client wants", '
                 || '"requirements": [{"category": "STRATEGY|AUDIENCE|SCALE|VENUE|SPATIAL|LOGISTICS|TIMELINE|COMMERCIAL|COMPLIANCE|DELIVERABLES", '
                 || '"label": "short name, max 8 words", "value": "what the document says, quote numbers and dates exactly", '
                 || '"page": page number or null, "missing": false, "contradictory": false}], '
                 || '"risks": [{"category": "short code e.g. VENUE_CLEARANCE, CURFEW, BUDGET, POWER, PERMITS, TIMELINE", '
                 || '"severity": "CRITICAL|WARNING|ADVISORY", "title": "short title", "description": "why it matters for planning, design or operations", '
                 || '"mitigation": "a practical next step"}], '
                 || '"questions": ["questions to ask the client where the brief is unclear or missing information"]}. '
                 || 'Only use facts stated in the document. If something important (budget, date, venue, audience size, deliverables, '
                 || 'submission format) is not stated, add it as a requirement with "missing": true and value "Not stated". '
                 || 'Flag statements that contradict each other with "contradictory": true. Write in plain British English.',
                p_user_prompt =>
                    'Client: ' || l_client || CHR(10) || 'Project: ' || l_title || CHR(10) || 'Office: ' || l_office || CHR(10)
                 || 'Document: ' || l_fname || CHR(10) || '--- DOCUMENT TEXT ---' || CHR(10)
                 || l_text,
                p_temperature => CASE l_attempt WHEN 1 THEN 0.2 ELSE 0.1 END,
                p_max_tokens  => 8000,
                p_tender_id   => p_tender_id,
                p_agent       => 'BRIEF_ANALYSIS',
                p_json_mode   => 'Y'
            );
            l_json := extract_json(l_reply);
            EXIT WHEN l_json IS NOT NULL;
        END LOOP;

        IF l_json IS NULL THEN
            -- Keep the start and end of the raw reply for troubleshooting.
            UPDATE fc_tender_documents
               SET analysis_status = 'FAILED',
                   analysis_summary = SUBSTR('AI reply could not be read. Length ' || NVL(DBMS_LOB.GETLENGTH(l_reply), 0)
                       || '. Start: ' || DBMS_LOB.SUBSTR(l_reply, 1500, 1)
                       || ' ... End: ' || DBMS_LOB.SUBSTR(l_reply, 1500, GREATEST(NVL(DBMS_LOB.GETLENGTH(l_reply), 0) - 1499, 1)), 1, 4000)
             WHERE document_id = p_document_id;
            x_message := 'The AI service did not return a usable analysis for ' || l_fname
                      || '. The document is saved; try "Analyse brief" again or check AI settings.';
            RETURN;
        END IF;

        l_summary := SUBSTR(json_value(l_json, '$.summary' RETURNING VARCHAR2(4000) NULL ON ERROR), 1, 4000);

        -- A new analysis replaces the previous AI output for this tender.
        DELETE FROM fc_intake_fields WHERE tender_id = p_tender_id;
        DELETE FROM fc_planning_flags WHERE tender_id = p_tender_id;

        FOR r IN (
            SELECT jt.*
              FROM json_table(l_json, '$.requirements[*]'
                     COLUMNS (category      VARCHAR2(100)  PATH '$.category',
                              label         VARCHAR2(400)  PATH '$.label',
                              val           VARCHAR2(4000) PATH '$.value',
                              page_no       VARCHAR2(20)   PATH '$.page',
                              missing       VARCHAR2(10)   PATH '$.missing',
                              contradictory VARCHAR2(10)   PATH '$.contradictory')) jt
        ) LOOP
            CONTINUE WHEN r.label IS NULL;
            INSERT INTO fc_intake_fields (
                tender_id, field_category, field_label, extracted_value, source_doc_ref,
                page_number, is_missing, is_contradictory, review_status
            ) VALUES (
                p_tender_id, SUBSTR(UPPER(NVL(r.category, 'GENERAL')), 1, 50), SUBSTR(r.label, 1, 100), r.val, SUBSTR(l_fname, 1, 255),
                CASE WHEN REGEXP_LIKE(r.page_no, '^\d+$') THEN TO_NUMBER(r.page_no) END,
                CASE WHEN LOWER(r.missing) = 'true' THEN 'Y' ELSE 'N' END,
                CASE WHEN LOWER(r.contradictory) = 'true' THEN 'Y' ELSE 'N' END,
                'PENDING'
            );
            l_req_cnt := l_req_cnt + 1;
        END LOOP;

        FOR q IN (
            SELECT jt.question
              FROM json_table(l_json, '$.questions[*]' COLUMNS (question VARCHAR2(4000) PATH '$')) jt
             WHERE jt.question IS NOT NULL
        ) LOOP
            l_q_cnt := l_q_cnt + 1;
            INSERT INTO fc_intake_fields (
                tender_id, field_category, field_label, extracted_value, source_doc_ref,
                is_missing, is_contradictory, review_status
            ) VALUES (
                p_tender_id, 'CLARIFICATION', 'Question for client ' || l_q_cnt, q.question, SUBSTR(l_fname, 1, 255),
                'Y', 'N', 'PENDING'
            );
        END LOOP;

        FOR f IN (
            SELECT jt.*
              FROM json_table(l_json, '$.risks[*]'
                     COLUMNS (category    VARCHAR2(100)  PATH '$.category',
                              severity    VARCHAR2(30)   PATH '$.severity',
                              title       VARCHAR2(400)  PATH '$.title',
                              description VARCHAR2(4000) PATH '$.description',
                              mitigation  VARCHAR2(4000) PATH '$.mitigation')) jt
        ) LOOP
            CONTINUE WHEN f.title IS NULL;
            INSERT INTO fc_planning_flags (
                tender_id, flag_category, severity, title, description, recommended_mitigation, status, created_at
            ) VALUES (
                p_tender_id,
                SUBSTR(REGEXP_REPLACE(UPPER(NVL(f.category, 'GENERAL')), '[^A-Z0-9]+', '_'), 1, 50),
                CASE WHEN UPPER(f.severity) IN ('CRITICAL', 'WARNING', 'ADVISORY', 'INFO') THEN UPPER(f.severity) ELSE 'ADVISORY' END,
                SUBSTR(f.title, 1, 200), SUBSTR(NVL(f.description, f.title), 1, 2000), SUBSTR(f.mitigation, 1, 2000),
                'ACTIVE', CURRENT_TIMESTAMP
            );
            l_risk_cnt := l_risk_cnt + 1;
        END LOOP;

        UPDATE fc_tender_documents
           SET analysis_status = 'ANALYSED',
               analysis_summary = l_summary
         WHERE document_id = p_document_id;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'AI_BRIEF_ANALYSIS', 'FC_INTAKE_FIELDS',
            'Analysed ' || l_fname || ': ' || l_req_cnt || ' requirements, ' || l_risk_cnt || ' risks, '
            || l_q_cnt || ' client questions. Pending human review (Gate 0).'
        );

        x_message := 'Brief analysed: ' || l_req_cnt || ' requirements, ' || l_risk_cnt || ' planning risks and '
                  || l_q_cnt || ' questions for the client. Please review them before confirming Gate 0.';
    END analyse_brief;

    -- Planning Agent (Michelle): concept options from the confirmed brief.
    PROCEDURE run_planning_agent(
        p_tender_id     IN NUMBER,
        p_user_name     IN VARCHAR2
    ) IS
        l_client        VARCHAR2(150);
        l_title         VARCHAR2(250);
        l_currency      VARCHAR2(10);
        l_budget        NUMBER;
        l_brief         CLOB;
        l_risks         CLOB;
        l_research      CLOB;
        l_reply         CLOB;
        l_json          CLOB;
        l_cnt           PLS_INTEGER := 0;
        l_need          PLS_INTEGER;
        l_avoid         VARCHAR2(4000);

        TYPE t_concept IS RECORD (
            title VARCHAR2(400), narrative VARCHAR2(4000), brief_fit VARCHAR2(4000), event_flow VARCHAR2(4000),
            spatial VARCHAR2(4000), fringe VARCHAR2(4000), img_prompt VARCHAR2(1000));
        TYPE t_concepts IS TABLE OF t_concept;
        l_list          t_concepts := t_concepts();

        PROCEDURE insert_template_concepts IS
        BEGIN
        INSERT INTO fc_concept_options (
            tender_id, option_code, concept_title, narrative, brief_fit,
            event_flow, spatial_notes, fringe_activities, image_url, is_selected
        ) VALUES (
            p_tender_id, 'A',
            l_client || ' Horizon: The Experience Journey',
            'An architectural transformation tailored specifically for ' || l_client || ' showcasing ' || l_title || '. Features an immersive central proscenium with perimeter interactive pods highlighting institutional leadership, automated workflows, and regional excellence.',
            'Direct alignment with ' || l_client || ' core strategy and audience engagement goals.',
            '09:00 Registration & Smart RFID Badge Activation' || CHR(10) ||
            '10:00 Opening Keynote: Shaping the Next Era of ' || l_client || CHR(10) ||
            '11:30 Interactive Solution Sandboxes & Solution Showcases' || CHR(10) ||
            '14:00 Executive Fireside Panels' || CHR(10) ||
            '17:30 Networking Cocktail & Recognition Showcase',
            '14.0m W x 8.0m D proscenium stage; minimum 3.2m safety aisle clearance maintained.',
            '1. Interactive AI Engagement Studio.' || CHR(10) ||
            '2. Zero-Waste Sustainable Refreshment Bar.' || CHR(10) ||
            '3. Acoustic Private Executive Pods.',
            'https://image.pollinations.ai/prompt/' || apex_util.url_encode('photorealistic futuristic keynote stage curved LED screen proscenium architectural lighting ' || l_client || ' ' || l_title || ' MICE event Singapore 8k') || '?width=1200&height=800&nologo=true&enhance=true',
            'Y'
        );

        INSERT INTO fc_concept_options (
            tender_id, option_code, concept_title, narrative, brief_fit,
            event_flow, spatial_notes, fringe_activities, image_url, is_selected
        ) VALUES (
            p_tender_id, 'B',
            'Quantum Velocity: Next-Gen ' || l_client || ' Experience',
            'A high-energy, digital-forward pavilion featuring 360-degree holographic ribbon displays, interactive spatial soundscapes, and real-time live demonstrations for ' || l_title || '.',
            'Emphasizes cutting-edge digital transformation and modern attendee engagement.',
            '09:30 Immersive Keynote on Future Horizons' || CHR(10) ||
            '11:00 Multi-Track Technical Demos' || CHR(10) ||
            '15:00 Rapid-Fire Lightning Innovation Pitches',
            'Overhead suspended trussing at 5.5m clear height. Verified within venue point-load limits.',
            '1. Holographic Live Demo Showcase.' || CHR(10) ||
            '2. Spatial Audio Networking Lounge.',
            'https://image.pollinations.ai/prompt/' || apex_util.url_encode('futuristic holographic exhibition booth pavilion ribbon displays 360 degree neon cyan lighting modern architecture ' || l_client) || '?width=1200&height=800&nologo=true&enhance=true',
            'N'
        );

        INSERT INTO fc_concept_options (
            tender_id, option_code, concept_title, narrative, brief_fit,
            event_flow, spatial_notes, fringe_activities, image_url, is_selected
        ) VALUES (
            p_tender_id, 'C',
            'EcoSphere: Sustainable Community & Impact Showcase',
            'A biophilic architectural showcase utilizing certified recycled timber, living greenery walls, and low-energy LED surfaces celebrating sustainable governance and community impact for ' || l_client || '.',
            'Fulfills strict Singapore Green Plan 2030 and BCA Green Mark MICE standards.',
            '09:30 Opening Panel on Sustainability Taxonomy' || CHR(10) ||
            '13:30 Climate Tech & Community Showcase' || CHR(10) ||
            '16:30 Leadership Impact Forum',
            'Single-story modular structures under 3.8m; eliminates need for PE structural permit.',
            '1. Living Wall Carbon Offset Counter.' || CHR(10) ||
            '2. Sustainable Hydroponic Tea Bar.',
            'https://image.pollinations.ai/prompt/' || apex_util.url_encode('biophilic sustainable exhibition booth living green plant walls recycled timber modern architecture warm ambient lighting ' || l_client) || '?width=1200&height=800&nologo=true&enhance=true',
            'N'
        );
        END insert_template_concepts;

    BEGIN
        SELECT client_name, project_title, NVL(primary_currency, 'SGD'), NVL(total_price, 0)
          INTO l_client, l_title, l_currency, l_budget
          FROM fc_tenders
         WHERE tender_id = p_tender_id;

        -- Confirmed (or extracted) requirements and active risks from Gate 0.
        FOR r IN (
            SELECT field_category, field_label, NVL(confirmed_value, extracted_value) AS val, is_missing
              FROM fc_intake_fields
             WHERE tender_id = p_tender_id
             ORDER BY field_category, field_id
        ) LOOP
            l_brief := l_brief || '- [' || r.field_category || '] ' || r.field_label || ': ' || r.val
                    || CASE WHEN r.is_missing = 'Y' THEN ' (not stated by client)' END || CHR(10);
        END LOOP;
        FOR f IN (
            SELECT severity, title, recommended_mitigation
              FROM fc_planning_flags
             WHERE tender_id = p_tender_id AND status <> 'RESOLVED'
        ) LOOP
            l_risks := l_risks || '- ' || f.severity || ': ' || f.title
                    || CASE WHEN f.recommended_mitigation IS NOT NULL THEN ' (plan: ' || f.recommended_mitigation || ')' END || CHR(10);
        END LOOP;
        -- Only research a planner has approved is used.
        FOR r IN (
            SELECT claim_text FROM fc_research_findings
             WHERE tender_id = p_tender_id AND review_status = 'APPROVED'
             ORDER BY finding_id FETCH FIRST 5 ROWS ONLY
        ) LOOP
            l_research := l_research || '- ' || r.claim_text || CHR(10);
        END LOOP;

        -- Free and small models often return fewer concepts than asked or break the JSON.
        -- Keep the valid ones and ask only for the missing ones, up to three calls.
        FOR l_attempt IN 1 .. 3 LOOP
            EXIT WHEN l_list.COUNT >= 3;
            l_need := 3 - l_list.COUNT;
            l_reply := call_openrouter(
                p_system_prompt =>
                    'You are a senior planning strategist at Flash Concepts, an experiential B2B event agency in Singapore and Jakarta '
                 || 'serving banks, payment providers and asset managers. Create exactly ' || l_need || ' clearly different event concept option(s) for the brief. '
                 || 'Each must answer the stated requirements, respect the listed risks and constraints, and be realistic to build. '
                 || 'Reply with ONE JSON object only, with ' || l_need || ' item(s) in the "concepts" array. Each item has these keys: '
                 || '"title" (concept name, max 8 words), '
                 || '"narrative" (4-6 sentences: the big idea and the attendee experience), '
                 || '"brief_fit" (how it meets the client''s objectives and requirements, refer to them specifically), '
                 || '"event_flow" (run of show, one line per item, each starting with a time, separated by \n), '
                 || '"spatial_notes" (key structures with approximate dimensions in metres and clearance notes), '
                 || '"fringe_activities" (2-4 numbered fringe activities separated by \n), '
                 || '"image_prompt" (2-3 sentences a designer can paste into an image generator: camera angle, the main structures, materials, lighting and mood). '
                 || 'Shape: {"concepts": [{"title": "...", "narrative": "...", ...}'
                 || CASE WHEN l_need > 1 THEN ', {"title": "...", ...}' END
                 || CASE WHEN l_need > 2 THEN ', {"title": "...", ...}' END
                 || ']}. Put your recommended concept first. Plain British English, no marketing cliches.',
                p_user_prompt =>
                    'Client: ' || l_client || CHR(10) || 'Project: ' || l_title || CHR(10)
                 || CASE WHEN l_budget > 0 THEN 'Indicative budget: ' || l_currency || ' ' || TO_CHAR(l_budget, 'FM999G999G999G990') || CHR(10) END
                 || 'Requirements from the brief:' || CHR(10) || NVL(l_brief, '- No requirements captured yet; use the project title.' || CHR(10))
                 || 'Risks and constraints:' || CHR(10) || NVL(l_risks, '- None recorded.' || CHR(10))
                 || CASE WHEN l_research IS NOT NULL THEN 'Client background approved by the planner:' || CHR(10) || l_research END
                 || CASE WHEN l_avoid IS NOT NULL THEN 'Already proposed (make yours clearly different from these): ' || l_avoid || CHR(10) END,
                p_temperature => CASE l_attempt WHEN 1 THEN 0.7 ELSE 0.8 END,
                p_max_tokens  => 8000,
                p_tender_id   => p_tender_id,
                p_agent       => 'CONCEPT_GENERATION',
                p_json_mode   => 'Y'
            );
            l_json := extract_json(l_reply);
            IF l_json IS NOT NULL THEN
                FOR c IN (
                    SELECT jt.*
                      FROM json_table(l_json, '$.concepts[*]'
                             COLUMNS (title       VARCHAR2(400)  PATH '$.title',
                                      narrative   VARCHAR2(4000) PATH '$.narrative',
                                      brief_fit   VARCHAR2(4000) PATH '$.brief_fit',
                                      event_flow  VARCHAR2(4000) PATH '$.event_flow',
                                      spatial     VARCHAR2(4000) PATH '$.spatial_notes',
                                      fringe      VARCHAR2(4000) PATH '$.fringe_activities',
                                      img_prompt  VARCHAR2(1000) PATH '$.image_prompt')) jt
                     WHERE jt.title IS NOT NULL AND jt.narrative IS NOT NULL
                ) LOOP
                    EXIT WHEN l_list.COUNT >= 3;
                    l_list.EXTEND;
                    l_list(l_list.COUNT) := t_concept(c.title, c.narrative, c.brief_fit, c.event_flow, c.spatial, c.fringe, c.img_prompt);
                    l_avoid := SUBSTR(l_avoid || CASE WHEN l_avoid IS NOT NULL THEN '; ' END || c.title, 1, 3900);
                END LOOP;
            END IF;
        END LOOP;

        DELETE FROM fc_concept_options WHERE tender_id = p_tender_id;

        FOR i IN 1 .. l_list.COUNT LOOP
            l_cnt := l_cnt + 1;
            INSERT INTO fc_concept_options (
                tender_id, option_code, concept_title, narrative, brief_fit, event_flow,
                spatial_notes, fringe_activities, image_url, image_prompt, is_selected, generated_by
            ) VALUES (
                p_tender_id, CHR(64 + l_cnt), SUBSTR(l_list(i).title, 1, 150), l_list(i).narrative, l_list(i).brief_fit, l_list(i).event_flow,
                SUBSTR(l_list(i).spatial, 1, 2000), SUBSTR(l_list(i).fringe, 1, 2000),
                NULL, SUBSTR(l_list(i).img_prompt, 1, 1000),  -- no hot-linked image; the designer renders the visual brief
                'N', 'AI'
            );
        END LOOP;

        IF l_cnt = 0 THEN
            -- AI unavailable: show the clearly labelled template options instead.
            insert_template_concepts;
            UPDATE fc_concept_options SET is_selected = 'N', generated_by = 'TEMPLATE' WHERE tender_id = p_tender_id;
        END IF;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'AI_PLANNING_AGENT_RUN', 'FC_CONCEPT_OPTIONS',
            CASE WHEN l_cnt > 0 THEN 'AI generated ' || l_cnt || ' concept options for ' || l_client
                 ELSE 'AI unavailable: template concept options shown for ' || l_client END
        );
    END run_planning_agent;


    -- Design & PPT Agent (Adi)
    PROCEDURE run_design_ppt_agent(
        p_tender_id     IN NUMBER,
        p_user_name     IN VARCHAR2
    ) IS
    BEGIN
        fc_design_api.generate_slide_deck_drafts(p_tender_id, p_user_name);
        fc_design_api.generate_3d_specs(p_tender_id, p_user_name);
        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'AI_DESIGN_PPT_AGENT_RUN', 'FC_SPATIAL_CHECKS',
            'Design & PPT Agent (Adi) generated slide deck drafts and 3D specifications.'
        );
    END run_design_ppt_agent;

    -- Operations & BOQ Costing Agent (Wei Lin)
    PROCEDURE run_costing_agent(
        p_tender_id     IN NUMBER,
        p_user_name     IN VARCHAR2
    ) IS
    BEGIN
        fc_costing_api.decode_sketches_to_boq(p_tender_id, p_user_name);
        fc_costing_api.calculate_boq_totals(p_tender_id, 33.33, p_user_name);
        fc_costing_api.generate_bespoke_rfqs(p_tender_id, p_user_name);
        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'AI_COSTING_AGENT_RUN', 'FC_BOQ_ITEMS',
            'Costing Agent (Wei Lin) verified >=45% margin and prepared contractor RFQ drafts.'
        );
    END run_costing_agent;

    -- Bilingual Regional Translation Agent (EN -> ID)
    PROCEDURE run_translation_agent(
        p_tender_id     IN NUMBER,
        p_user_name     IN VARCHAR2
    ) IS
    BEGIN
        fc_workflow_api.execute_bilingual_translation(p_tender_id, p_user_name);
    END run_translation_agent;

END fc_ai_agent_api;
/
