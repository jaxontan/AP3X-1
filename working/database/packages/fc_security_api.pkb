CREATE OR REPLACE PACKAGE BODY fc_security_api AS
    FUNCTION has_role(p_username IN VARCHAR2, p_role IN VARCHAR2) RETURN BOOLEAN IS
        l_cnt NUMBER := 0;
    BEGIN
        IF p_username IS NULL THEN RETURN FALSE; END IF;
        SELECT COUNT(*) INTO l_cnt
          FROM fc_user_roles
         WHERE UPPER(username) = UPPER(p_username)
           AND UPPER(role_code) = UPPER(p_role);
        RETURN l_cnt > 0;
    END has_role;

    FUNCTION is_admin(p_username IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN has_role(p_username, 'ADMINISTRATOR') OR UPPER(p_username) IN ('ADMIN', 'SGINT02');
    END is_admin;

    FUNCTION is_auditor(p_username IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN has_role(p_username, 'AUDITOR') OR is_admin(p_username) OR has_role(p_username, 'LEADERSHIP');
    END is_auditor;

    FUNCTION can_access_tender(p_tender_id IN NUMBER, p_username IN VARCHAR2) RETURN BOOLEAN IS
        l_cnt NUMBER := 0;
    BEGIN
        IF is_admin(p_username) THEN RETURN TRUE; END IF;
        SELECT COUNT(*) INTO l_cnt
          FROM fc_tenders
         WHERE tender_id = p_tender_id
           AND (is_confidential = 'N'
                OR UPPER(sponsor_user) = UPPER(p_username)
                OR UPPER(planning_lead) = UPPER(p_username)
                OR UPPER(designer_user) = UPPER(p_username)
                OR UPPER(ops_lead) = UPPER(p_username)
                OR UPPER(NVL(delegate_user, '___')) = UPPER(p_username));
        RETURN l_cnt > 0;
    END can_access_tender;

    PROCEDURE assign_role(p_username IN VARCHAR2, p_role IN VARCHAR2) IS
    BEGIN
        MERGE INTO fc_user_roles d
        USING (SELECT p_username AS u, p_role AS r FROM dual) s
        ON (UPPER(d.username) = UPPER(s.u) AND UPPER(d.role_code) = UPPER(s.r))
        WHEN NOT MATCHED THEN
            INSERT (username, role_code) VALUES (s.u, s.r);
    END assign_role;

    PROCEDURE set_delegate(p_tender_id IN NUMBER, p_delegate_user IN VARCHAR2) IS
    BEGIN
        UPDATE fc_tenders
           SET delegate_user = p_delegate_user,
               updated_at = CURRENT_TIMESTAMP
         WHERE tender_id = p_tender_id;
    END set_delegate;
END fc_security_api;
/
