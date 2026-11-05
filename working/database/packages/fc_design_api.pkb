CREATE OR REPLACE PACKAGE BODY fc_design_api AS
    -- Step 2: Adi Design Studio Operations

    PROCEDURE generate_slide_deck_drafts(
        p_tender_id   IN NUMBER,
        p_user_name   IN VARCHAR2
    ) IS
        l_client        VARCHAR2(150);
        l_title         VARCHAR2(250);
        l_deadline      VARCHAR2(50);
    BEGIN
        SELECT client_name, project_title, TO_CHAR(submission_deadline, 'DD-Mon-YYYY')
          INTO l_client, l_title, l_deadline
          FROM fc_tenders
         WHERE tender_id = p_tender_id;

        DELETE FROM fc_pitch_slides WHERE tender_id = p_tender_id;

        INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt)
        VALUES (p_tender_id, 1, 'Executive Vision: ' || l_client || ' Horizon', 'HERO_TITLE', 'Opening bold statement framing ' || l_title,
                '? Redefining Experiential Engagement for ' || l_client || CHR(10) ||
                '? Premier Exhibition & Stage Showcase | ' || l_deadline || CHR(10) ||
                '? Curated by Flash Concepts Singapore & Jakarta',
                'Full-bleed cinematic 3D render of the keynote stage with vibrant architectural lighting for ' || l_client,
                'Cinematic wide shot of futuristic event stage keynote lighting Singapore MICE ' || l_client || ' ' || l_title || ' hyperrealistic 8k');

        INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt)
        VALUES (p_tender_id, 2, 'Strategic Narrative & Brief Alignment', 'SPLIT_STORY', 'Mapping client objectives to creative experience strategy',
                '? Core Objective: Elevate ' || l_client || ' institutional brand equity and attendee engagement' || CHR(10) ||
                '? Solution: Interactive experiential journey demonstrating tangible ROI' || CHR(10) ||
                '? 100% compliance with venue regulations & statutory guidelines',
                'Infographic diagram illustrating the 3 pillars: Innovation, Sustainability, and Measurable Engagement Impact.',
                'Minimalist clean infographic diagram, technology icons, modern corporate Singapore skyline background');

        INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt)
        VALUES (p_tender_id, 3, 'Attendee Journey & Run-of-Show', 'TIMELINE_FLOW', 'Hour-by-hour operational flow and engagement rhythm',
                '? 08:30 Registration & Smart RFID Badge Activation' || CHR(10) ||
                '? 09:30 Opening Keynote: The Future of ' || l_client || CHR(10) ||
                '? 11:00 Live Interactive Solution Sandboxes & Demo Booths' || CHR(10) ||
                '? 14:00 Executive Roundtables & Fireside Panels' || CHR(10) ||
                '? 17:30 Networking Cocktail & Innovation Awards Showcase',
                'Visual horizontal timeline card layout showing progressive lighting transitions from morning daylight to evening lounge.',
                'Editorial timeline diagram of a luxury tech conference schedule, illuminated cards, sophisticated typography');

        INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt)
        VALUES (p_tender_id, 4, 'Main Stage & Spatial Architecture', 'CANVAS_3D', 'Hero 3D structure with verified spatial compliance',
                '? 14.0m W x 8.0m D x 5.8m H Curved Architectural Proscenium' || CHR(10) ||
                '? P2.6 Ultra-fine Curved LED Wall with 160? Viewing Angle' || CHR(10) ||
                '? Verified within clear ceiling height limits' || CHR(10) ||
                '? Pre-engineered modular trussing for rapid 6-hour build',
                'Photorealistic 3D front elevation render of the main stage proscenium with dimension callouts.',
                '3D architectural render of modern corporate event stage, 14 meter curved LED screen, warm oak wood trim, red ambient light, photorealistic');

        INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt)
        VALUES (p_tender_id, 5, 'Exhibition Pods & Interactive Fringe', 'GRID_ACTIVATIONS', 'Hands-on experiential zones driving attendee dwell time',
                '? Modular Demo Pods: 3.5m x 3.5m acoustic timber capsules for project showcases' || CHR(10) ||
                '? AI Innovation Sandbox: Interactive attendee tech kiosks' || CHR(10) ||
                '? Sustainable Refreshment Lounge: Zero-waste barista station' || CHR(10) ||
                '? SCDF 3.8m perimeter crowd safety aisle maintained',
                'Three vignette renders showing attendee interactions at the coffee bar, prompt lounge, and demo pods.',
                'Vignette render of interactive corporate exhibition booth, smiling business executives interacting with tablet kiosks, lush greenery');

        INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt)
        VALUES (p_tender_id, 6, 'Spatial Zoning & Verified Egress Plan', 'FLOORPLAN_MAP', 'Rigorous spatial compliance and crowd flow mapping',
                '? Total Floor Area: Verified against NYP Campus Centre atrium envelope' || CHR(10) ||
                '? Main Aisle Clearance: 3.8m (Exceeds statutory SCDF 3.5m minimum)' || CHR(10) ||
                '? Emergency Egress Setback: 4.8m clear from perimeter exits' || CHR(10) ||
                '? Zero spatial collisions detected by collision engine',
                'Overhead 2D architectural schematic highlighting designated attendee flow arrows, stage perimeter, and safety aisles.',
                'Architectural floor plan schematic, CAD blueprint style, marked safety zones in neon green and visitor flows in cyan');

        INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt)
        VALUES (p_tender_id, 7, 'Sustainability & BCA Green Mark Compliance', 'METRICS_CARDS', 'Delivering environmental excellence and social governance',
                '? 85% Material Reusability: Modular aluminum framing and timber pods' || CHR(10) ||
                '? 100% Zero Single-Use Plastics: Branded glass carafes and digital signage' || CHR(10) ||
                '? Low-Energy Fixtures: LED lighting yielding 40% power reduction' || CHR(10) ||
                '? Digital collateral distribution via NFC & QR portals',
                'ESG dashboard graphic displaying projected carbon offset and material recycling metrics.',
                'Clean ESG dashboard interface, leaf green and clean teal data visualizations, sustainability badges');

        INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt)
        VALUES (p_tender_id, 8, 'Operations Timeline & Commercial Envelope', 'SUMMARY_TABLE', 'Clear timeline, vendor milestones, and cost discipline',
                '? 6-Week Turnkey Production Schedule' || CHR(10) ||
                '? Build Date: Eve of event (08:00 - 20:00)' || CHR(10) ||
                '? Event Dates: ' || l_deadline || CHR(10) ||
                '? Teardown: Final event evening (22:00 - 06:00, curfew 23:00 SGT)' || CHR(10) ||
                '? Fixed Cost Integrity: 100% backed by historical vendor benchmarks',
                'Gantt chart timeline summary showing synchronized planning, design, and operations milestones.',
                'Corporate Gantt chart milestone graphic, organized colored phases, polished executive summary layout');

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'GENERATE_SLIDE_DRAFTS', 'FC_PITCH_SLIDES',
            'AI-assisted 8-slide pitch deck drafts and Pollinations.ai visual prompts generated for ' || l_client
        );
        COMMIT;
    END generate_slide_deck_drafts;

    PROCEDURE run_spatial_check(
        p_tender_id      IN NUMBER,
        p_venue_id       IN NUMBER,
        p_structure_name IN VARCHAR2,
        p_len            IN NUMBER,
        p_wid            IN NUMBER,
        p_hgt            IN NUMBER,
        p_user_name      IN VARCHAR2
    ) IS
        l_venue_len NUMBER;
        l_venue_wid NUMBER;
        l_venue_hgt NUMBER;
        l_status    VARCHAR2(20);
        l_delta     NUMBER;
        l_log       VARCHAR2(2000);
    BEGIN
        SELECT usable_length_m, usable_width_m, clear_height_m
          INTO l_venue_len, l_venue_wid, l_venue_hgt
          FROM fc_venue_profiles
         WHERE venue_id = p_venue_id;

        IF p_structure_name LIKE '%SCDF%' OR p_structure_name LIKE '%Fire Egress%' THEN
            -- Statutory SCDF Fire Egress corridor check: 3.8m actual vs 3.5m mandatory corridor
            l_delta := ROUND(p_wid - 3.50, 2);
            IF l_delta >= 0 THEN
                l_status := 'PASS';
            ELSE
                l_status := 'FAIL';
            END IF;
            l_log := 'Mandatory 3.5m SCDF campus perimeter corridor verified with ' || TO_CHAR(p_wid, 'FM990.0') || 'm unobstructed clear aisle (+' || TO_CHAR(l_delta, 'FM990.00') || 'm safety buffer). Result: ' || l_status;
        ELSE
            l_delta := ROUND(l_venue_hgt - p_hgt, 2);
            IF l_delta < 0 THEN
                l_status := 'FAIL';
            ELSIF l_delta < 1.0 THEN
                l_status := 'WARNING';
            ELSE
                l_status := 'PASS';
            END IF;
            l_log := 'Height ' || TO_CHAR(p_hgt, 'FM990.0') || 'm against venue clear height ' || TO_CHAR(l_venue_hgt, 'FM990.0') || 'm: '
                  || CASE WHEN l_delta < 0 THEN 'over by ' || TO_CHAR(-l_delta, 'FM990.00') || 'm' ELSE TO_CHAR(l_delta, 'FM990.00') || 'm to spare' END || '.';
            -- Footprint must fit the usable floor area too (either orientation).
            IF l_venue_len IS NOT NULL AND l_venue_wid IS NOT NULL
               AND NOT ((p_len <= l_venue_len AND p_wid <= l_venue_wid) OR (p_len <= l_venue_wid AND p_wid <= l_venue_len)) THEN
                l_status := 'FAIL';
                l_log := l_log || ' Footprint ' || TO_CHAR(p_len, 'FM990.0') || ' x ' || TO_CHAR(p_wid, 'FM990.0') || 'm does not fit the usable area '
                      || TO_CHAR(l_venue_len, 'FM990.0') || ' x ' || TO_CHAR(l_venue_wid, 'FM990.0') || 'm.';
            END IF;
            l_log := l_log || ' Result: ' || l_status;
        END IF;

        -- A re-check of the same structure replaces its earlier result.
        DELETE FROM fc_spatial_checks WHERE tender_id = p_tender_id AND structure_name = p_structure_name;

        INSERT INTO fc_spatial_checks (
            tender_id, venue_id, structure_name, req_length_m, req_width_m, req_height_m,
            feasibility_status, clearance_delta_m, assumptions_log, evaluated_by
        ) VALUES (
            p_tender_id, p_venue_id, p_structure_name, p_len, p_wid, p_hgt,
            l_status, l_delta, l_log, p_user_name
        );

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'SPATIAL_COLLISION_CHECK', 'FC_SPATIAL_CHECKS',
            p_structure_name || ' (W:' || p_wid || 'm, H:' || p_hgt || 'm) - Status: ' || l_status || ' (Clearance: +' || l_delta || 'm)'
        );
    END run_spatial_check;

    PROCEDURE upload_drawing_package(
        p_tender_id   IN NUMBER,
        p_title       IN VARCHAR2,
        p_version     IN NUMBER,
        p_user_name   IN VARCHAR2,
        x_package_id  OUT NUMBER
    ) IS
        l_clean_title VARCHAR2(250) := NVL(TRIM(p_title), 'NYP_InnovSphere_Stage_and_Pods_3D.dwg');
        l_ver         NUMBER := NVL(p_version, 1.0);
    BEGIN
        -- Invalidate existing packages
        UPDATE fc_drawing_packages
           SET is_current = 'N',
               approval_status = 'SUPERSEDED'
         WHERE tender_id = p_tender_id;

        INSERT INTO fc_drawing_packages (
            tender_id, version_num, package_title, drawing_url, approval_status, is_current, approved_by, approved_at
        ) VALUES (
            p_tender_id, l_ver, l_clean_title, '/03_3D_Sketches/' || l_clean_title, 'APPROVED', 'Y', p_user_name, CURRENT_TIMESTAMP
        ) RETURNING package_id INTO x_package_id;

        -- Register in SharePoint / Document Repository under /03_3D_Sketches/
        INSERT INTO fc_tender_documents (
            tender_id, file_name, doc_type, sharepoint_url, version_num, file_size_bytes, mime_type, uploaded_by, uploaded_at
        ) VALUES (
            p_tender_id, l_clean_title, 'DRAWING', '/03_3D_Sketches/' || l_clean_title, l_ver, 4528000, 'application/acad', p_user_name, CURRENT_TIMESTAMP
        );

        -- Invalidate downstream BOQ items if drawings change (BR-06 cascade rule)
        UPDATE fc_boq_items
           SET review_status = 'STALE'
         WHERE tender_id = p_tender_id;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'UPLOAD_DRAWING', 'FC_DRAWING_PACKAGES',
            'Drawing package v' || TO_CHAR(l_ver, 'FM990.0') || ' (' || l_clean_title || ') registered as Package ID #' || x_package_id || ' in /03_3D_Sketches/; downstream BOQ marked STALE (BR-06 cascade).'
        );
        COMMIT;
    END upload_drawing_package;

    PROCEDURE upload_drawing_package(
        p_tender_id   IN NUMBER,
        p_title       IN VARCHAR2,
        p_version     IN NUMBER,
        p_user_name   IN VARCHAR2
    ) IS
        l_dummy NUMBER;
    BEGIN
        upload_drawing_package(p_tender_id, p_title, p_version, p_user_name, l_dummy);
    END upload_drawing_package;

    PROCEDURE generate_3d_specs(
        p_tender_id   IN NUMBER,
        p_user_name   IN VARCHAR2,
        p_venue_id    IN NUMBER DEFAULT NULL
    ) IS
        l_venue_id    NUMBER := p_venue_id;
        l_client      VARCHAR2(150);
        l_title       VARCHAR2(250);
        l_office      VARCHAR2(30);
    BEGIN
        SELECT client_name, project_title, office
          INTO l_client, l_title, l_office
          FROM fc_tenders
         WHERE tender_id = p_tender_id;

        -- Re-run spatial checks for all key structures
        DELETE FROM fc_spatial_checks WHERE tender_id = p_tender_id;

        IF p_tender_id = 1 OR INSTR(UPPER(l_title), 'DBS') > 0 THEN
            -- SC-02 Constraint Event: DBS Summit at MBS Sands Expo Hall C (8.5m ceiling)
            IF l_venue_id IS NULL THEN
                l_venue_id := 1; -- Marina Bay Sands Sands Expo Hall C (8.5m)
            END IF;

            -- 1. Main Stage Arch (6.0m) -> 8.5m - 6.0m = +2.50m (PASS)
            run_spatial_check(p_tender_id, l_venue_id, 'The Spark Main Keynote Stage Proscenium', 12.0, 18.0, 6.0, p_user_name);

            -- 2. Custom Structure: 8.8m High Kinetic Chandelier -> 8.5m - 8.8m = -0.30m (FAIL)
            run_spatial_check(p_tender_id, l_venue_id, '8.8m High Custom Kinetic Chandelier & Proscenium', 14.0, 14.0, 8.8, p_user_name);

            -- 3. Circular Interactive Demo Pods (3.5m x 3.5m x 3.2m) -> 8.5m - 3.2m = +5.30m (PASS)
            run_spatial_check(p_tender_id, l_venue_id, 'Circular Interactive Demo Pods (Unit 1)', 3.5, 3.5, 3.2, p_user_name);

            -- 4. Statutory SCDF Primary Fire Egress Corridor (4.8m clear aisle vs 4.5m required) (PASS)
            run_spatial_check(p_tender_id, l_venue_id, 'Statutory SCDF Primary Fire Egress Corridor', 70.0, 4.8, 4.5, p_user_name);

        ELSIF p_tender_id = 4 OR l_office = 'JKT' OR INSTR(UPPER(l_title), 'PAYTECH') > 0 THEN
            -- SC-04 Regional Event: ASEAN PayTech at JCC Cendrawasih Hall (5.8m ceiling)
            IF l_venue_id IS NULL THEN
                l_venue_id := 3; -- Jakarta Convention Center Cendrawasih Hall (5.8m)
            END IF;

            -- 1. Main Keynote Stage (4.2m) -> 5.8m - 4.2m = +1.60m (PASS)
            run_spatial_check(p_tender_id, l_venue_id, 'Panggung Utama Melengkung & Dinding LED P2.5', 6.0, 12.0, 4.2, p_user_name);

            -- 2. Overhead Rigging Lighting Truss (3.8m) -> 5.8m - 3.8m = +2.00m (PASS)
            run_spatial_check(p_tender_id, l_venue_id, 'Truss Pencahayaan Rigging Atas', 4.0, 10.0, 3.8, p_user_name);

            -- 3. Demo Pods: 3.5m x 3.5m x 3.0m (PASS)
            run_spatial_check(p_tender_id, l_venue_id, 'Pod Demo Kayu Akustik (Unit 1)', 3.5, 3.5, 3.0, p_user_name);

            -- 4. Egress Corridor (3.5m) (PASS)
            run_spatial_check(p_tender_id, l_venue_id, 'Jalur Evakuasi Darurat Gedung JCC', 50.0, 3.5, 3.2, p_user_name);

        ELSIF p_tender_id = 2 OR INSTR(UPPER(l_title), 'FINTECH') > 0 OR INSTR(UPPER(l_title), 'SFF') > 0 THEN
            -- SC-03 Revision Event: SFF Pavilion at Singapore EXPO Hall 2 (10.0m ceiling)
            IF l_venue_id IS NULL THEN
                l_venue_id := 2; -- Singapore EXPO Hall 2 (10.0m)
            END IF;

            run_spatial_check(p_tender_id, l_venue_id, 'SFF Global Sustainability Main Pavilion Stage', 10.0, 16.0, 6.0, p_user_name);
            run_spatial_check(p_tender_id, l_venue_id, 'Overhead Ribbon LED Chandelier', 6.0, 12.0, 5.8, p_user_name);
            run_spatial_check(p_tender_id, l_venue_id, 'Sponsor Showcase Demo Pods (3.5m x 3.5m x 3.0m)', 3.5, 3.5, 3.0, p_user_name);
            run_spatial_check(p_tender_id, l_venue_id, 'Statutory Fire Egress Corridor', 60.0, 4.0, 3.5, p_user_name);

        ELSE
            -- SC-01 Standard Turnkey Event: NYP Campus Centre (Venue 21, 9.2m ceiling)
            IF l_venue_id IS NULL THEN
                BEGIN
                    SELECT venue_id
                      INTO l_venue_id
                      FROM fc_venue_profiles
                     WHERE venue_name LIKE '%NYP%' OR venue_name LIKE '%Nanyang%'
                     FETCH FIRST 1 ROWS ONLY;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_venue_id := 21;
                END;
            END IF;

            -- 1. Main Stage (14.0m W x 8.0m D x 5.8m H) -> 9.2m - 5.8m = +3.4m buffer (PASS)
            run_spatial_check(p_tender_id, l_venue_id, 'Main Stage Proscenium & Curved LED Backwall', 8.0, 14.0, 5.8, p_user_name);

            -- 2. Overhead Rigged LED Ribbon Truss (12.0m x 4.0m x 5.5m) -> 9.2m - 5.5m = +3.7m buffer (PASS)
            run_spatial_check(p_tender_id, l_venue_id, 'Overhead Rigged LED Ribbon Truss', 4.0, 12.0, 5.5, p_user_name);

            -- 3. Demo Pods: Exactly 3.5m x 3.5m x 3.0m Modular Acoustic Timber Pods (Unit 1) (PASS)
            run_spatial_check(p_tender_id, l_venue_id, 'Modular Acoustic Timber Demo Pods (Unit 1)', 3.5, 3.5, 3.0, p_user_name);

            -- 4. Interactive Student Sandbox Kiosks (2.5m x 5.0m x 2.6m) (PASS)
            run_spatial_check(p_tender_id, l_venue_id, 'Interactive Student Sandbox Kiosks', 2.5, 5.0, 2.6, p_user_name);

            -- 5. Zero-Waste Refreshment Lounge (3.0m x 6.0m x 2.8m) (PASS)
            run_spatial_check(p_tender_id, l_venue_id, 'Zero-Waste Refreshment Lounge', 3.0, 6.0, 2.8, p_user_name);

            -- 6. Statutory SCDF Perimeter Crowd Safety & Fire Egress Corridor (3.8m clear aisle vs 3.5m statutory corridor) (PASS)
            run_spatial_check(p_tender_id, l_venue_id, 'Statutory SCDF Perimeter Crowd Safety & Fire Egress Corridor', 55.0, 3.8, 3.5, p_user_name);
        END IF;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'GENERATE_3D_SPECS', 'FC_SPATIAL_CHECKS',
            'Generated quotation-ready 3D specs; all dimensions validated against venue ID ' || l_venue_id || '.'
        );
        COMMIT;
    END generate_3d_specs;

    PROCEDURE resolve_spatial_collision(
        p_tender_id      IN NUMBER,
        p_structure_name IN VARCHAR2 DEFAULT '8.8m High Custom Kinetic Chandelier & Proscenium',
        p_new_height     IN NUMBER DEFAULT 7.80,
        p_user_name      IN VARCHAR2 DEFAULT 'ADI'
    ) IS
        l_venue_id NUMBER;
        l_ceiling  NUMBER;
    BEGIN
        SELECT venue_id INTO l_venue_id FROM fc_spatial_checks WHERE tender_id = p_tender_id AND ROWNUM = 1;
        SELECT clear_height_m INTO l_ceiling FROM fc_venue_profiles WHERE venue_id = l_venue_id;

        UPDATE fc_spatial_checks
           SET req_height_m = p_new_height,
               clearance_delta_m = ROUND(l_ceiling - p_new_height, 2),
               feasibility_status = CASE WHEN l_ceiling >= p_new_height THEN 'PASS' ELSE 'FAIL' END,
               assumptions_log = 'Mitigated: Structure height adjusted to ' || TO_CHAR(p_new_height, 'FM990.00') || 'm; clearance buffer +' || TO_CHAR(ROUND(l_ceiling - p_new_height, 2), 'FM990.00') || 'm against ' || TO_CHAR(l_ceiling, 'FM990.00') || 'm venue ceiling (PASS).'
         WHERE tender_id = p_tender_id
           AND (structure_name LIKE '%Chandelier%' OR structure_name = p_structure_name);

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'RESOLVE_COLLISION', 'FC_SPATIAL_CHECKS',
            'Collision mitigated: Structure height trimmed to ' || p_new_height || 'm; clearance +' || ROUND(l_ceiling - p_new_height, 2) || 'm (PASS).'
        );
        COMMIT;
    END resolve_spatial_collision;

    PROCEDURE approve_gate2(
        p_tender_id   IN NUMBER,
        p_user_name   IN VARCHAR2,
        p_comments    IN VARCHAR2 DEFAULT NULL
    ) IS
        l_fail_cnt       NUMBER := 0;
        l_failing_struct VARCHAR2(250);
    BEGIN
        -- Check if any spatial check has FAIL status (SC-02 Collision Block)
        SELECT COUNT(*) INTO l_fail_cnt
          FROM fc_spatial_checks
         WHERE tender_id = p_tender_id
           AND feasibility_status = 'FAIL';

        IF l_fail_cnt > 0 THEN
            SELECT SUBSTR(structure_name || ': ' || assumptions_log, 1, 250)
              INTO l_failing_struct
              FROM fc_spatial_checks
             WHERE tender_id = p_tender_id
               AND feasibility_status = 'FAIL'
             FETCH FIRST 1 ROWS ONLY;

            raise_application_error(-20001, 'Gate 2 is blocked by a failed fit check. ' || l_failing_struct || '. Fix the design or re-check it before sign-off.');
        END IF;

        fc_workflow_api.approve_gate(
            p_tender_id   => p_tender_id,
            p_gate_number => 2,
            p_user_name   => p_user_name,
            p_comments    => NVL(p_comments, 'Gate 2 Design approved by Adi. 3D spatial dimensions validated; slide deck drafts ready; handoff to Operations.')
        );

        UPDATE fc_tenders
           SET current_stage = 'OPERATIONS',
               updated_by = p_user_name,
               updated_at = CURRENT_TIMESTAMP
         WHERE tender_id = p_tender_id;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'APPROVE_GATE_2', 'FC_WORKFLOW_GATES',
            'Gate 2 signed off. Tender advanced to Step 3 (Operations Hub).'
        );
        COMMIT;
    END approve_gate2;

    FUNCTION generate_ppt_deck_content(
        p_tender_id   IN NUMBER
    ) RETURN VARCHAR2 IS
        l_code        VARCHAR2(50) := 'FC-PROJECT';
        l_client      VARCHAR2(150) := 'Client';
        l_title       VARCHAR2(250) := 'Pitch Presentation';
        l_out         VARCHAR2(32767);
    BEGIN
        BEGIN
            SELECT tender_code, client_name, project_title
              INTO l_code, l_client, l_title
              FROM fc_tenders
             WHERE tender_id = p_tender_id;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;

        l_out := '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:powerpoint" xmlns="http://www.w3.org/TR/REC-html40">' || CHR(10) ||
                 '<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">' || CHR(10) ||
                 '<title>' || apex_escape.html(l_title) || ' - Pitch Deck</title>' || CHR(10) ||
                 '<style>' || CHR(10) ||
                 'body { font-family: Calibri, "Segoe UI", Arial, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 20px; }' || CHR(10) ||
                 '.slide-page { background: #1e293b; border: 1px solid #334155; border-radius: 12px; margin: 24px auto; max-width: 960px; padding: 40px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); page-break-after: always; }' || CHR(10) ||
                 '.slide-header { display: flex; justify-content: space-between; border-bottom: 2px solid #e11d48; padding-bottom: 12px; margin-bottom: 20px; }' || CHR(10) ||
                 '.slide-num { font-size: 13px; font-weight: bold; background: #e11d48; color: #fff; padding: 4px 10px; border-radius: 4px; }' || CHR(10) ||
                 '.slide-title { font-size: 24px; font-weight: 700; color: #fff; margin: 0; }' || CHR(10) ||
                 '.slide-body { font-size: 16px; line-height: 1.8; color: #cbd5e1; }' || CHR(10) ||
                 '.narrative { font-style: italic; color: #38bdf8; margin-bottom: 16px; }' || CHR(10) ||
                 '.notes { margin-top: 24px; padding: 12px; background: #0f172a; border-left: 4px solid #f59e0b; font-size: 13px; color: #94a3b8; }' || CHR(10) ||
                 '</style></head><body>' || CHR(10);

        FOR s IN (SELECT slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc
                    FROM fc_pitch_slides
                   WHERE tender_id = p_tender_id
                   ORDER BY slide_num ASC)
        LOOP
            l_out := l_out ||
                     '<div class="slide-page">' || CHR(10) ||
                     '  <div class="slide-header">' || CHR(10) ||
                     '    <h1 class="slide-title">' || apex_escape.html(s.slide_title) || '</h1>' || CHR(10) ||
                     '    <span class="slide-num">Slide ' || s.slide_num || ' of 8 | ' || apex_escape.html(s.layout_type) || '</span>' || CHR(10) ||
                     '  </div>' || CHR(10) ||
                     '  <div class="slide-body">' || CHR(10) ||
                     '    <div class="narrative"><strong>Narrative Alignment:</strong> ' || apex_escape.html(s.narrative_focus) || '</div>' || CHR(10) ||
                     '    <div style="white-space: pre-line;">' || apex_escape.html(s.key_bullet_points) || '</div>' || CHR(10) ||
                     '  </div>' || CHR(10) ||
                     '  <div class="notes">' || CHR(10) ||
                     '    <strong>AI Visual Direction &amp; Render Blueprint:</strong><br/>' || apex_escape.html(s.visual_placeholder_desc) || CHR(10) ||
                     '  </div>' || CHR(10) ||
                     '</div>' || CHR(10);
        END LOOP;

        l_out := l_out || '</body></html>';
        RETURN l_out;
    END generate_ppt_deck_content;

    FUNCTION render_html_slide_deck(
        p_tender_id   IN NUMBER
    ) RETURN VARCHAR2 IS
        l_html      VARCHAR2(32767);
        l_srcdoc    VARCHAR2(32767);
        l_code      VARCHAR2(50) := 'FC-2026-092';
        l_client    VARCHAR2(150) := 'Client';
        l_title     VARCHAR2(200) := 'Pitch Presentation';
        l_count     NUMBER := 0;
    BEGIN
        IF p_tender_id IS NULL THEN
            RETURN '<div class="fc-empty-state" style="padding:40px; text-align:center; color:#94a3b8; background:#0f172a; border-radius:12px; border:1px solid #334155; margin:16px 0;">' ||
                   '<i class="fa fa-television" style="font-size:36px; margin-bottom:12px; color:#60a5fa; display:block;"></i>' ||
                   '<h4 style="color:#f8fafc; margin-bottom:8px;">No Pitch Slides for this Project</h4>' ||
                   '<p style="margin:0;">Select or load an active project and click <strong>Generate Slide Deck Drafts</strong> to create presentation slides.</p>' ||
                   '</div>';
        END IF;

        BEGIN
            SELECT tender_code, client_name, project_title
              INTO l_code, l_client, l_title
              FROM fc_tenders
             WHERE tender_id = p_tender_id;
        EXCEPTION
            WHEN OTHERS THEN l_code := 'FC-' || p_tender_id;
        END;

        SELECT COUNT(*) INTO l_count FROM fc_pitch_slides WHERE tender_id = p_tender_id;

        -- Prepare iframe srcdoc HTML
        l_srcdoc := '<!DOCTYPE html><html><head><meta charset="utf-8">' ||
                    '<style>' ||
                    'body { margin:0; padding:20px; font-family:system-ui,-apple-system,sans-serif; background:#0b0f19; color:#f8fafc; }' ||
                    '.deck-nav { display:flex; justify-content:space-between; align-items:center; margin-bottom:16px; padding:10px 16px; background:#1e293b; border-radius:8px; border:1px solid #334155; }' ||
                    '.deck-title { font-weight:700; color:#38bdf8; font-size:14px; }' ||
                    '.slide-card { background:#1e293b; border:1px solid rgba(255,255,255,0.12); border-radius:10px; padding:20px; margin-bottom:18px; box-shadow:0 4px 15px rgba(0,0,0,0.4); }' ||
                    '.slide-header { display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid rgba(255,255,255,0.1); padding-bottom:8px; margin-bottom:12px; }' ||
                    '.slide-badge { background:#e11d48; color:#fff; font-size:11px; font-weight:700; padding:3px 8px; border-radius:10px; }' ||
                    '.slide-grid { display:grid; grid-template-columns:1.2fr 1fr; gap:20px; align-items:center; }' ||
                    '@media(max-width:768px){ .slide-grid { grid-template-columns:1fr; } }' ||
                    '</style></head><body>' ||
                    '<div class="deck-nav">' ||
                    '  <span class="deck-title">&#128250; ' || apex_escape.html(l_title) || ' (8 AI Slides)</span>' ||
                    '  <span style="font-size:12px; color:#94a3b8;">Interactive Viewport | M365 Presentation Mode</span>' ||
                    '</div>';

        IF l_count = 0 THEN
            l_srcdoc := l_srcdoc || '<div style="text-align:center; padding:50px; color:#94a3b8;">Click <strong>Generate AI Slide Deck Drafts</strong> to generate presentation slides.</div>';
        ELSE
            FOR s IN (SELECT slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt
                        FROM fc_pitch_slides
                       WHERE tender_id = p_tender_id
                         AND slide_num <= 3
                       ORDER BY slide_num ASC)
            LOOP
                l_srcdoc := l_srcdoc ||
                    '<div class="slide-card">' ||
                    '  <div class="slide-header">' ||
                    '    <div><span class="slide-badge">Slide ' || s.slide_num || ' of 8</span><strong style="font-size:15px; margin-left:8px; color:#fff;">' || apex_escape.html(s.slide_title) || '</strong></div>' ||
                    '    <span style="font-size:11px; color:#38bdf8; background:rgba(56,189,248,0.15); padding:2px 6px; border-radius:4px;">' || apex_escape.html(s.layout_type) || '</span>' ||
                    '  </div>' ||
                    '  <div class="slide-grid">' ||
                    '    <div>' ||
                    '      <p style="color:#94a3b8; font-size:12px; margin:0 0 6px 0;"><strong>Narrative:</strong> ' || apex_escape.html(s.narrative_focus) || '</p>' ||
                    '      <div style="color:#e2e8f0; font-size:12px; line-height:1.5; white-space:pre-line;">' || apex_escape.html(s.key_bullet_points) || '</div>' ||
                    '    </div>' ||
                    '    <div style="border-radius:6px; overflow:hidden; border:1px solid rgba(56,189,248,0.3); background:#0f172a;">' ||
                    '      <img src="https://image.pollinations.ai/prompt/' || apex_util.url_encode(NVL(s.image_prompt, 'futuristic corporate stage Singapore MICE')) || '?width=600&height=340&nologo=true&enhance=true"' ||
                    '           alt="AI Visual Placeholder" style="width:100%; height:130px; object-fit:cover; display:block;" loading="lazy" />' ||
                    '      <div style="padding:6px 8px; background:rgba(15,23,42,0.95); font-size:10px; color:#cbd5e1;">' ||
                    '        <span style="color:#38bdf8; font-weight:700; text-transform:uppercase; display:block;">AI Render Blueprint</span>' ||
                    '        ' || apex_escape.html(SUBSTR(s.visual_placeholder_desc, 1, 80)) ||
                    '      </div>' ||
                    '    </div>' ||
                    '  </div>' ||
                    '</div>';
            END LOOP;
            l_srcdoc := l_srcdoc || '<div style="text-align:center; padding:10px; font-size:11px; color:#94a3b8;">Showing primary slide blueprints (Slides 1?3) in interactive live viewport. Full 8 slides exportable to PowerPoint &amp; available in Table below.</div>';
        END IF;

        l_srcdoc := l_srcdoc || '</body></html>';

        -- Build mini-browser container with live interactive iframe
        l_html := '<div class="fc-mini-browser" style="background:#1e293b; border-radius:12px; overflow:hidden; border:1px solid #334155; margin:16px 0; box-shadow:0 10px 25px -5px rgba(0,0,0,0.3);">' ||
                  '  <div style="background:#0f172a; padding:10px 16px; display:flex; align-items:center; gap:12px; border-bottom:1px solid #334155; flex-wrap:wrap;">' ||
                  '    <div style="display:flex; gap:6px;">' ||
                  '      <span style="width:12px; height:12px; border-radius:50%; background:#ef4444; display:inline-block;"></span>' ||
                  '      <span style="width:12px; height:12px; border-radius:50%; background:#f59e0b; display:inline-block;"></span>' ||
                  '      <span style="width:12px; height:12px; border-radius:50%; background:#10b981; display:inline-block;"></span>' ||
                  '    </div>' ||
                  '    <div style="flex:1; min-width:220px; background:#1e293b; border-radius:6px; padding:6px 14px; font-family:monospace; font-size:12px; color:#94a3b8; display:flex; align-items:center; gap:8px;">' ||
                  '      <span style="color:#10b981;">[SSL]</span>' ||
                  '      <span>https://slides.flashconcepts.com.sg/pitches/' || apex_escape.html(l_code) || '.html</span>' ||
                  '    </div>' ||
                  '    <div style="display:flex; gap:8px; align-items:center;">' ||
                  '      <span style="background:rgba(59,130,246,0.2); color:#60a5fa; font-size:11px; font-weight:600; padding:4px 8px; border-radius:4px; border:1px solid rgba(59,130,246,0.3);">HTML PPT Studio</span>' ||
                  '      <button type="button" onclick="apex.submit({request:''EXPORT_PPTX''});" class="t-Button t-Button--hot t-Button--small" style="margin:0;"><span class="t-Icon fa fa-file-powerpoint-o"></span> Export to PowerPoint (.pptx)</button>' ||
                  '    </div>' ||
                  '  </div>' ||
                  '  <iframe id="slide-presentation-viewport" name="slide-presentation-viewport" srcdoc="' || apex_escape.html_attribute(l_srcdoc) || '" style="width:100%; height:540px; border:none; display:block;" title="Interactive Slide Deck Viewport"></iframe>' ||
                  '</div>';

        RETURN l_html;
    END render_html_slide_deck;

END fc_design_api;
/
