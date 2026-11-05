CREATE OR REPLACE PACKAGE fc_repository_api AS
    /**
     * Flash Concepts - Master Repositories API
     * Provides single row insertion and bulk Excel/CSV ingestion for:
     * 1. Venue Profiles & Spatial Constraints (FC_VENUE_PROFILES)
     * 2. Statutory & Venue Compliance Rules (FC_COMPLIANCE_RULES)
     */

    PROCEDURE insert_venue(
        p_venue_name   IN VARCHAR2,
        p_hall_name    IN VARCHAR2,
        p_location     IN VARCHAR2,
        p_length_m     IN NUMBER,
        p_width_m      IN NUMBER,
        p_height_m     IN NUMBER,
        p_floor_load   IN NUMBER DEFAULT NULL,
        p_obstructions IN VARCHAR2 DEFAULT NULL,
        p_user_name    IN VARCHAR2 DEFAULT USER,
        x_venue_id     OUT NUMBER
    );

    PROCEDURE ingest_venues_file(
        p_file_name IN VARCHAR2,
        p_user_name IN VARCHAR2,
        x_count     OUT NUMBER,
        x_message   OUT VARCHAR2
    );

    PROCEDURE insert_compliance_rule(
        p_jurisdiction IN VARCHAR2,
        p_category     IN VARCHAR2,
        p_rule_title   IN VARCHAR2,
        p_description  IN VARCHAR2,
        p_official_ref IN VARCHAR2,
        p_user_name    IN VARCHAR2 DEFAULT USER,
        x_rule_id      OUT NUMBER
    );

    PROCEDURE ingest_rules_file(
        p_file_name IN VARCHAR2,
        p_user_name IN VARCHAR2,
        x_count     OUT NUMBER,
        x_message   OUT VARCHAR2
    );

END fc_repository_api;
/
