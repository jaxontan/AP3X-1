// Flash Concepts APEX Client Enhancements, Language Translation & Accessibility Guard
(function() {
    'use strict';

    // 1. Accessibility Guard
    function fixAriaLabels() {
        document.querySelectorAll('button.t-Button--navBar, button.t-Button--header').forEach(function(btn) {
            var labelEl = btn.querySelector('.t-Button-label');
            var text = labelEl ? labelEl.textContent.trim() : (btn.textContent ? btn.textContent.trim() : '');
            var title = btn.getAttribute('title') || '';
            btn.setAttribute('aria-label', text || title || 'User Account Menu');
        });
    }

    // 2. English <-> Bahasa Translation Dictionary
    var FC_DICT = {
        // Navigation Menu & Top Bar
        "Dashboard": "Dasbor Proyek",
        "Tender Intake": "Penerimaan Tender",
        "Planning Studio": "Studio Perencanaan",
        "Design & Spatial": "Desain & Tata Ruang",
        "Operations & Costing": "Operasional & Biaya",
        "Review & Submission": "Tinjauan & Pengajuan",
        "Repositories": "Repositori Dokumen",
        "Audit & Administration": "Audit & Administrasi",
        "Executive Financials": "Keuangan Eksekutif",
        "Projects & Pipeline": "Proyek & Alur Kerja",
        "Sign Out": "Keluar",
        "Administration": "Administrasi",

        // Page 2: Tender Intake & Details
        "1. Tender details": "1. Rincian Tender",
        "2. Upload client brief": "2. Unggah Dokumen Brief",
        "3. Client research": "3. Riset Klien",
        "New tender": "Tender Baru",
        "Create tender": "Buat Tender",
        "Load tender": "Muat Tender",
        "Save details": "Simpan Rincian",
        "Add addendum": "Tambah Adendum",
        "Process addendum": "Proses Adendum",
        "Confirm brief (Gate 0)": "Konfirmasi Brief (Gerbang 0)",
        "CONFIRM BRIEF (GATE 0)": "KONFIRMASI BRIEF (GERBANG 0)",
        "GATE 0 STATUS: PENDING VERIFICATION": "STATUS GERBANG 0: MENUNGGU VERIFIKASI",
        "GATE 0 STATUS: CONFIRMED & VERIFIED": "STATUS GERBANG 0: TERKONFIRMASI",
        "PENDING GATE 0": "MENUNGGU GERBANG 0",
        "GATE 0 CONFIRMED": "GERBANG 0 TERKONFIRMASI",
        "Check the brief requirements and planning risks below, then click Confirm brief (Gate 0).": "Periksa persyaratan brief dan risiko perencanaan di bawah ini, lalu klik Konfirmasi brief (Gerbang 0).",
        "Open an existing tender": "Pilih tender yang ada",
        "Project Title": "Judul Proyek",
        "Client": "Klien",
        "Client type": "Jenis Klien",
        "Existing Customer": "Pelanggan Lama",
        "New Customer": "Pelanggan Baru",
        "Office": "Kantor Cabang",
        "Singapore (HQ)": "Singapura (Pusat)",
        "Jakarta": "Jakarta",
        "Client budget (SGD)": "Anggaran Klien (SGD)",
        "Target margin (%)": "Target Margin (%)",
        "Venue teardown deadline": "Batas Waktu Pembongkaran Lokasi",

        // Upload & AI Analysis
        "Drop Brief Document (PDF, Word, DWG) Here": "Tarik & Letakkan Dokumen Brief (PDF, Word, DWG) di Sini",
        "Upload tender specifications, floorplans, or client RFP addenda": "Unggah spesifikasi tender, denah lantai, atau adendum RFP klien",
        "Document type": "Jenis Dokumen",
        "Tender Brief / RFP": "Brief Tender / RFP",
        "Or use a file already in the library": "Atau gunakan dokumen dari pustaka",
        "Analyse brief": "Analisis Brief",

        // AI Client Deep-Search Card
        "AI Client Deep-Search": "Pencarian Mendalam Klien Berbasis AI",
        "What do you want to know about the client?": "Apa yang ingin Anda ketahui tentang klien?",
        "Quick prompts:": "Perintah cepat:",
        "Research focus": "Fokus Riset",
        "Search client info": "Cari Informasi Klien",
        "Company strategy and priorities": "Strategi dan prioritas perusahaan",
        "Recent ESG sustainability targets and net-zero commitments": "Target keberlanjutan ESG dan komitmen net-zero terkini",
        "Executive leadership priorities and corporate strategy announcements": "Prioritas kepemimpinan eksekutif dan pengumuman strategi",
        "MAS regulatory compliance standards and governance history": "Standar kepatuhan regulasi MAS dan riwayat tata kelola",
        "Digital transformation and spatial technology roadmap": "Peta jalan transformasi digital dan teknologi tata ruang",

        // Dossier Tabs
        "Tender Dossier & AI Intelligence Hub": "Berkas Tender & Pusat Inteligensi AI",
        "Brief requirements": "Persyaratan Brief",
        "Research sources": "Sumber Riset",
        "Planning risks": "Risiko Perencanaan",
        "Documents": "Dokumen",
        "Past pitches": "Arsip Presentasi",

        // Table Column Headings & Badges
        "Category": "Kategori",
        "Criterion / Label": "Kriteria / Label",
        "AI Extracted Fact": "Fakta Ekstraksi AI",
        "Confirmed Value": "Nilai Terkonfirmasi",
        "Status": "Status",
        "Confirmed": "Terkonfirmasi",
        "Edited": "Telah Diubah",
        "Pending": "Menunggu",
        "Approved": "Disetujui",
        "Rejected": "Ditolak",
        "Active": "Aktif",
        "Acknowledged": "Diakui",
        "Mitigated": "Dimitigasi",
        "Resolved": "Selesai",
        "Critical": "Kritis",
        "Warning": "Peringatan",
        "Advisory": "Penasehat",
        "Verified Fact / Initiative": "Fakta / Inisiatif Terverifikasi",
        "Confidence": "Tingkat Keyakinan",
        "Source": "Sumber",
        "Citation Link": "Tautan Rujukan",
        "Research Topic": "Topik Riset",
        "Planning Flag": "Indikator Risiko",
        "Operational Impact": "Dampak Operasional",
        "Recommended Action": "Tindakan yang Disarankan",
        "File Name": "Nama Berkas",
        "Uploaded By": "Diunggah Oleh",
        "Upload Date": "Tanggal Unggah",
        "Event Title": "Judul Acara",
        "Client Name": "Nama Klien",
        "Event Year": "Tahun Acara",
        "Venue": "Lokasi Acara",

        // Page 3 & Planning Studio
        "Concept options": "Pilihan Konsep",
        "Generate concepts": "Buat Konsep",
        "Generate AI concepts": "Buat Konsep Berbasis AI",
        "Build handover": "Bangun Serah Terima",
        "Approve Gate 1 and hand over": "Setujui Gerbang 1 & Serahkan",
        "Reject Gate 1": "Tolak Gerbang 1",
        "Edit Concept / Reprompt": "Ubah Konsep / Perintah Ulang",
        "Reprompt with AI": "Perintah Ulang dengan AI",
        "Save Changes": "Simpan Perubahan",
        "Cancel": "Batal",
        "Close": "Tutup",
        "Select as Hero": "Pilih sebagai Hero",
        "Selected as Hero": "Terpilih sebagai Hero",
        "Select Winning Concept": "Pilih Konsep Pemenang",
        "Edit Concept & Creative Reprompt": "Ubah Konsep & Perintah Ulang Kreatif",
        "Editing Concept Option": "Mengubah Pilihan Konsep",
        "AI Reprompt Instructions": "Instruksi Perintah Ulang AI",
        "Concept Title": "Judul Konsep",
        "Creative Narrative Framing": "Kerangka Narasi Kreatif",
        "Space & Clearance Guidelines": "Panduan Ruang & Jarak Bebas",
        "Run of Show / Event Flow": "Alur Acara / Susunan Acara",
        "Why it fits the brief": "Kesesuaian dengan brief",
        "Space and clearance": "Ruang dan jarak bebas",
        "Run of show": "Alur acara",
        "Fringe activities": "Aktivitas pendukung",
        "Visual brief for the design team": "Brief visual untuk tim desain",
        "GATE 1 PLANNING STATUS: IN REVIEW (PENDING MICHELLE SIGN-OFF)": "STATUS GERBANG 1: DALAM TINJAUAN (MENUNGGU PERSETUJUAN MICHELLE)",
        "GATE 1 PLANNING STATUS: SIGNED OFF & APPROVED": "STATUS GERBANG 1: TELAH DISETUJUI",
        "PENDING GATE 1": "MENUNGGU GERBANG 1",
        "STAGE 2: DESIGN READY": "TAHAP 2: SIAP DESAIN",
        "Team handover tasks": "Tugas Serah Terima Tim",
        "Venue and safety flags": "Indikator Lokasi & Keselamatan",
        "Tender and concept": "Tender dan Konsep",
        "Concept to select": "Konsep yang Dipilih",
        "Gate 1 comments": "Komentar Gerbang 1",
        "Handover language": "Bahasa Serah Terima",
        "Concept Ideation": "Pengembangan Konsep",
        "Selected Concept": "Konsep Terpilih",
        "Narrative & USPs": "Naratif & Keunggulan",
        "Approve Gate 1": "Setujui Gerbang 1",
        "Gate 1 Planning Sign-Off": "Persetujuan Perencanaan Gerbang 1",
        "Deal Closed": "Kesepakatan Berhasil",
        "Failed": "Gagal",
        "Expired": "Kedaluwarsa"
    };

    // Build Reverse Dictionary (Bahasa -> English)
    var FC_REV_DICT = {};
    Object.keys(FC_DICT).forEach(function(k) {
        FC_REV_DICT[FC_DICT[k]] = k;
    });

    // 3. Translation Engine
    function translateDOM(targetLang) {
        var dict = (targetLang === 'id') ? FC_DICT : FC_REV_DICT;

        // Translate text nodes
        var walker = document.createTreeWalker(
            document.body,
            NodeFilter.SHOW_TEXT,
            {
                acceptNode: function(node) {
                    if (!node.nodeValue || !node.nodeValue.trim()) return NodeFilter.FILTER_REJECT;
                    var parent = node.parentElement;
                    if (!parent) return NodeFilter.FILTER_REJECT;
                    var tag = parent.tagName.toLowerCase();
                    if (tag === 'script' || tag === 'style' || tag === 'code' || tag === 'pre') {
                        return NodeFilter.FILTER_REJECT;
                    }
                    if (parent.closest('#fcLangToggleBtn, .fc-lang-btn, .goog-te-combo')) {
                        return NodeFilter.FILTER_REJECT;
                    }
                    return NodeFilter.FILTER_ACCEPT;
                }
            },
            false
        );

        var node;
        while ((node = walker.nextNode())) {
            var orig = node.nodeValue.trim();
            if (dict[orig]) {
                node.nodeValue = node.nodeValue.replace(orig, dict[orig]);
            }
        }

        // Translate placeholders
        document.querySelectorAll('input[placeholder], textarea[placeholder]').forEach(function(el) {
            var ph = el.getAttribute('placeholder').trim();
            if (dict[ph]) {
                el.setAttribute('placeholder', dict[ph]);
            }
        });

        // Translate select options
        document.querySelectorAll('select option').forEach(function(opt) {
            var text = opt.textContent.trim();
            if (dict[text]) {
                opt.textContent = dict[text];
            }
        });

        // Update header switcher label
        updateSwitcherLabel(targetLang);
    }

    function updateSwitcherLabel(lang) {
        var labelText = (lang === 'id') ? 'English' : 'Bahasa';
        var activeBadge = (lang === 'id') ? ' [ID]' : ' [EN]';

        document.querySelectorAll('.fc-lang-btn, #fcLangToggleBtn, a[href*="fcToggleLanguage"]').forEach(function(btn) {
            var labelEl = btn.querySelector('.t-Button-label, span:last-child');
            if (labelEl) {
                labelEl.innerHTML = '<span class="fa fa-globe" aria-hidden="true"></span> ' + labelText + activeBadge;
            } else {
                btn.innerHTML = '<span class="fa fa-globe" aria-hidden="true"></span> ' + labelText + activeBadge;
            }
            btn.setAttribute('title', 'Switch to ' + labelText);
        });
    }

    // 4. Global Language Toggle Function
    window.fcToggleLanguage = function() {
        var current = localStorage.getItem('fc_app_lang') || 'en';
        var target = (current === 'en') ? 'id' : 'en';

        localStorage.setItem('fc_app_lang', target);
        document.cookie = 'googtrans=/en/' + target + '; path=/;';

        translateDOM(target);

        if (typeof apex !== 'undefined' && apex.message) {
            var msg = (target === 'id')
                ? 'Bahasa aplikasi diubah ke Bahasa Indonesia.'
                : 'Application language switched to English.';
            apex.message.showPageSuccess(msg);
            setTimeout(function() { apex.message.hidePageSuccess(); }, 2500);
        }
    };

    // 5. Initialize on load & on APEX ready
    function initLanguage() {
        fixAriaLabels();
        var savedLang = localStorage.getItem('fc_app_lang') || 'en';
        if (savedLang === 'id') {
            translateDOM('id');
        } else {
            updateSwitcherLabel('en');
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initLanguage);
    } else {
        initLanguage();
    }

    if (typeof apex !== 'undefined' && apex.jQuery) {
        apex.jQuery(document).on('apexready', initLanguage);
        apex.jQuery(document).on('apexafterrefresh', function() {
            var savedLang = localStorage.getItem('fc_app_lang') || 'en';
            if (savedLang === 'id') {
                translateDOM('id');
            }
        });
        apex.jQuery(document).on('click', '.t-Tabs-link', function() {
            setTimeout(function() {
                var savedLang = localStorage.getItem('fc_app_lang') || 'en';
                if (savedLang === 'id') {
                    translateDOM('id');
                }
            }, 100);
        });
    }

    // 6. Planning Studio (Page 3) Concept Modal & Selection Helpers
    window.openConceptEditModal = function(conceptId, optionCode) {
        if (typeof apex !== 'undefined' && apex.server) {
            apex.server.process('Fetch Concept Option Details', {
                x01: conceptId
            }, {
                success: function(data) {
                    if (data && !data.error) {
                        if (apex.item('P3_EDIT_CONCEPT_ID')) apex.item('P3_EDIT_CONCEPT_ID').setValue(data.concept_id);
                        if (apex.item('P3_EDIT_OPTION_CODE')) apex.item('P3_EDIT_OPTION_CODE').setValue('Option ' + data.option_code + ': ' + data.title);
                        if (apex.item('P3_EDIT_TITLE')) apex.item('P3_EDIT_TITLE').setValue(data.title || '');
                        if (apex.item('P3_EDIT_NARRATIVE')) apex.item('P3_EDIT_NARRATIVE').setValue(data.narrative || '');
                        if (apex.item('P3_EDIT_SPATIAL')) apex.item('P3_EDIT_SPATIAL').setValue(data.spatial || '');
                        if (apex.item('P3_EDIT_EVENT_FLOW')) apex.item('P3_EDIT_EVENT_FLOW').setValue(data.event_flow || '');
                        if (apex.item('P3_REPROMPT_INSTRUCTION')) apex.item('P3_REPROMPT_INSTRUCTION').setValue('');

                        var modalEl = document.getElementById('fc-concept-modal-region');
                        if (modalEl) {
                            modalEl.style.display = 'block';
                            modalEl.scrollIntoView({ behavior: 'smooth', block: 'start' });
                        }
                    } else if (data && data.error) {
                        apex.message.showErrors([{ type: 'error', location: 'page', message: data.error }]);
                    }
                },
                error: function(err) {
                    console.error('Failed to load concept details', err);
                }
            });
        }
    };

    window.closeConceptEditModal = function() {
        var modalEl = document.getElementById('fc-concept-modal-region');
        if (modalEl) {
            modalEl.style.display = 'none';
        }
    };

    window.selectConceptCard = function(conceptId, optionCode) {
        if (typeof apex !== 'undefined') {
            if (apex.item('P3_CONCEPT_ID')) {
                apex.item('P3_CONCEPT_ID').setValue(conceptId);
            }
            apex.submit('SELECT_CONCEPT');
        }
    };

    // 7. Feature Info & AI Status Mini-Modal System
    window.FC_FEATURE_INFO = {
        "slide-decks": {
            title: "Slide Decks & Pitch Drafts",
            module: "Page 4 • Design & Spatial Studio",
            icon: "fa-television",
            isAi: true,
            purpose: "Generates interactive 16:9 presentation previews and downloadable PowerPoint (.pptx) or standalone HTML pitch decks for client presentations. Allows spatial designers to verify visual storytelling flow and spatial renderings before executive review.",
            currentEngine: "Generative Pitch Agent powered by LLM narrative synthesis.",
            aiStatus: "✨ AI-Enabled",
            aiDetail: "The Generative Pitch Agent automatically drafts an 8-slide strategic narrative, tailors messaging to client priorities, structures spatial concepts, and formulates visual prompts for 3D renderings."
        },
        "fit-clearance": {
            title: "3D Fit & Clearance Checks",
            module: "Page 4 • Design & Spatial Studio",
            icon: "fa-cube",
            isAi: false,
            purpose: "Evaluates physical exhibition structures, keynote stages, and LED truss rigs against venue boundary dimensions, maximum ceiling heights, and statutory Singapore SCDF emergency egress corridors (minimum 3.0m).",
            currentEngine: "Deterministic geometric collision algorithm (fc_spatial_api.evaluate_spatial_fit).",
            aiStatus: "ℹ️ Rule-Based Engine (AI Planned)",
            aiDetail: "Currently calculates clearances mathematically based on venue boundary data. Planned AI: 3D Computer Vision AI for automated point-cloud clash detection against venue BIM/IFC models and rigging point weight load simulations."
        },
        "drawing-packages": {
            title: "Drawing Packages & CAD Repository",
            module: "Page 4 • Design & Spatial Studio",
            icon: "fa-file-code-o",
            isAi: false,
            purpose: "Official drawing package repository for spatial designers to register and version-control AutoCAD DWG, DXF, PDF, and ZIP blueprints. Enforces revision tracking (v1.0, v1.1) and triggers automated STALE alerts on downstream operations BOQ items upon drawing changes.",
            currentEngine: "Relational document repository with SHA-256 verification and version audit trails.",
            aiStatus: "ℹ️ Rule-Based Engine (AI Planned)",
            aiDetail: "Currently tracks file uploads, versions, and downstream status cascades. Planned AI: Multimodal CAD-LLM Parser to automatically read AutoCAD DWG layer manifests, detect fabrication materials, and extract structural dimensions directly into costing."
        },
        "design-brief": {
            title: "Design Brief & Planning Handoff",
            module: "Page 4 • Design & Spatial Studio",
            icon: "fa-newspaper-o",
            isAi: false,
            purpose: "Displays creative guidelines, client RFP assumptions, and spatial directives handed over from the Planning Studio (Michelle Lee) to Spatial Designers (Adi Nugroho) following Gate 1 concept sign-off.",
            currentEngine: "Structured relational task matrix (FC_HANDOVER_ITEMS) and Gate 1 state transitions.",
            aiStatus: "ℹ️ Rule-Based Engine (AI Planned)",
            aiDetail: "Currently displays structured handover records. Planned AI: Generative RFP Addenda Reconciliation Agent to automatically audit new client RFP amendments against active design assumptions and highlight required design pivots."
        },
        "brief-upload": {
            title: "Tender Brief Intake & Analysis",
            module: "Page 2 • Tender Intake",
            icon: "fa-cloud-upload",
            isAi: true,
            purpose: "Ingests client RFP briefs, tender PDFs, and specification documents to extract structured deliverables, event dates, venue constraints, and budget guidelines.",
            currentEngine: "Document parsing engine coupled with LLM tender extraction pipeline.",
            aiStatus: "✨ AI-Enabled",
            aiDetail: "Extracts key project scope, identifies unstated assumptions, flags operational risks, and seeds the tender dossier with structured requirements."
        },
        "client-deep-search": {
            title: "AI Client Deep-Search",
            module: "Page 2 • Tender Intake",
            icon: "fa-search-plus",
            isAi: true,
            purpose: "Performs deep intelligence research on the prospective client, corporate ESG sustainability commitments, leadership strategic goals, and previous event pitch history.",
            currentEngine: "Autonomous RAG retrieval and web intelligence synthesis agent.",
            aiStatus: "✨ AI-Enabled",
            aiDetail: "Synthesizes company background, executive initiatives, and past winning event angles to equip planners with high-impact strategic pitch hooks."
        },
        "concept-ideation": {
            title: "AI Concept Ideation & Studio",
            module: "Page 3 • Planning Studio",
            icon: "fa-lightbulb-o",
            isAi: true,
            purpose: "Generates creative thematic concepts, visitor journey narratives, spatial flow recommendations, and run-of-show suggestions aligned with tender specifications.",
            currentEngine: "Creative Direction LLM Agent (FC_PLANNING_API.GENERATE_AI_CONCEPTS).",
            aiStatus: "✨ AI-Enabled",
            aiDetail: "Generates 3 distinct thematic concepts with USP hooks, spatial layouts, and interactive reprompting to refine creative narratives."
        },
        "boq-decoding": {
            title: "Spatial-to-BOQ AI Decoder",
            module: "Page 5 • Operations & Costing",
            icon: "fa-calculator",
            isAi: true,
            purpose: "Translates 3D spatial models and structure packages into detailed Bill of Quantities (BOQ) line items for carpentry, AV equipment, lighting, and finishes.",
            currentEngine: "Generative Estimation Engine (FC_COSTING_API.RUN_AI_BOQ_DECODER).",
            aiStatus: "✨ AI-Enabled",
            aiDetail: "Automatically maps spatial objects to master cost rate cards, computes labor allowances, and applies corporate margin governance."
        },
        "bespoke-rfqs": {
            title: "Bespoke RFQ Synthesis",
            module: "Page 5 • Operations & Costing",
            icon: "fa-envelope-open-o",
            isAi: true,
            purpose: "Generates tailored Request for Quotation (RFQ) packages and scopes of work to dispatch to specialized fabrication subcontractors and AV vendors.",
            currentEngine: "Vendor Procurement Assistant (FC_COSTING_API.GENERATE_BESPOKE_RFQS).",
            aiStatus: "✨ AI-Enabled",
            aiDetail: "Synthesizes trade-specific RFQ documents with fabrication tolerances, material specifications, and delivery milestones."
        },
        "copy-quality-review": {
            title: "Proposal Copy & Quality Audit",
            module: "Page 6 • Review & Submission",
            icon: "fa-check-square-o",
            isAi: true,
            purpose: "Audits tender proposal narratives, verifies executive summary messaging, enforces corporate brand guidelines, and fact-checks pitch claims.",
            currentEngine: "Editorial & Compliance LLM Auditor (FC_WORKFLOW_API.RUN_COPY_AUDIT).",
            aiStatus: "✨ AI-Enabled",
            aiDetail: "Performs brand tone audits, checks consistency across proposal sections, flags unsupported claims, and verifies statutory compliance statements."
        },
        "export-pack": {
            title: "Presentation Pack & Export",
            module: "Page 6 • Review & Submission",
            icon: "fa-file-pdf-o",
            isAi: false,
            purpose: "Compiles final sign-offs, high-resolution rendering packages, and costing summaries into client-ready submission deliverables.",
            currentEngine: "Server-side document compilation and export packager.",
            aiStatus: "ℹ️ Rule-Based Engine (AI Planned)",
            aiDetail: "Currently bundles confirmed proposal artifacts into zip/pdf exports. Planned AI: Intelligent Executive Brief Generator to synthesize personalized 2-page decision summaries for each stakeholder role."
        }
    };

    function ensureInfoModalDOM() {
        var existing = document.getElementById('fc-info-modal-backdrop');
        if (existing) return existing;

        var backdrop = document.createElement('div');
        backdrop.id = 'fc-info-modal-backdrop';
        backdrop.className = 'fc-info-modal-backdrop';
        backdrop.setAttribute('role', 'dialog');
        backdrop.setAttribute('aria-modal', 'true');
        backdrop.setAttribute('aria-labelledby', 'fc-modal-title');

        backdrop.innerHTML = [
            '<div class="fc-info-modal-card" id="fc-info-modal-card">',
            '  <div class="fc-info-modal-header">',
            '    <div class="fc-info-modal-title-group">',
            '      <div class="fc-info-modal-icon-badge" id="fc-modal-icon"><span class="fa fa-info"></span></div>',
            '      <div>',
            '        <h3 class="fc-info-modal-title" id="fc-modal-title">Feature Details</h3>',
            '        <div class="fc-info-modal-subtitle" id="fc-modal-module">Module</div>',
            '      </div>',
            '    </div>',
            '    <button type="button" class="fc-info-modal-close" aria-label="Close dialog" onclick="fcCloseFeatureInfo();">&times;</button>',
            '  </div>',
            '  <div class="fc-info-modal-body">',
            '    <div id="fc-modal-badge" class="fc-modal-badge"></div>',
            '    <div class="fc-info-section">',
            '      <div class="fc-info-section-title"><span class="fa fa-bullseye" aria-hidden="true"></span> Feature Purpose &amp; Value</div>',
            '      <p class="fc-info-section-p" id="fc-modal-purpose"></p>',
            '    </div>',
            '    <div class="fc-info-section">',
            '      <div class="fc-info-section-title"><span class="fa fa-microchip" aria-hidden="true"></span> Engine &amp; AI Intelligence</div>',
            '      <div class="fc-info-ai-box" id="fc-modal-ai-box"></div>',
            '    </div>',
            '  </div>',
            '  <div class="fc-info-modal-footer">',
            '    <button type="button" class="fc-info-modal-btn-primary" onclick="fcCloseFeatureInfo();">Got it</button>',
            '  </div>',
            '</div>'
        ].join('');

        backdrop.addEventListener('click', function(e) {
            if (e.target === backdrop) {
                window.fcCloseFeatureInfo();
            }
        });

        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                var bd = document.getElementById('fc-info-modal-backdrop');
                if (bd && bd.classList.contains('is-active')) {
                    window.fcCloseFeatureInfo();
                }
            }
        });

        document.body.appendChild(backdrop);
        return backdrop;
    }

    window.fcShowFeatureInfo = function(key) {
        var item = window.FC_FEATURE_INFO[key];
        if (!item) {
            console.warn('Unknown feature info key:', key);
            return;
        }

        var backdrop = ensureInfoModalDOM();
        var iconEl = document.getElementById('fc-modal-icon');
        var titleEl = document.getElementById('fc-modal-title');
        var moduleEl = document.getElementById('fc-modal-module');
        var badgeEl = document.getElementById('fc-modal-badge');
        var purposeEl = document.getElementById('fc-modal-purpose');
        var aiBoxEl = document.getElementById('fc-modal-ai-box');

        titleEl.textContent = item.title;
        moduleEl.textContent = item.module;
        purposeEl.textContent = item.purpose;

        if (item.isAi) {
            iconEl.className = 'fc-info-modal-icon-badge fc-info-modal-icon-badge--ai';
            iconEl.innerHTML = '<span class="fa ' + item.icon + '" aria-hidden="true"></span>';
            badgeEl.className = 'fc-modal-badge fc-modal-badge--ai';
            badgeEl.innerHTML = '<span class="fa fa-magic"></span> <strong>AI-Enabled</strong> &bull; Generative Agent Active';
            aiBoxEl.className = 'fc-info-ai-box fc-info-ai-box--active';
            aiBoxEl.innerHTML = '<div><strong>Current Engine:</strong> ' + item.currentEngine + '</div><div style="margin-top:8px;"><strong>✨ AI Capability:</strong> ' + item.aiDetail + '</div>';
        } else {
            iconEl.className = 'fc-info-modal-icon-badge';
            iconEl.innerHTML = '<span class="fa ' + item.icon + '" aria-hidden="true"></span>';
            badgeEl.className = 'fc-modal-badge fc-modal-badge--planned';
            badgeEl.innerHTML = '<span class="fa fa-cogs"></span> <strong>Rule-Based Engine</strong> &bull; AI Planned';
            aiBoxEl.className = 'fc-info-ai-box fc-info-ai-box--planned';
            aiBoxEl.innerHTML = '<div><strong>Current Engine:</strong> ' + item.currentEngine + '</div><div style="margin-top:8px;">' + item.aiDetail + '</div>';
        }

        backdrop.classList.add('is-active');
    };

    window.fcCloseFeatureInfo = function() {
        var backdrop = document.getElementById('fc-info-modal-backdrop');
        if (backdrop) {
            backdrop.classList.remove('is-active');
        }
    };

    function decorateFeatureInfoTriggers() {
        // 1. Decorate tab navigation links
        document.querySelectorAll('.t-Tabs-link').forEach(function(link) {
            if (link.querySelector('.fc-info-btn')) return;
            var text = (link.textContent || '').trim().toLowerCase();
            var key = null;

            if (text.indexOf('slide deck') !== -1 || text.indexOf('slide draft') !== -1) {
                key = 'slide-decks';
            } else if (text.indexOf('fit and clearance') !== -1 || text.indexOf('fit & clearance') !== -1) {
                key = 'fit-clearance';
            } else if (text.indexOf('drawing package') !== -1) {
                key = 'drawing-packages';
            } else if (text.indexOf('design brief') !== -1) {
                key = 'design-brief';
            }

            if (key && window.FC_FEATURE_INFO[key]) {
                var info = window.FC_FEATURE_INFO[key];
                var btn = document.createElement('button');
                btn.type = 'button';
                btn.className = 'fc-info-btn' + (info.isAi ? ' fc-info-btn--ai' : '');
                btn.title = 'About ' + info.title + ' (' + (info.isAi ? 'AI-Enabled' : 'Rule-Based Engine, AI Planned') + ')';
                btn.setAttribute('aria-label', info.title + ' feature info');
                btn.innerHTML = '<span class="fa fa-info-circle" aria-hidden="true"></span>';
                btn.addEventListener('click', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    window.fcShowFeatureInfo(key);
                });
                link.appendChild(btn);
            }
        });

        // 2. Decorate region titles
        document.querySelectorAll('.t-Region-title').forEach(function(titleEl) {
            if (titleEl.querySelector('.fc-info-btn')) return;
            var text = (titleEl.textContent || '').trim().toLowerCase();
            var key = null;

            if (text.indexOf('upload & register drawing') !== -1 || text.indexOf('registered drawing packages') !== -1) {
                key = 'drawing-packages';
            } else if (text.indexOf('structure clearance') !== -1) {
                key = 'fit-clearance';
            } else if (text.indexOf('design brief') !== -1) {
                key = 'design-brief';
            } else if (text.indexOf('proposal copy & quality') !== -1) {
                key = 'copy-quality-review';
            } else if (text.indexOf('client deep-search') !== -1 || text.indexOf('client research') !== -1) {
                key = 'client-deep-search';
            } else if (text.indexOf('upload client brief') !== -1) {
                key = 'brief-upload';
            } else if (text.indexOf('concept options') !== -1) {
                key = 'concept-ideation';
            } else if (text.indexOf('bill of quantities') !== -1 || text.indexOf('spatial-to-boq') !== -1) {
                key = 'boq-decoding';
            } else if (text.indexOf('bespoke rfq') !== -1) {
                key = 'bespoke-rfqs';
            } else if (text.indexOf('presentation pack') !== -1 || text.indexOf('export presentation') !== -1) {
                key = 'export-pack';
            }

            if (key && window.FC_FEATURE_INFO[key]) {
                var info = window.FC_FEATURE_INFO[key];
                var btn = document.createElement('button');
                btn.type = 'button';
                btn.className = 'fc-info-btn' + (info.isAi ? ' fc-info-btn--ai' : '');
                btn.title = 'About ' + info.title + ' (' + (info.isAi ? 'AI-Enabled' : 'Rule-Based Engine, AI Planned') + ')';
                btn.setAttribute('aria-label', info.title + ' feature info');
                btn.innerHTML = '<span class="fa fa-info-circle" aria-hidden="true"></span>';
                btn.addEventListener('click', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    window.fcShowFeatureInfo(key);
                });
                titleEl.appendChild(btn);
            }
        });
    }

    // Call decorator on ready & after refresh
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', decorateFeatureInfoTriggers);
    } else {
        decorateFeatureInfoTriggers();
    }

    if (typeof apex !== 'undefined' && apex.jQuery) {
        apex.jQuery(document).on('apexready', decorateFeatureInfoTriggers);
        apex.jQuery(document).on('apexafterrefresh', decorateFeatureInfoTriggers);
        apex.jQuery(document).on('click', '.t-Tabs-link', function() {
            setTimeout(decorateFeatureInfoTriggers, 80);
        });
    }
})();
