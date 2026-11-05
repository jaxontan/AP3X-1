CREATE OR REPLACE PACKAGE fc_costing_api AS
    -- Step 3: Wei Lin Operations Hub & Costing

    PROCEDURE decode_sketches_to_boq(
        p_tender_id   IN NUMBER,
        p_user_name   IN VARCHAR2
    );

    PROCEDURE generate_bespoke_rfqs(
        p_tender_id   IN NUMBER,
        p_user_name   IN VARCHAR2
    );

    -- SC-03: Reconcile BOQ items and re-issue delta RFQs upon addendum
    PROCEDURE reconcile_boq_addendum(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2 DEFAULT 'WEI_LIN'
    );

    PROCEDURE reissue_delta_rfqs(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2 DEFAULT 'WEI_LIN'
    );

    PROCEDURE evaluate_compliance_and_fees(
        p_tender_id   IN NUMBER,
        p_user_name   IN VARCHAR2
    );

    PROCEDURE calculate_boq_totals(
        p_tender_id  IN NUMBER,
        p_markup_pct IN NUMBER,
        p_user_name  IN VARCHAR2
    );

    PROCEDURE record_rfq_sent(
        p_rfq_id    IN NUMBER,
        p_user_name IN VARCHAR2
    );

    PROCEDURE select_quotation(
        p_quote_id  IN NUMBER,
        p_reason    IN VARCHAR2,
        p_user_name IN VARCHAR2
    );

    PROCEDURE generate_client_invoice(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2
    );

    PROCEDURE bind_bom_image(
        p_boq_id       IN NUMBER,
        p_image_url    IN VARCHAR2,
        p_spec_details IN VARCHAR2 DEFAULT NULL,
        p_user_name    IN VARCHAR2 DEFAULT 'WEI_LIN'
    );

    PROCEDURE approve_gate3(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2,
        p_comments  IN VARCHAR2 DEFAULT NULL
    );
END fc_costing_api;
/
