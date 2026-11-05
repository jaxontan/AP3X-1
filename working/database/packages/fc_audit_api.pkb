CREATE OR REPLACE PACKAGE BODY fc_audit_api AS
    PROCEDURE log_event(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2,
        p_action    IN VARCHAR2,
        p_entity    IN VARCHAR2,
        p_details   IN VARCHAR2 DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO fc_audit_logs (
            tender_id, user_name, action_name, entity_name, details
        ) VALUES (
            p_tender_id, NVL(p_user_name, USER), p_action, p_entity, p_details
        );
        COMMIT;
    END log_event;
END fc_audit_api;
/
