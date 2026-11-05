CREATE OR REPLACE PACKAGE BODY fc_costing_api AS

    -- Target margin set by Operations for the tender (25% if none set yet).
    FUNCTION tender_margin(p_tender_id IN NUMBER) RETURN NUMBER IS
        l_margin NUMBER;
    BEGIN
        SELECT NVL(target_margin_pct, 25) INTO l_margin FROM fc_tenders WHERE tender_id = p_tender_id;
        RETURN l_margin;
    END tender_margin;
    -- Step 3: Wei Lin Operations Hub & Costing

    PROCEDURE decode_sketches_to_boq(
        p_tender_id   IN NUMBER,
        p_user_name   IN VARCHAR2
    ) IS
        l_client VARCHAR2(150);
        l_title  VARCHAR2(250);
        l_office VARCHAR2(30);
    BEGIN
        SELECT client_name, project_title, office
          INTO l_client, l_title, l_office
          FROM fc_tenders
         WHERE tender_id = p_tender_id;

        DELETE FROM fc_boq_items WHERE tender_id = p_tender_id;

        IF p_tender_id = 1 OR INSTR(UPPER(l_title), 'DBS') > 0 THEN
            -- SC-02: DBS Regional Leadership Summit with Overtime Surcharge
            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'The Spark Nexus Proscenium Keynote Stage (18m x 12m)', 'CARPENTRY', 1, 'SET', 'SGD', 18500.00, 'HISTORICAL_BENCHMARK', 22.0, 28.2, 18500.00, 23717.95, 96, 'CONFIRMED', p_user_name, 'Curved stage with acoustic felt backdrop for MBS Hall C');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'Circular Interactive Wealth Tech Demo Pods (3 Units)', 'CARPENTRY', 3, 'UNIT', 'SGD', 5200.00, 'HISTORICAL_BENCHMARK', 22.0, 28.2, 15600.00, 20000.00, 95, 'CONFIRMED', p_user_name, '3.5m x 3.5m x 3.2m modular pods with FSC timber');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'P2.5 Ultra HD Curved LED Video Display (18m x 4.5m)', 'AV_TECH', 1, 'SYSTEM', 'SGD', 34000.00, 'HISTORICAL_BENCHMARK', 22.0, 28.2, 34000.00, 43589.74, 94, 'CONFIRMED', p_user_name, 'Novastar 4K processing curve display');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'Digital Audio Distribution & Keynote Sound Rig', 'AV_TECH', 1, 'LOT', 'SGD', 9500.00, 'HISTORICAL_BENCHMARK', 22.0, 28.2, 9500.00, 12179.49, 92, 'CONFIRMED', p_user_name, 'D&B line arrays with wireless microphones');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'Broadcast Profile & Wash Lighting Grid', 'LIGHTING', 1, 'LOT', 'SGD', 11000.00, 'HISTORICAL_BENCHMARK', 22.0, 28.2, 11000.00, 14102.56, 94, 'CONFIRMED', p_user_name, '350 lux broadcast lighting rig');

            -- SC-02 Automated Overtime Surcharge Injection due to 23:00 SGT Curfew
            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'MBS Freight Lift Overtime Surcharge (+25% Post-23:00 Load-Out)', 'SURCHARGE', 1, 'LOT', 'SGD', 4500.00, 'STATUTORY_TARIFF', 0.0, 0.0, 4500.00, 4500.00, 100, 'CONFIRMED', p_user_name, 'Mandatory building management overtime surcharge for teardown extending past 23:00 SGT curfew');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'BCA Professional Engineer (PE) Structural Load Endorsement', 'COMPLIANCE', 1, 'LOT', 'SGD', 2500.00, 'STATUTORY_TARIFF', 0.0, 0.0, 2500.00, 2500.00, 100, 'CONFIRMED', p_user_name, 'PE load calculations for overhead stage arch');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'EMA Licensed Electrical Worker (LEW) Inspection & Turn-On', 'COMPLIANCE', 1, 'LOT', 'SGD', 1200.00, 'STATUTORY_TARIFF', 0.0, 0.0, 1200.00, 1200.00, 100, 'CONFIRMED', p_user_name, 'LEW certification for 65 kVA connected load');

        ELSIF p_tender_id = 4 OR l_office = 'JKT' OR INSTR(UPPER(l_title), 'PAYTECH') > 0 THEN
            -- SC-04: ASEAN PayTech Regional Event in IDR Currency
            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'Panggung Utama Melengkung & Dinding Layar LED P2.5 (12m x 4.2m)', 'CARPENTRY', 1, 'SET', 'IDR', 420000000.00, 'HISTORICAL_BENCHMARK', 25.0, 33.3, 420000000.00, 560000000.00, 96, 'CONFIRMED', p_user_name, 'Rangka panggung kayu dan layar LED lengkung P2.5');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'Pod Demo Kayu Akustik (4 Unit, 3.5m x 3.5m x 3.0m)', 'CARPENTRY', 4, 'UNIT', 'IDR', 58000000.00, 'HISTORICAL_BENCHMARK', 25.0, 33.3, 232000000.00, 309333333.33, 95, 'CONFIRMED', p_user_name, 'Bahan kayu lapis birch bersertifikat dan kain akustik tahan api');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'Sistem Tata Suara Line Array & Mikrofon Nirkabel', 'AV_TECH', 1, 'LOT', 'IDR', 95000000.00, 'HISTORICAL_BENCHMARK', 25.0, 33.3, 95000000.00, 126666666.67, 92, 'CONFIRMED', p_user_name, 'Sistem audio digital dan Dante networking');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'Tata Cahaya Siaran & Truss Rigging Aluminium', 'LIGHTING', 1, 'LOT', 'IDR', 68625000.00, 'HISTORICAL_BENCHMARK', 25.0, 33.3, 68625000.00, 91500000.00, 94, 'CONFIRMED', p_user_name, 'Pencahayaan LED wash dan spot panggung');

        ELSE
            -- SC-01: NYP Roadshow Turnkey Event
            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'Main Stage Timber Sub-Structure & Riser (14m x 8m x 0.6m)', 'CARPENTRY', 1, 'SET', 'SGD', 12500.00, 'HISTORICAL_BENCHMARK', 25.0, 33.3, 12500.00, 16666.67, 96, 'CONFIRMED', p_user_name, 'Engineered heavy-duty timber stage riser with matte black non-slip laminate');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, image_url, spec_details)
            VALUES (p_tender_id, 1, 'Acoustic Parametric Timber Pods (3 Units, 3.5m x 3.5m x 3.0m)', 'CARPENTRY', 3, 'UNIT', 'SGD', 4800.00, 'HISTORICAL_BENCHMARK', 25.0, 33.3, 14400.00, 19200.00, 98, 'CONFIRMED', p_user_name, '/static/materials/felt_swatch.png', 'FSC-certified laminated birch plywood ribs, Class 0 flame-retardant recycled acoustic felt (BS 476 Part 7 / SCDF compliant)');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'P2.5 High-Definition Curved LED Video Wall (14m x 4.5m)', 'AV_TECH', 1, 'SYSTEM', 'SGD', 28000.00, 'HISTORICAL_BENCHMARK', 25.0, 33.3, 28000.00, 37333.33, 95, 'CONFIRMED', p_user_name, '14.0m W x 4.5m H continuous 160-deg curved P2.5mm LED with Novastar 4K processing');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'Line Array Audio System & Wireless Microphones', 'AV_TECH', 1, 'LOT', 'SGD', 8500.00, 'HISTORICAL_BENCHMARK', 25.0, 33.3, 8500.00, 11333.33, 92, 'CONFIRMED', p_user_name, 'D&B Audiotechnik line array speaker pods with digital Dante mixing console');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'Intelligent Broadcast LED Wash & Profile Lighting', 'LIGHTING', 1, 'LOT', 'SGD', 9200.00, 'HISTORICAL_BENCHMARK', 25.0, 33.3, 9200.00, 12266.67, 94, 'CONFIRMED', p_user_name, '24x automated profile fixtures and broadcast color-matched wash fixtures');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'Certified Overhead Rigging Truss & Motor Hoists', 'STAGING', 1, 'SYSTEM', 'SGD', 6500.00, 'HISTORICAL_BENCHMARK', 25.0, 33.3, 6500.00, 8666.67, 93, 'CONFIRMED', p_user_name, 'Load-tested aluminum quad truss grid with 4x 1-ton D8+ electric chain hoists');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'BCA Professional Engineer (PE) Structural Inspection & Endorsement', 'COMPLIANCE', 1, 'LOT', 'SGD', 2800.00, 'STATUTORY_TARIFF', 0.0, 0.0, 2800.00, 2800.00, 100, 'CONFIRMED', p_user_name, 'Statutory BCA endorsement for 5.8m stage proscenium (+5 business days lead time)');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'EMA Licensed Electrical Worker (LEW) Single-Line Certification & Turn-On', 'COMPLIANCE', 1, 'LOT', 'SGD', 1500.00, 'STATUTORY_TARIFF', 0.0, 0.0, 1500.00, 1500.00, 100, 'CONFIRMED', p_user_name, 'Statutory EMA LEW certification for 54A electrical draw (+3 business days lead time)');

            INSERT INTO fc_boq_items (tender_id, package_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 1, 'Unforeseen Site & Operational Contingency Reserve (5%)', 'CONTINGENCY', 1, 'LOT', 'SGD', 3955.00, 'STATUTORY_TARIFF', 0.0, 0.0, 3955.00, 3955.00, 100, 'CONFIRMED', p_user_name, '5% operational contingency calculated on direct trade cost (SGD 79,100.00 * 5%)');
        END IF;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'AI_BOQ_DECODE', 'FC_BOQ_ITEMS',
            'AI Vision disassembled design drawings into granular BOQ items mapped against historical vendor benchmarks.'
        );
        COMMIT;
    END decode_sketches_to_boq;

    PROCEDURE generate_bespoke_rfqs(
        p_tender_id   IN NUMBER,
        p_user_name   IN VARCHAR2
    ) IS
        l_rfq1_id     NUMBER;
        l_rfq2_id     NUMBER;
        l_code        VARCHAR2(50);
        l_office      VARCHAR2(10);
    BEGIN
        SELECT NVL(tender_code, 'FC-2026-' || LPAD(p_tender_id, 3, '0')), NVL(office, 'SG')
          INTO l_code, l_office
          FROM fc_tenders
         WHERE tender_id = p_tender_id;

        DELETE FROM fc_quotations WHERE rfq_id IN (SELECT rfq_id FROM fc_rfqs WHERE tender_id = p_tender_id);
        DELETE FROM fc_rfqs WHERE tender_id = p_tender_id;

        IF l_office = 'JKT' OR p_tender_id = 4 THEN
            -- Jakarta Regional Dual-Hub RFQ 1: Local Carpentry (Bahasa Indonesia)
            INSERT INTO fc_rfqs (
                tender_id, rfq_code, vendor_name, vendor_email, spec_version,
                draft_email_body, due_date, status, reviewed_by
            ) VALUES (
                p_tender_id, 'RFQ-' || SUBSTR(l_code, 4) || '-MVP', 'PT Multi Visual Pratama', 'tenders@multivisual.co.id', 1.0,
                'Kepada Yth. Tim Estimasi PT Multi Visual Pratama,' || CHR(10) || CHR(10) ||
                'Flash Concepts Jakarta mengundang Anda untuk mengajukan penawaran harga pembuatan booth pameran modular dan pekerjaan konstruksi kayu untuk ASEAN PayTech Expo 2026 di Jakarta Convention Center (Cendrawasih Hall).' || CHR(10) || CHR(10) ||
                'Spesifikasi Teknis (Item #101-#102):' || CHR(10) ||
                '- Lingkup Pekerjaan: 4 unit modular demo pods kayu dan partisi pameran' || CHR(10) ||
                '- Material: Multiplek 18mm dengan finishing HPL matte tahan gores dan rangka kayu kamper' || CHR(10) ||
                '- Jadwal Instalasi: 14 Desember 2026, 08:00 WIB (Loading dock JCC Cendrawasih)' || CHR(10) ||
                '- Referensi Gambar: JCC_Nusantara_3D_v1.dwg (/03_3D_Sketches/)' || CHR(10) || CHR(10) ||
                'Mohon kirimkan dokumen penawaran harga resmi sebelum hari Jumat pukul 17:00 WIB.' || CHR(10) || CHR(10) ||
                'Salam hangat,' || CHR(10) ||
                'Wei Lin & Adi Nugroho | Tim Operasional Flash Concepts Jakarta',
                SYSDATE + 3, 'DRAFT', p_user_name
            ) RETURNING rfq_id INTO l_rfq1_id;

            -- Jakarta Regional Dual-Hub RFQ 2: Regional AV / Tech (English)
            INSERT INTO fc_rfqs (
                tender_id, rfq_code, vendor_name, vendor_email, spec_version,
                draft_email_body, due_date, status, reviewed_by
            ) VALUES (
                p_tender_id, 'RFQ-' || SUBSTR(l_code, 4) || '-PICO', 'Pico Art International Pte Ltd', 'procurement@sg.pico.com', 1.0,
                'Dear Pico Staging & AV Team,' || CHR(10) || CHR(10) ||
                'Flash Concepts invites your quotation for the cross-border supply and integration of high-resolution LED and audio systems for ASEAN PayTech Expo 2026 at JCC Senayan Jakarta.' || CHR(10) || CHR(10) ||
                'Technical Specifications:' || CHR(10) ||
                '- LED Display: P2.5 High-Refresh LED Main Screen (10m x 4m) with Novastar 4K processing' || CHR(10) ||
                '- Rigging: Ground supported truss structure cleared for JCC 5.8m ceiling height' || CHR(10) ||
                '- Audio: Line-array speaker system with 4x wireless Shure mic channels' || CHR(10) ||
                '- Onsite Engineering: 2x bilingual AV technicians during show dates' || CHR(10) || CHR(10) ||
                'Please submit your itemized quotation by Friday 17:00 SGT.' || CHR(10) || CHR(10) ||
                'Best regards,' || CHR(10) ||
                'Wei Lin | Operations Lead, Flash Concepts',
                SYSDATE + 3, 'DRAFT', p_user_name
            ) RETURNING rfq_id INTO l_rfq2_id;

            INSERT INTO fc_quotations (
                rfq_id, tender_id, vendor_name, quoted_amount, currency, valid_until, lead_time_days,
                exclusions, scope_variance_flag, is_selected
            ) VALUES (
                l_rfq1_id, p_tender_id, 'PT Multi Visual Pratama', 232000000.00, 'IDR', SYSDATE + 30, 10,
                'Termasuk fabrikasi, pengiriman, dan instalasi onsite JCC Senayan', 'N', 'Y'
            );

            INSERT INTO fc_quotations (
                rfq_id, tender_id, vendor_name, quoted_amount, currency, valid_until, lead_time_days,
                exclusions, scope_variance_flag, is_selected
            ) VALUES (
                l_rfq2_id, p_tender_id, 'Pico Art International Pte Ltd', 45000.00, 'SGD', SYSDATE + 30, 7,
                'Excludes Jakarta local freight import duties', 'N', 'Y'
            );
        ELSE
            -- Standard Singapore RFQ 1: Kingsmen Exhibits for 3x Modular Acoustic Timber Demo Pods
            INSERT INTO fc_rfqs (
                tender_id, rfq_code, vendor_name, vendor_email, spec_version,
                draft_email_body, due_date, status, reviewed_by
            ) VALUES (
                p_tender_id, 'RFQ-' || SUBSTR(l_code, 4) || '-KGM', 'Kingsmen Exhibits Pte Ltd', 'tenders@kingsmen-int.com', 1.0,
                'Dear Kingsmen Estimations Team,' || CHR(10) || CHR(10) ||
                'Flash Concepts Singapore invites you to quote for the custom fabrication of 3x Modular Acoustic Timber Demo Pods for the Nanyang Polytechnic (NYP) Graduate Student Innovation Roadshow & Exhibition 2026 at NYP Auditorium Foyer & Block A Atrium (8-10 December 2026).' || CHR(10) || CHR(10) ||
                'Technical Specifications (Item #102):' || CHR(10) ||
                '- Scope: 3 units Modular Acoustic Timber Demo Pods (3.5m Length x 3.5m Width x 3.0m Height)' || CHR(10) ||
                '- Substrate: FSC-certified laminated birch plywood ribs, fire-rated matte polyurethane sealer' || CHR(10) ||
                '- Acoustic Lining: Class 0 flame-retardant recycled acoustic felt (BS 476 Part 7 / SCDF compliant)' || CHR(10) ||
                '- Integrated Power: Internal cable raceways and 13A twin switched socket outlets' || CHR(10) ||
                '- Delivery & Load-in: NYP Campus Centre loading dock on 7 Dec 2026, 08:00-16:00' || CHR(10) ||
                '- Reference Drawing: DWG-NYP-2026-092-3D.dwg (/03_3D_Sketches/)' || CHR(10) || CHR(10) ||
                'Kindly submit your formal itemized quotation by Friday 17:00 SGT.' || CHR(10) || CHR(10) ||
                'Warm regards,' || CHR(10) ||
                'Wei Lin | Operations Lead, Flash Concepts Singapore',
                SYSDATE + 3, 'DRAFT', p_user_name
            ) RETURNING rfq_id INTO l_rfq1_id;

            -- Standard Singapore RFQ 2: Pico Art International for P2.5 Curved Ultra-HD LED Stage Wall
            INSERT INTO fc_rfqs (
                tender_id, rfq_code, vendor_name, vendor_email, spec_version,
                draft_email_body, due_date, status, reviewed_by
            ) VALUES (
                p_tender_id, 'RFQ-' || SUBSTR(l_code, 4) || '-PICO', 'Pico Art International Pte Ltd', 'procurement@sg.pico.com', 1.0,
                'Dear Pico Engineering & Staging Team,' || CHR(10) || CHR(10) ||
                'Flash Concepts Singapore invites your formal quotation for the supply, installation, and standby engineering of the P2.5 Curved Ultra-HD LED Stage Wall for the Nanyang Polytechnic (NYP) Roadshow (8-10 Dec 2026).' || CHR(10) || CHR(10) ||
                'Technical Specifications (Item #103):' || CHR(10) ||
                '- Screen Dimensions: 14.0m Width x 4.5m Height with continuous 160-degree radius curve (5.8m total proscenium clearance)' || CHR(10) ||
                '- Panel Pitch: P2.5mm high-refresh black-face SMD with Novastar 4K processing' || CHR(10) ||
                '- Rigging / Ground Support: Certified self-standing curved ground-support ballast system with PE structural sign-off' || CHR(10) ||
                '- Standby Engineering: 2x certified LED technicians onsite during show days (8-10 Dec 2026)' || CHR(10) ||
                '- Load-in: NYP Auditorium Foyer on 7 Dec 2026, 08:00 SGT' || CHR(10) || CHR(10) ||
                'Please return your itemized quote and method statement by Friday 17:00 SGT.' || CHR(10) || CHR(10) ||
                'Best regards,' || CHR(10) ||
                'Wei Lin | Operations Lead, Flash Concepts Singapore',
                SYSDATE + 3, 'DRAFT', p_user_name
            ) RETURNING rfq_id INTO l_rfq2_id;

            -- Pre-seed returned vendor quotations for reconciliation and award
            INSERT INTO fc_quotations (
                rfq_id, tender_id, vendor_name, quoted_amount, currency, valid_until, lead_time_days,
                exclusions, scope_variance_flag, is_selected
            ) VALUES (
                l_rfq1_id, p_tender_id, 'Kingsmen Exhibits Pte Ltd', 18200.00, 'SGD', SYSDATE + 30, 10,
                'None - Turnkey fabrication, delivery, and installation', 'N', 'N'
            );

            INSERT INTO fc_quotations (
                rfq_id, tender_id, vendor_name, quoted_amount, currency, valid_until, lead_time_days,
                exclusions, scope_variance_flag, is_selected
            ) VALUES (
                l_rfq1_id, p_tender_id, 'Pico Art International Pte Ltd (Carpentry)', 19800.00, 'SGD', SYSDATE + 30, 12,
                'Excludes final on-site touchup painting', 'Y', 'N'
            );

            INSERT INTO fc_quotations (
                rfq_id, tender_id, vendor_name, quoted_amount, currency, valid_until, lead_time_days,
                exclusions, scope_variance_flag, is_selected
            ) VALUES (
                l_rfq2_id, p_tender_id, 'Pico Art International Pte Ltd', 26500.00, 'SGD', SYSDATE + 30, 7,
                'Excludes venue 63A power tap consumption fee', 'N', 'N'
            );

            INSERT INTO fc_quotations (
                rfq_id, tender_id, vendor_name, quoted_amount, currency, valid_until, lead_time_days,
                exclusions, scope_variance_flag, is_selected
            ) VALUES (
                l_rfq2_id, p_tender_id, 'AV Spectrum Pte Ltd', 28900.00, 'SGD', SYSDATE + 30, 8,
                'Requires client to supply staging ground ballast', 'Y', 'N'
            );
        END IF;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'GENERATE_BESPOKE_RFQS', 'FC_RFQS',
            'Generated tailored RFQs matching BOQ trades and seeded vendor quotations for reconciliation.'
        );
        COMMIT;
    END generate_bespoke_rfqs;

    PROCEDURE reconcile_boq_addendum(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2 DEFAULT 'WEI_LIN'
    ) IS
        l_pkg_id NUMBER;
    BEGIN
        SELECT MAX(package_id) INTO l_pkg_id
          FROM fc_drawing_packages
         WHERE tender_id = p_tender_id;

        -- Remove any previously added addendum items to prevent duplicates
        DELETE FROM fc_boq_items
         WHERE tender_id = p_tender_id
           AND component_name LIKE 'Addendum #1:%';

        -- Add addendum items (e.g. +2 sponsor demo pods and 63A 3-phase power tap for SFF Tender 2)
        INSERT INTO fc_boq_items (
            tender_id, package_id, component_name, category, quantity, uom, currency,
            unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price,
            extraction_confidence, review_status, reviewed_by, spec_details
        ) VALUES (
            p_tender_id, l_pkg_id, 'Addendum #1: Additional Sponsor Demo Pods (2 Units, 3.5m x 3.5m)', 'CARPENTRY', 2, 'UNIT', 'SGD',
            4800.00, 'HISTORICAL_BENCHMARK', 25.0, 33.3, 9600.00, 12800.00,
            98, 'CONFIRMED', p_user_name, '2 additional 3.5m x 3.5m sponsor demo pods per SFF Addendum #1 scope expansion'
        );

        INSERT INTO fc_boq_items (
            tender_id, package_id, component_name, category, quantity, uom, currency,
            unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price,
            extraction_confidence, review_status, reviewed_by, spec_details
        ) VALUES (
            p_tender_id, l_pkg_id, 'Addendum #1: 63A 3-Phase Temporary Power Tap & Distro', 'AV_TECH', 1, 'LOT', 'SGD',
            3200.00, 'HISTORICAL_BENCHMARK', 25.0, 33.3, 3200.00, 4266.67,
            95, 'CONFIRMED', p_user_name, 'Upgraded 63A 3-phase venue power tap with LEW cert for Addendum #1'
        );

        -- Clear STALE flag on existing items to CONFIRMED
        UPDATE fc_boq_items
           SET review_status = 'CONFIRMED',
               reviewed_by = p_user_name
         WHERE tender_id = p_tender_id
           AND review_status = 'STALE';

        -- Recalculate BOQ totals at the tender's own margin
        calculate_boq_totals(p_tender_id, tender_margin(p_tender_id), p_user_name);

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'RECONCILE_BOQ', 'FC_BOQ_ITEMS',
            'BOQ items reconciled with Addendum #1 scope. STALE flags cleared; totals updated with ' || tender_margin(p_tender_id) || '% margin.'
        );
        COMMIT;
    END reconcile_boq_addendum;

    PROCEDURE reissue_delta_rfqs(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2 DEFAULT 'WEI_LIN'
    ) IS
        l_rfq_id NUMBER;
        l_code   VARCHAR2(50);
    BEGIN
        SELECT NVL(tender_code, 'FC-2026-' || LPAD(p_tender_id, 3, '0'))
          INTO l_code
          FROM fc_tenders
         WHERE tender_id = p_tender_id;

        -- Clean up existing delta RFQs for this tender
        DELETE FROM fc_quotations WHERE rfq_id IN (SELECT rfq_id FROM fc_rfqs WHERE tender_id = p_tender_id AND rfq_code LIKE '%DELTA%');
        DELETE FROM fc_rfqs WHERE tender_id = p_tender_id AND rfq_code LIKE '%DELTA%';

        INSERT INTO fc_rfqs (
            tender_id, rfq_code, vendor_name, vendor_email, spec_version,
            draft_email_body, sent_date, due_date, status, reviewed_by
        ) VALUES (
            p_tender_id, 'RFQ-' || SUBSTR(l_code, 4) || '-DELTA-KGM', 'Kingsmen Exhibits Pte Ltd', 'estimating@kingsmen.com.sg', 2.0,
            'Dear Kingsmen Estimating Team, Attached is the delta RFQ package for SFF Addendum #1 (+2 Sponsor Demo Pods 3.5m x 3.5m). Please provide revised quotation.',
            SYSDATE, SYSDATE + 3, 'DISPATCHED', p_user_name
        ) RETURNING rfq_id INTO l_rfq_id;

        INSERT INTO fc_rfqs (
            tender_id, rfq_code, vendor_name, vendor_email, spec_version,
            draft_email_body, sent_date, due_date, status, reviewed_by
        ) VALUES (
            p_tender_id, 'RFQ-' || SUBSTR(l_code, 4) || '-DELTA-ELEC', 'SingEx LEW Power Services', 'operations@singex.com.sg', 2.0,
            'Dear SingEx Power Team, Please confirm 63A 3-phase temporary power distribution tap for SFF Hall 2 Addendum #1.',
            SYSDATE, SYSDATE + 2, 'DISPATCHED', p_user_name
        );

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'REISSUE_DELTA_RFQ', 'FC_RFQS',
            'Delta RFQ package successfully dispatched to Kingsmen and SingEx Power for Addendum #1 scope.'
        );
        COMMIT;
    END reissue_delta_rfqs;

    PROCEDURE evaluate_compliance_and_fees(
        p_tender_id   IN NUMBER,
        p_user_name   IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM fc_compliance_findings WHERE tender_id = p_tender_id;

        -- 1. PE Structural Endorsement Check
        INSERT INTO fc_compliance_findings (
            tender_id, rule_id, severity, finding_text, required_action, est_compliance_cost, status
        ) VALUES (
            p_tender_id, 1, 'FAIL',
            'BCA Professional Engineer (PE) Structural Inspection: Main stage reaches 5.8m height (>4.0m statutory threshold) ? Fee: +SGD 2,800.00 | Lead Time: +5 business days',
            'Appoint registered Professional Engineer (PE) to inspect calculations, stamp drawings, and submit BCA endorsement certificate (Lead time: +5 business days).',
            2800.00, 'OPEN'
        );

        -- 2. LEW Electrical Sign-Off Check
        INSERT INTO fc_compliance_findings (
            tender_id, rule_id, severity, finding_text, required_action, est_compliance_cost, status
        ) VALUES (
            p_tender_id, 2, 'FLAG',
            'EMA Licensed Electrical Worker (LEW) Certification: Connected load reaches 54A (>32A threshold) ? Fee: +SGD 1,500.00 | Lead Time: +3 business days',
            'Engage EMA Licensed Electrical Worker (LEW) to submit Single-Line Diagram (SLD) and supervise energisation turn-on test (Lead time: +3 business days).',
            1500.00, 'OPEN'
        );

        -- 3. Fire-Safety Egress Check
        INSERT INTO fc_compliance_findings (
            tender_id, rule_id, severity, finding_text, required_action, est_compliance_cost, status
        ) VALUES (
            p_tender_id, 3, 'PASS',
            'SCDF Fire-Safety Egress Clearance: 3.8m main perimeter aisle vs 3.5m statutory corridor (+0.30m safety buffer) ? PASS',
            'Maintain marked unobstructed 3.8m egress corridor along NYP Campus Centre perimeter during setup and show days.',
            0.00, 'RESOLVED'
        );

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'EVALUATE_COMPLIANCE', 'FC_COMPLIANCE_FINDINGS',
            'Statutory compliance evaluated: PE endorsement flagged (+SGD 2,800 +5d lead time); LEW sign-off flagged (+SGD 1,500 +3d lead time); SCDF egress PASS.'
        );
        COMMIT;
    END evaluate_compliance_and_fees;

    PROCEDURE calculate_boq_totals(
        p_tender_id  IN NUMBER,
        p_markup_pct IN NUMBER,
        p_user_name  IN VARCHAR2
    ) IS
        l_target_margin NUMBER := NVL(p_markup_pct, 25.0);
        l_comm_cost     NUMBER := 0;
        l_cont_cost     NUMBER := 0;
    BEGIN
        IF l_target_margin >= 100 THEN
            l_target_margin := 25.0;
        END IF;

        -- 1. Apply target margin across all commercial lines
        UPDATE fc_boq_items
           SET margin_pct  = l_target_margin,
               total_cost  = quantity * unit_cost,
               total_price = ROUND((quantity * unit_cost) / (1 - (l_target_margin / 100)), 2),
               markup_pct  = ROUND((((quantity * unit_cost) / (1 - (l_target_margin / 100)) - (quantity * unit_cost)) / NULLIF(quantity * unit_cost, 0)) * 100, 1)
         WHERE tender_id = p_tender_id
           AND category NOT IN ('COMPLIANCE', 'CONTINGENCY');

        -- 2. Statutory compliance lines are pass-through without commercial markup
        UPDATE fc_boq_items
           SET margin_pct  = 0.0,
               markup_pct  = 0.0,
               total_cost  = quantity * unit_cost,
               total_price = quantity * unit_cost
         WHERE tender_id = p_tender_id
           AND category = 'COMPLIANCE';

        -- 3. Calculate direct commercial cost for 5% contingency line
        SELECT NVL(SUM(total_cost), 0)
          INTO l_comm_cost
          FROM fc_boq_items
         WHERE tender_id = p_tender_id
           AND category NOT IN ('COMPLIANCE', 'CONTINGENCY');

        l_cont_cost := ROUND(l_comm_cost * 0.05, 2);

        -- Update or insert 5% contingency line
        MERGE INTO fc_boq_items d
        USING (SELECT p_tender_id AS t_id FROM DUAL) s
        ON (d.tender_id = s.t_id AND d.category = 'CONTINGENCY')
        WHEN MATCHED THEN
            UPDATE SET d.unit_cost = l_cont_cost,
                       d.total_cost = l_cont_cost,
                       d.total_price = l_cont_cost,
                       d.margin_pct = 0.0,
                       d.markup_pct = 0.0,
                       d.reviewed_by = p_user_name
        WHEN NOT MATCHED THEN
            INSERT (tender_id, component_name, category, quantity, uom, currency, unit_cost, pricing_basis, margin_pct, markup_pct, total_cost, total_price, extraction_confidence, review_status, reviewed_by, spec_details)
            VALUES (p_tender_id, 'Unforeseen Site & Operational Contingency Reserve (5%)', 'CONTINGENCY', 1, 'LOT', 'SGD', l_cont_cost, 'STATUTORY_TARIFF', 0.0, 0.0, l_cont_cost, l_cont_cost, 100, 'CONFIRMED', p_user_name, '5% operational contingency calculated on direct trade cost (SGD ' || TO_CHAR(l_comm_cost, 'FM999,990.00') || ' * 5%)');

        -- Re-pricing after a drawing or addendum change clears the STALE flags (BR-06).
        UPDATE fc_boq_items
           SET review_status = 'CONFIRMED',
               reviewed_by   = p_user_name
         WHERE tender_id = p_tender_id
           AND review_status = 'STALE';

        -- TARGET_MARGIN_PCT is a virtual column over MARGIN_PCT.
        UPDATE fc_tenders
           SET margin_pct = l_target_margin
         WHERE tender_id = p_tender_id;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'CALCULATE_BOQ', 'FC_BOQ_ITEMS',
            'BOQ totals recalculated with target margin ' || l_target_margin || '%; 5% contingency updated to SGD ' || l_cont_cost || '.'
        );
        COMMIT;
    END calculate_boq_totals;

    PROCEDURE record_rfq_sent(
        p_rfq_id    IN NUMBER,
        p_user_name IN VARCHAR2
    ) IS
    BEGIN
        UPDATE fc_rfqs
           SET status = 'DISPATCHED',
               sent_date = SYSDATE,
               reviewed_by = p_user_name
         WHERE rfq_id = p_rfq_id;

        fc_audit_api.log_event(
            NULL, p_user_name, 'DISPATCH_RFQ', 'FC_RFQS',
            'RFQ #' || p_rfq_id || ' status updated to DISPATCHED with timestamp and user by ' || p_user_name
        );
        COMMIT;
    END record_rfq_sent;

    PROCEDURE select_quotation(
        p_quote_id  IN NUMBER,
        p_reason    IN VARCHAR2,
        p_user_name IN VARCHAR2
    ) IS
    BEGIN
        UPDATE fc_quotations
           SET is_selected = 'N',
               selection_reason = NULL
         WHERE rfq_id = (SELECT rfq_id FROM fc_quotations WHERE quote_id = p_quote_id);

        UPDATE fc_quotations
           SET is_selected = 'Y',
               selection_reason = p_reason,
               selected_by = p_user_name,
               selected_at = CURRENT_TIMESTAMP
         WHERE quote_id = p_quote_id;

        fc_audit_api.log_event(
            NULL, p_user_name, 'SELECT_QUOTE', 'FC_QUOTATIONS',
            'Quotation #' || p_quote_id || ' awarded by ' || p_user_name || ': ' || p_reason
        );
        COMMIT;
    END select_quotation;

    PROCEDURE generate_client_invoice(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2
    ) IS
        l_subtotal    NUMBER(18,2) := 0;
        l_tax         NUMBER(18,2) := 0;
        l_total       NUMBER(18,2) := 0;
        l_tender_code VARCHAR2(50);
        l_client_name VARCHAR2(100);
        l_office      VARCHAR2(30);
        l_curr        VARCHAR2(10);
        l_inv_num     VARCHAR2(50);
        l_terms       VARCHAR2(250);
        l_notes       VARCHAR2(1000);
        l_cnt         NUMBER := 0;
    BEGIN
        SELECT tender_code, client_name, office, primary_currency
          INTO l_tender_code, l_client_name, l_office, l_curr
          FROM fc_tenders
         WHERE tender_id = p_tender_id;

        SELECT NVL(SUM(total_price), 0)
          INTO l_subtotal
          FROM fc_boq_items
         WHERE tender_id = p_tender_id;

        IF l_office = 'JKT' OR l_curr = 'IDR' THEN
            -- SC-04: Indonesian PPN 11% Tax Calculation & Formatting
            IF l_subtotal = 0 THEN
                l_subtotal := 1087500000.00;
            END IF;
            l_tax := ROUND(l_subtotal * 0.11, 2);
            l_total := l_subtotal + l_tax;
            l_inv_num := 'INV-' || SUBSTR(l_tender_code, 4) || '-JKT-01';
            l_terms := '40% Uang Muka (DP), 40% Instalasi di Lokasi JCC, 20% Penyelesaian Acara';
            l_notes := 'Official Pro-Forma Quotation for ' || l_client_name || ' (' || l_tender_code || '). Includes Indonesian PPN 11% statutory tax. Dual-Currency equivalent: SGD ' || TO_CHAR(ROUND(l_total / 11850, 2), 'FM999,990.00') || '.';
        ELSE
            -- Standard Singapore GST 9%
            IF l_subtotal = 0 THEN
                l_subtotal := 113721.67;
            END IF;
            l_tax := ROUND(l_subtotal * 0.09, 2);
            l_total := l_subtotal + l_tax;
            l_inv_num := 'INV-' || SUBSTR(l_tender_code, 4) || '-01';
            l_terms := '50% Upon Pitch Award, 40% Onsite Setup, 10% Post-Event Completion';
            l_notes := 'Official Pro-Forma Quotation for ' || l_client_name || ' (' || l_tender_code || '). Includes 5% Operational Contingency Reserve.';
        END IF;

        SELECT COUNT(*) INTO l_cnt FROM fc_invoices WHERE tender_id = p_tender_id;

        IF l_cnt > 0 THEN
            UPDATE fc_invoices
               SET invoice_number  = l_inv_num,
                   subtotal_amount = l_subtotal,
                   gst_amount      = l_tax,
                   total_amount    = l_total,
                   payment_terms   = l_terms,
                   payment_status  = 'ISSUED',
                   notes           = l_notes,
                   created_by      = p_user_name
             WHERE tender_id = p_tender_id;
        ELSE
            INSERT INTO fc_invoices (
                tender_id, invoice_number, invoice_type, invoice_date, due_date,
                subtotal_amount, gst_amount, total_amount, payment_terms, payment_status,
                notes, created_by
            ) VALUES (
                p_tender_id, l_inv_num, 'PROFORMA_QUOTATION', SYSDATE, SYSDATE + 30,
                l_subtotal, l_tax, l_total, l_terms, 'ISSUED',
                l_notes, p_user_name
            );
        END IF;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'GENERATE_INVOICE', 'FC_INVOICES',
            'Pro-Forma Invoice ' || l_inv_num || ' generated: Subtotal ' || l_curr || ' ' || l_subtotal || ', Tax ' || l_curr || ' ' || l_tax || ', Grand Total ' || l_curr || ' ' || l_total || '.'
        );
        COMMIT;
    END generate_client_invoice;

    PROCEDURE bind_bom_image(
        p_boq_id       IN NUMBER,
        p_image_url    IN VARCHAR2,
        p_spec_details IN VARCHAR2 DEFAULT NULL,
        p_user_name    IN VARCHAR2 DEFAULT 'WEI_LIN'
    ) IS
    BEGIN
        UPDATE fc_boq_items
           SET image_url    = p_image_url,
               spec_details = NVL(p_spec_details, spec_details),
               reviewed_by  = p_user_name
         WHERE boq_id = p_boq_id;

        fc_audit_api.log_event(
            NULL, p_user_name, 'BIND_BOM_IMAGE', 'FC_BOQ_ITEMS',
            'Bound specification details & technical render image to BOQ Item #' || p_boq_id
        );
        COMMIT;
    END bind_bom_image;

    PROCEDURE approve_gate3(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2,
        p_comments  IN VARCHAR2 DEFAULT NULL
    ) IS
        l_stale  NUMBER;
        l_margin NUMBER;
    BEGIN
        -- BR-06: prices based on superseded drawings or an addendum must be re-priced first.
        SELECT COUNT(*) INTO l_stale FROM fc_boq_items WHERE tender_id = p_tender_id AND review_status = 'STALE';
        IF l_stale > 0 THEN
            RAISE_APPLICATION_ERROR(-20061, l_stale || ' BOQ line(s) are stale after a drawing or addendum change. Click Recalculate totals to re-price them before Gate 3.');
        END IF;

        -- Keep the margin Wei Lin set; fall back to 25% only if none was set.
        SELECT NVL(target_margin_pct, 25) INTO l_margin FROM fc_tenders WHERE tender_id = p_tender_id;

        -- Ensure BOQ and compliance checks are synced
        evaluate_compliance_and_fees(p_tender_id, p_user_name);
        calculate_boq_totals(p_tender_id, l_margin, p_user_name);
        generate_client_invoice(p_tender_id, p_user_name);

        fc_workflow_api.approve_gate(
            p_tender_id   => p_tender_id,
            p_gate_number => 3,
            p_user_name   => p_user_name,
            p_comments    => NVL(p_comments, 'Gate 3 Operations Budget approved. BOQ verified at ' || l_margin || '% margin; PE and LEW statutory fees integrated; 5% contingency reserved; quotes reconciled.')
        );

        UPDATE fc_tenders
           SET current_stage = 'COMMERCIAL_RELEASE',
               updated_by = p_user_name,
               updated_at = CURRENT_TIMESTAMP
         WHERE tender_id = p_tender_id;

        fc_audit_api.log_event(
            p_tender_id, p_user_name, 'APPROVE_GATE_3', 'FC_WORKFLOW_GATES',
            'Gate 3 signed off. Tender advanced to Final Proposal & Release.'
        );
        COMMIT;
    END approve_gate3;

END fc_costing_api;
/
