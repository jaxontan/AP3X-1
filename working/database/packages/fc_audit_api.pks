CREATE OR REPLACE PACKAGE fc_audit_api AS
    PROCEDURE log_event(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2,
        p_action    IN VARCHAR2,
        p_entity    IN VARCHAR2,
        p_details   IN VARCHAR2 DEFAULT NULL
    );
END fc_audit_api;
/
