# Design Brief: Flash Concepts Pitch Studio

- **People and moments**:
  - **Michelle (Planning Strategist)**: Opens the studio at 08:30 during peak FinTech Festival season to review an incoming multi-deck corporate tender brief, extract mandatory criteria, run cited public research, and prepare 2-3 concept options for Gate 1 approval in under 1 working day.
  - **Adi (Senior Designer)**: Receives the approved planning handover, checks 3D booth/stage structure dimensions against venue ceiling and clearance constraints before rendering, avoiding costly structural rework, and signs Gate 2.
  - **Wei Lin (Operations Executive)**: Reviews extracted drawing components, maps BOQ lines to fixed/historical prices from SharePoint Excel, drafts vendor RFQ enquiries without autonomous sending, and reconciles incoming quotes while strictly separating markup from margin for Gate 3.
  - **Copywriter & Translator**: Audits proposals for typo-free copy and validates English to Bahasa Indonesia translations for Singapore and Jakarta teams.
  - **Leadership / Sponsor**: Monitors pipeline bottlenecks and gives final commercial sign-off for Gate 5.

- **Per page jobs**:
  - **Page 1 (Pipeline Dashboard)**: Job: Spot bottlenecks and workload peaks across SG & Jakarta. First-seen: Active capacity and deadline progress. Main action: Create Tender.
  - **Page 2 (Intake Review)**: Job: Convert raw brief into verified criteria. First-seen: Extraction confidence and missing items. Main action: Confirm Intake.
  - **Page 3 (Planning Studio)**: Job: Evidence-based creative concepts and handover. First-seen: Concept cards. Main action: Gate 1 Planning Approval.
  - **Page 4 (Design & Spatial)**: Job: Preliminary clearance check. First-seen: Spatial feasibility matrix. Main action: Gate 2 Design Approval.
  - **Page 5 (Operations & Costing)**: Job: Deterministic BOQ pricing and RFQs. First-seen: Cost/margin summary cards. Main action: Gate 3 Operations Approval.
  - **Page 6 (Quality & Release)**: Job: Consistency check and translation. First-seen: Gate audit checklist. Main action: Gate 5 Final Release.

- **The reference's character**:
  High-impact creative agency aesthetic balancing stark dark/light contrast with vibrant sustainability mint (#3BE891), pill badges, and bold typography.
  - Transferable moves: Full-bleed statement bands, pill buttons/badges (300px radius), flat crisp depth, and high-contrast dark ink typography.

- **Must not transfer**:
  Reference company name, client trademarks, specific marketing copy, video assets, or external logos.

**Forbidden words:** squarespace, typekit, logomark, webflow, wordpress

## Data reality

The application connects to Oracle AI Database 26ai (`YJ_PDB`) under schema `SGINT02`:
- Core tables: `FC_TENDERS`, `FC_TENDER_DOCUMENTS`, `FC_INTAKE_FIELDS`, `FC_RESEARCH_FINDINGS`, `FC_CONCEPT_OPTIONS`, `FC_HANDOVER_ITEMS`, `FC_VENUE_PROFILES`, `FC_SPATIAL_CHECKS`, `FC_DRAWING_PACKAGES`, `FC_PRICE_ITEMS`, `FC_BOQ_ITEMS`, `FC_RFQS`, `FC_QUOTATIONS`, `FC_COMPLIANCE_RULES`, `FC_COMPLIANCE_FINDINGS`, `FC_COPY_CHECKS`, `FC_TRANSLATIONS`, `FC_WORKFLOW_GATES`, `FC_AUDIT_LOGS`, `FC_KPI_TELEMETRY`.
- Real supported data: Tender codes, client names, office (SG/JKT), stage, submission deadlines, primary currency (SGD/IDR), structured intake criteria, venue dimensions (usable length, width, clear height), fixed price items, line item BOQ costs, markup % and margin %, RFQ human dispatch dates, gate approval history.
- What pages may NOT promise:
  - No autonomous vendor negotiations or automatic external email dispatching.
  - No automated PE structural engineering legal certification (checks are preliminary decision support).
  - No unverified regulatory law assertions (synthetic rules are tagged as demo).
  - No invented venue clearance if venue profile dimensions are missing (status must report UNKNOWN).
