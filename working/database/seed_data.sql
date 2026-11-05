-- Seed Data for Flash Concepts APEX Engine
-- Schema: SGINT02

SET DEFINE OFF;

-- 1. Users
MERGE INTO fc_users t USING (
    SELECT 'ADMIN' AS u, 'System Administrator' AS fn, 'admin@flashconcepts.com.sg' AS em, 'SG' AS off FROM dual UNION ALL
    SELECT 'SGINT02', 'Lead Architect SGINT02', 'sgint02@flashconcepts.com.sg', 'SG' FROM dual UNION ALL
    SELECT 'MICHELLE', 'Michelle Tan (Planning Lead)', 'michelle.tan@flashconcepts.com.sg', 'SG' FROM dual UNION ALL
    SELECT 'ADI', 'Adi Nugroho (Senior Designer)', 'adi.nugroho@flashconcepts.com.sg', 'JKT' FROM dual UNION ALL
    SELECT 'WEI_LIN', 'Wei Lin Koh (Operations Lead)', 'weilin.koh@flashconcepts.com.sg', 'SG' FROM dual UNION ALL
    SELECT 'COPYWRITER', 'Sarah Lim (In-House Copywriter)', 'sarah.lim@flashconcepts.com.sg', 'SG' FROM dual UNION ALL
    SELECT 'TRANS_REV', 'Budi Santoso (Jakarta Localization)', 'budi.santoso@flashconcepts.com.sg', 'JKT' FROM dual UNION ALL
    SELECT 'AUDITOR', 'Internal Compliance Auditor', 'auditor@flashconcepts.com.sg', 'SG' FROM dual
) s ON (t.username = s.u)
WHEN MATCHED THEN UPDATE SET t.full_name = s.fn, t.email = s.em, t.office = s.off
WHEN NOT MATCHED THEN INSERT (username, full_name, email, office) VALUES (s.u, s.fn, s.em, s.off);

-- 2. User Roles
DELETE FROM fc_user_roles;
INSERT INTO fc_user_roles (username, role_code) VALUES ('ADMIN', 'ADMINISTRATOR');
INSERT INTO fc_user_roles (username, role_code) VALUES ('ADMIN', 'LEADERSHIP');
INSERT INTO fc_user_roles (username, role_code) VALUES ('SGINT02', 'ADMINISTRATOR');
INSERT INTO fc_user_roles (username, role_code) VALUES ('SGINT02', 'LEADERSHIP');
INSERT INTO fc_user_roles (username, role_code) VALUES ('MICHELLE', 'PLANNING_LEAD');
INSERT INTO fc_user_roles (username, role_code) VALUES ('ADI', 'DESIGNER');
INSERT INTO fc_user_roles (username, role_code) VALUES ('WEI_LIN', 'OPERATIONS_LEAD');
INSERT INTO fc_user_roles (username, role_code) VALUES ('COPYWRITER', 'COPYWRITER');
INSERT INTO fc_user_roles (username, role_code) VALUES ('TRANS_REV', 'TRANSLATION_REVIEWER');
INSERT INTO fc_user_roles (username, role_code) VALUES ('AUDITOR', 'AUDITOR');

-- 3. Venues
DELETE FROM fc_venue_profiles;
INSERT INTO fc_venue_profiles (venue_name, hall_name, location, usable_length_m, usable_width_m, clear_height_m, max_floor_load_kn, obstructions, verification_status, verified_by)
VALUES ('Marina Bay Sands', 'Sands Expo Hall C', 'Singapore', 72.00, 45.00, 8.50, 15.00, 'Columns at 18m grid spacing; overhead rigging points every 4m', 'VERIFIED', 'WEI_LIN');

INSERT INTO fc_venue_profiles (venue_name, hall_name, location, usable_length_m, usable_width_m, clear_height_m, max_floor_load_kn, obstructions, verification_status, verified_by)
VALUES ('Singapore EXPO', 'Hall 2', 'Singapore', 90.00, 50.00, 10.00, 20.00, 'Clear span; perimeter fire hydrant access required at north door', 'VERIFIED', 'WEI_LIN');

INSERT INTO fc_venue_profiles (venue_name, hall_name, location, usable_length_m, usable_width_m, clear_height_m, max_floor_load_kn, obstructions, verification_status, verified_by)
VALUES ('Jakarta Convention Center', 'Cendrawasih Hall', 'Jakarta', 60.00, 36.00, 5.80, 10.00, 'Low hanging acoustic baffles at 5.5m; service door width 3.2m', 'VERIFIED', 'ADI');

INSERT INTO fc_venue_profiles (venue_name, hall_name, location, usable_length_m, usable_width_m, clear_height_m, max_floor_load_kn, obstructions, verification_status, verified_by)
VALUES ('Suntec Singapore', 'Summit 1 (Level 3)', 'Singapore', 40.00, 28.00, 4.80, 7.50, 'Escalator entrance ceiling clearance 4.2m', 'VERIFIED', 'WEI_LIN');

