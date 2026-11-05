CREATE OR REPLACE PACKAGE fc_design_api AS
    -- Step 2: Adi Design Studio Operations

    PROCEDURE generate_slide_deck_drafts(
        p_tender_id   IN NUMBER,
        p_user_name   IN VARCHAR2
    );

    PROCEDURE run_spatial_check(
        p_tender_id      IN NUMBER,
        p_venue_id       IN NUMBER,
        p_structure_name IN VARCHAR2,
        p_len            IN NUMBER,
        p_wid            IN NUMBER,
        p_hgt            IN NUMBER,
        p_user_name      IN VARCHAR2
    );

    PROCEDURE upload_drawing_package(
        p_tender_id   IN NUMBER,
        p_title       IN VARCHAR2,
        p_version     IN NUMBER,
        p_user_name   IN VARCHAR2,
        x_package_id  OUT NUMBER
    );

    PROCEDURE upload_drawing_package(
        p_tender_id   IN NUMBER,
        p_title       IN VARCHAR2,
        p_version     IN NUMBER,
        p_user_name   IN VARCHAR2
    );

    PROCEDURE generate_3d_specs(
        p_tender_id   IN NUMBER,
        p_user_name   IN VARCHAR2,
        p_venue_id    IN NUMBER DEFAULT NULL
    );

    -- SC-02: Collision Mitigation Action
    PROCEDURE resolve_spatial_collision(
        p_tender_id      IN NUMBER,
        p_structure_name IN VARCHAR2 DEFAULT '8.8m High Custom Kinetic Chandelier & Proscenium',
        p_new_height     IN NUMBER DEFAULT 7.80,
        p_user_name      IN VARCHAR2 DEFAULT 'ADI'
    );

    PROCEDURE approve_gate2(
        p_tender_id   IN NUMBER,
        p_user_name   IN VARCHAR2,
        p_comments    IN VARCHAR2 DEFAULT NULL
    );

    FUNCTION generate_ppt_deck_content(
        p_tender_id   IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION render_html_slide_deck(
        p_tender_id   IN NUMBER
    ) RETURN VARCHAR2;
END fc_design_api;
/
