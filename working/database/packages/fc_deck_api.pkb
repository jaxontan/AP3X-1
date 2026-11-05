CREATE OR REPLACE PACKAGE BODY fc_deck_api AS

    c_layouts CONSTANT VARCHAR2(400) :=
        'HERO_TITLE,SPLIT_STORY,CANVAS_3D,TIMELINE_FLOW,FLOORPLAN_MAP,GRID_ACTIVATIONS,METRICS_CARDS,SUMMARY_TABLE';

    PROCEDURE draft_slides(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2,
        x_message   OUT VARCHAR2
    ) IS
        l_client   VARCHAR2(150);
        l_title    VARCHAR2(250);
        l_context  CLOB;
        l_reply    CLOB;
        l_json     CLOB;
        l_valid    PLS_INTEGER := 0;
        l_cnt      PLS_INTEGER := 0;
        l_bullets  VARCHAR2(2000);
    BEGIN
        SELECT client_name, project_title INTO l_client, l_title FROM fc_tenders WHERE tender_id = p_tender_id;

        l_context := 'Client: ' || l_client || CHR(10) || 'Project: ' || l_title || CHR(10) || 'Confirmed brief:' || CHR(10);
        FOR r IN (SELECT field_category, field_label, NVL(confirmed_value, extracted_value) AS val
                    FROM fc_intake_fields
                   WHERE tender_id = p_tender_id AND field_category <> 'CLARIFICATION'
                   ORDER BY field_category, field_id) LOOP
            l_context := l_context || '- ' || r.field_label || ': ' || r.val || CHR(10);
        END LOOP;
        FOR c IN (SELECT concept_title, narrative, brief_fit, event_flow, spatial_notes, fringe_activities
                    FROM fc_concept_options
                   WHERE tender_id = p_tender_id AND is_selected = 'Y'
                   FETCH FIRST 1 ROW ONLY) LOOP
            l_context := l_context || 'Selected concept: ' || c.concept_title || CHR(10)
                      || 'Idea: ' || c.narrative || CHR(10) || 'Fit with brief: ' || c.brief_fit || CHR(10)
                      || 'Run of show: ' || c.event_flow || CHR(10) || 'Space: ' || c.spatial_notes || CHR(10)
                      || 'Fringe activities: ' || c.fringe_activities || CHR(10);
        END LOOP;
        FOR s IN (SELECT structure_name, req_length_m, req_width_m, req_height_m, feasibility_status
                    FROM fc_spatial_checks WHERE tender_id = p_tender_id ORDER BY check_id) LOOP
            l_context := l_context || 'Fit check: ' || s.structure_name || ' ' || s.req_length_m || ' x ' || s.req_width_m
                      || ' x ' || s.req_height_m || ' m = ' || s.feasibility_status || CHR(10);
        END LOOP;
        FOR f IN (SELECT title, recommended_mitigation FROM fc_planning_flags
                   WHERE tender_id = p_tender_id AND status <> 'RESOLVED') LOOP
            l_context := l_context || 'Risk: ' || f.title || CASE WHEN f.recommended_mitigation IS NOT NULL THEN ' (plan: ' || f.recommended_mitigation || ')' END || CHR(10);
        END LOOP;
        FOR r IN (SELECT claim_text FROM fc_research_findings
                   WHERE tender_id = p_tender_id AND review_status = 'APPROVED') LOOP
            l_context := l_context || 'Client background: ' || r.claim_text || CHR(10);
        END LOOP;

        FOR l_attempt IN 1 .. 2 LOOP
            l_reply := fc_ai_agent_api.call_openrouter(
                p_system_prompt =>
                    'You are the Principal Creative Pitch Director at Flash Concepts, a premier B2B experiential event agency in Singapore and Jakarta. '
                 || 'Synthesize an extraordinary, highly persuasive 8-slide executive pitch deck tailored specifically for the tender brief below. '
                 || 'Storytelling Arc (exactly 8 slides in this order): '
                 || '1. Executive Vision & Theme Hook: Bold overarching creative title, setting the stage for transformational attendee experience. '
                 || '2. Strategic Brief Alignment: Client core brand objectives, attendee psychology, and target stakeholder personas. '
                 || '3. The Signature Concept & Creative Metaphor: Core narrative, atmosphere, spatial identity, and multi-sensory brand world. '
                 || '4. Curated Attendee Journey & Run-of-Show: Arrival/registration, dramatic reveal, keynote experience, and networking flow. '
                 || '5. Spatial Architecture & 3D Stage Blueprint: Stage proscenium dimensions, immersive LED ribbon walls, acoustic zoning, and egress corridors. '
                 || '6. Interactive Activation Ecosystem: Multi-sensory demo pods, gamified brand touchpoints, and sustainability credentials (e.g. MICE reusability standards). '
                 || '7. Operational Feasibility, Safety & Statutory Compliance: SCDF fire clearances, BCA structural engineering sign-offs, and risk mitigation. '
                 || '8. Commercial Roadmap & Milestones: 12-week delivery countdown, fabrication milestones, rehearsal schedule, and call to action. '
                 || 'Rules: '
                 || '- Ground every claim strictly in the confirmed client brief, selected concept option, fit checks, and approved research. Never hallucinate unsupported facts. '
                 || '- Plain British English, authoritative, elegant, razor-sharp experiential vocabulary. '
                 || '- Visual prompts must describe exact architectural, lighting, and spatial staging details for 3D visualizers. '
                 || 'Reply with ONE JSON object only: {"slides": [{"title": "Punchy slide title (max 8 words)", "focus": "Strategic narrative focus (1-2 sentences)", '
                 || '"bullets": ["3-4 crisp bullet points with concrete metrics and experiential mechanics"], '
                 || '"visual": "Detailed visual staging and architectural brief for designers", '
                 || '"image_prompt": "Detailed AI image prompt: cinematic 3D architectural render, Unreal Engine 5, photorealistic event stage"}... 8 items]}.',
                p_user_prompt => l_context,
                p_temperature => CASE l_attempt WHEN 1 THEN 0.5 ELSE 0.3 END,
                p_max_tokens  => 6000,
                p_tender_id   => p_tender_id,
                p_agent       => 'DECK_DRAFT',
                p_json_mode   => 'Y'
            );
            l_json := fc_ai_agent_api.extract_json(l_reply);
            l_valid := 0;
            IF l_json IS NOT NULL THEN
                SELECT COUNT(*) INTO l_valid
                  FROM json_table(l_json, '$.slides[*]' COLUMNS (title VARCHAR2(400) PATH '$.title')) jt
                 WHERE jt.title IS NOT NULL;
            END IF;
            EXIT WHEN l_valid >= 6;
        END LOOP;

        IF l_valid < 6 THEN
            fc_design_api.generate_slide_deck_drafts(p_tender_id, p_user_name);
            x_message := 'The AI service is unavailable, so the template deck is shown. Check AI settings and try again.';
            RETURN;
        END IF;

        DELETE FROM fc_pitch_slides WHERE tender_id = p_tender_id;
        FOR s IN (SELECT jt.idx, jt.title, jt.focus, jt.visual, jt.image_prompt
                    FROM json_table(l_json, '$.slides[*]'
                           COLUMNS (idx          FOR ORDINALITY,
                                    title        VARCHAR2(400)  PATH '$.title',
                                    focus        VARCHAR2(1000) PATH '$.focus',
                                    visual       VARCHAR2(2000) PATH '$.visual',
                                    image_prompt VARCHAR2(2000) PATH '$.image_prompt')) jt
                   WHERE jt.title IS NOT NULL
                   ORDER BY jt.idx) LOOP
            EXIT WHEN l_cnt >= 8;
            l_cnt := l_cnt + 1;
            l_bullets := NULL;
            FOR b IN (SELECT bt.bullet
                        FROM json_table(l_json, '$.slides[*]'
                               COLUMNS (idx FOR ORDINALITY,
                                        NESTED PATH '$.bullets[*]' COLUMNS (bnum FOR ORDINALITY, bullet VARCHAR2(400) PATH '$'))) bt
                       WHERE bt.idx = s.idx AND bt.bullet IS NOT NULL
                       ORDER BY bt.bnum) LOOP
                l_bullets := SUBSTR(l_bullets || CASE WHEN l_bullets IS NOT NULL THEN CHR(10) END || '• ' || b.bullet, 1, 2000);
            END LOOP;
            INSERT INTO fc_pitch_slides (
                tender_id, slide_num, slide_title, layout_type, narrative_focus,
                key_bullet_points, visual_placeholder_desc, image_prompt, is_customized
            ) VALUES (
                p_tender_id, l_cnt, SUBSTR(s.title, 1, 200),
                NVL(REGEXP_SUBSTR(c_layouts, '[^,]+', 1, l_cnt), 'SPLIT_STORY'),
                SUBSTR(s.focus, 1, 500), l_bullets, SUBSTR(s.visual, 1, 2000),
                NVL(SUBSTR(s.image_prompt, 1, 2000), SUBSTR(s.visual, 1, 2000)), 'N'
            );
        END LOOP;

        fc_audit_api.log_event(p_tender_id, p_user_name, 'AI_DECK_DRAFT', 'FC_PITCH_SLIDES',
            'AI drafted ' || l_cnt || ' pitch slides from the confirmed brief and selected concept.');
        x_message := l_cnt || ' slides drafted by AI from the confirmed brief and selected concept. Review them before Gate 2.';
    END draft_slides;

    -- ---------------------------------------------------------------- PowerPoint export

    FUNCTION x(p_text IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN dbms_xmlgen.convert(p_text);
    END x;

    FUNCTION run(p_text IN VARCHAR2, p_size IN NUMBER, p_color IN VARCHAR2, p_bold IN BOOLEAN DEFAULT FALSE,
                 p_italic IN BOOLEAN DEFAULT FALSE) RETURN VARCHAR2 IS
    BEGIN
        RETURN '<a:r><a:rPr lang="en-GB" sz="' || p_size || '"' || CASE WHEN p_bold THEN ' b="1"' END
            || CASE WHEN p_italic THEN ' i="1"' END || ' dirty="0"><a:solidFill><a:srgbClr val="' || p_color
            || '"/></a:solidFill><a:latin typeface="Montserrat"/></a:rPr><a:t>' || x(p_text) || '</a:t></a:r>';
    END run;

    FUNCTION box(p_id IN NUMBER, p_name IN VARCHAR2, p_x IN NUMBER, p_y IN NUMBER, p_w IN NUMBER, p_h IN NUMBER,
                 p_paras IN CLOB, p_anchor IN VARCHAR2 DEFAULT 't') RETURN CLOB IS
    BEGIN
        RETURN '<p:sp><p:nvSpPr><p:cNvPr id="' || p_id || '" name="' || p_name || '"/><p:cNvSpPr txBox="1"/><p:nvPr/></p:nvSpPr>'
            || '<p:spPr><a:xfrm><a:off x="' || p_x || '" y="' || p_y || '"/><a:ext cx="' || p_w || '" cy="' || p_h || '"/></a:xfrm>'
            || '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:noFill/></p:spPr>'
            || '<p:txBody><a:bodyPr wrap="square" lIns="0" rIns="0" anchor="' || p_anchor || '"><a:normAutofit/></a:bodyPr><a:lstStyle/>'
            || p_paras || '</p:txBody></p:sp>';
    END box;

    FUNCTION bar(p_id IN NUMBER, p_x IN NUMBER, p_y IN NUMBER, p_w IN NUMBER, p_h IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        -- Brand rule: mint to blue gradient.
        RETURN '<p:sp><p:nvSpPr><p:cNvPr id="' || p_id || '" name="Accent"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>'
            || '<p:spPr><a:xfrm><a:off x="' || p_x || '" y="' || p_y || '"/><a:ext cx="' || p_w || '" cy="' || p_h || '"/></a:xfrm>'
            || '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:gradFill rotWithShape="1"><a:gsLst>'
            || '<a:gs pos="0"><a:srgbClr val="36FF9F"/></a:gs><a:gs pos="100000"><a:srgbClr val="026BD3"/></a:gs>'
            || '</a:gsLst><a:lin ang="0" scaled="0"/></a:gradFill><a:ln><a:noFill/></a:ln></p:spPr></p:sp>';
    END bar;

    FUNCTION to_blob(p_clob IN CLOB) RETURN BLOB IS
        l_blob   BLOB;
        l_dest   INTEGER := 1;
        l_src    INTEGER := 1;
        l_ctx    INTEGER := dbms_lob.default_lang_ctx;
        l_warn   INTEGER;
    BEGIN
        dbms_lob.createtemporary(l_blob, TRUE);
        dbms_lob.converttoblob(l_blob, p_clob, dbms_lob.lobmaxsize, l_dest, l_src,
                               nls_charset_id('AL32UTF8'), l_ctx, l_warn);
        RETURN l_blob;
    END to_blob;

    FUNCTION build_pptx(p_tender_id IN NUMBER) RETURN BLOB IS
        c_ns     CONSTANT VARCHAR2(400) := 'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
                                        || 'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
                                        || 'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"';
        c_hdr    CONSTANT VARCHAR2(60) := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
        c_tree   CONSTANT VARCHAR2(300) := '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>'
                                        || '<p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>';
        l_zip    BLOB;
        l_code   VARCHAR2(50);
        l_client VARCHAR2(150);
        l_title  VARCHAR2(250);
        l_total  PLS_INTEGER;
        l_n      PLS_INTEGER := 0;
        l_types  CLOB;
        l_prels  CLOB;
        l_ids    CLOB;
        l_slide  CLOB;
        l_paras  CLOB;
        l_dark   BOOLEAN;
        l_fg     VARCHAR2(6);

        PROCEDURE add(p_name IN VARCHAR2, p_xml IN CLOB) IS
        BEGIN
            apex_zip.add_file(p_zipped_blob => l_zip, p_file_name => p_name, p_content => to_blob(p_xml));
        END add;
    BEGIN
        SELECT tender_code, client_name, project_title INTO l_code, l_client, l_title
          FROM fc_tenders WHERE tender_id = p_tender_id;
        SELECT COUNT(*) INTO l_total FROM fc_pitch_slides WHERE tender_id = p_tender_id;
        IF l_total = 0 THEN
            raise_application_error(-20041, 'Draft the slides first, then export.');
        END IF;

        l_types := c_hdr || '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
                || '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
                || '<Default Extension="xml" ContentType="application/xml"/>'
                || '<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>'
                || '<Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>'
                || '<Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>'
                || '<Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>';
        l_prels := c_hdr || '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                || '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>'
                || '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>';

        FOR s IN (SELECT slide_num, slide_title, narrative_focus, key_bullet_points, visual_placeholder_desc
                    FROM fc_pitch_slides WHERE tender_id = p_tender_id ORDER BY slide_num) LOOP
            l_n := l_n + 1;
            l_dark := (l_n = 1);          -- title slide on the brand black
            l_fg := CASE WHEN l_dark THEN 'FFFFFF' ELSE '121212' END;

            l_paras := NULL;
            FOR b IN (SELECT TRIM(REGEXP_REPLACE(COLUMN_VALUE, '^\s*(?|-|\*|' || UNISTR('\FFFD') || ')\s*', '')) AS t
                        FROM TABLE(apex_string.split(s.key_bullet_points, CHR(10)))
                       WHERE TRIM(COLUMN_VALUE) IS NOT NULL) LOOP
                l_paras := l_paras || '<a:p><a:pPr marL="342900" indent="-342900"><a:spcBef><a:spcPts val="900"/></a:spcBef>'
                        || '<a:buClr><a:srgbClr val="3BE891"/></a:buClr><a:buFont typeface="Arial"/><a:buChar char="&#8226;"/></a:pPr>'
                        || run(b.t, 2000, l_fg) || '</a:p>';
            END LOOP;

            l_slide := c_hdr || '<p:sld ' || c_ns || '><p:cSld><p:bg><p:bgPr><a:solidFill><a:srgbClr val="'
                    || CASE WHEN l_dark THEN '121212' ELSE 'FFFFFF' END || '"/></a:solidFill><a:effectLst/></p:bgPr></p:bg><p:spTree>' || c_tree
                    || bar(2, 609600, 548640, 1371600, 73152)
                    || box(3, 'Title', 609600, 685800, 10972800, CASE WHEN l_dark THEN 2286000 ELSE 1005840 END,
                           '<a:p>' || run(CASE WHEN l_dark THEN l_title ELSE s.slide_title END, CASE WHEN l_dark THEN 4000 ELSE 3000 END, l_fg, TRUE) || '</a:p>', 'b')
                    || box(4, 'Focus', 609600, CASE WHEN l_dark THEN 3063240 ELSE 1737360 END, 10972800, 640080,
                           '<a:p>' || run(CASE WHEN l_dark AND s.slide_title <> l_title THEN s.slide_title || '. ' END || s.narrative_focus, 1600,
                                          CASE WHEN l_dark THEN '3BE891' ELSE '026BD3' END) || '</a:p>');
            IF l_paras IS NOT NULL THEN
                l_slide := l_slide || box(5, 'Bullets', 609600, CASE WHEN l_dark THEN 3794760 ELSE 2468880 END, 10972800,
                                          CASE WHEN l_dark THEN 1828800 ELSE 2926080 END, l_paras);
            END IF;
            IF s.visual_placeholder_desc IS NOT NULL AND NOT l_dark THEN
                l_slide := l_slide || box(6, 'Visual brief', 609600, 5486400, 10972800, 548640,
                    '<a:p>' || run('Visual: ' || SUBSTR(s.visual_placeholder_desc, 1, 300), 1100, '7F7F7F', FALSE, TRUE) || '</a:p>');
            END IF;
            l_slide := l_slide || box(7, 'Footer', 609600, 6217920, 10972800, 320040,
                    '<a:p><a:pPr algn="r"/>' || run(l_code || '  ?  ' || l_client || '  ?  ' || l_n || ' / ' || l_total, 1000,
                                                     CASE WHEN l_dark THEN 'BFBFBF' ELSE '7F7F7F' END) || '</a:p>')
                    || '</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>';

            add('ppt/slides/slide' || l_n || '.xml', l_slide);
            add('ppt/slides/_rels/slide' || l_n || '.xml.rels', c_hdr
                || '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                || '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>'
                || '</Relationships>');
            l_types := l_types || '<Override PartName="/ppt/slides/slide' || l_n
                    || '.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>';
            l_prels := l_prels || '<Relationship Id="rId' || (l_n + 2)
                    || '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide' || l_n || '.xml"/>';
            l_ids := l_ids || '<p:sldId id="' || (255 + l_n) || '" r:id="rId' || (l_n + 2) || '"/>';
        END LOOP;

        add('[Content_Types].xml', l_types || '</Types>');
        add('_rels/.rels', c_hdr || '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            || '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>'
            || '</Relationships>');
        add('ppt/presentation.xml', c_hdr || '<p:presentation ' || c_ns || '>'
            || '<p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>'
            || '<p:sldIdLst>' || l_ids || '</p:sldIdLst>'
            || '<p:sldSz cx="12192000" cy="6858000"/><p:notesSz cx="6858000" cy="9144000"/></p:presentation>');
        add('ppt/_rels/presentation.xml.rels', l_prels || '</Relationships>');
        add('ppt/slideMasters/slideMaster1.xml', c_hdr || '<p:sldMaster ' || c_ns || '><p:cSld><p:spTree>' || c_tree || '</p:spTree></p:cSld>'
            || '<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" '
            || 'accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>'
            || '<p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst></p:sldMaster>');
        add('ppt/slideMasters/_rels/slideMaster1.xml.rels', c_hdr
            || '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            || '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>'
            || '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>'
            || '</Relationships>');
        add('ppt/slideLayouts/slideLayout1.xml', c_hdr || '<p:sldLayout ' || c_ns || ' type="blank" preserve="1">'
            || '<p:cSld name="Blank"><p:spTree>' || c_tree || '</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sldLayout>');
        add('ppt/slideLayouts/_rels/slideLayout1.xml.rels', c_hdr
            || '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            || '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>'
            || '</Relationships>');
        add('ppt/theme/theme1.xml', c_hdr || '<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Flash Concepts">'
            || '<a:themeElements><a:clrScheme name="Flash Concepts">'
            || '<a:dk1><a:srgbClr val="121212"/></a:dk1><a:lt1><a:srgbClr val="FFFFFF"/></a:lt1>'
            || '<a:dk2><a:srgbClr val="121212"/></a:dk2><a:lt2><a:srgbClr val="E9F2E9"/></a:lt2>'
            || '<a:accent1><a:srgbClr val="3BE891"/></a:accent1><a:accent2><a:srgbClr val="026BD3"/></a:accent2>'
            || '<a:accent3><a:srgbClr val="3976C6"/></a:accent3><a:accent4><a:srgbClr val="6FEE91"/></a:accent4>'
            || '<a:accent5><a:srgbClr val="3274CD"/></a:accent5><a:accent6><a:srgbClr val="7F7F7F"/></a:accent6>'
            || '<a:hlink><a:srgbClr val="026BD3"/></a:hlink><a:folHlink><a:srgbClr val="3976C6"/></a:folHlink></a:clrScheme>'
            || '<a:fontScheme name="Flash Concepts"><a:majorFont><a:latin typeface="Montserrat"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont>'
            || '<a:minorFont><a:latin typeface="Montserrat"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont></a:fontScheme>'
            || '<a:fmtScheme name="Flash Concepts"><a:fillStyleLst>'
            || '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill>'
            || '</a:fillStyleLst><a:lnStyleLst>'
            || '<a:ln w="6350"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln>'
            || '<a:ln w="12700"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln>'
            || '<a:ln w="19050"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln>'
            || '</a:lnStyleLst><a:effectStyleLst>'
            || '<a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle>'
            || '</a:effectStyleLst><a:bgFillStyleLst>'
            || '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill>'
            || '</a:bgFillStyleLst></a:fmtScheme></a:themeElements></a:theme>');

        apex_zip.finish(p_zipped_blob => l_zip);
        RETURN l_zip;
    END build_pptx;

    FUNCTION build_html(p_tender_id IN NUMBER) RETURN BLOB IS
        l_code   VARCHAR2(50);
        l_client VARCHAR2(150);
        l_title  VARCHAR2(250);
        l_total  PLS_INTEGER;
        l_html   CLOB;
        l_idx    PLS_INTEGER := 0;

        PROCEDURE append_str(p_str IN VARCHAR2) IS
        BEGIN
            DBMS_LOB.WRITEAPPEND(l_html, LENGTH(p_str), p_str);
        END;
    BEGIN
        SELECT tender_code, client_name, project_title INTO l_code, l_client, l_title
          FROM fc_tenders WHERE tender_id = p_tender_id;
        SELECT COUNT(*) INTO l_total FROM fc_pitch_slides WHERE tender_id = p_tender_id;
        IF l_total = 0 THEN
            raise_application_error(-20041, 'Draft the slides first, then export.');
        END IF;

        DBMS_LOB.CREATETEMPORARY(l_html, TRUE);
        append_str('<!DOCTYPE html>' || CHR(10) || '<html lang="en">' || CHR(10) || '<head>' || CHR(10)
            || '<meta charset="utf-8">' || CHR(10)
            || '<meta name="viewport" content="width=device-width, initial-scale=1">' || CHR(10)
            || '<title>' || apex_escape.html(l_code) || ' - ' || apex_escape.html(l_client) || ' Pitch Deck</title>' || CHR(10)
            || '<style>' || CHR(10)
            || '* { box-sizing: border-box; margin: 0; padding: 0; }' || CHR(10)
            || 'body { background: #0b0f17; color: #e6edf3; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; min-height: 100vh; display: flex; flex-direction: column; }' || CHR(10)
            || '.fc-nav { display: flex; justify-content: space-between; align-items: center; background: #161b22; padding: 12px 24px; border-bottom: 1px solid rgba(255,255,255,0.08); position: sticky; top: 0; z-index: 100; }' || CHR(10)
            || '.fc-brand { font-weight: 700; font-size: 14px; letter-spacing: 0.5px; color: #fff; display: flex; align-items: center; gap: 10px; }' || CHR(10)
            || '.fc-badge { background: linear-gradient(135deg, #36FF9F, #026BD3); color: #000; font-size: 11px; font-weight: 800; padding: 2px 8px; border-radius: 4px; text-transform: uppercase; }' || CHR(10)
            || '.fc-controls { display: flex; align-items: center; gap: 10px; }' || CHR(10)
            || '.fc-btn { background: #21262d; border: 1px solid rgba(255,255,255,0.15); color: #e6edf3; padding: 6px 14px; border-radius: 6px; font-size: 13px; cursor: pointer; font-weight: 500; transition: all 0.2s; }' || CHR(10)
            || '.fc-btn:hover { background: #30363d; border-color: #8b949e; }' || CHR(10)
            || '.fc-btn-hot { background: #026BD3; color: #fff; border-color: #026BD3; }' || CHR(10)
            || '.fc-btn-hot:hover { background: #0378ea; }' || CHR(10)
            || '.fc-counter { font-size: 13px; color: #8b949e; font-variant-numeric: tabular-nums; margin: 0 4px; }' || CHR(10)
            || '.fc-deck-container { flex: 1; display: flex; justify-content: center; align-items: center; padding: 28px 16px; }' || CHR(10)
            || '.fc-slide { width: 100%; max-width: 960px; aspect-ratio: 16 / 9; background: #121824; border: 1px solid rgba(255,255,255,0.1); border-radius: 12px; padding: 40px 48px; display: none; flex-direction: column; justify-content: space-between; box-shadow: 0 20px 40px rgba(0,0,0,0.5); position: relative; overflow: hidden; }' || CHR(10)
            || '.fc-slide.active { display: flex; }' || CHR(10)
            || '.fc-slide::before { content: ""; position: absolute; top: 0; left: 0; right: 0; height: 5px; background: linear-gradient(90deg, #36FF9F 0%, #026BD3 100%); }' || CHR(10)
            || '.fc-slide-title-card { background: radial-gradient(circle at top right, #1a2333 0%, #0d121c 100%); justify-content: center; }' || CHR(10)
            || '.fc-slide-title { font-size: 26px; font-weight: 700; color: #ffffff; line-height: 1.3; margin-bottom: 12px; }' || CHR(10)
            || '.fc-slide-title-card .fc-slide-title { font-size: 34px; font-weight: 800; margin-bottom: 16px; }' || CHR(10)
            || '.fc-slide-subtitle { font-size: 18px; color: #36FF9F; font-weight: 500; margin-bottom: 20px; }' || CHR(10)
            || '.fc-slide-focus { font-size: 14px; color: #38bdf8; background: rgba(56, 189, 248, 0.08); border-left: 3px solid #38bdf8; padding: 8px 14px; border-radius: 0 6px 6px 0; margin-bottom: 18px; line-height: 1.4; }' || CHR(10)
            || '.fc-slide-body { flex: 1; }' || CHR(10)
            || '.fc-slide-bullets { list-style: none; display: flex; flex-direction: column; gap: 12px; }' || CHR(10)
            || '.fc-slide-bullets li { position: relative; padding-left: 24px; font-size: 15px; line-height: 1.5; color: #c9d1d9; }' || CHR(10)
            || '.fc-slide-bullets li::before { content: ""; position: absolute; left: 4px; top: 8px; width: 8px; height: 8px; border-radius: 50%; background: #36FF9F; box-shadow: 0 0 8px rgba(54,255,159,0.5); }' || CHR(10)
            || '.fc-slide-visual { margin-top: 14px; padding: 10px 14px; background: rgba(255,255,255,0.03); border: 1px dashed rgba(255,255,255,0.15); border-radius: 6px; font-size: 13px; color: #8b949e; }' || CHR(10)
            || '.fc-slide-visual strong { color: #f0883e; }' || CHR(10)
            || '.fc-slide-footer { display: flex; justify-content: space-between; align-items: center; padding-top: 14px; border-top: 1px solid rgba(255,255,255,0.06); font-size: 12px; color: #6e7681; }' || CHR(10)
            || '@media print { body { background: #fff !important; color: #000 !important; } .fc-nav { display: none !important; } .fc-deck-container { display: block !important; padding: 0 !important; } .fc-slide { display: flex !important; page-break-after: always; break-after: page; border: none !important; box-shadow: none !important; background: #fff !important; color: #000 !important; width: 100% !important; max-width: none !important; aspect-ratio: auto !important; height: 95vh !important; } .fc-slide-title { color: #000 !important; } .fc-slide-bullets li { color: #222 !important; } .fc-slide-bullets li::before { background: #026BD3 !important; } .fc-slide-visual { background: #f6f8fa !important; border-color: #ccc !important; } }' || CHR(10)
            || '</style>' || CHR(10)
            || '</head>' || CHR(10)
            || '<body>' || CHR(10)
            || '<header class="fc-nav">' || CHR(10)
            || '  <div class="fc-brand"><span class="fc-badge">HTML5 Deck</span> ' || apex_escape.html(l_code) || ' · ' || apex_escape.html(l_client) || '</div>' || CHR(10)
            || '  <div class="fc-controls">' || CHR(10)
            || '    <button class="fc-btn" onclick="prevSlide()" title="Previous slide (Left Arrow)">Previous</button>' || CHR(10)
            || '    <span class="fc-counter" id="slideCounter">1 / ' || l_total || '</span>' || CHR(10)
            || '    <button class="fc-btn" onclick="nextSlide()" title="Next slide (Right Arrow / Space)">Next</button>' || CHR(10)
            || '    <button class="fc-btn fc-btn-hot" onclick="window.print()" title="Print or Save as PDF">Print / PDF</button>' || CHR(10)
            || '  </div>' || CHR(10)
            || '</header>' || CHR(10)
            || '<main class="fc-deck-container">' || CHR(10)
        );

        FOR s IN (SELECT slide_num, slide_title, narrative_focus, key_bullet_points, visual_placeholder_desc
                    FROM fc_pitch_slides WHERE tender_id = p_tender_id ORDER BY slide_num) LOOP
            l_idx := l_idx + 1;
            IF l_idx = 1 THEN
                append_str(
                    '<article class="fc-slide fc-slide-title-card active">' || CHR(10)
                 || '  <div>' || CHR(10)
                 || '    <div class="fc-slide-subtitle">FLASH CONCEPTS · PITCH DECK</div>' || CHR(10)
                 || '    <h1 class="fc-slide-title">' || apex_escape.html(l_title) || '</h1>' || CHR(10)
                 || '    <p class="fc-slide-focus" style="display:inline-block;">Client: ' || apex_escape.html(l_client) || ' · ' || apex_escape.html(s.slide_title) || '</p>' || CHR(10)
                 || '    <div style="margin-top:20px; font-size:15px; color:#c9d1d9; max-width:700px; line-height:1.6;">' || apex_escape.html(s.narrative_focus) || '</div>' || CHR(10)
                 || '  </div>' || CHR(10)
                 || '  <footer class="fc-slide-footer">' || CHR(10)
                 || '    <span>' || apex_escape.html(l_code) || ' · CONFIDENTIAL</span>' || CHR(10)
                 || '    <span>Slide 1 of ' || l_total || '</span>' || CHR(10)
                 || '  </footer>' || CHR(10)
                 || '</article>' || CHR(10)
                );
            ELSE
                append_str(
                    '<article class="fc-slide">' || CHR(10)
                 || '  <div>' || CHR(10)
                 || '    <h2 class="fc-slide-title">' || apex_escape.html(s.slide_title) || '</h2>' || CHR(10)
                 || CASE WHEN s.narrative_focus IS NOT NULL
                         THEN '    <div class="fc-slide-focus"><strong>Focus:</strong> ' || apex_escape.html(s.narrative_focus) || '</div>' || CHR(10)
                    END
                 || '    <div class="fc-slide-body">' || CHR(10)
                 || '      <ul class="fc-slide-bullets">' || CHR(10)
                );

                FOR b IN (SELECT TRIM(REGEXP_REPLACE(COLUMN_VALUE, '^\s*(?|-|\*|' || UNISTR('\FFFD') || ')\s*', '')) AS t
                            FROM TABLE(apex_string.split(s.key_bullet_points, CHR(10)))
                           WHERE TRIM(COLUMN_VALUE) IS NOT NULL) LOOP
                    append_str('        <li>' || apex_escape.html(b.t) || '</li>' || CHR(10));
                END LOOP;

                append_str(
                    '      </ul>' || CHR(10)
                 || CASE WHEN s.visual_placeholder_desc IS NOT NULL
                         THEN '      <div class="fc-slide-visual"><strong>Visual staging:</strong> ' || apex_escape.html(s.visual_placeholder_desc) || '</div>' || CHR(10)
                    END
                 || '    </div>' || CHR(10)
                 || '  </div>' || CHR(10)
                 || '  <footer class="fc-slide-footer">' || CHR(10)
                 || '    <span>' || apex_escape.html(l_code) || ' · ' || apex_escape.html(l_client) || '</span>' || CHR(10)
                 || '    <span>Slide ' || l_idx || ' of ' || l_total || '</span>' || CHR(10)
                 || '  </footer>' || CHR(10)
                 || '</article>' || CHR(10)
                );
            END IF;
        END LOOP;

        append_str(
            '</main>' || CHR(10)
         || '<script>' || CHR(10)
         || 'var cur = 0;' || CHR(10)
         || 'var slides = document.querySelectorAll(".fc-slide");' || CHR(10)
         || 'function updateSlide(i) {' || CHR(10)
         || '  if (i < 0) i = 0;' || CHR(10)
         || '  if (i >= slides.length) i = slides.length - 1;' || CHR(10)
         || '  cur = i;' || CHR(10)
         || '  slides.forEach(function(s, idx) { if (idx === cur) s.classList.add("active"); else s.classList.remove("active"); });' || CHR(10)
         || '  document.getElementById("slideCounter").textContent = (cur + 1) + " / " + slides.length;' || CHR(10)
         || '}' || CHR(10)
         || 'function nextSlide() { updateSlide(cur + 1); }' || CHR(10)
         || 'function prevSlide() { updateSlide(cur - 1); }' || CHR(10)
         || 'document.addEventListener("keydown", function(e) {' || CHR(10)
         || '  if (e.key === "ArrowRight" || e.key === " " || e.key === "PageDown") { nextSlide(); }' || CHR(10)
         || '  if (e.key === "ArrowLeft" || e.key === "PageUp") { prevSlide(); }' || CHR(10)
         || '});' || CHR(10)
         || '</script>' || CHR(10)
         || '</body></html>'
        );

        RETURN to_blob(l_html);
    END build_html;

    FUNCTION build_pdf(p_tender_id IN NUMBER) RETURN BLOB IS
        TYPE t_num_list IS TABLE OF INTEGER INDEX BY PLS_INTEGER;
        l_offsets   t_num_list;
        l_pdf       CLOB;
        l_obj_cnt   PLS_INTEGER := 0;
        l_total     PLS_INTEGER;
        l_code      VARCHAR2(50);
        l_client    VARCHAR2(150);
        l_title     VARCHAR2(250);
        l_dummy     PLS_INTEGER;
        l_f1_id     PLS_INTEGER;
        l_f2_id     PLS_INTEGER;
        l_stream    VARCHAR2(32767);
        l_xref_pos  INTEGER;
        l_idx       PLS_INTEGER := 0;

        PROCEDURE append_str(p_str IN VARCHAR2) IS
        BEGIN
            DBMS_LOB.WRITEAPPEND(l_pdf, LENGTH(p_str), p_str);
        END;

        FUNCTION start_obj RETURN PLS_INTEGER IS
        BEGIN
            l_obj_cnt := l_obj_cnt + 1;
            l_offsets(l_obj_cnt) := DBMS_LOB.GETLENGTH(l_pdf);
            append_str(l_obj_cnt || ' 0 obj' || CHR(10));
            RETURN l_obj_cnt;
        END;

        PROCEDURE end_obj IS
        BEGIN
            append_str('endobj' || CHR(10));
        END;

        FUNCTION esc(p_txt IN VARCHAR2) RETURN VARCHAR2 IS
            l_res VARCHAR2(4000);
        BEGIN
            l_res := SUBSTR(NVL(p_txt, ' '), 1, 150);
            l_res := REPLACE(l_res, '\', '\\');
            l_res := REPLACE(l_res, '(', '\(');
            l_res := REPLACE(l_res, ')', '\)');
            l_res := REGEXP_REPLACE(l_res, '[^ -~]', ' ');
            RETURN l_res;
        END;
    BEGIN
        SELECT tender_code, client_name, project_title INTO l_code, l_client, l_title
          FROM fc_tenders WHERE tender_id = p_tender_id;
        SELECT COUNT(*) INTO l_total FROM fc_pitch_slides WHERE tender_id = p_tender_id;
        IF l_total = 0 THEN
            raise_application_error(-20041, 'Draft the slides first, then export.');
        END IF;

        l_f1_id := 2 + l_total * 2 + 1;
        l_f2_id := 2 + l_total * 2 + 2;

        DBMS_LOB.CREATETEMPORARY(l_pdf, TRUE);
        append_str('%PDF-1.4' || CHR(10));

        -- Obj 1: Catalog
        l_dummy := start_obj;
        append_str('<< /Type /Catalog /Pages 2 0 R >>' || CHR(10));
        end_obj;

        -- Obj 2: Pages
        DECLARE
            l_kids VARCHAR2(4000) := '';
        BEGIN
            FOR i IN 1..l_total LOOP
                l_kids := l_kids || (2 + (i-1)*2 + 1) || ' 0 R ';
            END LOOP;
            l_dummy := start_obj;
            append_str('<< /Type /Pages /Kids [' || TRIM(l_kids) || '] /Count ' || l_total || ' /MediaBox [0 0 792 612] >>' || CHR(10));
            end_obj;
        END;

        -- Slides
        FOR s IN (SELECT slide_num, slide_title, narrative_focus, key_bullet_points, visual_placeholder_desc
                    FROM fc_pitch_slides WHERE tender_id = p_tender_id ORDER BY slide_num) LOOP
            l_idx := l_idx + 1;

            -- Page obj
            l_dummy := start_obj;
            append_str('<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 ' || l_f1_id || ' 0 R /F2 ' || l_f2_id || ' 0 R >> >> /Contents ' || (l_dummy + 1) || ' 0 R >>' || CHR(10));
            end_obj;

            -- Content stream
            IF l_idx = 1 THEN
                -- Title slide (dark brand)
                l_stream := '0.06 0.08 0.12 rg 0 0 792 612 re f' || CHR(10)
                         || '0.21 1.0 0.62 rg 54 530 180 5 re f' || CHR(10)
                         || 'BT /F2 12 Tf 0.21 1.0 0.62 rg 54 505 Td (FLASH CONCEPTS  |  PITCH DECK) Tj ET' || CHR(10)
                         || 'BT /F2 24 Tf 1.0 1.0 1.0 rg 54 440 Td (' || esc(l_title) || ') Tj ET' || CHR(10)
                         || 'BT /F1 15 Tf 0.22 0.74 0.97 rg 54 400 Td (Client: ' || esc(l_client) || ') Tj ET' || CHR(10)
                         || 'BT /F1 12 Tf 0.8 0.85 0.9 rg 54 350 Td (' || esc(s.narrative_focus) || ') Tj ET' || CHR(10)
                         || 'BT /F1 10 Tf 0.5 0.5 0.5 rg 54 40 Td (' || esc(l_code) || '  -  CONFIDENTIAL PROPOSAL) Tj ET' || CHR(10);
            ELSE
                -- Content slide
                l_stream := '0.98 0.99 1.0 rg 0 0 792 612 re f' || CHR(10)
                         || '0.07 0.10 0.15 rg 0 540 792 72 re f' || CHR(10)
                         || '0.21 1.0 0.62 rg 0 537 792 3 re f' || CHR(10)
                         || 'BT /F2 20 Tf 1.0 1.0 1.0 rg 54 570 Td (' || esc(s.slide_title) || ') Tj ET' || CHR(10)
                         || 'BT /F1 12 Tf 0.21 1.0 0.62 rg 710 570 Td (' || l_idx || ' / ' || l_total || ') Tj ET' || CHR(10);

                IF s.narrative_focus IS NOT NULL THEN
                    l_stream := l_stream
                             || '0.92 0.95 0.98 rg 54 475 684 36 re f' || CHR(10)
                             || '0.01 0.42 0.83 rg 54 475 4 36 re f' || CHR(10)
                             || 'BT /F2 11 Tf 0.01 0.42 0.83 rg 68 488 Td (STRATEGIC FOCUS: ' || esc(s.narrative_focus) || ') Tj ET' || CHR(10);
                END IF;

                DECLARE
                    l_y PLS_INTEGER := 440;
                BEGIN
                    FOR b IN (SELECT TRIM(REGEXP_REPLACE(COLUMN_VALUE, '^\s*(?|-|\*|' || UNISTR('\FFFD') || ')\s*', '')) AS t
                                FROM TABLE(apex_string.split(s.key_bullet_points, CHR(10)))
                               WHERE TRIM(COLUMN_VALUE) IS NOT NULL) LOOP
                        EXIT WHEN l_y < 160;
                        l_stream := l_stream
                                 || '0.21 1.0 0.62 rg 58 ' || (l_y + 3) || ' 5 5 re f' || CHR(10)
                                 || 'BT /F1 12 Tf 0.15 0.15 0.15 rg 72 ' || l_y || ' Td (' || esc(b.t) || ') Tj ET' || CHR(10);
                        l_y := l_y - 30;
                    END LOOP;
                END;

                IF s.visual_placeholder_desc IS NOT NULL THEN
                    l_stream := l_stream
                             || '0.95 0.96 0.97 rg 54 90 684 36 re f' || CHR(10)
                             || 'BT /F1 10 Tf 0.85 0.45 0.1 rg 64 102 Td (VISUAL: ' || esc(s.visual_placeholder_desc) || ') Tj ET' || CHR(10);
                END IF;

                -- Footer
                l_stream := l_stream
                         || '0.07 0.10 0.15 rg 0 0 792 36 re f' || CHR(10)
                         || 'BT /F1 10 Tf 0.7 0.7 0.7 rg 54 14 Td (' || esc(l_code) || '  |  ' || esc(l_client) || ') Tj ET' || CHR(10)
                         || 'BT /F1 10 Tf 0.7 0.7 0.7 rg 690 14 Td (Flash Concepts) Tj ET' || CHR(10);
            END IF;

            l_dummy := start_obj;
            append_str('<< /Length ' || LENGTH(l_stream) || ' >>' || CHR(10));
            append_str('stream' || CHR(10));
            append_str(l_stream);
            append_str('endstream' || CHR(10));
            end_obj;
        END LOOP;

        -- Obj font 1
        l_dummy := start_obj;
        append_str('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>' || CHR(10));
        end_obj;

        -- Obj font 2
        l_dummy := start_obj;
        append_str('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>' || CHR(10));
        end_obj;

        -- Xref
        l_xref_pos := DBMS_LOB.GETLENGTH(l_pdf);
        append_str('xref' || CHR(10));
        append_str('0 ' || (l_obj_cnt + 1) || CHR(10));
        append_str('0000000000 65535 f ' || CHR(10));
        FOR i IN 1..l_obj_cnt LOOP
            append_str(TO_CHAR(l_offsets(i), 'FM0000000000') || ' 00000 n ' || CHR(10));
        END LOOP;

        -- Trailer
        append_str('trailer << /Size ' || (l_obj_cnt + 1) || ' /Root 1 0 R >>' || CHR(10));
        append_str('startxref' || CHR(10));
        append_str(l_xref_pos || CHR(10));
        append_str('%%EOF' || CHR(10));

        RETURN to_blob(l_pdf);
    END build_pdf;

    FUNCTION render_preview(p_tender_id IN NUMBER) RETURN CLOB IS
        l_html      CLOB;
        l_srcdoc    CLOB;
        l_total     PLS_INTEGER;
        l_code      VARCHAR2(50) := 'FC-TENDER';
        l_client    VARCHAR2(150) := 'Client';
        l_title     VARCHAR2(250) := 'Executive Pitch Deck';
        l_idx       PLS_INTEGER := 0;

        PROCEDURE append_doc(p_str IN VARCHAR2) IS
        BEGIN
            DBMS_LOB.WRITEAPPEND(l_srcdoc, LENGTH(p_str), p_str);
        END;

        PROCEDURE append_html(p_str IN VARCHAR2) IS
        BEGIN
            DBMS_LOB.WRITEAPPEND(l_html, LENGTH(p_str), p_str);
        END;
    BEGIN
        SELECT COUNT(*) INTO l_total FROM fc_pitch_slides WHERE tender_id = p_tender_id;
        IF l_total = 0 THEN
            RETURN '<div class="fc-deck-empty" style="padding:40px; text-align:center; color:#94a3b8; background:#0f172a; border-radius:12px; border:1px solid #334155; margin:16px 0;">'
                || '<span class="t-Icon fa fa-television" style="font-size:36px; margin-bottom:12px; color:#38bdf8; display:block;" aria-hidden="true"></span>'
                || '<h4 style="color:#f8fafc; margin-bottom:8px;">No Slide Deck Drafts Yet</h4>'
                || '<p style="margin:0;">Click <strong>Draft slides</strong> above to synthesize the 8-slide executive pitch deck using AI.</p>'
                || '</div>';
        END IF;

        BEGIN
            SELECT tender_code, client_name, project_title
              INTO l_code, l_client, l_title
              FROM fc_tenders
             WHERE tender_id = p_tender_id;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;

        -- 1. Construct embedded HTML-PPT viewport srcdoc
        DBMS_LOB.CREATETEMPORARY(l_srcdoc, TRUE);
        append_doc('<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">' || CHR(10)
            || '<meta name="viewport" content="width=device-width, initial-scale=1">' || CHR(10)
            || '<style>' || CHR(10)
            || '* { box-sizing: border-box; margin: 0; padding: 0; }' || CHR(10)
            || 'body { background: #080c14; color: #f1f5f9; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 20px; min-height: 100vh; display: flex; flex-direction: column; }' || CHR(10)
            || '.deck-nav { display: flex; justify-content: space-between; align-items: center; background: #131b2e; border: 1px solid rgba(255,255,255,0.08); border-radius: 8px; padding: 10px 18px; margin-bottom: 16px; }' || CHR(10)
            || '.deck-title { font-weight: 700; color: #38bdf8; font-size: 14px; display: flex; align-items: center; gap: 8px; }' || CHR(10)
            || '.deck-ctrls { display: flex; align-items: center; gap: 8px; }' || CHR(10)
            || '.ctrl-btn { background: #1e293b; border: 1px solid rgba(255,255,255,0.15); color: #e2e8f0; padding: 5px 12px; border-radius: 5px; font-size: 12px; cursor: pointer; font-weight: 600; }' || CHR(10)
            || '.ctrl-btn:hover { background: #334155; }' || CHR(10)
            || '.slide-counter { font-size: 13px; color: #94a3b8; font-variant-numeric: tabular-nums; margin: 0 4px; }' || CHR(10)
            || '.slide-viewport { flex: 1; display: flex; justify-content: center; align-items: center; }' || CHR(10)
            || '.v-slide { width: 100%; max-width: 900px; aspect-ratio: 16 / 9; background: #0f172a; border: 1px solid rgba(255,255,255,0.1); border-radius: 12px; padding: 32px 36px; display: none; flex-direction: column; justify-content: space-between; box-shadow: 0 16px 36px rgba(0,0,0,0.6); position: relative; overflow: hidden; }' || CHR(10)
            || '.v-slide.active { display: flex; }' || CHR(10)
            || '.v-slide::before { content: ""; position: absolute; top: 0; left: 0; right: 0; height: 4px; background: linear-gradient(90deg, #36FF9F, #026BD3); }' || CHR(10)
            || '.v-slide-title { font-size: 22px; font-weight: 700; color: #fff; margin-bottom: 10px; }' || CHR(10)
            || '.v-focus { font-size: 13px; color: #38bdf8; background: rgba(56,189,248,0.1); border-left: 3px solid #38bdf8; padding: 6px 12px; border-radius: 0 4px 4px 0; margin-bottom: 14px; line-height: 1.4; }' || CHR(10)
            || '.v-grid { display: grid; grid-template-columns: 1.15fr 0.85fr; gap: 20px; flex: 1; align-items: center; }' || CHR(10)
            || '@media(max-width: 720px) { .v-grid { grid-template-columns: 1fr; } }' || CHR(10)
            || '.v-bullets { list-style: none; display: flex; flex-direction: column; gap: 10px; }' || CHR(10)
            || '.v-bullets li { position: relative; padding-left: 20px; font-size: 13px; line-height: 1.5; color: #cbd5e1; }' || CHR(10)
            || '.v-bullets li::before { content: ""; position: absolute; left: 2px; top: 7px; width: 7px; height: 7px; border-radius: 50%; background: #36FF9F; box-shadow: 0 0 6px #36FF9F; }' || CHR(10)
            || '.v-render-box { background: #1e293b; border: 1px solid rgba(56,189,248,0.25); border-radius: 8px; overflow: hidden; display: flex; flex-direction: column; }' || CHR(10)
            || '.v-render-img { width: 100%; height: 160px; object-fit: cover; display: block; background: #080c14; }' || CHR(10)
            || '.v-render-caption { padding: 8px 10px; background: rgba(15,23,42,0.95); font-size: 11px; color: #94a3b8; line-height: 1.35; border-top: 1px solid rgba(255,255,255,0.06); }' || CHR(10)
            || '.v-render-caption strong { color: #f59e0b; display: block; font-size: 10px; text-transform: uppercase; margin-bottom: 2px; }' || CHR(10)
            || '.v-footer { display: flex; justify-content: space-between; align-items: center; border-top: 1px solid rgba(255,255,255,0.08); padding-top: 10px; font-size: 11px; color: #64748b; }' || CHR(10)
            || '</style></head><body>' || CHR(10)
            || '<div class="deck-nav">' || CHR(10)
            || '  <div class="deck-title">&#128250; ' || apex_escape.html(l_code) || ' · ' || apex_escape.html(l_client) || '</div>' || CHR(10)
            || '  <div class="deck-ctrls">' || CHR(10)
            || '    <button class="ctrl-btn" onclick="prevSlide()">&#9664; Prev</button>' || CHR(10)
            || '    <span class="slide-counter" id="vCounter">1 / ' || l_total || '</span>' || CHR(10)
            || '    <button class="ctrl-btn" onclick="nextSlide()">Next &#9654;</button>' || CHR(10)
            || '  </div>' || CHR(10)
            || '</div>' || CHR(10)
            || '<div class="slide-viewport">' || CHR(10)
        );

        FOR s IN (SELECT slide_num, slide_title, layout_type, narrative_focus, key_bullet_points, visual_placeholder_desc, image_prompt
                    FROM fc_pitch_slides WHERE tender_id = p_tender_id ORDER BY slide_num) LOOP
            l_idx := l_idx + 1;
            append_doc(
                '<div class="v-slide' || CASE WHEN l_idx = 1 THEN ' active' END || '">' || CHR(10)
             || '  <div>' || CHR(10)
             || '    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">' || CHR(10)
             || '      <span style="font-size:11px; font-weight:700; color:#36FF9F; background:rgba(54,255,159,0.12); padding:3px 8px; border-radius:4px; text-transform:uppercase;">Slide ' || l_idx || ' of ' || l_total || '</span>' || CHR(10)
             || '      <span style="font-size:11px; color:#38bdf8;">' || apex_escape.html(s.layout_type) || '</span>' || CHR(10)
             || '    </div>' || CHR(10)
             || '    <h3 class="v-slide-title">' || apex_escape.html(s.slide_title) || '</h3>' || CHR(10)
             || CASE WHEN s.narrative_focus IS NOT NULL
                     THEN '    <div class="v-focus"><strong>Focus:</strong> ' || apex_escape.html(s.narrative_focus) || '</div>' || CHR(10)
                END
             || '  </div>' || CHR(10)
             || '  <div class="v-grid">' || CHR(10)
             || '    <ul class="v-bullets">' || CHR(10)
            );

            FOR b IN (SELECT TRIM(REGEXP_REPLACE(COLUMN_VALUE, '^\s*(?|-|\*|' || UNISTR('\FFFD') || ')\s*', '')) AS t
                        FROM TABLE(apex_string.split(s.key_bullet_points, CHR(10)))
                       WHERE TRIM(COLUMN_VALUE) IS NOT NULL) LOOP
                append_doc('      <li>' || apex_escape.html(b.t) || '</li>' || CHR(10));
            END LOOP;

            append_doc(
                '    </ul>' || CHR(10)
             || '    <div class="v-render-box">' || CHR(10)
             || '      <img class="v-render-img" src="https://image.pollinations.ai/prompt/' || apex_util.url_encode(NVL(s.image_prompt, 'futuristic corporate stage Singapore event MICE render')) || '?width=600&height=340&nologo=true&enhance=true" alt="AI Staging Render" loading="lazy" />' || CHR(10)
             || '      <div class="v-render-caption">' || CHR(10)
             || '        <strong>AI Staging Blueprint</strong>' || CHR(10)
             || '        ' || apex_escape.html(NVL(SUBSTR(s.visual_placeholder_desc, 1, 140), 'Spatial and lighting staging brief')) || CHR(10)
             || '      </div>' || CHR(10)
             || '    </div>' || CHR(10)
             || '  </div>' || CHR(10)
             || '  <div class="v-footer">' || CHR(10)
             || '    <span>' || apex_escape.html(l_code) || ' · Flash Concepts Proposal</span>' || CHR(10)
             || '    <span>Slide ' || l_idx || ' / ' || l_total || '</span>' || CHR(10)
             || '  </div>' || CHR(10)
             || '</div>' || CHR(10)
            );
        END LOOP;

        append_doc(
            '</div>' || CHR(10)
         || '<script>' || CHR(10)
         || 'var c = 0;' || CHR(10)
         || 'var sl = document.querySelectorAll(".v-slide");' || CHR(10)
         || 'function go(i) {' || CHR(10)
         || '  if (i < 0) i = 0;' || CHR(10)
         || '  if (i >= sl.length) i = sl.length - 1;' || CHR(10)
         || '  c = i;' || CHR(10)
         || '  sl.forEach(function(s, idx) { if (idx === c) s.classList.add("active"); else s.classList.remove("active"); });' || CHR(10)
         || '  document.getElementById("vCounter").textContent = (c + 1) + " / " + sl.length;' || CHR(10)
         || '}' || CHR(10)
         || 'function nextSlide() { go(c + 1); }' || CHR(10)
         || 'function prevSlide() { go(c - 1); }' || CHR(10)
         || 'document.addEventListener("keydown", function(e) {' || CHR(10)
         || '  if (e.key === "ArrowRight" || e.key === " " || e.key === "PageDown") nextSlide();' || CHR(10)
         || '  if (e.key === "ArrowLeft" || e.key === "PageUp") prevSlide();' || CHR(10)
         || '});' || CHR(10)
         || '</script></body></html>'
        );

        -- 2. Build Mini-Browser Viewport Container with macOS window chrome
        DBMS_LOB.CREATETEMPORARY(l_html, TRUE);

        append_html(
            '<div class="fc-mini-browser" style="background:#131b2e; border-radius:12px; overflow:hidden; border:1px solid #334155; margin-bottom:20px; box-shadow:0 12px 30px rgba(0,0,0,0.4);">'
         || '  <div style="background:#090d16; padding:10px 16px; display:flex; align-items:center; gap:12px; border-bottom:1px solid #243049; flex-wrap:wrap;">'
         || '    <div style="display:flex; gap:6px;">'
         || '      <span style="width:12px; height:12px; border-radius:50%; background:#ef4444; display:inline-block;"></span>'
         || '      <span style="width:12px; height:12px; border-radius:50%; background:#f59e0b; display:inline-block;"></span>'
         || '      <span style="width:12px; height:12px; border-radius:50%; background:#10b981; display:inline-block;"></span>'
         || '    </div>'
         || '    <div style="flex:1; min-width:200px; background:#162035; border-radius:6px; padding:6px 14px; font-family:monospace; font-size:12px; color:#94a3b8; display:flex; align-items:center; gap:8px;">'
         || '      <span style="color:#10b981; font-weight:700;">[SSL]</span>'
         || '      <span>https://deck.flashconcepts.sg/pitches/' || apex_escape.html(l_code) || '.html</span>'
         || '    </div>'
         || '    <div class="fc-deck-actions" style="display:inline-flex; gap:8px; flex-wrap:wrap;">'
         || '      <button type="button" class="t-Button t-Button--hot t-Button--small" onclick="fcExportDeck(''EXPORT_PPTX'');">'
         || '        <span class="t-Icon fa fa-file-powerpoint-o" aria-hidden="true"></span> PowerPoint (.pptx)</button>'
         || '      <button type="button" class="t-Button t-Button--small" onclick="fcExportDeck(''EXPORT_HTML'');">'
         || '        <span class="t-Icon fa fa-file-code-o" aria-hidden="true"></span> HTML Deck (.html)</button>'
         || '      <button type="button" class="t-Button t-Button--small" onclick="fcExportDeck(''EXPORT_PDF'');">'
         || '        <span class="t-Icon fa fa-file-pdf-o" aria-hidden="true"></span> PDF (.pdf)</button>'
         || '    </div>'
         || '  </div>'
         || '  <iframe id="slide-presentation-viewport" name="slide-presentation-viewport" style="width:100%; height:520px; border:none; display:block;" title="Interactive HTML-PPT Viewport"></iframe>'
         || '  <template id="fc-deck-template">'
        );

        DBMS_LOB.APPEND(l_html, l_srcdoc);

        append_html(
            '  </template>'
         || '  <script>'
         || '  function fcExportDeck(req) {'
         || '    var tid = $v("P4_TENDER_ID") || "' || p_tender_id || '";'
         || '    var flow = $v("pFlowId") || "101";'
         || '    var inst = $v("pInstance") || "";'
         || '    window.location.href = "f?p=" + flow + ":4:" + inst + ":" + req + ":::P4_TENDER_ID:" + tid;'
         || '  }'
         || '  (function() {'
         || '    var ifr = document.getElementById("slide-presentation-viewport");'
         || '    var tmpl = document.getElementById("fc-deck-template");'
         || '    if (ifr && tmpl) {'
         || '      ifr.srcdoc = tmpl.innerHTML;'
         || '    }'
         || '  })();'
         || '  </script>'
         || '</div>'
        );

        -- 3. Slide Breakdown Cards
        append_html('<div class="fc-deck">');
        FOR s IN (SELECT slide_num, slide_title, narrative_focus, key_bullet_points, visual_placeholder_desc
                    FROM fc_pitch_slides WHERE tender_id = p_tender_id ORDER BY slide_num) LOOP
            append_html('<article class="fc-slide' || CASE WHEN s.slide_num = 1 THEN ' fc-slide--title' END || '">'
                   || '<span class="fc-slide-num">' || s.slide_num || ' / ' || l_total || '</span>'
                   || '<h3 class="fc-slide-title">' || apex_escape.html(s.slide_title) || '</h3>'
                   || CASE WHEN s.narrative_focus IS NOT NULL THEN '<p class="fc-slide-focus">' || apex_escape.html(s.narrative_focus) || '</p>' END
                   || '<ul class="fc-slide-bullets">');
            FOR b IN (SELECT TRIM(REGEXP_REPLACE(COLUMN_VALUE, '^\s*(?|-|\*|' || UNISTR('\FFFD') || ')\s*', '')) AS t
                        FROM TABLE(apex_string.split(s.key_bullet_points, CHR(10)))
                       WHERE TRIM(COLUMN_VALUE) IS NOT NULL) LOOP
                append_html('<li>' || apex_escape.html(b.t) || '</li>');
            END LOOP;
            append_html('</ul>'
                   || CASE WHEN s.visual_placeholder_desc IS NOT NULL
                           THEN '<p class="fc-slide-visual"><strong>Visual:</strong> ' || apex_escape.html(s.visual_placeholder_desc) || '</p>' END
                   || '</article>');
        END LOOP;
        append_html('</div>');
        RETURN l_html;
    END render_preview;

END fc_deck_api;
/
