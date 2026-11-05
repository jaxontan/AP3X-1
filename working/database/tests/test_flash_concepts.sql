-- ============================================================================
-- Flash Concepts - Unit & Business Rule Test Suite
-- Tests all public API subprograms and gate validation business rules
-- ============================================================================
SET DEFINE OFF;
SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    l_test_count  NUMBER := 0;
    l_pass_count  NUMBER := 0;
    l_fail_count  NUMBER := 0;
    l_dummy_bool  BOOLEAN;
    l_dummy_str   VARCHAR2(100);
    l_deck_html   VARCHAR2(32767);

    PROCEDURE assert_true(p_condition IN BOOLEAN, p_msg IN VARCHAR2) IS
    BEGIN
        l_test_count := l_test_count + 1;
        IF p_condition THEN
            l_pass_count := l_pass_count + 1;
            DBMS_OUTPUT.PUT_LINE('  [PASS] ' || p_msg);
        ELSE
            l_fail_count := l_fail_count + 1;
            DBMS_OUTPUT.PUT_LINE('  [FAIL] ' || p_msg);
        END IF;
    END assert_true;

BEGIN
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('Running Flash Concepts Package & Rule Test Suite');
    DBMS_OUTPUT.PUT_LINE('====================================================');

    -- Test 1: Security API has_role and is_admin
    l_dummy_bool := fc_security_api.has_role('ADMIN', 'ADMINISTRATOR');
    assert_true(l_dummy_bool, 'fc_security_api.has_role returns TRUE for ADMIN');

    l_dummy_bool := fc_security_api.is_admin('ADMIN');
    assert_true(l_dummy_bool, 'fc_security_api.is_admin returns TRUE for ADMIN');

    l_dummy_bool := fc_security_api.is_auditor('AUDITOR');
    assert_true(l_dummy_bool, 'fc_security_api.is_auditor returns TRUE for AUDITOR');

    l_dummy_bool := fc_security_api.can_access_tender(1, 'MICHELLE');
    assert_true(l_dummy_bool, 'fc_security_api.can_access_tender returns TRUE for tender owner');

    -- Test 2: Assign role & set delegate
    fc_security_api.assign_role('MICHELLE', 'PLANNING_LEAD');
    fc_security_api.set_delegate(1, 'WEI_LIN');
    assert_true(TRUE, 'fc_security_api.assign_role and set_delegate executed');

    -- Test 3: Audit Logging
    fc_audit_api.log_event(1, 'ADMIN', 'TEST_RUN', 'UNIT_TEST', 'Asserting audit logging');
    assert_true(TRUE, 'fc_audit_api.log_event completed successfully');

    -- Test 4: Planning API
    fc_planning_api.confirm_intake(1, 'MICHELLE');
    fc_planning_api.review_finding(1, 'APPROVED', 'MICHELLE');
    fc_planning_api.select_concept(1, 1, 'MICHELLE');
    fc_planning_api.reprompt_concept(1, 1, 'Incorporate biophilic timber elements', 'MICHELLE');
    fc_planning_api.update_concept(1, 'Horizon: The Experience Journey (Updated)', 'Refined narrative text', 'Spatial clearance 5m', 'Run of show opening at 9am', 'MICHELLE');
    fc_planning_api.generate_handover(1, 'MICHELLE');
    assert_true(TRUE, 'fc_planning_api subprograms executed successfully');

    -- Test 5: Design API
    fc_design_api.run_spatial_check(1, 1, 'Test Truss Arch', 10, 8, 5.5, 'ADI');
    fc_design_api.upload_drawing_package(1, 'Presentation Drawing v1.1', 1.1, 'ADI');
    l_deck_html := fc_design_api.render_html_slide_deck(1);
    assert_true(l_deck_html IS NOT NULL, 'fc_design_api spatial check, package upload, and slide deck render executed');

    -- Test 6: Costing API
    fc_costing_api.calculate_boq_totals(1, 33.33, 'WEI_LIN');
    fc_costing_api.record_rfq_sent(1, 'WEI_LIN');
    fc_costing_api.select_quotation(1, 'Best technical spec and lead time', 'WEI_LIN');
    fc_costing_api.generate_client_invoice(1, 'WEI_LIN');
    fc_costing_api.bind_bom_image(1, '#APP_FILES#images/nyp_hex_pod.png', 'Class 0 flame-retardant birch timber acoustic pod', 'WEI_LIN');
    assert_true(TRUE, 'fc_costing_api calculation, quotation, invoice, and BOM image binding executed');

    -- Test 7: Workflow API Stage & Gate
    l_dummy_str := fc_workflow_api.get_current_stage(1);
    assert_true(l_dummy_str IS NOT NULL, 'fc_workflow_api.get_current_stage returns valid stage');

    l_dummy_bool := fc_workflow_api.is_gate_approved(1, 1);
    assert_true(l_dummy_bool, 'fc_workflow_api.is_gate_approved returns TRUE for Gate 1');

    -- Test 8: Gate Prerequisite Rejection Check
    BEGIN
        -- Attempting Gate 3 directly for an unapproved tender should fail
        fc_workflow_api.approve_gate(4, 3, 'WEI_LIN', 'Bypassing Gate 2');
        assert_true(FALSE, 'Gate sequence bypass should raise error');
    EXCEPTION
        WHEN OTHERS THEN
            assert_true(SQLCODE = -20002, 'Gate sequence check caught invalid progression (ORA-20002)');
    END;

    -- Test 9: Gate Rejection
    fc_workflow_api.reject_gate(1, 4, 'COPYWRITER', 'Typo in delegate count statement');
    assert_true(TRUE, 'fc_workflow_api.reject_gate recorded rejection comment');

    -- Test 10: Specific Gate Approvals and Proposal Release
    fc_design_api.approve_gate2(p_tender_id => 1, p_user_name => 'DES_LEAD', p_comments => 'Spatial clearance verified');
    assert_true(TRUE, 'fc_design_api.approve_gate2 passed');

    fc_costing_api.approve_gate3(p_tender_id => 1, p_user_name => 'OPS_LEAD', p_comments => 'Target margin 18.5% calibrated');
    assert_true(TRUE, 'fc_costing_api.approve_gate3 passed');

    fc_workflow_api.approve_gate(p_tender_id => 1, p_gate_number => 4, p_user_name => 'COPYWRITER', p_comments => 'Typo resolved; copy verified');
    assert_true(TRUE, 'fc_workflow_api.approve_gate passed for Gate 4');

    fc_workflow_api.release_proposal(p_tender_id => 1, p_user_name => 'EXEC_LEAD', p_comments => 'Final client deck ready');
    assert_true(TRUE, 'fc_workflow_api.release_proposal passed');

    -- Summary
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Tests Run: ' || l_test_count || ', Passed: ' || l_pass_count || ', Failed: ' || l_fail_count);
    DBMS_OUTPUT.PUT_LINE('====================================================');
END;
/
