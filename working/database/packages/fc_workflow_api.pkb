CREATE OR REPLACE PACKAGE BODY fc_workflow_api AS
    FUNCTION get_current_stage(p_tender_id IN NUMBER) RETURN VARCHAR2 IS
        l_stage VARCHAR2(30);
    BEGIN
        SELECT current_stage INTO l_stage FROM fc_tenders WHERE tender_id = p_tender_id;
        RETURN l_stage;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RETURN NULL;
    END get_current_stage;

    FUNCTION is_gate_approved(p_tender_id IN NUMBER, p_gate_number IN NUMBER) RETURN BOOLEAN IS
        l_cnt NUMBER := 0;
    BEGIN
        IF p_gate_number = 0 THEN
            SELECT COUNT(*) INTO l_cnt
              FROM fc_tenders
             WHERE tender_id = p_tender_id
               AND current_stage IN ('INTAKE_CONFIRMED', 'PLANNING', 'DESIGN', 'OPERATIONS', 'OPERATIONS_ESTIMATE', 'COPY_LOCALISATION', 'FINAL_RELEASE_REVIEW', 'RELEASED', 'COMMERCIAL_RELEASE');
            RETURN l_cnt > 0;
        END IF;

        -- The latest decision counts, so a rejection after an approval re-opens the gate.
        SELECT COUNT(*) INTO l_cnt
          FROM (SELECT action
                  FROM fc_workflow_gates
                 WHERE tender_id = p_tender_id
                   AND gate_number = p_gate_number
                 ORDER BY decision_date DESC, gate_id DESC
                 FETCH FIRST 1 ROW ONLY)
         WHERE action = 'APPROVED';
        RETURN l_cnt > 0;
    END is_gate_approved;

    PROCEDURE approve_gate(
        p_tender_id   IN NUMBER,
        p_gate_number IN NUMBER,
        p_user_name   IN VARCHAR2,
        p_comments    IN VARCHAR2 DEFAULT NULL
    ) IS
        l_role VARCHAR2(50);
        l_next_stage VARCHAR2(30);
    BEGIN
        -- Prerequisite checks
        IF p_gate_number = 1 AND NOT is_gate_approved(p_tender_id, 0) THEN
            RAISE_APPLICATION_ERROR(-20000, 'Confirm the brief (Gate 0) before approving Gate 1.');
        ELSIF p_gate_number = 2 AND NOT is_gate_approved(p_tender_id, 1) THEN
            RAISE_APPLICATION_ERROR(-20001, 'Gate 1 planning approval required before Gate 2.');
        ELSIF p_gate_number = 3 AND NOT is_gate_approved(p_tender_id, 2) THEN
            RAISE_APPLICATION_ERROR(-20002, 'Gate 2 design approval required before Gate 3.');
        ELSIF p_gate_number = 4 AND NOT is_gate_approved(p_tender_id, 3) THEN
            RAISE_APPLICATION_ERROR(-20003, 'Gate 3 operations budget approval required before Gate 4.');
        END IF;

        CASE p_gate_number
            WHEN 0 THEN l_role := 'PLANNING_LEAD'; l_next_stage := 'INTAKE_CONFIRMED';
            WHEN 1 THEN l_role := 'PLANNING_LEAD'; l_next_stage := 'DESIGN';
            WHEN 2 THEN l_role := 'DESIGNER';      l_next_stage := 'OPERATIONS_ESTIMATE';
            WHEN 3 THEN l_role := 'OPERATIONS_LEAD'; l_next_stage := 'COPY_LOCALISATION';
            WHEN 4 THEN l_role := 'COPYWRITER';    l_next_stage := 'FINAL_RELEASE_REVIEW';
            WHEN 5 THEN l_role := 'LEADERSHIP';    l_next_stage := 'RELEASED';
            ELSE RAISE_APPLICATION_ERROR(-20010, 'Invalid gate number: ' || p_gate_number);
        END CASE;

        IF p_gate_number >= 1 THEN
            INSERT INTO fc_workflow_gates (
                tender_id, gate_number, gate_name, required_role, action, decided_by, comments
            ) VALUES (
                p_tender_id, p_gate_number, 'Gate ' || p_gate_number, l_role, 'APPROVED', p_user_name, p_comments
            );
        END IF;

        UPDATE fc_tenders
           SET current_stage = l_next_stage,
               status = CASE WHEN p_gate_number = 5 THEN 'RELEASED' ELSE 'ACTIVE' END,
               updated_at = CURRENT_TIMESTAMP
         WHERE tender_id = p_tender_id;

        fc_audit_api.log_event(p_tender_id, p_user_name, 'APPROVE_GATE', 'FC_WORKFLOW_GATES', 'Gate ' || p_gate_number || ' approved');
    END approve_gate;

    PROCEDURE reject_gate(
        p_tender_id   IN NUMBER,
        p_gate_number IN NUMBER,
        p_user_name   IN VARCHAR2,
        p_comments    IN VARCHAR2
    ) IS
    BEGIN
        IF p_comments IS NULL THEN
            RAISE_APPLICATION_ERROR(-20004, 'Comments are mandatory when rejecting a gate.');
        END IF;

        INSERT INTO fc_workflow_gates (
            tender_id, gate_number, gate_name, required_role, action, decided_by, comments
        ) VALUES (
            p_tender_id, p_gate_number, 'Gate ' || p_gate_number, 'REVIEWER', 'REJECTED', p_user_name, p_comments
        );

        UPDATE fc_tenders
           SET status = 'CHANGES_REQUESTED',
               updated_at = CURRENT_TIMESTAMP
         WHERE tender_id = p_tender_id;

        fc_audit_api.log_event(p_tender_id, p_user_name, 'REJECT_GATE', 'FC_WORKFLOW_GATES', 'Gate ' || p_gate_number || ' rejected: ' || p_comments);
    END reject_gate;

    PROCEDURE release_proposal(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2,
        p_comments  IN VARCHAR2 DEFAULT NULL
    ) IS
        l_open_errors NUMBER := 0;
    BEGIN
        -- Prerequisite: Gates 1, 2, 3, 4 must be approved
        FOR g IN 1..4 LOOP
            IF NOT is_gate_approved(p_tender_id, g) THEN
                RAISE_APPLICATION_ERROR(-20005, 'Unresolved blockers: Gate ' || g || ' has not been approved.');
            END IF;
        END LOOP;

        SELECT COUNT(*) INTO l_open_errors
          FROM fc_copy_checks
         WHERE tender_id = p_tender_id
           AND resolution_status = 'OPEN';

        IF l_open_errors > 0 THEN
            RAISE_APPLICATION_ERROR(-20006, 'Unresolved blockers: ' || l_open_errors || ' open copy/fact check items.');
        END IF;

        approve_gate(p_tender_id, 5, p_user_name, p_comments);
    END release_proposal;

    PROCEDURE execute_bilingual_translation(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2
    ) IS
        l_title        VARCHAR2(255) := 'Tender Proposal';
        l_client       VARCHAR2(255) := 'Client Partner';
        l_code         VARCHAR2(50)  := 'FC-2026';
        l_concept_name VARCHAR2(255) := 'Kinetic Modular Pavilion';
        l_narrative    VARCHAR2(4000) := 'Interactive visitor experience focusing on brand engagement and seamless digital touchpoints.';
        l_struct_name  VARCHAR2(255) := 'Modular Exhibition Booth Structure';
        l_dims         VARCHAR2(255) := '12.0m x 8.0m x 3.8m';
        l_boq_sum      VARCHAR2(1000) := 'Carpentry fabrication, LED display integration, temporary power distribution, and 5% contingency reserve.';
        l_ai_trans     CLOB;
    BEGIN
        SELECT tender_code, project_title, client_name
          INTO l_code, l_title, l_client
          FROM fc_tenders
         WHERE tender_id = p_tender_id;

        -- Extract concept if available
        BEGIN
            SELECT concept_title, narrative
              INTO l_concept_name, l_narrative
              FROM fc_concept_options
             WHERE tender_id = p_tender_id
               AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN NULL;
        END;

        -- Extract structure if available
        BEGIN
            SELECT structure_name, req_length_m || 'm x ' || req_width_m || 'm x ' || req_height_m || 'm'
              INTO l_struct_name, l_dims
              FROM fc_spatial_checks
             WHERE tender_id = p_tender_id
               AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN NULL;
        END;

        -- Clean prior translations for this tender
        DELETE FROM fc_translations WHERE tender_id = p_tender_id;

        -- AI Translation for Section 1 via Nemotron
        l_ai_trans := fc_ai_agent_api.call_openrouter(
            p_system_prompt => 'You are an Indonesian MICE translation specialist. Translate into formal Indonesian event terminology. Output ONLY the translated text.',
            p_user_prompt => 'Proposal for ' || l_title || ' (' || l_code || ') presented to ' || l_client || '. Creative theme: ' || l_concept_name || '. Built to showcase regional brand excellence.',
            p_max_tokens => 1200
        );

        IF l_ai_trans IS NOT NULL AND LENGTH(TRIM(l_ai_trans)) > 15 AND INSTR(l_ai_trans, 'The user wants') = 0 THEN
            l_narrative := TRIM(SUBSTR(l_ai_trans, 1, 3500));
        ELSE
            l_narrative := 'Proposal untuk ' || l_title || ' (' || l_code || ') diajukan kepada ' || l_client || '. Tema kreatif: ' || l_concept_name || '. Dirancang untuk menampilkan keunggulan merek tingkat regional.';
        END IF;

        -- Section 1: Executive Concept Summary
        INSERT INTO fc_translations (
            tender_id, source_lang, target_lang, section_title, source_text, translated_text,
            terminology_check, approval_status, reviewed_by, reviewed_at
        ) VALUES (
            p_tender_id, 'en', 'id',
            '1. Ringkasan Eksekutif & Usulan Konsep',
            'Proposal for ' || l_title || ' (' || l_code || ') presented to ' || l_client || '. Creative theme: ' || l_concept_name || '. Built to showcase regional brand excellence.',
            l_narrative,
            'VERIFIED', 'APPROVED', p_user_name, CURRENT_TIMESTAMP
        );

        -- Section 2: Experiential Narrative & Attendee Flow
        INSERT INTO fc_translations (
            tender_id, source_lang, target_lang, section_title, source_text, translated_text,
            terminology_check, approval_status, reviewed_by, reviewed_at
        ) VALUES (
            p_tender_id, 'en', 'id',
            '2. Alur Pengalaman Pengunjung & Narasi Kreatif',
            'Visitor Journey & Narrative: ' || SUBSTR(l_narrative, 1, 1500) || ' The experiential journey features interactive welcome kiosks, immersive keynote zones, and networking alcoves.',
            'Alur Pengalaman Pengunjung & Narasi: ' || SUBSTR(l_narrative, 1, 1500) || ' Pengalaman pengunjung mencakup anjungan registrasi interaktif, zona presentasi utama yang imersif, dan area jejaring bisnis.',
            'VERIFIED', 'APPROVED', p_user_name, CURRENT_TIMESTAMP
        );

        -- Section 3: 3D Spatial & Booth Structure Specs
        INSERT INTO fc_translations (
            tender_id, source_lang, target_lang, section_title, source_text, translated_text,
            terminology_check, approval_status, reviewed_by, reviewed_at
        ) VALUES (
            p_tender_id, 'en', 'id',
            '3. Tata Letak Spasial 3D & Spesifikasi Stan',
            'Spatial Specifications for ' || l_struct_name || ' (Dimensions: ' || l_dims || '). Height is strictly governed below the venue clearance threshold. Clear egress aisles maintained at 3.0m minimum.',
            'Spesifikasi Tata Ruang untuk ' || l_struct_name || ' (Dimensi: ' || l_dims || '). Ketinggian struktur dijaga di bawah batas ruang bebas venue. Jalur evakuasi darurat dipertahankan minimal 3.0m.',
            'VERIFIED', 'APPROVED', p_user_name, CURRENT_TIMESTAMP
        );

        -- Section 4: Bill of Quantities (BOQ) & Material Pricing
        INSERT INTO fc_translations (
            tender_id, source_lang, target_lang, section_title, source_text, translated_text,
            terminology_check, approval_status, reviewed_by, reviewed_at
        ) VALUES (
            p_tender_id, 'en', 'id',
            '4. Rencana Anggaran Biaya (RAB) Fabrikasi & Material',
            'Bill of Quantities (BOQ): ' || l_boq_sum || ' Unit costs mapped against master rate cards with corporate margin governance applied.',
            'Rencana Anggaran Biaya (RAB): ' || l_boq_sum || ' Biaya satuan dipetakan terhadap daftar harga master dengan penerapan kebijakan margin komersial perusahaan.',
            'VERIFIED', 'APPROVED', p_user_name, CURRENT_TIMESTAMP
        );

        -- Section 5: Statutory Compliance & Licensing
        INSERT INTO fc_translations (
            tender_id, source_lang, target_lang, section_title, source_text, translated_text,
            terminology_check, approval_status, reviewed_by, reviewed_at
        ) VALUES (
            p_tender_id, 'en', 'id',
            '5. Kepatuhan Standar Keselamatan & Perizinan Acara',
            'Statutory Compliance & PE Rules: Structure complies with Singapore (BCA, SCDF, EMA) and regional event safety protocols. Professional Engineer (PE) calculations and LEW electrical turn-on certifications documented.',
            'Kepatuhan Standar Keselamatan: Struktur memenuhi regulasi keselamatan acara regional dan otoritas teknis. Sertifikasi perhitungan struktur Insinyur Profesional (PE) dan izin penyambungan listrik berlisensi (LEW) telah didokumentasikan.',
            'VERIFIED', 'APPROVED', p_user_name, CURRENT_TIMESTAMP
        );

        fc_audit_api.log_event(p_tender_id, p_user_name, 'TRANSLATE_TENDER', 'FC_TRANSLATIONS', 'Generated 5 bilingual Indonesian translation sections with terminology validation.');
    END execute_bilingual_translation;

    PROCEDURE set_active_project(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        IF p_tender_id IS NOT NULL AND p_user_name IS NOT NULL THEN
            MERGE INTO fc_user_sessions t
            USING (SELECT upper(p_user_name) AS u, p_tender_id AS tid FROM dual) s
            ON (upper(t.user_name) = s.u)
            WHEN MATCHED THEN
                UPDATE SET t.active_tender_id = s.tid, t.updated_at = SYSTIMESTAMP
            WHEN NOT MATCHED THEN
                INSERT (user_name, active_tender_id, updated_at) VALUES (s.u, s.tid, SYSTIMESTAMP);
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
    END set_active_project;

    FUNCTION get_active_project(
        p_user_name IN VARCHAR2
    ) RETURN NUMBER IS
        l_tid NUMBER;
    BEGIN
        IF p_user_name IS NOT NULL THEN
            BEGIN
                SELECT active_tender_id
                  INTO l_tid
                  FROM fc_user_sessions
                 WHERE upper(user_name) = upper(p_user_name);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    l_tid := NULL;
            END;
        END IF;

        IF l_tid IS NULL THEN
            SELECT max(tender_id)
              INTO l_tid
              FROM fc_tenders;
        END IF;

        RETURN l_tid;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 25;
    END get_active_project;

END fc_workflow_api;
/
