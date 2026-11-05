CREATE OR REPLACE PACKAGE fc_ai_agent_api AS
    /**
     * Flash Concepts AI gateway.
     * Every LLM call goes through call_openrouter, which works with any
     * OpenAI-compatible chat endpoint (OpenRouter today; our own LLM later by
     * changing FC_AI_SETTINGS) and logs tokens, cost and latency to FC_AI_CALLS.
     * Agents:
     *   - analyse_brief       : brief text -> requirements, risks, client questions
     *   - run_planning_agent  : confirmed brief -> 3 concept options
     *   - design / costing / translation agents (wrappers over the domain APIs)
     */

    -- Test live connectivity to the configured LLM endpoint
    FUNCTION test_connection RETURN VARCHAR2;

    -- Update LLM configuration
    PROCEDURE save_config(
        p_api_key       IN VARCHAR2,
        p_model_name    IN VARCHAR2 DEFAULT 'google/gemini-flash-1.5',
        p_endpoint_url  IN VARCHAR2 DEFAULT 'https://openrouter.ai/api/v1/chat/completions',
        p_user_name     IN VARCHAR2 DEFAULT USER
    );

    -- Core chat-completion caller. Returns NULL when offline or on error
    -- (the reason is logged in FC_AI_CALLS). p_json_mode = 'Y' asks the model
    -- for a JSON object reply.
    FUNCTION call_openrouter(
        p_system_prompt IN CLOB,
        p_user_prompt   IN CLOB,
        p_model         IN VARCHAR2 DEFAULT NULL,
        p_temperature   IN NUMBER DEFAULT 0.7,
        p_max_tokens    IN NUMBER DEFAULT 1800,
        p_tender_id     IN NUMBER DEFAULT NULL,
        p_agent         IN VARCHAR2 DEFAULT 'GENERAL',
        p_json_mode     IN VARCHAR2 DEFAULT 'N'
    ) RETURN CLOB;

    -- Pull the JSON object out of a model reply (strips code fences and chatter).
    -- Returns NULL if no valid JSON object is found.
    FUNCTION extract_json(p_text IN CLOB) RETURN CLOB;

    -- Analyse a stored tender document (FC_TENDER_DOCUMENTS.EXTRACTED_TEXT) into
    -- FC_INTAKE_FIELDS (requirements + client questions) and FC_PLANNING_FLAGS (risks).
    PROCEDURE analyse_brief(
        p_tender_id     IN NUMBER,
        p_document_id   IN NUMBER,
        p_user_name     IN VARCHAR2,
        x_message       OUT VARCHAR2
    );

    -- Michelle (planning): 3 concept options from the confirmed brief.
    PROCEDURE run_planning_agent(
        p_tender_id     IN NUMBER,
        p_user_name     IN VARCHAR2
    );

END fc_ai_agent_api;
/
