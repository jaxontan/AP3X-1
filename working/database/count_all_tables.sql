SET SERVEROUTPUT ON SIZE UNLIMITED;
DECLARE
    l_cnt NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('TABLE NAME', 28) || 'ACTUAL ROW COUNT');
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
    FOR t IN (SELECT table_name FROM user_tables WHERE table_name LIKE 'FC_%' ORDER BY table_name) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'SELECT count(*) FROM "' || t.table_name || '"' INTO l_cnt;
            DBMS_OUTPUT.PUT_LINE(RPAD(t.table_name, 28) || l_cnt);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE(RPAD(t.table_name, 28) || 'ERROR: ' || SQLERRM);
        END;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
END;
/