INSERT INTO fc_venue_profiles (venue_name, hall_name, location, usable_length_m, usable_width_m, clear_height_m, max_floor_load_kn, obstructions, verification_status, verified_by)
VALUES ('Nanyang Polytechnic (NYP)', 'Campus Centre & Central Atrium', '180 Ang Mo Kio Ave 8, Singapore', 55.00, 32.00, 9.20, 12.50, 'Central glass elevator shaft; 3.5m clear perimeter crowd corridor mandatory along outer ring', 'VERIFIED', 'ADI');

-- 4. Master Price Catalogue
DELETE FROM fc_price_items;
INSERT INTO fc_price_items (item_code, category, description, specification, uom, currency, unit_price, price_basis, supplier_name)
VALUES ('TRUSS-MOD-40', 'Structural', 'Modular Aluminium Truss 40cm', 'Heavy duty quad truss box section, black powder coat', 'METRE', 'SGD', 85.00, 'FIXED_INTERNAL', 'Flash Inventory');

INSERT INTO fc_price_items (item_code, category, description, specification, uom, currency, unit_price, price_basis, supplier_name)
VALUES ('LED-P2-5-CAB', 'Audio Visual', 'P2.5 High Res Indoor LED Screen Panel', '500x500mm die cast magnesium cabinet, Novastar card', 'SQM', 'SGD', 320.00, 'FIXED_INTERNAL', 'AV Spectrum Pte Ltd');

INSERT INTO fc_price_items (item_code, category, description, specification, uom, currency, unit_price, price_basis, supplier_name)
VALUES ('STAGE-PLAT-12', 'Carpentry', 'Modular Stage Platform 1.2m x 2.4m', 'High density anti slip surface, steel adjustable riser frame', 'PIECE', 'SGD', 140.00, 'FIXED_INTERNAL', 'Flash Inventory');

INSERT INTO fc_price_items (item_code, category, description, specification, uom, currency, unit_price, price_basis, supplier_name)
VALUES ('PRINT-FAB-BACK', 'Graphics', 'Seamless Tension Fabric Backdrop', 'Eco-friendly dye-sublimation print with silicon beading', 'SQM', 'SGD', 48.00, 'FIXED_INTERNAL', 'PrintCorp Regional');

INSERT INTO fc_price_items (item_code, category, description, specification, uom, currency, unit_price, price_basis, supplier_name)
VALUES ('CARP-PORTAL-CUSTOM', 'Carpentry', 'Bespoke Welcome Arch Portal', 'Timber frame with laminate finish, LED contour strip', 'SET', 'SGD', 4800.00, 'VENDOR_QUOTED', 'StudioCraft Asia');

-- 5. Compliance Rules
DELETE FROM fc_compliance_rules;
INSERT INTO fc_compliance_rules (jurisdiction, category, rule_title, description, official_ref, is_validated)
VALUES ('SG', 'Structural', 'PE Structural Endorsement for Installations >4.5m', 'Temporary structures or rigging exceeding 4.5 metres in height require sign-off by a registered Professional Engineer.', 'BCA Temporary Structures Act 2022', 'Y');

INSERT INTO fc_compliance_rules (jurisdiction, category, rule_title, description, official_ref, is_validated)
VALUES ('SG', 'Electrical', 'Licensed Electrical Worker (LEW) Sign-off >45 kVA', 'Electrical installations exceeding 45 kVA aggregate connected load require LEW endorsement and turn-on certification.', 'EMA Licensing Regulations Chapter 89A', 'Y');

INSERT INTO fc_compliance_rules (jurisdiction, category, rule_title, description, official_ref, is_validated)
VALUES ('SG', 'Fire Safety', 'Clear Egress Corridor Minimum 2.4m Width', 'Exhibition hall passageways and primary evacuation routes must maintain unobstructed minimum clear width of 2.4 metres.', 'SCDF Fire Code 2023 cl. 2.2.4', 'Y');

INSERT INTO fc_compliance_rules (jurisdiction, category, rule_title, description, official_ref, is_validated)
VALUES ('JKT', 'Safety', 'DKI Jakarta Keramaian & Venue Rigging Permit', 'Rigging and hanging structures inside commercial convention centres require Dinas Citra Karya permit inspection.', 'Perda DKI Jakarta No 7/2010', 'Y');

-- 6. Research Sources
DELETE FROM fc_research_sources;
INSERT INTO fc_research_sources (source_name, base_url, allowed_method, governance_notes)
VALUES ('Official Client Websites', 'https://', 'WEB_PUBLIC', 'Public press releases, product updates, leadership bios');

INSERT INTO fc_research_sources (source_name, base_url, allowed_method, governance_notes)
VALUES ('LinkedIn Corporate Pages', 'https://www.linkedin.com/company/', 'WEB_PUBLIC', 'Executive posts and hiring signals without direct contact outreach');

INSERT INTO fc_research_sources (source_name, base_url, allowed_method, governance_notes)
VALUES ('SG Regulated News (Monetary Authority SG)', 'https://www.mas.gov.sg', 'WEB_PUBLIC', 'Banking, fintech, and payment initiatives announcements');

-- 7. Master Terminology
DELETE FROM fc_terminology;
INSERT INTO fc_terminology (english_term, bahasa_term, category, context_note)
VALUES ('Key Visual', 'Visual Utama', 'Creative', 'Primary thematic graphic defining pitch visual identity');

