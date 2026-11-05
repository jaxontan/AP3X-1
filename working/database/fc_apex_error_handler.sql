CREATE OR REPLACE FUNCTION fc_apex_error_handler (
    p_error in apex_error.t_error
) return apex_error.t_error_result
is
    l_result apex_error.t_error_result;
begin
    l_result := apex_error.init_error_result(p_error => p_error);
    if p_error.ora_sqlcode between -20999 and -20000 then
        l_result.message         := apex_error.get_first_ora_error_text(p_error => p_error);
        l_result.additional_info := null;
    end if;
    return l_result;
end fc_apex_error_handler;
/
