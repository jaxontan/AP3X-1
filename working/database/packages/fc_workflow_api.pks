CREATE OR REPLACE PACKAGE fc_workflow_api AS
    PROCEDURE approve_gate(
        p_tender_id   IN NUMBER,
        p_gate_number IN NUMBER,
        p_user_name   IN VARCHAR2,
        p_comments    IN VARCHAR2 DEFAULT NULL
    );
    PROCEDURE reject_gate(
        p_tender_id   IN NUMBER,
        p_gate_number IN NUMBER,
        p_user_name   IN VARCHAR2,
        p_comments    IN VARCHAR2
    );
    PROCEDURE release_proposal(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2,
        p_comments  IN VARCHAR2 DEFAULT NULL
    );
    PROCEDURE execute_bilingual_translation(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2
    );
    FUNCTION get_current_stage(p_tender_id IN NUMBER) RETURN VARCHAR2;
    FUNCTION is_gate_approved(p_tender_id IN NUMBER, p_gate_number IN NUMBER) RETURN BOOLEAN;
    PROCEDURE set_active_project(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2
    );
    FUNCTION get_active_project(
        p_user_name IN VARCHAR2
    ) RETURN NUMBER;
END fc_workflow_api;
/