INSERT INTO fc_terminology (english_term, bahasa_term, category, context_note)
VALUES ('Bill of Quantities (BOQ)', 'Rincian Anggaran Biaya (RAB)', 'Operations', 'Detailed schedule of works, materials, and quantities');

INSERT INTO fc_terminology (english_term, bahasa_term, category, context_note)
VALUES ('Handover Document', 'Dokumen Serah Terima', 'Workflow', 'Internal milestone package transitioning between planning, design, and ops');

INSERT INTO fc_terminology (english_term, bahasa_term, category, context_note)
VALUES ('Spatial Clearance', 'Batas Ruang Bebas', 'Technical', 'Safety distance from ceiling, lights, and venue obstructions');

-- 8. Tenders (Representative Pitches)
DELETE FROM fc_tenders;
INSERT INTO fc_tenders (tender_code, client_name, project_title, office, current_stage, status, submission_deadline, primary_currency, sponsor_user, planning_lead, designer_user, ops_lead, total_cost, total_price, margin_pct, markup_pct, deal_progression, deal_value, deal_won_date)
VALUES ('FC-2026-089', 'DBS Bank', 'DBS Spark Showcase & FinTech Experience 2026', 'SG', 'COMMERCIAL_RELEASE', 'RELEASED', SYSDATE - 2, 'SGD', 'ADMIN', 'MICHELLE', 'ADI', 'WEI_LIN', 108750.00, 145000.00, 25.00, 33.33, 'DEAL_CLOSED', 145000.00, SYSDATE - 2);

INSERT INTO fc_tenders (tender_code, client_name, project_title, office, current_stage, status, submission_deadline, primary_currency, sponsor_user, planning_lead, designer_user, ops_lead, total_cost, total_price, margin_pct, markup_pct, deal_progression, deal_value)
VALUES ('FC-2026-092', 'Nanyang Polytechnic', 'NYP Graduate Student Innovation Roadshow & Exhibition 2026', 'SG', 'OPERATIONS', 'ACTIVE', SYSDATE + 7, 'SGD', 'ADMIN', 'MICHELLE', 'ADI', 'WEI_LIN', 76200.00, 101500.00, 24.93, 33.20, 'IN_PROGRESS', 120000.00);

INSERT INTO fc_tenders (tender_code, client_name, project_title, office, current_stage, status, submission_deadline, primary_currency, sponsor_user, planning_lead, designer_user, ops_lead, total_cost, total_price, margin_pct, markup_pct)
VALUES ('FC-2026-088', 'Singapore FinTech Festival', 'Global Sustainability & Regional Trade Pavilion', 'SG', 'DESIGN', 'ACTIVE', SYSDATE + 15, 'SGD', 'ADMIN', 'MICHELLE', 'ADI', 'WEI_LIN', 210000.00, 280000.00, 25.00, 33.33);

INSERT INTO fc_tenders (tender_code, client_name, project_title, office, current_stage, status, submission_deadline, primary_currency, sponsor_user, planning_lead, designer_user, ops_lead, total_cost, total_price, margin_pct, markup_pct)
VALUES ('FC-2026-087', 'Wise Asia-Pac', 'Wise Transparent Borderless Exchange Hub', 'SG', 'FINAL_RELEASE_REVIEW', 'ACTIVE', SYSDATE + 5, 'SGD', 'ADMIN', 'MICHELLE', 'ADI', 'WEI_LIN', 46875.00, 62500.00, 25.00, 33.33);

INSERT INTO fc_tenders (tender_code, client_name, project_title, office, current_stage, status, submission_deadline, primary_currency, sponsor_user, planning_lead, designer_user, ops_lead, total_cost, total_price, margin_pct, markup_pct)
VALUES ('FC-2026-086', 'FedEx Regional', 'APAC Logistics Innovation Summit 2026', 'JKT', 'INTAKE_REVIEW', 'ACTIVE', SYSDATE + 21, 'IDR', 'ADMIN', 'MICHELLE', 'ADI', 'WEI_LIN', 840000000.00, 1120000000.00, 25.00, 33.33);

INSERT INTO fc_tenders (tender_code, client_name, project_title, office, current_stage, status, submission_deadline, primary_currency, sponsor_user, planning_lead, designer_user, ops_lead, total_cost, total_price, margin_pct, markup_pct)
VALUES ('FC-2026-085', 'Friso Consumer', 'Friso Family Discovery & Digestive Health Journey', 'JKT', 'RELEASED', 'RELEASED', SYSDATE - 2, 'IDR', 'ADMIN', 'MICHELLE', 'ADI', 'WEI_LIN', 1012500000.00, 1350000000.00, 25.00, 33.33);

-- Set active user session
INSERT INTO fc_user_sessions (user_name, active_tender_id)
SELECT 'ADMIN', MAX(tender_id) FROM fc_tenders;

INSERT INTO fc_user_sessions (user_name, active_tender_id)
SELECT 'SGINT02', MAX(tender_id) FROM fc_tenders;

COMMIT;
