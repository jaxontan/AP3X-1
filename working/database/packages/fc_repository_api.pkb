CREATE OR REPLACE PACKAGE BODY fc_repository_api AS

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
    ) IS
        l_hall VARCHAR2(100);
    BEGIN
        IF TRIM(p_venue_name) IS NULL THEN
            raise_application_error(-20011, 'Venue name is required.');
        END IF;

        IF p_length_m <= 0 OR p_width_m <= 0 OR p_height_m <= 0 THEN
            raise_application_error(-20012, 'Venue dimensions (length, width, clear height) must be greater than zero.');
        END IF;

        l_hall := NVL(TRIM(p_hall_name), 'Main Hall');

        MERGE INTO fc_venue_profiles t
        USING (SELECT TRIM(p_venue_name) AS v_name, l_hall AS h_name FROM dual) s
           ON (t.venue_name = s.v_name AND t.hall_name = s.h_name)
        WHEN MATCHED THEN
            UPDATE SET location = NVL(TRIM(p_location), t.location),
                       usable_length_m = p_length_m,
                       usable_width_m = p_width_m,
                       clear_height_m = p_height_m,
                       max_floor_load_kn = p_floor_load,
                       obstructions = p_obstructions,
                       verified_by = p_user_name,
                       last_review_date = SYSDATE
        WHEN NOT MATCHED THEN
            INSERT (venue_name, hall_name, location, usable_length_m, usable_width_m, clear_height_m, max_floor_load_kn, obstructions, verification_status, verified_by, last_review_date)
            VALUES (TRIM(p_venue_name), l_hall, NVL(TRIM(p_location), 'Singapore'), p_length_m, p_width_m, p_height_m, p_floor_load, p_obstructions, 'VERIFIED', p_user_name, SYSDATE);

        SELECT venue_id INTO x_venue_id
          FROM fc_venue_profiles
         WHERE venue_name = TRIM(p_venue_name) AND hall_name = l_hall;

        fc_audit_api.log_event(
            NULL, p_user_name, 'VENUE_INSERT', 'FC_VENUE_PROFILES',
            'Added/updated venue: ' || p_venue_name || ' (' || l_hall || '), clear height: ' || p_height_m || 'm'
        );
    END insert_venue;

    PROCEDURE ingest_venues_file(
        p_file_name IN VARCHAR2,
        p_user_name IN VARCHAR2,
        x_count     OUT NUMBER,
        x_message   OUT VARCHAR2
    ) IS
        l_blob BLOB;
        l_cnt  NUMBER := 0;
    BEGIN
        SELECT blob_content
          INTO l_blob
          FROM apex_application_temp_files
         WHERE name = p_file_name;

        FOR r IN (
            SELECT line_number,
                   TRIM(col001) AS v_name,
                   TRIM(col002) AS h_name,
                   TRIM(col003) AS loc,
                   TO_NUMBER(REGEXP_REPLACE(TRIM(col004), '[^0-9\.]', '')) AS len_m,
                   TO_NUMBER(REGEXP_REPLACE(TRIM(col005), '[^0-9\.]', '')) AS wid_m,
                   TO_NUMBER(REGEXP_REPLACE(TRIM(col006), '[^0-9\.]', '')) AS hgt_m,
                   TO_NUMBER(REGEXP_REPLACE(TRIM(col007), '[^0-9\.]', '')) AS floor_kn,
                   TRIM(col008) AS obst
              FROM TABLE(apex_data_parser.parse(
                  p_content   => l_blob,
                  p_file_name => p_file_name,
                  p_skip_rows => 1
              ))
             WHERE col001 IS NOT NULL
        ) LOOP
            MERGE INTO fc_venue_profiles t
            USING (SELECT r.v_name AS v_name, NVL(r.h_name, 'Main Hall') AS h_name FROM dual) s
               ON (t.venue_name = s.v_name AND t.hall_name = s.h_name)
            WHEN MATCHED THEN
                UPDATE SET location = NVL(r.loc, t.location),
                           usable_length_m = NVL(r.len_m, t.usable_length_m),
                           usable_width_m = NVL(r.wid_m, t.usable_width_m),
                           clear_height_m = NVL(r.hgt_m, t.clear_height_m),
                           max_floor_load_kn = NVL(r.floor_kn, t.max_floor_load_kn),
                           obstructions = NVL(r.obst, t.obstructions),
                           verified_by = p_user_name,
                           last_review_date = SYSDATE
            WHEN NOT MATCHED THEN
                INSERT (venue_name, hall_name, location, usable_length_m, usable_width_m, clear_height_m, max_floor_load_kn, obstructions, verification_status, verified_by, last_review_date)
                VALUES (r.v_name, NVL(r.h_name, 'Main Hall'), NVL(r.loc, 'Singapore'), NVL(r.len_m, 25.0), NVL(r.wid_m, 15.0), NVL(r.hgt_m, 6.0), r.floor_kn, r.obst, 'VERIFIED', p_user_name, SYSDATE);

            l_cnt := l_cnt + 1;
        END LOOP;

        fc_audit_api.log_event(
            NULL, p_user_name, 'VENUE_EXCEL_INGEST', 'FC_VENUE_PROFILES',
            'Bulk-ingested ' || l_cnt || ' venues from file ' || p_file_name
        );

        x_count := l_cnt;
        x_message := 'Successfully ingested ' || l_cnt || ' venue records from Excel / CSV file.';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            raise_application_error(-20001, 'Uploaded file not found in temporary storage. Please re-upload.');
    END ingest_venues_file;

    PROCEDURE insert_compliance_rule(
        p_jurisdiction IN VARCHAR2,
        p_category     IN VARCHAR2,
        p_rule_title   IN VARCHAR2,
        p_description  IN VARCHAR2,
        p_official_ref IN VARCHAR2,
        p_user_name    IN VARCHAR2 DEFAULT USER,
        x_rule_id      OUT NUMBER
    ) IS
        l_jur VARCHAR2(10);
    BEGIN
        IF TRIM(p_rule_title) IS NULL OR TRIM(p_category) IS NULL THEN
            raise_application_error(-20021, 'Rule category and title are required.');
        END IF;

        l_jur := UPPER(NVL(TRIM(p_jurisdiction), 'SG'));
        IF l_jur NOT IN ('SG', 'JKT') THEN
            l_jur := 'SG';
        END IF;

        INSERT INTO fc_compliance_rules (
            jurisdiction, category, rule_title, description, official_ref, is_validated, effective_date
        ) VALUES (
            l_jur,
            TRIM(p_category),
            TRIM(p_rule_title),
            NVL(TRIM(p_description), TRIM(p_rule_title)),
            NVL(TRIM(p_official_ref), 'Regulatory Authority Endorsement'),
            'Y',
            SYSDATE
        ) RETURNING rule_id INTO x_rule_id;

        fc_audit_api.log_event(
            NULL, p_user_name, 'COMPLIANCE_RULE_INSERT', 'FC_COMPLIANCE_RULES',
            'Added compliance rule [' || l_jur || '] ' || p_category || ': ' || p_rule_title
        );
    END insert_compliance_rule;

    PROCEDURE ingest_rules_file(
        p_file_name IN VARCHAR2,
        p_user_name IN VARCHAR2,
        x_count     OUT NUMBER,
        x_message   OUT VARCHAR2
    ) IS
        l_blob BLOB;
        l_cnt  NUMBER := 0;
        l_jur  VARCHAR2(10);
    BEGIN
        SELECT blob_content
          INTO l_blob
          FROM apex_application_temp_files
         WHERE name = p_file_name;

        FOR r IN (
            SELECT line_number,
                   TRIM(col001) AS jur,
                   TRIM(col002) AS cat,
                   TRIM(col003) AS title,
                   TRIM(col004) AS descr,
                   TRIM(col005) AS ref
              FROM TABLE(apex_data_parser.parse(
                  p_content   => l_blob,
                  p_file_name => p_file_name,
                  p_skip_rows => 1
              ))
             WHERE col002 IS NOT NULL
        ) LOOP
            l_jur := UPPER(NVL(r.jur, 'SG'));
            IF l_jur NOT IN ('SG', 'JKT') THEN
                IF INSTR(l_jur, 'IND') > 0 OR INSTR(l_jur, 'JAK') > 0 THEN
                    l_jur := 'JKT';
                ELSE
                    l_jur := 'SG';
                END IF;
            END IF;

            INSERT INTO fc_compliance_rules (
                jurisdiction, category, rule_title, description, official_ref, is_validated, effective_date
            ) VALUES (
                l_jur,
                NVL(r.cat, 'VENUE_REGULATION'),
                NVL(r.title, 'Statutory Venue Requirement'),
                NVL(r.descr, 'Operational compliance rule ingested via Excel repository import.'),
                NVL(r.ref, 'Regulatory Authority Endorsement'),
                'Y',
                SYSDATE
            );
            l_cnt := l_cnt + 1;
        END LOOP;

        fc_audit_api.log_event(
            NULL, p_user_name, 'COMPLIANCE_EXCEL_INGEST', 'FC_COMPLIANCE_RULES',
            'Bulk-ingested ' || l_cnt || ' compliance rules from file ' || p_file_name
        );

        x_count := l_cnt;
        x_message := 'Successfully ingested ' || l_cnt || ' compliance rules from Excel / CSV file.';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            raise_application_error(-20001, 'Uploaded file not found in temporary storage. Please re-upload.');
    END ingest_rules_file;

END fc_repository_api;
/
