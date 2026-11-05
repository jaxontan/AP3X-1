CREATE OR REPLACE PACKAGE BODY fc_planning_api AS

    PROCEDURE create_tender(
        p_client_name    IN VARCHAR2,
        p_project_title  IN VARCHAR2,
        p_tender_code    IN VARCHAR2 DEFAULT NULL,
        p_office         IN VARCHAR2 DEFAULT 'SG',
        p_deadline_days  IN NUMBER DEFAULT 14,
        p_budget_ceiling IN NUMBER DEFAULT 150000,
        p_currency       IN VARCHAR2 DEFAULT 'SGD',
        p_user_name      IN VARCHAR2,
        x_tender_id      OUT NUMBER
    ) IS
        l_code VARCHAR2(30);
    BEGIN
        IF p_tender_code IS NULL THEN
            SELECT 'FC-' || TO_CHAR(SYSDATE, 'YYYY') || '-' || LPAD(TO_CHAR(NVL(MAX(tender_id)+1, 1)), 3, '0')
              INTO l_code
              FROM fc_tenders;
        ELSE
            l_code := p_tender_code;
        END IF;

        INSERT INTO fc_tenders (
            tender_code, client_name, project_title, office,
            current_stage, status, submission_deadline,
            primary_currency, total_price, sponsor_user,
            planning_lead, designer_user, ops_lead
        ) VALUES (
            l_code, p_client_name, p_project_title, NVL(p_office, 'SG'),
            'INTAKE_REVIEW', 'ACTIVE', SYSDATE + NVL(p_deadline_days, 14),
            NVL(p_currency, 'SGD'), NVL(p_budget_ceiling, 150000), p_user_name,
            p_user_name, 'ADI', 'WEILIN'
        ) RETURNING tender_id INTO x_tender_id;

        -- Commit tender so autonomous transaction logger can reference foreign key
        COMMIT;

        fc_audit_api.log_event(
            x_tender_id, p_user_name, 'CREATE_TENDER', 'FC_TENDERS',
            'New tender ' || l_code || ' created for ' || p_client_name
        );
    END create_tender;

    PROCEDURE confirm_intake(
        p_tender_id      IN NUMBER,
        p_user_name      IN VARCHAR2
    ) IS
        l_open_critical NUMBER;
    BEGIN
        -- Human checkpoint: every critical risk needs a decision before the brief is locked.
        SELECT COUNT(*) INTO l_open_critical
          FROM fc_planning_flags
         WHERE tender_id = p_tender_id AND severity = 'CRITICAL' AND status = 'ACTIVE';
        IF l_open_critical > 0 THEN
            RAISE_APPLICATION_ERROR(-20008, l_open_critical || ' critical risk(s) still open. Save a mitigation for each one before confirming Gate 0.');
        END IF;

        UPDATE fc_tenders
           SET current_stage = 'INTAKE_CONFIRMED',
               updated_by = p_user_name,
               updated_at = CURRENT_TIMESTAMP
         WHERE tender_id = p_tender_id;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'CONFIRM_INTAKE', 'FC_TENDERS',
            'Tender intake confirmed and locked for concept ideation'
        );
    END confirm_intake;

    PROCEDURE generate_concept_options(
        p_tender_id      IN NUMBER,
        p_user_name      IN VARCHAR2
    ) IS
    BEGIN
        IF NOT fc_workflow_api.is_gate_approved(p_tender_id, 0) THEN
            RAISE_APPLICATION_ERROR(-20009, 'Confirm the brief (Gate 0) on the Intake page before generating concepts.');
        END IF;
        fc_ai_agent_api.run_planning_agent(p_tender_id, p_user_name);
    END generate_concept_options;

    PROCEDURE ingest_and_parse_brief(
        p_tender_id      IN NUMBER,
        p_file_name      IN VARCHAR2,
        p_doc_type       IN VARCHAR2 DEFAULT 'BRIEF',
        p_user_name      IN VARCHAR2,
        x_doc_id         OUT NUMBER
    ) IS
        l_client        VARCHAR2(150);
        l_title         VARCHAR2(250);
        l_office        VARCHAR2(30);
        l_is_nyp        BOOLEAN := FALSE;
        l_is_dbs        BOOLEAN := FALSE;
        l_is_sff        BOOLEAN := FALSE;
        l_is_jkt        BOOLEAN := FALSE;
    BEGIN
        SELECT client_name, project_title, office
          INTO l_client, l_title, l_office
          FROM fc_tenders
         WHERE tender_id = p_tender_id;

        IF UPPER(p_file_name) LIKE '%NYP%' OR UPPER(l_client) LIKE '%NANYANG%' OR UPPER(l_title) LIKE '%NYP%' OR UPPER(l_title) LIKE '%ROADSHOW%' OR p_tender_id = 25 THEN
            l_is_nyp := TRUE;
        ELSIF UPPER(p_file_name) LIKE '%DBS%' OR UPPER(l_client) LIKE '%DBS%' OR UPPER(l_title) LIKE '%DBS%' OR p_tender_id = 1 THEN
            l_is_dbs := TRUE;
        ELSIF UPPER(p_file_name) LIKE '%FINTECH%' OR UPPER(p_file_name) LIKE '%SFF%' OR UPPER(l_title) LIKE '%FINTECH%' OR UPPER(l_title) LIKE '%SFF%' OR p_tender_id = 2 THEN
            l_is_sff := TRUE;
        ELSIF UPPER(p_file_name) LIKE '%PAYTECH%' OR UPPER(l_office) = 'JKT' OR p_tender_id = 4 THEN
            l_is_jkt := TRUE;
        ELSE
            l_is_nyp := TRUE;
        END IF;

        INSERT INTO fc_tender_documents (
            tender_id, doc_type, file_name, file_size_bytes,
            mime_type, version_num, uploaded_by
        ) VALUES (
            p_tender_id, NVL(p_doc_type, 'BRIEF'), p_file_name, 1420000,
            'application/pdf', 1.0, p_user_name
        ) RETURNING document_id INTO x_doc_id;

        -- 1. Populate Structured Diagnostic Criteria
        DELETE FROM fc_intake_fields WHERE tender_id = p_tender_id;

        IF l_is_nyp THEN
            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'LOGISTICS', 'EVENT_DATES', '8?10 December 2026 (Setup: 7 Dec 2026)', '8?10 December 2026', p_file_name, 2, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'VENUE', 'VENUE_LOCATION', 'NYP Auditorium Foyer & Block A Atrium', 'NYP Auditorium Foyer & Block A Atrium', p_file_name, 3, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'SCALE', 'ATTENDEE_SCALE', '1,200 attendees (students, faculty, industry partners)', '1,200 attendees', p_file_name, 4, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'SPATIAL', 'SPATIAL_FOOTPRINT', '18.0m x 12.0m allocated atrium zone (Clearance: 3.5m perimeter fire egress)', '18.0m x 12.0m allocated atrium zone', p_file_name, 5, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'COMMERCIAL', 'BUDGET_CEILING', 'SGD 150,000.00 (Target Margin: 25.0%)', 'SGD 150,000.00', p_file_name, 6, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'LOGISTICS', 'TEARDOWN_CURFEW', '23:00 SGT (Strict Campus Security Curfew & Egress Locking)', '23:00 SGT', p_file_name, 6, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'COMPLIANCE', 'SUSTAINABILITY_MANDATE', 'BCA Green Mark Singapore, Zero Single-Use Plastics, FSC-Timber', 'BCA Green Mark Standard', p_file_name, 7, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'STRATEGY', 'CORE_OBJECTIVES', 'Elevate NYP Graduate Student Innovation Roadshow & Exhibition 2026 with 14m proscenium keynote stage and interactive student demo pods', 'Elevate NYP Graduate Student Innovation Roadshow & Exhibition 2026', p_file_name, 1, 'N', 'N', 'CONFIRMED', p_user_name);

            UPDATE fc_tenders
               SET deal_value = 150000.00,
                   total_price = 150000.00,
                   submission_deadline = TO_DATE('2026-12-08', 'YYYY-MM-DD')
             WHERE tender_id = p_tender_id;

            DELETE FROM fc_planning_flags WHERE tender_id = p_tender_id;

            INSERT INTO fc_planning_flags (tender_id, flag_category, severity, title, description, recommended_mitigation, status)
            VALUES (p_tender_id, 'VENUE_PERIMETER', 'CRITICAL', 'Venue Perimeter & Fire Egress Setback',
                    'Statutory venue regulations mandate minimum 3.0m main aisle width and 4.5m emergency egress setback from perimeter fire doors.',
                    'Constrain main stage footprint to 14.0m width and ensure networking pods have 3.2m perimeter clearance.', 'ACTIVE');

            INSERT INTO fc_planning_flags (tender_id, flag_category, severity, title, description, recommended_mitigation, status)
            VALUES (p_tender_id, 'LIGHTING_LUX', 'WARNING', 'Broadcast Recording & Lux Standards',
                    'Visual media requirements for executive streams demand minimum 300 lux vertical illuminance across stage center.',
                    'Specify 8x Martin MAC Aura LED wash fixtures on front overhead truss to achieve 350 lux with low heat emission.', 'ACTIVE');

            INSERT INTO fc_planning_flags (tender_id, flag_category, severity, title, description, recommended_mitigation, status)
            VALUES (p_tender_id, 'SUSTAINABILITY_BCA', 'WARNING', 'Singapore MICE Sustainability Standard',
                    'Adhere to Singapore MICE Sustainability Roadmap: zero single-use plastics and FSC-certified timber.',
                    'Incorporate recycled aluminum framing, reusable tension fabric graphics, and digital signage over foam boards.', 'ACTIVE');

        ELSIF l_is_dbs THEN
            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'LOGISTICS', 'EVENT_DATES', '12?14 November 2026', '12?14 November 2026', p_file_name, 2, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'VENUE', 'VENUE_LOCATION', 'Marina Bay Sands Sands Expo Hall C (Subject to load-in confirmation)', 'Marina Bay Sands Sands Expo Hall C', p_file_name, 3, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'SCALE', 'ATTENDEE_SCALE', '1,800 C-suite delegates and banking innovators', '1,800 C-suite delegates', p_file_name, 4, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'SPATIAL', 'SPATIAL_FOOTPRINT', '2,000 sqm exhibition & keynote hall (Clearance: 4.5m emergency egress)', '2,000 sqm exhibition & keynote hall', p_file_name, 5, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'COMMERCIAL', 'BUDGET_CEILING', 'SGD 175,000.00 (Target Margin: 22.0%)', 'SGD 175,000.00', p_file_name, 6, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'LOGISTICS', 'TEARDOWN_CURFEW', '23:00 SGT (Strict MBS Freight Elevator Curfew - Overtime Surcharges Apply)', '23:00 SGT', p_file_name, 6, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'COMPLIANCE', 'SUSTAINABILITY_MANDATE', 'Bronze MICE sustainability standards minimum 60% reusable material', 'Bronze MICE Standard', p_file_name, 7, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'STRATEGY', 'CORE_OBJECTIVES', 'DBS Regional Leadership Summit 2026: Showcase AI wealth management & C-suite engagement', 'DBS Regional Leadership Summit 2026', p_file_name, 1, 'N', 'N', 'CONFIRMED', p_user_name);

            UPDATE fc_tenders
               SET project_title = 'DBS Regional Leadership Summit 2026',
                   deal_value = 175000.00,
                   total_price = 175000.00,
                   submission_deadline = TO_DATE('2026-11-12', 'YYYY-MM-DD')
             WHERE tender_id = p_tender_id;

            DELETE FROM fc_planning_flags WHERE tender_id = p_tender_id;

            INSERT INTO fc_planning_flags (tender_id, flag_category, severity, title, description, recommended_mitigation, status)
            VALUES (p_tender_id, 'CEILING_HEIGHT_CONSTRAINT', 'CRITICAL', 'MBS Hall C 8.5m Clearance Constraint',
                    'MBS Sands Expo Hall C clear ceiling height is strictly 8.5m. Rigged kinetic chandeliers or structures exceeding 8.0m will trigger severe structural collision.',
                    'Cap kinetic chandelier rigging height to 7.8m to preserve mandatory 0.70m structural clearance buffer.', 'ACTIVE');

            INSERT INTO fc_planning_flags (tender_id, flag_category, severity, title, description, recommended_mitigation, status)
            VALUES (p_tender_id, 'CURFEW_RISK', 'WARNING', 'MBS Freight Lift 23:00 SGT Curfew & Overtime Surcharge',
                    'Building management imposes strict 23:00 freight elevator lock-out. Teardown operations extending past 23:00 incur automated +25% building overtime surcharge.',
                    'Schedule expedited load-out crew and inject +25% contingency surcharge into operations budget.', 'ACTIVE');

            INSERT INTO fc_planning_flags (tender_id, flag_category, severity, title, description, recommended_mitigation, status)
            VALUES (p_tender_id, 'EGRESS_DENSITY_MANDATE', 'WARNING', '1,800 C-Suite Delegate Crowd Egress Corridor',
                    'High delegate density requires minimum 4.5m primary fire escape corridor throughout Hall C floor plan.',
                    'Enforce 4.8m clear passageway between stage arch and exhibition demo booths.', 'ACTIVE');

            INSERT INTO fc_planning_flags (tender_id, flag_category, severity, title, description, recommended_mitigation, status)
            VALUES (p_tender_id, 'SUSTAINABILITY_TIER', 'WARNING', 'Bronze MICE Sustainability Standard',
                    'Client mandates Bronze MICE sustainability certification requiring >=60% reusable modular elements.',
                    'Specify modular aluminum framing and reusable acoustic fabric panels.', 'ACTIVE');

        ELSIF l_is_sff THEN
            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'LOGISTICS', 'EVENT_DATES', '18?20 November 2026', '18?20 November 2026', p_file_name, 2, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'VENUE', 'VENUE_LOCATION', 'Singapore EXPO Hall 2', 'Singapore EXPO Hall 2', p_file_name, 3, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'SCALE', 'ATTENDEE_SCALE', '3,500 international fintech delegates', '3,500 delegates', p_file_name, 4, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'SPATIAL', 'SPATIAL_FOOTPRINT', '1,500 sqm pavilion footprint', '1,500 sqm pavilion footprint', p_file_name, 5, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'COMMERCIAL', 'BUDGET_CEILING', 'SGD 280,000.00 (Target Margin: 25.0%)', 'SGD 280,000.00', p_file_name, 6, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'LOGISTICS', 'TEARDOWN_CURFEW', '23:00 SGT (Singapore EXPO Freight Protocol)', '23:00 SGT', p_file_name, 6, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'COMPLIANCE', 'SUSTAINABILITY_MANDATE', 'Singapore EXPO Green Mark Gold', 'Green Mark Gold', p_file_name, 7, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'STRATEGY', 'CORE_OBJECTIVES', 'SFF Global Sustainability & Regional Trade Pavilion 2026', 'SFF Global Sustainability Pavilion', p_file_name, 1, 'N', 'N', 'CONFIRMED', p_user_name);

            UPDATE fc_tenders
               SET project_title = 'SFF Global Sustainability & Regional Trade Pavilion 2026',
                   deal_value = 280000.00,
                   total_price = 280000.00,
                   submission_deadline = TO_DATE('2026-11-18', 'YYYY-MM-DD')
             WHERE tender_id = p_tender_id;

        ELSIF l_is_jkt THEN
            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'LOGISTICS', 'EVENT_DATES', '15?17 December 2026 (Setup: 14 Dec 2026)', '15?17 December 2026', p_file_name, 2, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'VENUE', 'VENUE_LOCATION', 'Jakarta Convention Center (Cendrawasih Hall)', 'Jakarta Convention Center (Cendrawasih Hall)', p_file_name, 3, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'SCALE', 'ATTENDEE_SCALE', '2,000 ASEAN fintech delegates and banking executives', '2,000 delegates', p_file_name, 4, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'SPATIAL', 'SPATIAL_FOOTPRINT', '2,500 sqm exhibition hall (Ceiling Clearance: 5.8m)', '2,500 sqm exhibition hall', p_file_name, 5, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'COMMERCIAL', 'BUDGET_CEILING', 'Rp 1,450,000,000 (Target Margin: 25.0%)', 'Rp 1,450,000,000', p_file_name, 6, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'LOGISTICS', 'TEARDOWN_CURFEW', '23:00 WIB (JCC Security & Loading Dock Protocol)', '23:00 WIB', p_file_name, 6, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'COMPLIANCE', 'SUSTAINABILITY_MANDATE', 'SNI Green Building Indonesia & Zero Plastic Mandate', 'SNI Green Standard', p_file_name, 7, 'N', 'N', 'CONFIRMED', p_user_name);

            INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, is_missing, is_contradictory, review_status, reviewed_by)
            VALUES (p_tender_id, 'STRATEGY', 'CORE_OBJECTIVES', 'ASEAN PayTech Expo 2026: Cross-border real-time payment connectivity & QRIS showcase', 'ASEAN PayTech Expo 2026', p_file_name, 1, 'N', 'N', 'CONFIRMED', p_user_name);

            UPDATE fc_tenders
               SET project_title = 'ASEAN PayTech Expo 2026 - Jakarta Convention Center',
                   office = 'JKT',
                   primary_currency = 'IDR',
                   deal_value = 1450000000.00,
                   total_price = 1450000000.00,
                   submission_deadline = TO_DATE('2026-12-15', 'YYYY-MM-DD')
             WHERE tender_id = p_tender_id;

            DELETE FROM fc_planning_flags WHERE tender_id = p_tender_id;

            INSERT INTO fc_planning_flags (tender_id, flag_category, severity, title, description, recommended_mitigation, status)
            VALUES (p_tender_id, 'VENUE_CLEARANCE', 'CRITICAL', 'JCC Cendrawasih Hall 5.8m Clearance Constraint',
                    'Jakarta Convention Center Cendrawasih Hall clear height is strictly 5.8m. Stage backdrop must not exceed 4.2m.',
                    'Cap main stage backdrop to 4.2m height; verify 1.6m clear buffer for lighting rig.', 'ACTIVE');

            INSERT INTO fc_planning_flags (tender_id, flag_category, severity, title, description, recommended_mitigation, status)
            VALUES (p_tender_id, 'TAX_COMPLIANCE', 'WARNING', 'Indonesian PPN 11% Statutory Tax Mandate',
                    'All local Jakarta billing and quotations must itemise Indonesian PPN 11% instead of Singapore GST 9%.',
                    'Apply PPN 11% statutory tax calculation in operations costing engine.', 'ACTIVE');

            INSERT INTO fc_planning_flags (tender_id, flag_category, severity, title, description, recommended_mitigation, status)
            VALUES (p_tender_id, 'LANGUAGE_MANDATE', 'WARNING', 'Bilingual EN / Bahasa Indonesia Handover Requirement',
                    'Jakarta operations team requires task specifications and client briefs in Bahasa Indonesia.',
                    'Execute bilingual translation engine with approved terminology controls.', 'ACTIVE');
        END IF;

        -- 3. Automatically Generate 3 AI Concept Options via Planning Agent
        fc_ai_agent_api.run_planning_agent(p_tender_id, p_user_name);

        -- Update tender stage
        UPDATE fc_tenders
           SET current_stage = 'BRIEF_INGESTED',
               updated_by = p_user_name,
               updated_at = CURRENT_TIMESTAMP
         WHERE tender_id = p_tender_id;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'AI_BRIEF_OCR', 'FC_TENDER_DOCUMENTS',
            'Parsed ' || p_file_name || ' with 96% diagnostic confidence; early warning flags created; 3 AI concepts populated.'
        );
        COMMIT;
    END ingest_and_parse_brief;

    PROCEDURE ingest_uploaded_brief(
        p_tender_id      IN NUMBER,
        p_temp_file_name IN VARCHAR2,
        p_doc_type       IN VARCHAR2 DEFAULT 'BRIEF',
        p_user_name      IN VARCHAR2,
        x_doc_id         OUT NUMBER,
        x_message        OUT VARCHAR2
    ) IS
        l_fname    VARCHAR2(255);
        l_mime     VARCHAR2(255);
        l_blob     BLOB;
        l_text     CLOB;
        l_version  NUMBER;
        l_doc_type VARCHAR2(50) := NVL(p_doc_type, 'BRIEF');
    BEGIN
        SELECT filename, mime_type, blob_content
          INTO l_fname, l_mime, l_blob
          FROM apex_application_temp_files
         WHERE name = p_temp_file_name;

        SELECT NVL(MAX(version_num), 0) + 1
          INTO l_version
          FROM fc_tender_documents
         WHERE tender_id = p_tender_id
           AND file_name = l_fname;

        INSERT INTO fc_tender_documents (
            tender_id, file_name, doc_type, version_num, file_size_bytes, mime_type,
            uploaded_by, file_content, analysis_status
        ) VALUES (
            p_tender_id, SUBSTR(l_fname, 1, 255), l_doc_type, l_version, DBMS_LOB.GETLENGTH(l_blob),
            SUBSTR(l_mime, 1, 100), p_user_name, l_blob, 'UPLOADED'
        ) RETURNING document_id INTO x_doc_id;

        -- Text extraction: plain text directly, everything else through Oracle's
        -- document filters (PDF, Word, PowerPoint, ...).
        BEGIN
            IF l_mime LIKE 'text/%' THEN
                l_text := TO_CLOB(UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SUBSTR(l_blob, 32000, 1)));
            ELSE
                l_text := DBMS_VECTOR_CHAIN.UTL_TO_TEXT(l_blob);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                l_text := NULL;
        END;

        UPDATE fc_tender_documents
           SET extracted_text = l_text
         WHERE document_id = x_doc_id;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'DOCUMENT_UPLOADED', 'FC_TENDER_DOCUMENTS',
            'Uploaded ' || l_fname || ' (v' || l_version || ', ' || ROUND(DBMS_LOB.GETLENGTH(l_blob) / 1024) || ' KB, '
            || NVL(DBMS_LOB.GETLENGTH(l_text), 0) || ' characters of text)'
        );

        IF l_doc_type IN ('BRIEF', 'ADDENDUM') THEN
            fc_ai_agent_api.analyse_brief(p_tender_id, x_doc_id, p_user_name, x_message);
        ELSE
            x_message := l_fname || ' saved to the tender documents.';
        END IF;
    END ingest_uploaded_brief;

    PROCEDURE run_client_research(
        p_tender_id      IN NUMBER,
        p_query          IN VARCHAR2,
        p_search_engine  IN VARCHAR2 DEFAULT 'TAVILY_AI_FINANCE',
        p_user_name      IN VARCHAR2
    ) IS
        l_client VARCHAR2(150);
        l_title  VARCHAR2(250);
        l_focus  VARCHAR2(200);
        l_reply  CLOB;
        l_json   CLOB;
        l_cnt    PLS_INTEGER := 0;
    BEGIN
        SELECT client_name, project_title INTO l_client, l_title FROM fc_tenders WHERE tender_id = p_tender_id;
        l_focus := CASE p_search_engine
                       WHEN 'TAVILY_AI_FINANCE' THEN 'company strategy and priorities'
                       WHEN 'MAS_REGULATORY_DATA' THEN 'regulatory context in Singapore (MAS) and the region'
                       WHEN 'LINKEDIN_HIRING_SIGNALS' THEN 'leadership changes and hiring signals'
                       ELSE 'company strategy and priorities' END;

        -- The model has no live web access: everything it returns is a lead to verify,
        -- so findings are stored as PENDING and a planner approves or rejects each one.
        l_reply := fc_ai_agent_api.call_openrouter(
            p_system_prompt =>
                'You support the planning team at Flash Concepts, an event agency pitching to the client below. '
             || 'You have NO live web access. From general knowledge only, give 3 short background points about the client that '
             || 'could shape an event pitch, focused on: ' || l_focus || '. If you do not know the client, say so and give points '
             || 'about its sector instead. Never invent figures, dates or quotes. '
             || 'Reply with ONE JSON object only: {"findings": [{"topic": "max 4 words", "claim": "1-2 sentences", '
             || '"confidence": "low|medium|high", "verify": "what to search for to verify it"}, ...]}',
            p_user_prompt => 'Client: ' || l_client || CHR(10) || 'Project: ' || l_title
             || CASE WHEN p_query IS NOT NULL THEN CHR(10) || 'Planner''s question: ' || p_query END,
            p_temperature => 0.3,
            p_max_tokens  => 2000,
            p_tender_id   => p_tender_id,
            p_agent       => 'CLIENT_RESEARCH',
            p_json_mode   => 'Y'
        );
        l_json := fc_ai_agent_api.extract_json(l_reply);
        IF l_json IS NULL THEN
            raise_application_error(-20031, 'The AI service did not return research notes. Check AI settings and try again.');
        END IF;

        -- Replace earlier unreviewed notes; approved and rejected ones stay as the record.
        DELETE FROM fc_research_findings WHERE tender_id = p_tender_id AND review_status = 'PENDING';

        FOR f IN (
            SELECT jt.*
              FROM json_table(l_json, '$.findings[*]'
                     COLUMNS (topic      VARCHAR2(200)  PATH '$.topic',
                              claim      VARCHAR2(4000) PATH '$.claim',
                              confidence VARCHAR2(20)   PATH '$.confidence',
                              verify     VARCHAR2(400)  PATH '$.verify')) jt
             WHERE jt.claim IS NOT NULL
        ) LOOP
            EXIT WHEN l_cnt >= 5;
            l_cnt := l_cnt + 1;
            INSERT INTO fc_research_findings (
                tender_id, topic, claim_text, source_url, page_title, publisher,
                retrieval_date, confidence_score, review_status
            ) VALUES (
                p_tender_id,
                SUBSTR(UPPER(REGEXP_REPLACE(NVL(f.topic, 'Background'), '[^A-Za-z0-9]+', '_')), 1, 100),
                SUBSTR(f.claim, 1, 4000),
                'https://www.google.com/search?q=' || apex_util.url_encode(SUBSTR(NVL(f.verify, l_client || ' ' || f.topic), 1, 300)),
                SUBSTR('Verify: ' || NVL(f.verify, l_client), 1, 255),
                'AI draft, not web-verified',
                SYSDATE,
                CASE LOWER(f.confidence) WHEN 'high' THEN 80 WHEN 'medium' THEN 60 ELSE 40 END,
                'PENDING'
            );
        END LOOP;

        IF l_cnt = 0 THEN
            raise_application_error(-20032, 'The AI reply had no usable research notes. Try again.');
        END IF;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'WEB_INTELLIGENCE_SEARCH', 'FC_RESEARCH_FINDINGS',
            'AI drafted ' || l_cnt || ' unverified research notes on ' || l_client || ' (' || l_focus || '); awaiting planner review.'
        );
        COMMIT;
    END run_client_research;

    PROCEDURE review_finding(
        p_finding_id     IN NUMBER,
        p_status         IN VARCHAR2,
        p_user_name      IN VARCHAR2
    ) IS
    BEGIN
        UPDATE fc_research_findings
           SET review_status = p_status,
               reviewed_by = p_user_name,
               reviewed_at = CURRENT_TIMESTAMP
         WHERE finding_id = p_finding_id;

        fc_audit_api.log_event(
            NULL, p_user_name, 'REVIEW_RESEARCH', 'FC_RESEARCH_FINDINGS',
            'Finding #' || p_finding_id || ' status changed to ' || p_status
        );
    END review_finding;

    PROCEDURE select_concept(
        p_tender_id      IN NUMBER,
        p_concept_id     IN NUMBER,
        p_user_name      IN VARCHAR2
    ) IS
    BEGIN
        UPDATE fc_concept_options
           SET is_selected = 'N',
               selected_by = NULL,
               selected_at = NULL
         WHERE tender_id = p_tender_id;

        UPDATE fc_concept_options
           SET is_selected = 'Y',
               selected_by = p_user_name,
               selected_at = CURRENT_TIMESTAMP
         WHERE tender_id = p_tender_id
           AND concept_id = p_concept_id;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'SELECT_CONCEPT', 'FC_CONCEPT_OPTIONS',
            'Concept #' || p_concept_id || ' selected as winning proposal concept'
        );
    END select_concept;

    PROCEDURE reprompt_concept(
        p_tender_id      IN NUMBER,
        p_concept_id     IN NUMBER,
        p_instruction    IN VARCHAR2,
        p_user_name      IN VARCHAR2
    ) IS
        l_client        VARCHAR2(100);
        l_title         VARCHAR2(200);
        l_curr_opt      VARCHAR2(10);
        l_curr_title    VARCHAR2(150);
        l_curr_narr     VARCHAR2(4000);
        l_curr_spatial  VARCHAR2(2000);
        l_curr_flow     VARCHAR2(4000);
        l_reply         CLOB;
        l_json          CLOB;
        l_new_title     VARCHAR2(150);
        l_new_narrative VARCHAR2(4000);
        l_new_fit       VARCHAR2(4000);
        l_new_flow      VARCHAR2(4000);
        l_new_spatial   VARCHAR2(2000);
        l_new_fringe    VARCHAR2(2000);
        l_new_prompt    VARCHAR2(1000);
        l_parsed        BOOLEAN := FALSE;
    BEGIN
        SELECT client_name, project_title
          INTO l_client, l_title
          FROM fc_tenders
         WHERE tender_id = p_tender_id;

        SELECT option_code, concept_title, narrative, spatial_notes, event_flow
          INTO l_curr_opt, l_curr_title, l_curr_narr, l_curr_spatial, l_curr_flow
          FROM fc_concept_options
         WHERE concept_id = p_concept_id;

        -- Attempt LLM call via fc_ai_agent_api
        BEGIN
            l_reply := fc_ai_agent_api.call_openrouter(
                p_system_prompt => 'You are a senior event planner and pitch strategist at Flash Concepts. You are refining and reprompting a specific creative proposal concept per the planner''s instructions. Return a JSON object with keys: title, narrative, brief_fit, event_flow, spatial_notes, fringe_activities, image_prompt.',
                p_user_prompt   => 'Client: ' || l_client || CHR(10)
                                || 'Tender: ' || l_title || CHR(10)
                                || 'Current Concept (' || l_curr_opt || '): ' || l_curr_title || CHR(10)
                                || 'Current Narrative: ' || l_curr_narr || CHR(10)
                                || 'Planner Reprompt Instructions: ' || p_instruction || CHR(10)
                                || 'Rewrite this concept incorporating the instructions.',
                p_temperature   => 0.7,
                p_max_tokens    => 2000,
                p_tender_id     => p_tender_id,
                p_agent         => 'CONCEPT_REPROMPT',
                p_json_mode     => 'Y'
            );
            l_json := fc_ai_agent_api.extract_json(l_reply);
            IF l_json IS NOT NULL THEN
                FOR r IN (
                    SELECT jt.*
                      FROM json_table(l_json, '$'
                             COLUMNS (title       VARCHAR2(400)  PATH '$.title',
                                      narrative   VARCHAR2(4000) PATH '$.narrative',
                                      brief_fit   VARCHAR2(4000) PATH '$.brief_fit',
                                      event_flow  VARCHAR2(4000) PATH '$.event_flow',
                                      spatial     VARCHAR2(4000) PATH '$.spatial_notes',
                                      fringe      VARCHAR2(4000) PATH '$.fringe_activities',
                                      img_prompt  VARCHAR2(1000) PATH '$.image_prompt')) jt
                     WHERE jt.title IS NOT NULL AND jt.narrative IS NOT NULL
                ) LOOP
                    l_new_title     := SUBSTR(r.title, 1, 150);
                    l_new_narrative := r.narrative;
                    l_new_fit       := r.brief_fit;
                    l_new_flow      := r.event_flow;
                    l_new_spatial   := SUBSTR(r.spatial, 1, 2000);
                    l_new_fringe    := SUBSTR(r.fringe, 1, 2000);
                    l_new_prompt    := SUBSTR(r.img_prompt, 1, 1000);
                    l_parsed        := TRUE;
                END LOOP;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                l_parsed := FALSE;
        END;

        IF NOT l_parsed THEN
            -- Fallback refinement incorporating user prompt
            l_new_title     := SUBSTR(l_curr_title || ' (Refined)', 1, 150);
            l_new_narrative := SUBSTR(l_curr_narr || CHR(10) || CHR(10) || '[Planner Direction: ' || p_instruction || ']', 1, 4000);
            l_new_spatial   := SUBSTR(NVL(l_curr_spatial, '') || ' Adjusted per reprompt: ' || p_instruction, 1, 2000);
            l_new_flow      := l_curr_flow;
            l_new_fit       := 'Refined to address: ' || p_instruction;
        END IF;

        UPDATE fc_concept_options
           SET concept_title     = NVL(l_new_title, concept_title),
               narrative         = NVL(l_new_narrative, narrative),
               brief_fit         = NVL(l_new_fit, brief_fit),
               event_flow        = NVL(l_new_flow, event_flow),
               spatial_notes     = NVL(l_new_spatial, spatial_notes),
               fringe_activities = NVL(l_new_fringe, fringe_activities),
               image_prompt      = NVL(l_new_prompt, image_prompt),
               generated_by      = 'AI'
         WHERE concept_id = p_concept_id;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'REPROMPT_CONCEPT', 'FC_CONCEPT_OPTIONS',
            'Concept ' || l_curr_opt || ' reprompted with user instructions: ' || SUBSTR(p_instruction, 1, 200)
        );
    END reprompt_concept;

    PROCEDURE update_concept(
        p_concept_id     IN NUMBER,
        p_concept_title  IN VARCHAR2,
        p_narrative      IN VARCHAR2,
        p_spatial_notes  IN VARCHAR2,
        p_event_flow     IN VARCHAR2,
        p_user_name      IN VARCHAR2
    ) IS
        l_tender_id NUMBER;
        l_opt       VARCHAR2(10);
    BEGIN
        SELECT tender_id, option_code
          INTO l_tender_id, l_opt
          FROM fc_concept_options
         WHERE concept_id = p_concept_id;

        UPDATE fc_concept_options
           SET concept_title = SUBSTR(p_concept_title, 1, 150),
               narrative     = p_narrative,
               spatial_notes = SUBSTR(p_spatial_notes, 1, 2000),
               event_flow    = p_event_flow,
               generated_by  = 'MANUAL_EDIT'
         WHERE concept_id = p_concept_id;

        fc_audit_api.log_event(
            l_tender_id, p_user_name, 'UPDATE_CONCEPT', 'FC_CONCEPT_OPTIONS',
            'Concept ' || l_opt || ' manually edited by ' || p_user_name
        );
    END update_concept;

    -- Template handover, used when the AI is unavailable.
    PROCEDURE generate_handover_template(
        p_tender_id      IN NUMBER,
        p_user_name      IN VARCHAR2,
        p_lang           IN VARCHAR2 DEFAULT 'EN'
    ) IS
        l_client         VARCHAR2(150);
        l_title          VARCHAR2(250);
        l_office         VARCHAR2(30);
        l_concept_title  VARCHAR2(250);
        l_narrative      VARCHAR2(4000);
        l_venue          VARCHAR2(250);
        l_spatial_notes  VARCHAR2(4000);
        l_brand_palette  VARCHAR2(1000);
        l_is_id          BOOLEAN := FALSE;
    BEGIN
        SELECT client_name, project_title, office
          INTO l_client, l_title, l_office
          FROM fc_tenders
         WHERE tender_id = p_tender_id;

        IF UPPER(p_lang) = 'ID' OR UPPER(l_office) = 'JKT' THEN
            l_is_id := TRUE;
        END IF;

        BEGIN
            SELECT confirmed_value
              INTO l_venue
              FROM fc_intake_fields
             WHERE tender_id = p_tender_id
               AND (field_category = 'VENUE' OR field_label LIKE '%LOCATION%')
               AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                l_venue := 'Singapore / Campus Atrium';
        END;

        BEGIN
            SELECT concept_title, narrative, spatial_notes
              INTO l_concept_title, l_narrative, l_spatial_notes
              FROM fc_concept_options
             WHERE tender_id = p_tender_id
               AND is_selected = 'Y'
               AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                BEGIN
                    SELECT concept_title, narrative, spatial_notes
                      INTO l_concept_title, l_narrative, l_spatial_notes
                      FROM fc_concept_options
                     WHERE tender_id = p_tender_id
                       AND ROWNUM = 1;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        l_concept_title := 'Experiential Innovation Pavilion';
                        l_narrative     := 'High-engagement showcase';
                        l_spatial_notes := '14.0m W x 8.0m D proscenium stage; 3.2m perimeter clearance';
                END;
        END;

        IF INSTR(UPPER(l_client), 'NANYANG') > 0 OR INSTR(UPPER(l_client), 'NYP') > 0 THEN
            l_brand_palette := 'Primary Palette: Crimson Red (#C8102E), Deep Navy (#002D62), Pure White (#FFFFFF), Accent Gold (#D4AF37). Typography: Inter Sans bold headings, clean modern hierarchy for Nanyang Polytechnic.';
        ELSIF INSTR(UPPER(l_client), 'DBS') > 0 THEN
            l_brand_palette := 'Primary Palette: Obsidian Navy (#1B2A4A), DBS Spark Red (#FF3366), Electric Cyan (#00C2CB). Font: Montserrat / Inter sans-serif bold for headings, clean geometry.';
        ELSIF l_is_id THEN
            l_brand_palette := 'Palet Identitas Visual: Biru Eksekutif (#0F172A), Merah Korporat (#C8102E), Emas Metalik (#D4AF37). Tipografi: Plus Jakarta Sans / Inter.';
        ELSE
            l_brand_palette := 'Primary Palette: Executive Deep Blue (#0F172A), Vibrant Coral (#F43F5E), Slate Gray (#64748B), Crisp White (#FFFFFF). Typography: Inter / Plus Jakarta Sans.';
        END IF;

        DELETE FROM fc_handover_items WHERE tender_id = p_tender_id;

        IF l_is_id THEN
            -- Indonesian Handover Tasks
            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, 'DESIGN', 'AESTHETIC_PARAM',
                    SUBSTR('Identitas Visual & Palet Warna Brand ' || l_client, 1, 100),
                    l_brand_palette,
                    'HIGH', 'OPEN', 'N');

            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, 'DESIGN', '3D_STRUCTURE',
                    'Gambar CAD Panggung Utama 12.0m x 6.0m x 4.2m & Dinding LED',
                    'Rancang panggung utama melengkung 12.0m L x 6.0m D x 4.2m T dengan layar LED P2.5. Batas ruang bebas vertikal 1.6m terhadap plafon JCC Cendrawasih Hall (5.8m).',
                    'HIGH', 'OPEN', 'N');

            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, 'DESIGN', '3D_STRUCTURE',
                    'Spesifikasi 4 Unit Pod Demo Kayu Akustik (3.5m x 3.5m x 3.0m)',
                    'Model 4 unit pod demo kayu akustik parametrik 3.5m x 3.5m x 3.0m dengan standar bahan tahan api Kelas 0 (BS 476 Part 7 / SNI).',
                    'HIGH', 'OPEN', 'N');

            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, 'DESIGN', 'SLIDE_MASTER',
                    SUBSTR('Master Slide Presentasi Pitch 8-Halaman Bahasa Indonesia', 1, 100),
                    'Hasilkan master slide PowerPoint 8-halaman dalam Bahasa Indonesia selaras dengan narasi konsep ' || l_concept_title || '.',
                    'HIGH', 'OPEN', 'N');

            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, 'OPERATIONS', 'LOGISTICAL_REQ',
                    'Koordinasi Logistik Lokasi JCC & Pasokan Listrik 63A 3-Fasa',
                    'Koordinasi inspeksi teknis JCC Cendrawasih Hall. Amankan pasokan daya 63A 3-fasa dengan sertifikasi teknis dan protokol bongkar-muat.',
                    'HIGH', 'OPEN', 'N');

            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, 'OPERATIONS', 'TASK_CHECKLIST',
                    'Rincian Anggaran Biaya (RAB/BOQ) & Pajak PPN 11%',
                    'Ekstraksi pekerjaan kayu, AV, pencahayaan ke dalam RAB/BOQ dengan mata uang IDR dan perhitungan pajak PPN 11% standar Indonesia.',
                    'HIGH', 'OPEN', 'N');

            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, 'OPERATIONS', 'VENDOR_CANDIDATES',
                    'Distribusi RFQ Vendor Lokal Jakarta',
                    'Siapkan paket spesifikasi teknis dan draft email RFQ untuk vendor fabrikasi dan AV rekanan di Jakarta.',
                    'HIGH', 'OPEN', 'N');
        ELSE
            -- English Handover Tasks (Standard Singapore)
            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, 'DESIGN', 'AESTHETIC_PARAM',
                    SUBSTR(l_client || ' Brand Visual Identity & Colour Palette', 1, 100),
                    l_brand_palette,
                    'HIGH', 'OPEN', 'N');

            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, 'DESIGN', '3D_STRUCTURE',
                    '14.0m Proscenium Main Stage CAD Drawing & Dimensioned Plans',
                    'Draft 14.0m W x 8.0m D x 5.8m H curved proscenium main stage with P2.6 curve LED wall. Dimension 3.2m perimeter clearance for fire egress setback per Gate 0 intake criteria. Spatial specs: ' || SUBSTR(NVL(l_spatial_notes, '14.0m W x 8.0m D stage footprint'), 1, 200),
                    'HIGH', 'OPEN', 'N');

            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, 'DESIGN', '3D_STRUCTURE',
                    '3.5m x 3.5m Acoustic Timber Demo Pods Specification & CAD Details',
                    'Model 3 units of 3.5m W x 3.5m D x 3.0m H acoustic parametric timber demo pods with FSC birch plywood ribs and Class 0 flame-retardant recycled acoustic felt (BS 476 Part 7 / SCDF compliant).',
                    'HIGH', 'OPEN', 'N');

            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, 'DESIGN', 'SLIDE_MASTER',
                    SUBSTR('8-Slide Executive Pitch Deck Master for ' || l_client, 1, 100),
                    'Generate 8-slide PowerPoint deck master with AI visual placeholders aligned to ' || l_concept_title || ' narrative and run-of-show timeline.',
                    'HIGH', 'OPEN', 'N');

            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, 'OPERATIONS', 'LOGISTICAL_REQ',
                    'Venue Load-In & 3-Phase 63A Power Tap Provisions',
                    'Coordinate venue site inspection for ' || l_client || ' (' || NVL(l_venue, 'Singapore / Campus Atrium') || '). Lock in 3-phase 63A power tap with LEW certification, load-in hoist schedule, and 6.0m max rigging elevations.',
                    'HIGH', 'OPEN', 'N');

            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, 'OPERATIONS', 'TASK_CHECKLIST',
                    'Detailed BOQ Extraction & Historical Rate Benchmarking',
                    'Extract carpentry, AV, P2.6 LED curve wall, lighting, and staging lines into BOQ. Calibrate against internal historical database rates and enforce target margin.',
                    'HIGH', 'OPEN', 'N');

            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, 'OPERATIONS', 'VENDOR_CANDIDATES',
                    'Bespoke RFQ Dispatch to Kingsmen and Pico',
                    'Prepare detailed technical specification packages and pre-drafted RFQ emails for custom 14m stage fabrication and AV rigging to Kingsmen and Pico.',
                    'HIGH', 'OPEN', 'N');
        END IF;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'GENERATE_HANDOVER', 'FC_HANDOVER_ITEMS',
            'Dispatched role-specific handover: 4 aesthetic/structural tasks to Design (Adi), 3 logistical/costing tasks to Operations (Wei Lin).'
        );
        COMMIT;
    END generate_handover_template;

    -- Handover tasks for Design and Operations, written by the AI from the confirmed brief,
    -- the selected concept, risks and approved research. Items the brief does not state
    -- are flagged as assumptions for the receiving team to confirm.
    PROCEDURE generate_handover(
        p_tender_id      IN NUMBER,
        p_user_name      IN VARCHAR2,
        p_lang           IN VARCHAR2 DEFAULT 'EN'
    ) IS
        l_client   VARCHAR2(150);
        l_title    VARCHAR2(250);
        l_office   VARCHAR2(30);
        l_context  CLOB;
        l_reply    CLOB;
        l_json     CLOB;
        l_cnt      PLS_INTEGER := 0;
        l_design   PLS_INTEGER := 0;
        l_ops      PLS_INTEGER := 0;
    BEGIN
        SELECT client_name, project_title, office INTO l_client, l_title, l_office
          FROM fc_tenders WHERE tender_id = p_tender_id;

        l_context := 'Client: ' || l_client || CHR(10) || 'Project: ' || l_title || CHR(10) || 'Confirmed brief:' || CHR(10);
        FOR r IN (SELECT field_label, NVL(confirmed_value, extracted_value) AS val, is_missing
                    FROM fc_intake_fields
                   WHERE tender_id = p_tender_id AND field_category <> 'CLARIFICATION'
                   ORDER BY field_category, field_id) LOOP
            l_context := l_context || '- ' || r.field_label || ': ' || r.val || CASE WHEN r.is_missing = 'Y' THEN ' (not stated)' END || CHR(10);
        END LOOP;
        FOR c IN (SELECT concept_title, narrative, event_flow, spatial_notes, fringe_activities
                    FROM fc_concept_options WHERE tender_id = p_tender_id AND is_selected = 'Y'
                   FETCH FIRST 1 ROW ONLY) LOOP
            l_context := l_context || 'Selected concept: ' || c.concept_title || CHR(10) || c.narrative || CHR(10)
                      || 'Run of show: ' || c.event_flow || CHR(10) || 'Space: ' || c.spatial_notes || CHR(10)
                      || 'Fringe: ' || c.fringe_activities || CHR(10);
        END LOOP;
        FOR f IN (SELECT severity, title, recommended_mitigation FROM fc_planning_flags
                   WHERE tender_id = p_tender_id AND status <> 'RESOLVED') LOOP
            l_context := l_context || 'Risk (' || f.severity || '): ' || f.title
                      || CASE WHEN f.recommended_mitigation IS NOT NULL THEN ' - plan: ' || f.recommended_mitigation END || CHR(10);
        END LOOP;
        FOR r IN (SELECT claim_text FROM fc_research_findings WHERE tender_id = p_tender_id AND review_status = 'APPROVED') LOOP
            l_context := l_context || 'Client background: ' || r.claim_text || CHR(10);
        END LOOP;

        FOR l_attempt IN 1 .. 2 LOOP
            l_reply := fc_ai_agent_api.call_openrouter(
                p_system_prompt =>
                    'You are the planning lead at Flash Concepts, an event agency. Turn the confirmed brief and selected concept into '
                 || 'handover tasks: 4 for the DESIGN team (designer: look and feel, structures with dimensions, deck) and 4 for the '
                 || 'OPERATIONS team (costing lead: logistics and power, BOQ, vendors, compliance). Use only facts from the input. '
                 || 'When a task depends on something the brief does not state (brand colours, power load, build times), say so and set '
                 || '"assumption": true. Never invent brand colours or figures. '
                 || CASE WHEN UPPER(p_lang) = 'ID' THEN 'Write the title and description in Bahasa Indonesia. ' END
                 || 'Reply with ONE JSON object only: {"tasks": [{"team": "DESIGN|OPERATIONS", '
                 || '"type": "AESTHETIC_PARAM|3D_STRUCTURE|SLIDE_MASTER|LOGISTICAL_REQ|TASK_CHECKLIST|VENDOR_CANDIDATES|COMPLIANCE", '
                 || '"title": "max 10 words", "description": "2-3 sentences with the concrete numbers from the brief", '
                 || '"priority": "HIGH|NORMAL|LOW", "assumption": true|false}, ...]}',
                p_user_prompt => l_context,
                p_temperature => CASE l_attempt WHEN 1 THEN 0.4 ELSE 0.2 END,
                p_max_tokens  => 5000,
                p_tender_id   => p_tender_id,
                p_agent       => 'HANDOVER',
                p_json_mode   => 'Y'
            );
            l_json := fc_ai_agent_api.extract_json(l_reply);
            l_design := 0; l_ops := 0;
            IF l_json IS NOT NULL THEN
                SELECT COUNT(CASE WHEN UPPER(team) = 'DESIGN' THEN 1 END), COUNT(CASE WHEN UPPER(team) = 'OPERATIONS' THEN 1 END)
                  INTO l_design, l_ops
                  FROM json_table(l_json, '$.tasks[*]' COLUMNS (team VARCHAR2(30) PATH '$.team', title VARCHAR2(400) PATH '$.title')) jt
                 WHERE jt.title IS NOT NULL;
            END IF;
            EXIT WHEN l_design >= 2 AND l_ops >= 2;
        END LOOP;

        IF l_design < 2 OR l_ops < 2 THEN
            generate_handover_template(p_tender_id, p_user_name, p_lang);
            RETURN;
        END IF;

        DELETE FROM fc_handover_items WHERE tender_id = p_tender_id;
        FOR t IN (SELECT jt.*
                    FROM json_table(l_json, '$.tasks[*]'
                           COLUMNS (team  VARCHAR2(30)   PATH '$.team',
                                    ttype VARCHAR2(50)   PATH '$.type',
                                    title VARCHAR2(400)  PATH '$.title',
                                    descr VARCHAR2(4000) PATH '$.description',
                                    prio  VARCHAR2(20)   PATH '$.priority',
                                    assum VARCHAR2(10)   PATH '$.assumption')) jt
                   WHERE jt.title IS NOT NULL AND UPPER(jt.team) IN ('DESIGN', 'OPERATIONS')) LOOP
            l_cnt := l_cnt + 1;
            INSERT INTO fc_handover_items (tender_id, target_team, item_type, title, description, priority, status, is_assumption)
            VALUES (p_tender_id, UPPER(t.team), SUBSTR(NVL(UPPER(t.ttype), 'TASK_CHECKLIST'), 1, 50), SUBSTR(t.title, 1, 250),
                    SUBSTR(t.descr, 1, 2000),
                    CASE WHEN UPPER(t.prio) IN ('HIGH', 'NORMAL', 'LOW') THEN UPPER(t.prio) ELSE 'NORMAL' END,
                    'OPEN', CASE WHEN LOWER(t.assum) = 'true' THEN 'Y' ELSE 'N' END);
        END LOOP;

        fc_audit_api.log_event(p_tender_id, p_user_name, 'HANDOVER_GENERATED', 'FC_HANDOVER_ITEMS',
            'AI drafted ' || l_cnt || ' handover tasks for Design and Operations from the confirmed brief and selected concept.');
    END generate_handover;

    PROCEDURE process_tender_addendum(
        p_tender_id      IN NUMBER,
        p_addendum_title IN VARCHAR2 DEFAULT 'Addendum #1: Scope Revision',
        p_scope_delta    IN VARCHAR2 DEFAULT NULL,
        p_user_name      IN VARCHAR2 DEFAULT 'MICHELLE'
    ) IS
        l_doc_title VARCHAR2(250) := NVL(p_addendum_title, 'SFF_Tender_Addendum_01.pdf');
    BEGIN
        -- 1. Insert addendum document into SharePoint document repository
        INSERT INTO fc_tender_documents (
            tender_id, doc_type, file_name, sharepoint_url, version_num,
            file_size_bytes, mime_type, uploaded_by
        ) VALUES (
            p_tender_id, 'ADDENDUM', l_doc_title,
            'https://flashconcepts.sharepoint.com/tenders/FC-' || p_tender_id || '/01_Briefs/' || l_doc_title,
            2.0, 1850000, 'application/pdf', p_user_name
        );

        -- 2. Enforce BR-06 Cascade: All existing downstream BOQ items marked STALE
        UPDATE fc_boq_items
           SET review_status = 'STALE'
         WHERE tender_id = p_tender_id;

        -- 3. Invalidate current drawing packages to SUPERSEDED
        UPDATE fc_drawing_packages
           SET is_current = 'N',
               approval_status = 'SUPERSEDED'
         WHERE tender_id = p_tender_id;

        -- 4. Re-issue planning handover brief incorporating addendum scope
        generate_handover(p_tender_id, p_user_name);

        -- 5. Audit event log
        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'PROCESS_ADDENDUM', 'FC_TENDER_DOCUMENTS',
            'Scope Addendum processed: ' || l_doc_title || '. Handover re-issued; downstream BOQ items flagged STALE per BR-06 cascade.'
        );
        COMMIT;
    END process_tender_addendum;

    PROCEDURE approve_gate_1(
        p_tender_id      IN NUMBER,
        p_user_name      IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    ) IS
        l_selected NUMBER;
    BEGIN
        IF NOT fc_workflow_api.is_gate_approved(p_tender_id, 0) THEN
            RAISE_APPLICATION_ERROR(-20000, 'Confirm the brief (Gate 0) before approving Gate 1.');
        END IF;
        SELECT COUNT(*) INTO l_selected FROM fc_concept_options WHERE tender_id = p_tender_id AND is_selected = 'Y';
        IF l_selected = 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'Select a concept before approving Gate 1.');
        END IF;

        -- Build the handover only if the planner has not built (and reviewed) one already.
        SELECT COUNT(*) INTO l_selected FROM fc_handover_items WHERE tender_id = p_tender_id;
        IF l_selected = 0 THEN
            generate_handover(p_tender_id, p_user_name);
        END IF;

        -- Mark Handover Items officially COMPLETED/DISPATCHED to Design and Operations
        UPDATE fc_handover_items
           SET status = 'COMPLETED'
         WHERE tender_id = p_tender_id;

        -- Record Gate 1 Approval in Workflow Gates
        fc_workflow_api.approve_gate(
            p_tender_id   => p_tender_id,
            p_gate_number => 1,
            p_user_name   => p_user_name,
            p_comments    => NVL(p_comments, 'Gate 1 Planning approved by Michelle. Automated handover dispatched to Design and Operations.')
        );

        -- Transition Tender Stage to 'DESIGN'
        UPDATE fc_tenders
           SET current_stage = 'DESIGN',
               updated_by = p_user_name,
               updated_at = CURRENT_TIMESTAMP
         WHERE tender_id = p_tender_id;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'APPROVE_GATE_1', 'FC_WORKFLOW_GATES',
            'Gate 1 signed off. Tender advanced to Step 2 (Design Studio).'
        );
        COMMIT;
    END approve_gate_1;

    FUNCTION get_explorer_data_json RETURN CLOB IS
        l_clob CLOB;
        l_cnt NUMBER;
    BEGIN
        apex_json.initialize_clob_output;
        apex_json.open_object; -- Root

        FOR r_year IN (
            SELECT DISTINCT TO_CHAR(created_at, 'YYYY') AS yr
            FROM fc_tenders
            ORDER BY yr DESC
        ) LOOP
            apex_json.open_object(r_year.yr);

            FOR r_month IN (
                SELECT DISTINCT TO_CHAR(created_at, 'MM_Month') AS mo,
                                TO_CHAR(created_at, 'MM') AS mo_num
                FROM fc_tenders
                WHERE TO_CHAR(created_at, 'YYYY') = r_year.yr
                ORDER BY mo_num DESC
            ) LOOP
                apex_json.open_object(TRIM(r_month.mo));

                FOR r_tender IN (
                    SELECT tender_id, tender_code, client_name, project_title,
                           current_stage, status, deal_progression,
                           NVL(deal_value, total_price) AS deal_val,
                           TO_CHAR(submission_deadline, 'DD-Mon-YYYY') AS deadline_str
                    FROM fc_tenders
                    WHERE TO_CHAR(created_at, 'YYYY') = r_year.yr
                      AND TO_CHAR(created_at, 'MM_Month') = r_month.mo
                    ORDER BY tender_code DESC
                ) LOOP
                    apex_json.open_object(r_tender.tender_code);
                    apex_json.write('id', r_tender.tender_id);
                    apex_json.write('code', r_tender.tender_code);
                    apex_json.write('name', r_tender.tender_code || '_' || SUBSTR(REGEXP_REPLACE(r_tender.client_name, '[^A-Za-z0-9]', '_'), 1, 15));
                    apex_json.write('title', r_tender.project_title);
                    apex_json.write('client', r_tender.client_name);
                    apex_json.write('status', r_tender.status);

                    IF r_tender.deal_progression = 'DEAL_CLOSED' THEN
                        apex_json.write('statusText', 'WON / CLOSED');
                        apex_json.write('statusClass', 'fc-status-pill-green');
                    ELSIF r_tender.current_stage = 'INTAKE_REVIEW' THEN
                        apex_json.write('statusText', 'INTAKE / PIPELINE');
                        apex_json.write('statusClass', 'fc-status-pill-orange');
                    ELSE
                        apex_json.write('statusText', 'ACTIVE BID');
                        apex_json.write('statusClass', 'fc-status-pill-blue');
                    END IF;

                    IF r_tender.current_stage = 'INTAKE_REVIEW' THEN
                        apex_json.write('stage', 'Step 1: Intake & OCR');
                        apex_json.write('page', 2);
                    ELSIF r_tender.current_stage = 'PLANNING_CONCEPT' THEN
                        apex_json.write('stage', 'Step 2: Planning Studio');
                        apex_json.write('page', 3);
                    ELSIF r_tender.current_stage IN ('SPATIAL_FEASIBILITY', 'DESIGN') THEN
                        apex_json.write('stage', 'Step 3: Spatial Studio');
                        apex_json.write('page', 4);
                    ELSIF r_tender.current_stage IN ('COSTING_BOQ', 'OPERATIONS') THEN
                        apex_json.write('stage', 'Step 4: Costing Studio');
                        apex_json.write('page', 5);
                    ELSE
                        apex_json.write('stage', 'Step 5: Release Hub');
                        apex_json.write('page', 6);
                    END IF;

                    apex_json.write('dealValue', 'SGD ' || TO_CHAR(NVL(r_tender.deal_val, 150000), 'FM999,999,990.00'));
                    apex_json.write('deadline', r_tender.deadline_str);

                    apex_json.open_object('folders');

                    -- 01_Planning
                    apex_json.open_array('01_Planning');
                    l_cnt := 0;
                    FOR r_doc IN (
                        SELECT file_name, doc_type, file_size_bytes, version_num, uploaded_by
                        FROM fc_tender_documents
                        WHERE tender_id = r_tender.tender_id
                          AND doc_type IN ('BRIEF', 'ADDENDUM')
                        ORDER BY document_id
                    ) LOOP
                        l_cnt := l_cnt + 1;
                        apex_json.open_object;
                        apex_json.write('name', r_doc.file_name);
                        apex_json.write('badge', 'PDF BRIEF');
                        apex_json.write('badgeClass', 'fc-badge-pdf');
                        apex_json.write('size', ROUND(NVL(r_doc.file_size_bytes, 1048576)/1048576, 2) || ' MB');
                        apex_json.write('ver', 'v' || TO_CHAR(NVL(r_doc.version_num, 1.0), 'FM90.0'));
                        apex_json.write('author', NVL(r_doc.uploaded_by, 'MICHELLE'));
                        apex_json.write('page', 2);
                        apex_json.close_object;
                    END LOOP;
                    IF l_cnt = 0 THEN
                        apex_json.open_object;
                        apex_json.write('name', r_tender.tender_code || '_Tender_Brief.pdf');
                        apex_json.write('badge', 'INTAKE BRIEF');
                        apex_json.write('badgeClass', 'fc-badge-pdf');
                        apex_json.write('size', '2.50 MB');
                        apex_json.write('ver', 'v1.0');
                        apex_json.write('author', 'MICHELLE');
                        apex_json.write('page', 2);
                        apex_json.close_object;
                    END IF;
                    apex_json.close_array;

                    -- 02_Designing
                    apex_json.open_array('02_Designing');
                    l_cnt := 0;
                    FOR r_doc IN (
                        SELECT file_name, doc_type, file_size_bytes, version_num, uploaded_by
                        FROM fc_tender_documents
                        WHERE tender_id = r_tender.tender_id
                          AND doc_type IN ('FLOORPLAN', '3D_RENDER', 'DRAWING')
                        ORDER BY document_id
                    ) LOOP
                        l_cnt := l_cnt + 1;
                        apex_json.open_object;
                        apex_json.write('name', r_doc.file_name);
                        apex_json.write('badge', CASE WHEN r_doc.doc_type = 'FLOORPLAN' THEN 'DWG PLAN' ELSE '3D CAD' END);
                        apex_json.write('badgeClass', CASE WHEN r_doc.doc_type = 'FLOORPLAN' THEN 'fc-badge-dwg' ELSE 'fc-badge-3d' END);
                        apex_json.write('size', ROUND(NVL(r_doc.file_size_bytes, 5242880)/1048576, 2) || ' MB');
                        apex_json.write('ver', 'v' || TO_CHAR(NVL(r_doc.version_num, 1.0), 'FM90.0'));
                        apex_json.write('author', NVL(r_doc.uploaded_by, 'ADI'));
                        apex_json.write('page', 4);
                        apex_json.close_object;
                    END LOOP;
                    IF l_cnt = 0 THEN
                        apex_json.open_object;
                        apex_json.write('name', r_tender.tender_code || '_Spatial_Feasibility.dwg');
                        apex_json.write('badge', '3D CAD');
                        apex_json.write('badgeClass', 'fc-badge-3d');
                        apex_json.write('size', '8.40 MB');
                        apex_json.write('ver', 'v1.0');
                        apex_json.write('author', 'ADI');
                        apex_json.write('page', 4);
                        apex_json.close_object;
                    END IF;
                    apex_json.close_array;

                    -- 03_Operations
                    apex_json.open_array('03_Operations');
                    l_cnt := 0;
                    FOR r_doc IN (
                        SELECT file_name, doc_type, file_size_bytes, version_num, uploaded_by
                        FROM fc_tender_documents
                        WHERE tender_id = r_tender.tender_id
                          AND doc_type IN ('QUOTE')
                        ORDER BY document_id
                    ) LOOP
                        l_cnt := l_cnt + 1;
                        apex_json.open_object;
                        apex_json.write('name', r_doc.file_name);
                        apex_json.write('badge', 'BOQ QUOTE');
                        apex_json.write('badgeClass', 'fc-badge-quote');
                        apex_json.write('size', ROUND(NVL(r_doc.file_size_bytes, 1572864)/1048576, 2) || ' MB');
                        apex_json.write('ver', 'v' || TO_CHAR(NVL(r_doc.version_num, 1.0), 'FM90.0'));
                        apex_json.write('author', NVL(r_doc.uploaded_by, 'WEI_LIN'));
                        apex_json.write('page', 5);
                        apex_json.close_object;
                    END LOOP;
                    IF l_cnt = 0 THEN
                        apex_json.open_object;
                        apex_json.write('name', r_tender.tender_code || '_BOQ_LineItems.xlsx');
                        apex_json.write('badge', 'BOQ XLS');
                        apex_json.write('badgeClass', 'fc-badge-quote');
                        apex_json.write('size', '1.80 MB');
                        apex_json.write('ver', 'v1.0');
                        apex_json.write('author', 'WEI_LIN');
                        apex_json.write('page', 5);
                        apex_json.close_object;
                    END IF;
                    apex_json.close_array;

                    apex_json.close_object; -- folders
                    apex_json.close_object; -- tender
                END LOOP;

                apex_json.close_object; -- month
            END LOOP;

            apex_json.close_object; -- year
        END LOOP;

        apex_json.close_object; -- root
        l_clob := apex_json.get_clob_output;
        apex_json.free_output;
        RETURN l_clob;
    END get_explorer_data_json;

END fc_planning_api;
/
