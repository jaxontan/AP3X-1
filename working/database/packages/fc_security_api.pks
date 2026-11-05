CREATE OR REPLACE PACKAGE fc_security_api AS
    FUNCTION has_role(p_username IN VARCHAR2, p_role IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION is_admin(p_username IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION is_auditor(p_username IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION can_access_tender(p_tender_id IN NUMBER, p_username IN VARCHAR2) RETURN BOOLEAN;
    PROCEDURE assign_role(p_username IN VARCHAR2, p_role IN VARCHAR2);
    PROCEDURE set_delegate(p_tender_id IN NUMBER, p_delegate_user IN VARCHAR2);
END fc_security_api;
/
