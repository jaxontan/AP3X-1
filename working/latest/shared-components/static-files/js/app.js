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

        // Page 3 & Stages
        "Generate Concepts": "Buat Konsep",
        "Generate AI Concepts": "Buat Konsep Berbasis AI",
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
})();
