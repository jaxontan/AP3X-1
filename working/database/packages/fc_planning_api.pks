CREATE OR REPLACE PACKAGE fc_planning_api AS
    -- Tender Management
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
    );

    -- AI OCR & Document Ingestion
    PROCEDURE ingest_and_parse_brief(
        p_tender_id      IN NUMBER,
        p_file_name      IN VARCHAR2,
        p_doc_type       IN VARCHAR2 DEFAULT 'BRIEF',
        p_user_name      IN VARCHAR2,
        x_doc_id         OUT NUMBER
    );

    -- Real document upload: stores the file from APEX_APPLICATION_TEMP_FILES,
    -- extracts its text (PDF, Word, text) and, for briefs and addenda, runs the
    -- AI brief analysis. x_message is a user-facing result line.
    PROCEDURE ingest_uploaded_brief(
        p_tender_id      IN NUMBER,
        p_temp_file_name IN VARCHAR2,
        p_doc_type       IN VARCHAR2 DEFAULT 'BRIEF',
        p_user_name      IN VARCHAR2,
        x_doc_id         OUT NUMBER,
        x_message        OUT VARCHAR2
    );

    -- Supervised Client Research (Tavily / Search API Integration)
    PROCEDURE run_client_research(
        p_tender_id      IN NUMBER,
        p_query          IN VARCHAR2,
        p_search_engine  IN VARCHAR2 DEFAULT 'TAVILY_AI_FINANCE',
        p_user_name      IN VARCHAR2
    );

    -- Research Finding Review
    PROCEDURE review_finding(
        p_finding_id     IN NUMBER,
        p_status         IN VARCHAR2,
        p_user_name      IN VARCHAR2
    );

    -- Intake Confirmation
    PROCEDURE confirm_intake(
        p_tender_id      IN NUMBER,
        p_user_name      IN VARCHAR2
    );

    -- Concept Generation & Selection (Step 1: Michelle)
    PROCEDURE generate_concept_options(
        p_tender_id      IN NUMBER,
        p_user_name      IN VARCHAR2
    );

    PROCEDURE select_concept(
        p_tender_id      IN NUMBER,
        p_concept_id     IN NUMBER,
        p_user_name      IN VARCHAR2
    );

    -- Concept Reprompt & Direct Edit (Planning Studio)
    PROCEDURE reprompt_concept(
        p_tender_id      IN NUMBER,
        p_concept_id     IN NUMBER,
        p_instruction    IN VARCHAR2,
        p_user_name      IN VARCHAR2
    );

    PROCEDURE update_concept(
        p_concept_id     IN NUMBER,
        p_concept_title  IN VARCHAR2,
        p_narrative      IN VARCHAR2,
        p_spatial_notes  IN VARCHAR2,
        p_event_flow     IN VARCHAR2,
        p_user_name      IN VARCHAR2
    );

    -- Automated Downstream Handover Distribution (Supports Bilingual EN / ID)
    PROCEDURE generate_handover(
        p_tender_id      IN NUMBER,
        p_user_name      IN VARCHAR2,
        p_lang           IN VARCHAR2 DEFAULT 'EN'
    );

    -- SC-03: Process Scope Addendum & Revision Engine
    PROCEDURE process_tender_addendum(
        p_tender_id      IN NUMBER,
        p_addendum_title IN VARCHAR2 DEFAULT 'Addendum #1: Scope Revision',
        p_scope_delta    IN VARCHAR2 DEFAULT NULL,
        p_user_name      IN VARCHAR2 DEFAULT 'MICHELLE'
    );

    -- Gate 1 Approval
    PROCEDURE approve_gate_1(
        p_tender_id      IN NUMBER,
        p_user_name      IN VARCHAR2,
        p_comments       IN VARCHAR2 DEFAULT NULL
    );

    -- Dynamic File Explorer Data JSON (Live Database Tenders & Documents)
    FUNCTION get_explorer_data_json RETURN CLOB;

    -- Custom Document Upload (allows anyone to upload to Custom Uploads repository)
    PROCEDURE upload_custom_document(
        p_tender_id      IN NUMBER,
        p_file_name      IN VARCHAR2,
        p_file_size      IN NUMBER DEFAULT NULL,
        p_mime_type      IN VARCHAR2 DEFAULT NULL,
        p_user_name      IN VARCHAR2 DEFAULT NULL,
        p_notes          IN VARCHAR2 DEFAULT NULL
    );
END fc_planning_api;
/
