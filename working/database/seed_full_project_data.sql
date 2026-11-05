-- Full Project & Workflow Seed Data
-- Schema: SGINT02

SET DEFINE OFF;

-- 1. Ensure FC-2026-124 (User's Project: Yue Jun Tan Jaxon - Frogineer showcase) exists
MERGE INTO fc_tenders t USING (
    SELECT 'FC-2026-124' AS tcode,
           'Yue Jun Tan Jaxon' AS cname,
           'Frogineer showcase' AS ptitle,
           'SG' AS off,
           'DESIGN' AS stage,
           'ACTIVE' AS stat,
           SYSDATE + 14 AS dline,
           'SGD' AS curr,
           'ADMIN' AS spon,
           'MICHELLE' AS plan,
           'ADI' AS des,
           'WEI_LIN' AS ops,
           112500.00 AS tcost,
           150000.00 AS tprice,
           25.00 AS margin,
           33.33 AS markup,
           'IN_PROGRESS' AS prog,
           150000.00 AS val
    FROM dual
) s ON (t.tender_code = s.tcode)
WHEN MATCHED THEN
    UPDATE SET t.client_name = s.cname, t.project_title = s.ptitle, t.current_stage = s.stage
WHEN NOT MATCHED THEN
    INSERT (tender_code, client_name, project_title, office, current_stage, status, submission_deadline, primary_currency, sponsor_user, planning_lead, designer_user, ops_lead, total_cost, total_price, margin_pct, markup_pct, deal_progression, deal_value)
    VALUES (s.tcode, s.cname, s.ptitle, s.off, s.stage, s.stat, s.dline, s.curr, s.spon, s.plan, s.des, s.ops, s.tcost, s.tprice, s.margin, s.markup, s.prog, s.val);

COMMIT;

-- Get IDs and seed child data
DECLARE
    l_t1     NUMBER;
    l_t2     NUMBER;
    l_t124   NUMBER;
    l_mbs_id NUMBER;
    l_rule1  NUMBER;
    l_rule2  NUMBER;
    l_rule3  NUMBER;
    l_item1  NUMBER;
    l_item2  NUMBER;
    l_item3  NUMBER;
    l_item5  NUMBER;
BEGIN
    SELECT tender_id INTO l_t1 FROM fc_tenders WHERE tender_code = 'FC-2026-089';
    SELECT tender_id INTO l_t2 FROM fc_tenders WHERE tender_code = 'FC-2026-092';
    SELECT tender_id INTO l_t124 FROM fc_tenders WHERE tender_code = 'FC-2026-124';

    SELECT MIN(venue_id) INTO l_mbs_id FROM fc_venue_profiles WHERE venue_name LIKE 'Marina Bay%';
    SELECT MIN(rule_id) INTO l_rule1 FROM fc_compliance_rules WHERE category = 'Structural';
    SELECT MIN(rule_id) INTO l_rule2 FROM fc_compliance_rules WHERE category = 'Electrical';
    SELECT MIN(rule_id) INTO l_rule3 FROM fc_compliance_rules WHERE category = 'Fire Safety';

    SELECT MIN(item_id) INTO l_item1 FROM fc_price_items WHERE item_code = 'TRUSS-MOD-40';
    SELECT MIN(item_id) INTO l_item2 FROM fc_price_items WHERE item_code = 'LED-P2-5-CAB';
    SELECT MIN(item_id) INTO l_item3 FROM fc_price_items WHERE item_code = 'STAGE-PLAT-12';
    SELECT MIN(item_id) INTO l_item5 FROM fc_price_items WHERE item_code = 'CARP-PORTAL-CUSTOM';

    -- Set active session for all users to FC-2026-124
    MERGE INTO fc_user_sessions u USING (
        SELECT 'ADMIN' AS un, l_t124 AS tid FROM dual UNION ALL
        SELECT 'SGINT02' AS un, l_t124 AS tid FROM dual UNION ALL
        SELECT 'MICHELLE' AS un, l_t124 AS tid FROM dual UNION ALL
        SELECT 'ADI' AS un, l_t124 AS tid FROM dual UNION ALL
        SELECT 'WEI_LIN' AS un, l_t124 AS tid FROM dual
    ) s ON (upper(u.user_name) = upper(s.un))
    WHEN MATCHED THEN UPDATE SET u.active_tender_id = s.tid, u.updated_at = CURRENT_TIMESTAMP
    WHEN NOT MATCHED THEN INSERT (user_name, active_tender_id) VALUES (s.un, s.tid);

    -- 2. Tender Documents
    DELETE FROM fc_tender_documents WHERE tender_id IN (l_t1, l_t124);
    INSERT INTO fc_tender_documents (tender_id, file_name, doc_type, sharepoint_url, version_num, file_size_bytes, mime_type, hash_sha256, uploaded_by)
    VALUES (l_t1, 'DBS_Spark_Tender_Brief_v2.0.pdf', 'BRIEF', 'https://flashconcepts.sharepoint.com/tenders/FC-089/brief.pdf', 2.0, 4829100, 'application/pdf', '3a7b9c1d5e6f8a2b4c6e8d0f1a3b5c7e9f1a3b5c7e9f1a3b5c7e9f1a3b5c7e9f', 'MICHELLE');

    INSERT INTO fc_tender_documents (tender_id, file_name, doc_type, sharepoint_url, version_num, file_size_bytes, mime_type, hash_sha256, uploaded_by)
    VALUES (l_t124, 'Frogineer_Showcase_Executive_Brief.pdf', 'BRIEF', 'https://flashconcepts.sharepoint.com/tenders/FC-124/brief.pdf', 1.0, 3240000, 'application/pdf', 'a1b2c3d4e5f678901234567890abcdef1234567890abcdef1234567890abcdef', 'MICHELLE');

    -- 3. Intake Fields
    DELETE FROM fc_intake_fields WHERE tender_id IN (l_t1, l_t124);
    INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, review_status, reviewed_by, reviewed_at)
    VALUES (l_t1, 'Schedule', 'Event Date Window', '12–14 November 2026', '12–14 November 2026', 'DBS_Brief.pdf', 3, 'CONFIRMED', 'MICHELLE', SYSDATE);

    INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, review_status, reviewed_by, reviewed_at)
    VALUES (l_t124, 'Event Focus', 'Event Type & Objective', 'Frogineer Regional FinTech & Engineering Showcase', 'Regional FinTech & Engineering Showcase', 'Frogineer_Brief.pdf', 1, 'CONFIRMED', 'MICHELLE', SYSDATE);

    INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, review_status, reviewed_by, reviewed_at)
    VALUES (l_t124, 'Venue', 'Selected Hall', 'Marina Bay Sands Sands Expo Hall C', 'Marina Bay Sands Sands Expo Hall C', 'Frogineer_Brief.pdf', 2, 'CONFIRMED', 'MICHELLE', SYSDATE);

    INSERT INTO fc_intake_fields (tender_id, field_category, field_label, extracted_value, confirmed_value, source_doc_ref, page_number, review_status, reviewed_by, reviewed_at)
    VALUES (l_t124, 'Audience', 'Expected Footfall', '1,200 Executive Bankers & Tech Innovators', '1,200 delegates', 'Frogineer_Brief.pdf', 2, 'CONFIRMED', 'MICHELLE', SYSDATE);

    -- 4. Research Findings
    DELETE FROM fc_research_findings WHERE tender_id IN (l_t1, l_t124);
    INSERT INTO fc_research_findings (tender_id, topic, claim_text, source_url, page_title, publisher, confidence_score, review_status, reviewed_by, reviewed_at)
    VALUES (l_t1, 'Client Initiative', 'DBS Spark GenAI Programme launched with IMDA and Enterprise SG supporting 500+ SMEs.', 'https://www.dbs.com/newsroom/spark-genai', 'DBS Accelerates SME AI Transformation', 'DBS Newsroom', 98, 'APPROVED', 'MICHELLE', SYSDATE);

    INSERT INTO fc_research_findings (tender_id, topic, claim_text, source_url, page_title, publisher, confidence_score, review_status, reviewed_by, reviewed_at)
    VALUES (l_t124, 'Sector Context', 'Regional financial infrastructure transition toward real-time modular core banking frameworks.', 'https://www.mas.gov.sg/fintech', 'Singapore FinTech Ecosystem Report 2026', 'Monetary Authority of Singapore', 96, 'APPROVED', 'MICHELLE', SYSDATE);

    INSERT INTO fc_research_findings (tender_id, topic, claim_text, source_url, page_title, publisher, confidence_score, review_status, reviewed_by, reviewed_at)
    VALUES (l_t124, 'Event Focus', 'Tier-1 executive showcase focusing on high-impact stage proscenium architecture and live interactive breakout sandboxes.', 'https://www.marinabaysands.com/expo', 'MBS Sands Expo Convention Guide', 'Marina Bay Sands', 95, 'APPROVED', 'MICHELLE', SYSDATE);

    -- 5. Creative Concepts
    DELETE FROM fc_concept_options WHERE tender_id IN (l_t1, l_t124);
    INSERT INTO fc_concept_options (tender_id, option_code, concept_title, narrative, brief_fit, event_flow, spatial_notes, fringe_activities, is_selected, selected_by, selected_at)
    VALUES (l_t1, 'OPT_A', 'The Spark Nexus: Dynamic AI Innovation Hub', 'A circular experiential journey mapping client business transformation through light-sculpted portals and live interactive demo clusters.', 'Directly addresses DBS Spark GenAI theme with modular interactive pods', 'Entrance Tunnel -> The Spark Arena -> Enterprise Showcase -> Networking Atrium', 'Central installation at 6.8m height; fits MBS Hall C 8.5m ceiling comfortably', 'AI Prompt Studio & Sustainable Coffee Bar with reusable smart cups', 'Y', 'MICHELLE', SYSDATE);

    INSERT INTO fc_concept_options (tender_id, option_code, concept_title, narrative, brief_fit, event_flow, spatial_notes, fringe_activities, is_selected, selected_by, selected_at)
    VALUES (l_t124, 'OPT_A', 'Frogineer Horizon: Luminescent Digital Core', 'An immersive obsidian amphitheatre stage surrounded by 360-degree curved P2.6 LED ribbons and high-contrast ambient glow pods.', 'Translates core engineering precision into an elite executive keynote experience', 'Obsidian Welcome Portal -> Luminescent Core Plenary -> Interactive Solution Sandboxes -> VIP Lounge', '12m curved LED wall, 6.2m ceiling clearance inside MBS Hall C', 'Interactive Code Sandboxes & Holographic Architecture Pylons', 'Y', 'MICHELLE', SYSDATE);

    -- 6. Spatial Checks
    DELETE FROM fc_spatial_checks WHERE tender_id IN (l_t1, l_t124);
    IF l_mbs_id IS NOT NULL THEN
        INSERT INTO fc_spatial_checks (tender_id, venue_id, structure_name, req_length_m, req_width_m, req_height_m, feasibility_status, clearance_delta_m, assumptions_log, evaluated_by)
        VALUES (l_t1, l_mbs_id, 'The Spark Circular Stage Arch', 24.00, 16.00, 6.80, 'PASS', 1.70, 'MBS ceiling 8.5m allows 1.7m clear safety buffer above lighting trusses.', 'ADI');

        INSERT INTO fc_spatial_checks (tender_id, venue_id, structure_name, req_length_m, req_width_m, req_height_m, feasibility_status, clearance_delta_m, assumptions_log, evaluated_by)
        VALUES (l_t124, l_mbs_id, 'Frogineer Curved Keynote Proscenium', 20.00, 12.00, 6.20, 'PASS', 2.30, 'MBS Sands Expo Hall C ceiling 8.5m allows 2.3m safety clearance above P2.6 LED screen rig.', 'ADI');

        INSERT INTO fc_spatial_checks (tender_id, venue_id, structure_name, req_length_m, req_width_m, req_height_m, feasibility_status, clearance_delta_m, assumptions_log, evaluated_by)
        VALUES (l_t124, l_mbs_id, 'Interactive Solution Demo Pods (x4)', 14.00, 10.00, 3.40, 'PASS', 5.10, '3.0m emergency fire egress aisles fully preserved on all perimeter paths.', 'ADI');
    END IF;

    -- 7. BOQ Items
    DELETE FROM fc_boq_items WHERE tender_id IN (l_t1, l_t124);
    INSERT INTO fc_boq_items (tender_id, component_name, item_id, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by)
    VALUES (l_t1, 'Main Stage Curve P2.5 LED Screen', l_item2, 'Audio Visual', 72.00, 'SQM', 'SGD', 320.00, 'FIXED_INTERNAL', 25.00, 33.33, 23040.00, 30720.00, 98, 'CONFIRMED', 'WEI_LIN');

    INSERT INTO fc_boq_items (tender_id, component_name, item_id, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by)
    VALUES (l_t1, 'Overhead Rigging Truss Box Structure', l_item1, 'Structural', 180.00, 'METRE', 'SGD', 85.00, 'FIXED_INTERNAL', 25.00, 33.33, 15300.00, 20400.00, 95, 'CONFIRMED', 'WEI_LIN');

    INSERT INTO fc_boq_items (tender_id, component_name, item_id, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by)
    VALUES (l_t124, 'Main Proscenium Curved P2.6 LED Video Wall', l_item2, 'Audio Visual', 60.00, 'SQM', 'SGD', 320.00, 'FIXED_INTERNAL', 25.00, 33.33, 19200.00, 25600.00, 98, 'CONFIRMED', 'WEI_LIN');

    INSERT INTO fc_boq_items (tender_id, component_name, item_id, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by)
    VALUES (l_t124, 'Overhead Rigging & Lighting Truss Structure', l_item1, 'Structural', 140.00, 'METRE', 'SGD', 85.00, 'FIXED_INTERNAL', 25.00, 33.33, 11900.00, 15866.67, 95, 'CONFIRMED', 'WEI_LIN');

    INSERT INTO fc_boq_items (tender_id, component_name, item_id, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by)
    VALUES (l_t124, 'Obsidian Main Keynote Stage Platform 12x6m', l_item3, 'Carpentry', 24.00, 'PIECE', 'SGD', 140.00, 'FIXED_INTERNAL', 25.00, 33.33, 3360.00, 4480.00, 92, 'CONFIRMED', 'WEI_LIN');

    INSERT INTO fc_boq_items (tender_id, component_name, item_id, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by)
    VALUES (l_t124, 'Bespoke Luminescent Portal & Registration Tunnel', l_item5, 'Carpentry', 1.00, 'SET', 'SGD', 4800.00, 'VENDOR_QUOTED', 25.00, 33.33, 4800.00, 6400.00, 90, 'CONFIRMED', 'WEI_LIN');

    -- 8. Compliance Findings
    DELETE FROM fc_compliance_findings WHERE tender_id IN (l_t1, l_t124);
    IF l_rule1 IS NOT NULL THEN
        INSERT INTO fc_compliance_findings (tender_id, rule_id, severity, finding_text, required_action, est_compliance_cost, status)
        VALUES (l_t124, l_rule1, 'TASK', 'Keynote proscenium truss reaches 6.2m height (>4.5m statutory threshold).', 'Engage registered Professional Engineer (PE) for structural endorsement before rigging.', 2500.00, 'OPEN');
    END IF;

    IF l_rule2 IS NOT NULL THEN
        INSERT INTO fc_compliance_findings (tender_id, rule_id, severity, finding_text, required_action, est_compliance_cost, status)
        VALUES (l_t124, l_rule2, 'TASK', 'P2.6 LED screen and stage lighting aggregate load reaches 58 kVA (>45 kVA threshold).', 'Licensed Electrical Worker (LEW) turn-on inspection and certification scheduled.', 1200.00, 'OPEN');
    END IF;

    IF l_rule3 IS NOT NULL THEN
        INSERT INTO fc_compliance_findings (tender_id, rule_id, severity, finding_text, required_action, est_compliance_cost, status)
        VALUES (l_t124, l_rule3, 'PASS', 'Passageways and evacuation routes maintain 3.0m clear width (>2.4m minimum).', 'Verified in spatial CAD layout.', 0.00, 'RESOLVED');
    END IF;

    -- 9. RFQs & Quotations
    DELETE FROM fc_rfqs WHERE tender_id IN (l_t1, l_t124);
    INSERT INTO fc_rfqs (tender_id, rfq_code, vendor_name, vendor_email, spec_version, draft_email_body, sent_date, due_date, status, reviewed_by)
    VALUES (l_t124, 'RFQ-2026-124-AV', 'AV Spectrum Pte Ltd', 'sales@avspectrum.com.sg', 1.0, 'Detailed RFQ for P2.6 LED curved wall (60 sqm) and rigging for MBS Hall C.', SYSDATE - 3, SYSDATE + 4, 'SENT', 'WEI_LIN');

    DELETE FROM fc_quotations WHERE tender_id IN (l_t1, l_t124);
    INSERT INTO fc_quotations (rfq_id, tender_id, vendor_name, quoted_amount, currency, valid_until, lead_time_days, exclusions, scope_variance_flag, is_selected, selection_reason, selected_by, selected_at)
    VALUES (1, l_t124, 'AV Spectrum Pte Ltd', 19200.00, 'SGD', SYSDATE + 30, 7, 'Power generator excluded; venue commando point provided', 'N', 'Y', 'Verified tier-1 vendor on MBS approved list', 'WEI_LIN', SYSDATE);

    INSERT INTO fc_quotations (rfq_id, tender_id, vendor_name, quoted_amount, currency, valid_until, lead_time_days, exclusions, scope_variance_flag, is_selected, selection_reason, selected_by, selected_at)
    VALUES (1, l_t124, 'StudioCraft Asia', 16700.00, 'SGD', SYSDATE + 21, 10, 'On-site paint touchup requires overnight permit', 'N', 'Y', 'Bespoke entrance portal fabricator with BCA Class 1 fire rating', 'WEI_LIN', SYSDATE);

    -- 10. Pitch Slides for T124 (Full 8 Obsidian Dark Theme Slides)
    DELETE FROM fc_pitch_slides WHERE tender_id = l_t124;
    INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt, is_customized)
    VALUES (l_t124, 1, 'Executive Vision & Obsidian Keynote Staging', 'DARK_THEME',
            'Immersive Dark Obsidian Aesthetic: High-contrast luminescent cyan, gold, and stage LED accents engineered for C-suite keynote impact.',
            '• Positioning Frogineer as the definitive core engineering foundation of regional digital finance' || CHR(10) ||
            '• Delivering a precision-crafted experience reflecting technological mastery and architectural elegance' || CHR(10) ||
            '• Curated by Flash Concepts Singapore with 100% statutory clearance adherence',
            'Obsidian proscenium keynote stage with luminescent cyan perimeter wash',
            'Cinematic 3D render of futuristic dark obsidian event stage with cyan neon lighting Singapore MICE', 'Y');

    INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt, is_customized)
    VALUES (l_t124, 2, 'Strategic Brief Alignment & Stakeholder Persona', 'DARK_THEME',
            'Strategic C-Suite Immersion: Orchestrating an elite low-light auditorium ambience tailored for institutional decision-makers.',
            '• Addressing high-level regional banking stakeholders with zero commercial friction' || CHR(10) ||
            '• High-contrast typography and digital clarity reducing ambient eye fatigue' || CHR(10) ||
            '• Direct alignment with confirmed Singapore MICE sustainability benchmarks',
            'Minimalist executive briefing lounge with ambient architectural glow',
            'Low light VIP executive lounge modern architecture warm amber lighting', 'Y');

    INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt, is_customized)
    VALUES (l_t124, 3, 'Signature Concept: Luminescent Circuit Core', 'DARK_THEME',
            'Luminescent Spatial Identity: Dynamic neon cyan light ribbons echoing regional financial infrastructure.',
            '• Central hexagonal plenary stage enveloped in reactive floor-to-ceiling LED ribbon pylons' || CHR(10) ||
            '• Midnight acoustic velour drapes eliminating stray ambient reflections across the 1,200-seat hall' || CHR(10) ||
            '• 92% circular modular trussing engineered for rapid low-waste overnight assembly',
            'Hexagonal dark proscenium stage with glowing neon light ribbons',
            'Futuristic stage with glowing circuit lines and curved video screens photorealistic', 'Y');

    INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt, is_customized)
    VALUES (l_t124, 4, 'Curated Attendee Journey & Immersion', 'DARK_THEME',
            'Experiential Contrast Flow: Guiding VIPs through a dim ambient entrance into a high-lux reveal chamber.',
            '• Low-glare illuminated directional floor runners guiding movement without overhead light bleed' || CHR(10) ||
            '• Integrated RFID smart badges triggering personalized holographic welcome beacons' || CHR(10) ||
            '• Acoustically isolated demo pods for high-confidentiality executive briefings',
            'Low-light entrance tunnel with dynamic LED light strips leading to plenary',
            'Modern event registration tunnel with ambient LED lighting and digital signage', 'Y');

    INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt, is_customized)
    VALUES (l_t124, 5, 'Spatial Architecture & Luminescent Curved LED Rig', 'DARK_THEME',
            'Dynamic Contrast Staging: 12.0m curved P2.6 LED proscenium set against a midnight black acoustic backdrop.',
            '• High-contrast black-level calibration for ultra-deep cinematic visual presentation' || CHR(10) ||
            '• Overhead rigged ribbon truss with directional spotlighting and zero glare bounce' || CHR(10) ||
            '• Singapore SCDF 3.0m emergency egress safety corridors clearly illuminated with low-level LED pathfinding',
            'Curved 12m LED video wall rigging with dark stage proscenium',
            'Overhead truss rigging with professional stage lighting and curved LED screens', 'Y');

    INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt, is_customized)
    VALUES (l_t124, 6, 'Interactive Activation Ecosystem & Glow Demo Pods', 'DARK_THEME',
            'Luminescent Interactive Pods: Tactile interactive demo stations with edge-lit acrylics and integrated touchscreens.',
            '• 4x modular breakout pods equipped with ultra-responsive 65-inch 4K capacitive displays' || CHR(10) ||
            '• Integrated directional sound showers preventing audio bleed across adjacent demo zones' || CHR(10) ||
            '• Cloud-synced telemetry analytics tracking attendee dwell times and engagement metrics',
            'High-tech interactive kiosk stations with edge-lit acrylic frames and glowing pedestals',
            'Interactive exhibition booth with glowing touchscreens and modern tech displays', 'Y');

    INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt, is_customized)
    VALUES (l_t124, 7, 'Operational Feasibility, SCDF Egress & Safety Luminescence', 'DARK_THEME',
            'Statutory Rigor & Safety Luminescence: PE certified trussing with illuminated SCDF emergency pathways.',
            '• Professional Engineer (PE) structural calculation endorsement for dark overhead rigging' || CHR(10) ||
            '• Licensed Electrical Worker (LEW) turn-on certification for multi-phase LED power delivery' || CHR(10) ||
            '• Continuous photoluminescent exit signage and 3.0m fire egress lanes compliant with SCDF Fire Code',
            'Singapore SCDF approved venue layout showing green photoluminescent egress markers',
            'Architectural floorplan showing fire egress pathways and event booth layout', 'Y');

    INSERT INTO fc_pitch_slides (tender_id, slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt, is_customized)
    VALUES (l_t124, 8, 'Commercial Roadmap, Milestones & Turnkey Delivery', 'DARK_THEME',
            'Milestone Precision & Transparency: Turnkey delivery governance with zero hidden production costs.',
            '• Structured milestone progress: 50% upon pitch confirmation, 40% onsite build, 10% post-strike handover' || CHR(10) ||
            '• Guaranteed Singapore BCA / EMA / SCDF statutory compliance package bundled in base tender' || CHR(10) ||
            '• 24/7 dedicated show-call team and technical standby throughout the entire event duration',
            'Gantt timeline chart showing 12-week design, engineering, fabrication and rehearsal phases',
            'Clean corporate project roadmap diagram with milestones and timeline markers', 'Y');

    -- 11. Workflow Gates
    DELETE FROM fc_workflow_gates WHERE tender_id IN (l_t1, l_t124);
    INSERT INTO fc_workflow_gates (tender_id, gate_number, gate_name, required_role, action, decided_by, is_delegate, comments)
    VALUES (l_t124, 1, 'Gate 1: Planning Approval', 'PLANNING_LEAD', 'APPROVED', 'MICHELLE', 'N', 'Brief confirmed and concept option A approved.');

    -- 12. Invoices
    DELETE FROM fc_invoices WHERE tender_id = l_t124;
    INSERT INTO fc_invoices (tender_id, invoice_number, invoice_type, invoice_date, due_date, currency, subtotal_amount, gst_rate_pct, gst_amount, total_amount, payment_terms, payment_status, client_contact, notes, created_by)
    VALUES (l_t124, 'INV-2026-124-DEP', 'DEPOSIT_INVOICE', SYSDATE, SYSDATE + 14, 'SGD', 68807.34, 9.00, 6192.66, 75000.00, '50% Initial Commitment Deposit Upon Pitch Award', 'ISSUED', 'Yue Jun Tan Jaxon (jaxon@frogineer.com)', 'Initial 50% mobilization deposit invoice for Frogineer Showcase', 'WEI_LIN');

    COMMIT;
END;
/
