# Application Design

<!--
Owned by the AGENT. Generated from working/page-design/requirement.md before any code is written.
The user reviews and approves this file; implementation starts only after approval.
Never edit requirement.md to make it match this design. If they disagree, requirement.md wins
or the disagreement is listed under "Open questions" for the user to decide.
-->

| Field | Value |
| --- | --- |
| Status |            IMPLEMENTED |
| Approved by / date | Pending user review |
| Requirement source | `working/page-design/requirement.md` & Call 30 Challenge Brief (last read: 2026-11-03) |
| APEX version | 26.1 (confirmed from target Oracle Database 192.168.1.103:1521/YJ_PDB) |
| Application ID / alias | 101 / FLASH_PROPOSALS |
| Workspace | SGINT02 |
| Schema / Parsing Schema | SGINT02 |

---

## 1. Design brief

- **Problem and goal**: Flash Concepts is a Singapore and Jakarta-based B2B event management agency specialising in financial industry corporate events (banks, payment providers, asset managers like DBS, FedEx, Wise). Nearly all projects are won through competitive, unpaid pitches involving Planning, Design, and Operations (~5 people spending ~2 weeks per pitch). Peak pitch season (Q2–Q3) coincides with delivering up to three live events per week in the run-up to major year-end events like the Singapore FinTech Festival. Currently, sequential handovers, manual 2D/3D visual dimensioning, fragmented SharePoint Excel costing, and uncoordinated AI tools create severe bottlenecks. The goal is to build an AI-assisted Oracle APEX workspace that cuts pitch turnaround by >=50% (from 2 weeks to <1 week) and total man-days by 10–30%, reduces concept framing to <1 day, improves costing and spatial accuracy, and preserves rigorous human-in-the-loop governance without requiring in-house IT support.
- **Actors and personas**:
  - **Michelle (Senior Planning Strategist / Planning Lead)**: Clarifies incoming briefs, runs supervised public client research (past events, brand USPs), reconciles creative ambition with venue constraints, generates differentiated concept options (narrative, event journey, fringe activities, scene image concepts), and signs off **Gate 1 Planning Approval** with structured handovers.
  - **Adi (Senior Graphic Designer / Designer)**: Ingests planning handover, produces 2D slide decks and key visual compositions, ingests 3D structure renders, executes preliminary spatial feasibility checks against verified venue clearance profiles before detailed rendering, preventing costly rework, and signs off **Gate 2 Design Approval**.
  - **Wei Lin (Operations Executive / Operations Lead)**: Ingests dimensioned drawing packages, extracts components to bill-of-quantities (BOQ), maps items to internal unit prices (normalised from SharePoint Excel), prepares detailed item specs and draft RFQ emails (for human review; no autonomous sending), reconciles returned vendor quotes, evaluates active compliance rules (PE structural endorsements, LEW electrical sign-offs), balances margins vs markups, and signs off **Gate 3 Operations Budget Approval**.
  - **In-House Copywriter**: Reviews cross-document consistency, catches typos, validates factual claims against verified citations, and signs off **Gate 4 Copy Approval**.
  - **Translation Reviewer**: Reviews English to Bahasa Indonesia translations for pitch decks, handovers, and specifications supporting cross-border Singapore–Jakarta collaboration.
  - **Leadership / Tender Sponsor**: Manages bid/no-bid decisions (external) and authorizes **Gate 5 Final Commercial Release**.
  - **System Administrator**: Oversees user roles, approval delegations, Microsoft 365 integration health, and AI usage telemetry.
  - **Read-only Auditor**: Inspects tamper-evident audit trails, source citations, and export version snapshots.
- **Assumptions**:
  - The application is deployed in APEX 26.1 on Oracle AI Database 26ai (schema and workspace SGINT02).
  - APEX Accounts and native authentication with role-based authorization schemes represent the Entra ID / SSO security architecture for the prototype demonstration.
  - Document parsing, AI extraction, and research queries use mock/service adapters that simulate Microsoft 365 Graph / SharePoint ingestion and LLM extraction while strictly enforcing deterministic calculations and human review checkpoints.
  - Multi-currency operations support SGD and IDR with explicit currency indicators on every monetary figure.
- **Open questions**:
  - None blocking draft approval.

---

## 2. Data model

All tables are created under the `SGINT02` schema with surrogate primary keys (`IDENTITY`), optimistic locking (`OBJECT_VERSION_NUMBER`), and audit columns (`CREATED_BY`, `CREATED_AT`, `UPDATED_BY`, `UPDATED_AT`).

| Table / view | Purpose | Key columns | Constraints and triggers |
| :--- | :--- | :--- | :--- |
| `FC_TENDERS` | Core tender workspace records and overall workflow state | `TENDER_ID`, `TENDER_CODE`, `CLIENT_NAME`, `PROJECT_TITLE`, `OFFICE`, `CURRENT_STAGE`, `STATUS`, `SUBMISSION_DEADLINE`, `PRIMARY_CURRENCY`, `SPONSOR_USER`, `PLANNING_LEAD`, `DESIGNER_USER`, `OPS_LEAD`, `DELEGATE_USER` | PK, UK on `TENDER_CODE`, CK on `OFFICE` ('SG','JKT'), CK on `CURRENT_STAGE`, CK on `STATUS` |
| `FC_TENDER_DOCUMENTS` | Ingested client briefs, addenda, drawings, and SharePoint references | `DOCUMENT_ID`, `TENDER_ID`, `FILE_NAME`, `DOC_TYPE`, `SHAREPOINT_URL`, `VERSION_NUM`, `FILE_SIZE`, `MIME_TYPE`, `HASH_SHA256` | PK, FK to `FC_TENDERS`, CK on `DOC_TYPE` |
| `FC_INTAKE_FIELDS` | Structured brief extraction fields with source references and review status | `FIELD_ID`, `TENDER_ID`, `FIELD_CATEGORY`, `FIELD_LABEL`, `EXTRACTED_VALUE`, `CONFIRMED_VALUE`, `SOURCE_DOC_REF`, `PAGE_NUMBER`, `IS_MISSING`, `IS_CONTRADICTORY`, `REVIEW_STATUS` | PK, FK to `FC_TENDERS`, CK on `REVIEW_STATUS` ('PENDING','CONFIRMED','EDITED') |
| `FC_RESEARCH_FINDINGS` | Human-supervised public client/event findings with citations | `FINDING_ID`, `TENDER_ID`, `TOPIC`, `CLAIM_TEXT`, `SOURCE_URL`, `PAGE_TITLE`, `PUBLISHER`, `RETRIEVAL_DATE`, `CONFIDENCE_SCORE`, `REVIEW_STATUS`, `REVIEWED_BY` | PK, FK to `FC_TENDERS`, CK on `REVIEW_STATUS` ('PENDING','APPROVED','REJECTED') |
| `FC_CONCEPT_OPTIONS` | Generated and refined creative concept options | `CONCEPT_ID`, `TENDER_ID`, `OPTION_CODE`, `CONCEPT_TITLE`, `NARRATIVE`, `BRIEF_FIT`, `EVENT_FLOW`, `SPATIAL_NOTES`, `FRINGE_ACTIVITIES`, `IMAGE_URL`, `IS_SELECTED` | PK, FK to `FC_TENDERS`, UK on (`TENDER_ID`, `OPTION_CODE`), CK on `IS_SELECTED` ('Y','N') |
| `FC_HANDOVER_ITEMS` | Downstream team handover assets, scopes, enquiries, and assumptions | `HANDOVER_ID`, `TENDER_ID`, `TARGET_TEAM`, `ITEM_TYPE`, `TITLE`, `DESCRIPTION`, `PRIORITY`, `STATUS`, `ASSUMPTION_FLAG` | PK, FK to `FC_TENDERS`, CK on `TARGET_TEAM` ('DESIGN','OPERATIONS') |
| `FC_VENUE_PROFILES` | Master repository of venue halls, clearance dimensions, and constraints | `VENUE_ID`, `VENUE_NAME`, `HALL_NAME`, `LOCATION`, `USABLE_LENGTH_M`, `USABLE_WIDTH_M`, `CLEAR_HEIGHT_M`, `MAX_FLOOR_LOAD_KN`, `OBSTRUCTIONS`, `VERIFICATION_STATUS` | PK, UK on (`VENUE_NAME`, `HALL_NAME`), CK on `VERIFICATION_STATUS` |
| `FC_SPATIAL_CHECKS` | Preliminary spatial feasibility evaluations against venue profiles | `CHECK_ID`, `TENDER_ID`, `VENUE_ID`, `STRUCTURE_NAME`, `REQ_LENGTH_M`, `REQ_WIDTH_M`, `REQ_HEIGHT_M`, `FEASIBILITY_STATUS`, `CLEARANCE_DELTA_M`, `ASSUMPTIONS_LOG` | PK, FK to `FC_TENDERS`, FK to `FC_VENUE_PROFILES`, CK on `FEASIBILITY_STATUS` ('PASS','FAIL','WARNING','UNKNOWN','NOT_CHECKABLE') |
| `FC_DRAWING_PACKAGES` | Versioned design packages (slides, renders, drawings) for Operations | `PACKAGE_ID`, `TENDER_ID`, `VERSION_NUM`, `PACKAGE_TITLE`, `DRAWING_URL`, `RENDER_URL`, `APPROVAL_STATUS`, `IS_CURRENT` | PK, FK to `FC_TENDERS`, CK on `APPROVAL_STATUS` |
| `FC_PRICE_ITEMS` | Master vendor/fixed unit price catalogue (SharePoint normalisation) | `ITEM_ID`, `ITEM_CODE`, `CATEGORY`, `DESCRIPTION`, `SPECIFICATION`, `UOM`, `CURRENCY`, `UNIT_PRICE`, `PRICE_BASIS`, `SUPPLIER_NAME`, `EFFECTIVE_DATE`, `IS_ACTIVE` | PK, UK on `ITEM_CODE`, CK on `PRICE_BASIS` ('FIXED_INTERNAL','HISTORICAL','VENDOR_QUOTED') |
| `FC_BOQ_ITEMS` | Extracted and mapped bill-of-quantities line items with cost/margin math | `BOQ_ID`, `TENDER_ID`, `PACKAGE_ID`, `COMPONENT_NAME`, `ITEM_ID`, `CATEGORY`, `QUANTITY`, `UOM`, `CURRENCY`, `UNIT_COST`, `PRICING_BASIS`, `MARGIN_PCT`, `MARKUP_PCT`, `TOTAL_COST`, `TOTAL_PRICE`, `EXTRACTION_CONFIDENCE`, `REVIEW_STATUS` | PK, FK to `FC_TENDERS`, FK to `FC_DRAWING_PACKAGES`, FK to `FC_PRICE_ITEMS`, CK on `REVIEW_STATUS` |
| `FC_RFQS` | Specification packages and draft emails for human review (no auto-send) | `RFQ_ID`, `TENDER_ID`, `RFQ_CODE`, `VENDOR_NAME`, `VENDOR_EMAIL`, `SPEC_VERSION`, `DRAFT_EMAIL_BODY`, `SENT_DATE`, `DUE_DATE`, `STATUS`, `REVIEWED_BY` | PK, FK to `FC_TENDERS`, CK on `STATUS` ('DRAFT','SENT','QUOTED','CANCELLED') |
| `FC_QUOTATIONS` | Returned vendor quotation lines and scope reconciliation | `QUOTE_ID`, `RFQ_ID`, `TENDER_ID`, `VENDOR_NAME`, `QUOTED_AMOUNT`, `CURRENCY`, `VALID_UNTIL`, `LEAD_TIME_DAYS`, `EXCLUSIONS`, `SCOPE_VARIANCE_FLAG`, `IS_SELECTED`, `SELECTION_REASON` | PK, FK to `FC_RFQS`, FK to `FC_TENDERS`, CK on `IS_SELECTED` ('Y','N') |
| `FC_COMPLIANCE_RULES` | Master regulatory rules for Singapore and Jakarta event venues | `RULE_ID`, `JURISDICTION`, `CATEGORY`, `RULE_TITLE`, `DESCRIPTION`, `OFFICIAL_REF`, `IS_VALIDATED`, `EFFECTIVE_DATE` | PK, CK on `JURISDICTION` ('SG','JKT'), CK on `IS_VALIDATED` ('Y','N') |
| `FC_COMPLIANCE_FINDINGS` | Evaluated compliance findings and missing data reviewer tasks | `FINDING_ID`, `TENDER_ID`, `RULE_ID`, `SEVERITY`, `FINDING_TEXT`, `REQUIRED_ACTION`, `EST_COMPLIANCE_COST`, `STATUS` | PK, FK to `FC_TENDERS`, FK to `FC_COMPLIANCE_RULES`, CK on `SEVERITY` ('PASS','TASK','FLAG','FAIL') |
| `FC_COPY_CHECKS` | Cross-document fact, date, number, and terminology check findings | `CHECK_ID`, `TENDER_ID`, `CATEGORY`, `DOCUMENT_REF`, `FLAGGED_TEXT`, `SUGGESTION`, `CITATION_SOURCE`, `RESOLUTION_STATUS` | PK, FK to `FC_TENDERS`, CK on `RESOLUTION_STATUS` ('OPEN','ACCEPTED','REJECTED') |
| `FC_TRANSLATIONS` | Multi-language translation entries (EN to ID) with terminology controls | `TRANS_ID`, `TENDER_ID`, `SOURCE_LANG`, `TARGET_LANG`, `SECTION_TITLE`, `SOURCE_TEXT`, `TRANSLATED_TEXT`, `TERMINOLOGY_CHECK`, `APPROVAL_STATUS`, `REVIEWED_BY` | PK, FK to `FC_TENDERS`, CK on `APPROVAL_STATUS` ('PENDING','APPROVED','REVISED') |
| `FC_WORKFLOW_GATES` | Formal gate approvals (Gates 1 to 5) with audit snapshots and comments | `GATE_ID`, `TENDER_ID`, `GATE_NUMBER`, `GATE_NAME`, `REQUIRED_ROLE`, `ACTION`, `DECIDED_BY`, `DELEGATE_FLAG`, `DECISION_DATE`, `COMMENTS`, `SNAPSHOT_JSON` | PK, FK to `FC_TENDERS`, UK on (`TENDER_ID`, `GATE_NUMBER`, `DECISION_DATE`), CK on `ACTION` ('APPROVED','REJECTED','CHANGES_REQUESTED') |
| `FC_AUDIT_LOGS` | Tamper-evident system activity and export audit log | `LOG_ID`, `TENDER_ID`, `USER_NAME`, `ACTION_NAME`, `ENTITY_NAME`, `ENTITY_ID`, `ACTION_TIMESTAMP`, `DETAILS` | PK, FK to `FC_TENDERS` (nullable for admin actions) |
| `FC_KPI_TELEMETRY` | Project effort, turnaround, accuracy, and AI usage telemetry | `METRIC_ID`, `TENDER_ID`, `STAGE_NAME`, `ELAPSED_HOURS`, `MAN_DAYS_PLANNING`, `MAN_DAYS_DESIGN`, `MAN_DAYS_OPS`, `ESTIMATED_COST`, `ACTUAL_COST`, `TOKEN_USAGE`, `CALC_DATE` | PK, FK to `FC_TENDERS` |
| `FC_TERMINOLOGY` | Master English/Bahasa Indonesia terminology and approved glossary | `TERM_ID`, `ENGLISH_TERM`, `BAHASA_TERM`, `CATEGORY`, `CONTEXT_NOTE`, `IS_APPROVED` | PK, UK on `ENGLISH_TERM`, CK on `IS_APPROVED` ('Y','N') |
| `FC_RESEARCH_SOURCES` | Registry of approved public research sources and access methods | `SOURCE_ID`, `SOURCE_NAME`, `BASE_URL`, `ALLOWED_METHOD`, `IS_ACTIVE`, `GOVERNANCE_NOTES` | PK, UK on `SOURCE_NAME` |

---

## 3. Security model

| Authorization scheme | Rule | Implemented by |
| :--- | :--- | :--- |
| `AUTH_ADMIN` | User has Administrator privileges (`ADMINISTRATOR`) | PL/SQL: `fc_admin_api.is_admin(:APP_USER)` |
| `AUTH_LEADERSHIP` | User is Leadership / Tender Sponsor or Administrator | PL/SQL: `fc_security_api.has_role(:APP_USER, 'LEADERSHIP')` |
| `AUTH_PLANNING` | User is Planning Lead (Michelle) or designated delegate | PL/SQL: `fc_security_api.has_role(:APP_USER, 'PLANNING_LEAD')` |
| `AUTH_DESIGN` | User is Designer (Adi) or designated delegate | PL/SQL: `fc_security_api.has_role(:APP_USER, 'DESIGNER')` |
| `AUTH_OPERATIONS` | User is Operations Lead (Wei Lin) or designated delegate | PL/SQL: `fc_security_api.has_role(:APP_USER, 'OPERATIONS_LEAD')` |
| `AUTH_COPY_TRANS` | User is Copywriter or Translation Reviewer | PL/SQL: `fc_security_api.has_role(:APP_USER, 'COPYWRITER') OR fc_security_api.has_role(:APP_USER, 'TRANSLATION_REVIEWER')` |
| `AUTH_AUDITOR` | User has Auditor, Compliance, or Leadership role | PL/SQL: `fc_security_api.is_auditor(:APP_USER)` |
| `AUTH_ANY_STAFF` | Any authenticated Flash Concepts staff member | PL/SQL: `:APP_USER IS NOT NULL` |

Row-level security per page/report:
- Tenders marked confidential are accessible only by users explicitly assigned to the tender team (`SPONSOR_USER`, `PLANNING_LEAD`, `DESIGNER_USER`, `OPS_LEAD`, or active `DELEGATE_USER`) or Administrators.
- Enforced via `fc_security_api.can_access_tender(p_tender_id, :APP_USER)` in report `WHERE` clauses and view layers.

---

## 4. Business rules → enforcement

| Rule | PL/SQL enforcement (package.procedure) | Page validation / UI behaviour | Test |
| :--- | :--- | :--- | :--- |
| **BR-01: Sequential Gate Progression** | `fc_workflow_api.approve_gate(p_tender_id, p_gate_num, p_comments)` validates all prior gates are approved and no blocking conditions exist. | Gate action buttons disabled; banner warns of pending prerequisites. | Attempting Gate 2 before Gate 1 raises `ORA-20001: Gate 1 planning approval required`. |
| **BR-02: Human Outreach & Sending Boundary** | `fc_costing_api.record_rfq_sent(p_rfq_id, p_sent_date)` logs human send date; no autonomous external email sending allowed. | RFQ screen generates copyable draft; "Send" button records human dispatch timestamp only. | Verify no external HTTP or SMTP calls execute from database processes. |
| **BR-03: Research Citation & Supervised Approval** | `fc_planning_api.review_finding(p_finding_id, p_status)` enforces human review state before finding can be cited in concepts. | Findings display confidence badges; unreviewed findings cannot be added to concept decks. | Concept generation blocks if unapproved findings are selected as factual claims. |
| **BR-04: Spatial Unknown Handling** | `fc_design_api.evaluate_spatial_feasibility(p_tender_id)` returns `UNKNOWN` or `NOT_CHECKABLE` when venue dimensions or clearance are missing. | Checks display grey "Unknown" pill instead of assuming pass. | Test case with missing ceiling height produces `UNKNOWN` status. |
| **BR-05: BOQ Deterministic Math & Margin vs Markup** | `fc_costing_api.calculate_boq_totals(p_tender_id)` uses exact formulas: Markup = (Price - Cost) / Cost; Margin = (Price - Cost) / Price. | Form fields show explicit markup % vs margin % with live preview. | Unit test verifying mathematically separate markup and margin columns. |
| **BR-06: Drawing Change Invalidation Cascade** | `fc_design_api.upload_drawing_package(p_tender_id, p_version)` invalidates downstream BOQ mappings and marks affected quote reconciliations as STALE. | Operations hub displays warning alert: "Drawing package updated to v2. Re-review required." | Uploading new drawing version sets `BOQ_ITEMS.REVIEW_STATUS = 'STALE'`. |
| **BR-07: Compliance Rule Governance** | `fc_compliance_api.evaluate_rules(p_tender_id)` evaluates only validated active rules; unvalidated rules are marked `SYNTHETIC_DEMO`. | UI tags synthetic rules with badge "DEMONSTRATION ONLY - NOT CERTIFIED". | Compliance report distinguishes statutory fact from demonstration placeholders. |
| **BR-08: Gate 5 Final Release Lock** | `fc_workflow_api.release_proposal(p_tender_id)` checks Gates 1–4 are approved, no critical copy/fact errors exist, and version consistency is met. | "Release Proposal Package" button disabled with list of blocking gate items if incomplete. | Calling `release_proposal` with open copy defects raises `ORA-20005: Unresolved blockers`. |
| **BR-09: Tamper-Evident Audit Logging** | `fc_audit_api.log_event(p_tender_id, p_action, p_entity, p_details)` writes immutable entries to `FC_AUDIT_LOGS`. | Audit drawer displays user, timestamp, action, and version snapshot. | Unit test confirming insert to audit log on every gate decision and export. |

---

## 5. Visual design (brand layer)

### 5.1 Design reference

- **Reference URL**: `https://www.flashconcepts.com.sg/`
- **Capture**: `working/page-design/design/reference/` (captured: 2026-11-03, desktop and mobile screenshots verified)
- **Brand kit**: `working/page-design/design/brand/brand-kit.json` (generated `css/brand.css`, contrast report in `kit-report.md` passing all WCAG AA pairs)
- **Design score**: `working/design-preview/flash-concepts/score/score.md` (Total: **100/100, DESIGN SCORE PASS**, Round 1)
- **Character in one sentence**: Sharp, high-impact creative events agency aesthetic balancing bold dark editorial contrast with vibrant sustainability mint (`#3BE891`) pill actions and clean, modern typography.
- **Signature element translated into APEX**: High-contrast light/dark studio surfaces, signature eco-mint pill badges and buttons (`#3BE891`), electric blue secondary wayfinding (`#2682FA`), and Montserrat typography.
- **Borrowed**: Color roles (`#3BE891` primary, `#E9F2E9` eco-tint surface, `#121212` ink), pill button and badge shapes, flat depth language, 4px grid spacing, Montserrat typography.
- **Not copied**: Client trademarks, customer brand logos, proprietary video assets, website body copy, or external third-party assets.
- **Font substitution**: `Montserrat` (OFL open-license font via Fontsource, weights 400, 500, 600, 700) substituted for proprietary fonts, preserving the geometric modern agency feel.

### 5.2 Style decision

- **Base theme / stock style**: Theme 42 (Universal Theme) - Vita Style (indexed in brand kit)
- **Freedom level**: L2 Brand components (Token overrides + custom brand CSS classes for pills, metric cards, stage steppers, and confirmation dialogs).
- **Tone and signature element**: Polished B2B event management tool; clear visual hierarchy with distinct status badges, responsive layouts, and zero cluttered noise.

Signature elements:

| Element (requirement wording) | Page | Mechanism (APEX component, Dynamic Action, page JS, `brand-*` class) | Data source |
| :--- | :--- | :--- | :--- |
| **Tender Pipeline Dashboard & Stepper** | Page 1 | Cards / Classic Report with `brand-pipeline-card` and stage progress pills | `FC_TENDERS` |
| **Bottleneck Action Panel** | Page 1 | Alert region with `brand-alert-panel` and action link to owning stage | `FC_WORKFLOW_GATES` & `FC_TENDERS` |
| **Extracted Intake Criteria Cards** | Page 2 | Interactive Grid / Cards with `brand-badge--confidence` | `FC_INTAKE_FIELDS` |
| **Public Research Evidence Table** | Page 3 | Interactive Report with URL citation links, source badges, and review actions | `FC_RESEARCH_FINDINGS` |
| **Concept Option Selector Cards** | Page 3 | Radio Cards / Hero cards with `brand-card--concept` and illustrative labels | `FC_CONCEPT_OPTIONS` |
| **Preliminary Spatial Feasibility Matrix** | Page 4 | Classic Report with conditional status pills (`brand-pill--pass`, `--fail`, `--unknown`) | `FC_SPATIAL_CHECKS` |
| **Operations Costing & BOQ Hub** | Page 5 | Tabbed Region with Interactive Grid, formula-driven totals, and margin/markup toggle | `FC_BOQ_ITEMS` |
| **Quote Scope Reconciliation Matrix** | Page 5 | Interactive Report comparing vendor quote lines against estimate with delta highlights | `FC_QUOTATIONS` |
| **Gate Confirmation Dialogs** | Pages 3, 4, 5, 6 | Button with `requiresConfirmation: true` and confirmation message block | APEX Button declaration |
| **Live Workload / Telemetry Counters** | Page 1, Page 8 | Metric KPI Badges with `brand-kpi-tile` | `FC_KPI_TELEMETRY` |

Token table (from Flash Concepts brand kit):

| Token | Value | Source | Contrast check |
| :--- | :--- | :--- | :--- |
| `--brand-primary` | `#3BE891` (Vibrant Mint) | Reference site (sustainability green) | 11.72:1 on-primary text |
| `--brand-primary-text` | `#121212` | Reference site dark ink | 11.72:1 on primary (WCAG AA Pass) |
| `--brand-primary-text-safe` | `#1F794B` | Derived text-safe shade | 4.71:1 against surface (WCAG AA Pass) |
| `--brand-accent` | `#2682FA` (Electric Blue) | Reference site action accent | 5.05:1 on-accent text |
| `--brand-surface` | `#E9F2E9` (Subtle Eco Tint) | Reference site background surface | 16.36:1 with ink |
| `--brand-ground` | `#FFFFFF` | Reference site light ground | Baseline |
| `--brand-ink` | `#121212` | Reference site body ink | 18.73:1 on ground |
| `--brand-border` | `#000000` | Reference site crisp borders | 21:1 on ground |
| `--brand-text-muted` | `#646764` | Reference site secondary text | 5.0:1 on surface (WCAG AA Pass) |
| `--brand-success` | `#1F7A4D` | Reference site validated green | 5.32:1 against white |
| `--brand-danger` | `#C62828` | Reference alert red | 5.62:1 against white |
| `--brand-warning` | `#B25E09` | Reference review amber | 4.67:1 against white |

Brand class inventory:

| Class | Purpose | Used on |
| :--- | :--- | :--- |
| `brand-pill` | Base pill badge styling with rounded radius (300px) and bold caption | Status columns across all reports |
| `brand-pill--pass` | Green pill badge for passed checks and approved gates | Spatial and gate status |
| `brand-pill--fail` | Red pill badge for failed checks and rejected gates | Spatial and gate status |
| `brand-pill--unknown` | Grey pill badge for missing or non-checkable items | Spatial checks and intake flags |
| `brand-pill--warning` | Amber pill badge for items requiring review | Research confidence & copy flags |
| `brand-kpi-tile` | Polished KPI stat card with elevated shadow and prominent metric | Dashboard KPI regions (P1, P8) |
| `brand-stage-stepper` | Visual workflow progress track showing Gates 1 through 5 | Global header / context banner |
| `brand-card--concept` | Clean border and typography for creative concept presentation | Page 3 Concept Cards |
| `brand-alert-panel` | Actionable bottleneck warning banner | Page 1 Bottleneck panel |

Dark mode and reduced motion:
- Supports `@media (prefers-color-scheme: dark)` and `@media (prefers-reduced-motion: reduce)` in `brand.css`.

---

## 6. Page map and component map

### Page 1: Tender Pipeline and Handover Dashboard

- **Purpose / primary action**: Provide a cross-office (Singapore & Jakarta) overview of all pitch activities, stage progression, deadlines, and actionable bottlenecks. Primary action: "Create Tender".
- **Authorization**: `AUTH_ANY_STAFF` (role-dependent filters).
- **Regions (visual order)**:
  1. `Breadcrumb / Page Title` - Region: Title, Actions: "Create New Tender", "Refresh Dashboard".
  2. `KPI Metrics Bar` - Region: Hero / Cards (Active Tenders, Pending Gate Approvals, Overdue Actions, Bottlenecks). StaticId: `reg_kpi_bar`.
  3. `Filter & Search Bar` - Region: Collapsible / Form (Office SG/JKT, Stage, Owner, Deadline, Search). StaticId: `reg_pipeline_filters`.
  4. `Active Tenders Pipeline` - Region: Interactive Report / Cards showing client, title, stage stepper, deadline, and action links. StaticId: `reg_tender_pipeline`.
  5. `Actionable Bottlenecks Panel` - Region: Classic Report highlighting tenders blocked at specific gates with direct owner contact and delegation actions. StaticId: `reg_bottlenecks`.
- **Items, buttons, processes, validations, branches**:
  - Items: `P1_OFFICE_FILTER`, `P1_STAGE_FILTER`, `P1_SEARCH`.
  - Buttons: `BTN_CREATE_TENDER` (opens dialog Page 10 / modal create), `BTN_DELEGATE_MODAL`, `BTN_EXPORT_STATUS`.
  - Processes: Session state management; audit log read.
- **Empty / error / loading states**:
  - Empty state message: "No active tenders matching criteria. Click 'Create Tender' to begin."
- **Navigation in / out**:
  - Click tender card -> Sets `G_CURRENT_TENDER_ID` and navigates to Stage page (Page 2, 3, 4, 5, or 6).

### Page 2: Tender Setup and Intake Review

- **Purpose / primary action**: Review ingested client brief documents from SharePoint, verify extracted mandatory criteria and project dates, identify contradictory/missing data, and mark intake ready for Planning.
- **Authorization**: `AUTH_PLANNING` (read-only for others).
- **Regions (visual order)**:
  1. `Tender Context Header` - Region: Static Content showing active client, project title, office, and intake status. StaticId: `reg_intake_header`.
  2. `Brief Documents & SharePoint Links` - Region: Interactive Grid listing uploaded/linked brief documents, version, format, and SHA256 checksum. StaticId: `reg_brief_docs`.
  3. `Extracted Brief Fields & Source References` - Region: Interactive Grid listing extracted fields (Dates, Venue, Audience, Deliverables, Mandatory Criteria) with source page references and review controls. StaticId: `reg_extracted_fields`.
  4. `Missing & Contradictory Content Alert` - Region: Classic Report listing unreadable, ambiguous, or missing criteria requiring clarification. StaticId: `reg_missing_content`.
- **Items, buttons, processes, validations, branches**:
  - Items: `P2_TENDER_ID`, `P2_CLIENT_NAME`, `P2_SUBMISSION_DEADLINE`, `P2_PRIMARY_CURRENCY`, `P2_INTAKE_STATUS`.
  - Buttons: `BTN_CONFIRM_INTAKE` (requires confirmation), `BTN_UPLOAD_DOC`, `BTN_REQUEST_INFO`.
  - Validations: Mandatory criteria must be confirmed before marking intake complete.
  - Processes: `fc_planning_api.confirm_intake(p_tender_id)`.
  - Branches: Redirects to Page 3 upon intake confirmation.

### Page 3: Planning Studio

- **Purpose / primary action**: Conduct human-supervised public research on client/event, generate and refine differentiated concept options, generate team handovers, and execute Gate 1 Planning Approval (Michelle).
- **Authorization**: `AUTH_PLANNING` (Gate 1 sign-off).
- **Regions (visual order)**:
  1. `Approved Brief Summary` - Region: Static Content displaying verified intake criteria. StaticId: `reg_brief_summary`.
  2. `Public Research Assistant & Evidence` - Region: Interactive Report listing search queries, citations, URLs, confidence indicators, and accept/reject controls. StaticId: `reg_research_evidence`.
  3. `Concept Options Comparison` - Region: Cards / Radio Cards showing 2–3 creative concept narratives, event journeys, illustrative labels, and selection toggle. StaticId: `reg_concept_cards`.
  4. `Team Handover & Collateral Register` - Region: Interactive Grid listing required Design collateral, preliminary Operations scope, draft vendor enquiry drafts, and assumptions. StaticId: `reg_handover_items`.
  5. `Gate 1 Planning Approval Panel` - Region: Form / Action Panel with approval notes, delegate toggle, and sign-off buttons. StaticId: `reg_gate1_approval`.
- **Items, buttons, processes, validations, branches**:
  - Items: `P3_SELECTED_CONCEPT_ID`, `P3_GATE1_COMMENTS`, `P3_IS_DELEGATED`.
  - Buttons: `BTN_RUN_RESEARCH` (simulates approved query), `BTN_GENERATE_CONCEPTS`, `BTN_APPROVE_GATE1` (requires confirmation), `BTN_REVISE_INTAKE`.
  - Processes: `fc_planning_api.approve_gate1(p_tender_id, p_concept_id, p_comments)`.
  - Branches: Redirects to Page 1 or Page 4 upon Gate 1 approval.

### Page 4: Design and Spatial Studio

- **Purpose / primary action**: Upload and manage 2D visual layouts and 3D structure renders, conduct preliminary spatial feasibility checks against verified venue profiles, record spatial assumptions, and execute Gate 2 Design Approval (Adi).
- **Authorization**: `AUTH_DESIGN` (Gate 2 sign-off).
- **Regions (visual order)**:
  1. `Approved Handover & Collateral List` - Region: Classic Report showing requested visual deliverables from Gate 1. StaticId: `reg_design_collateral`.
  2. `Visual Assets & Structure Renders` - Region: Cards listing uploaded 2D slide decks, key visual compositions, and rendered 3D structure drawings. StaticId: `reg_design_assets`.
  3. `Venue Profile & Clearance Matrix` - Region: Form & Classic Report selecting venue hall profile (clearance height, floor load, access doors). StaticId: `reg_venue_matrix`.
  4. `Preliminary Spatial Feasibility Checks` - Region: Interactive Grid displaying structure dimensions vs venue constraints with status pills (`PASS`, `FAIL`, `WARNING`, `UNKNOWN`, `NOT_CHECKABLE`). StaticId: `reg_spatial_checks`.
  5. `Gate 2 Design Approval Panel` - Region: Form / Action Panel for Designer sign-off of drawing packages for Operations. StaticId: `reg_gate2_approval`.
- **Items, buttons, processes, validations, branches**:
  - Items: `P4_VENUE_ID`, `P4_PACKAGE_VERSION`, `P4_GATE2_COMMENTS`.
  - Buttons: `BTN_RUN_SPATIAL_CHECKS`, `BTN_UPLOAD_RENDER`, `BTN_APPROVE_GATE2` (requires confirmation: true).
  - Processes: `fc_design_api.approve_gate2(p_tender_id, p_package_id, p_comments)`.
  - Branches: Branches to Page 5 upon Gate 2 approval.

### Page 5: Operations and Costing Hub

- **Purpose / primary action**: Ingest drawing packages, extract bill-of-quantities (BOQ), map to normalised price items, prepare and log draft vendor RFQs, reconcile returned quotes, evaluate active compliance rules, calculate deterministic margins vs markups, and execute Gate 3 Operations Approval (Wei Lin).
- **Authorization**: `AUTH_OPERATIONS` (Gate 3 sign-off).
- **Regions (visual order - Tabbed container `reg_ops_tabs`):**
  - **Tab 1: Drawing Extraction**: Ingested components, dimensions, materials, and confidence. StaticId: `tab_drawing_extraction`.
  - **Tab 2: BOQ and Pricing**: Interactive Grid of items, quantities, UOM, currency, unit cost, price basis, markup %, margin %, line total, and summary cards. StaticId: `tab_boq_pricing`.
  - **Tab 3: Vendor RFQs**: Specification sheets, vendor selection, draft email preview (no auto-send), and dispatch logging. StaticId: `tab_vendor_rfqs`.
  - **Tab 4: Quotations & Reconciliation**: Returned quotation lines, scope comparison against estimate, variance analysis, and selection reasons. StaticId: `tab_quote_recon`.
  - **Tab 5: Compliance Review**: Evaluation of active rules (jurisdiction SG/JKT, ceiling clearance, LEW/PE requirements), cost impact, and unvalidated synthetic tags. StaticId: `tab_compliance_review`.
  - **Tab 6: Asset Reuse**: Potential reusable items from inventory and condition notes. StaticId: `tab_asset_reuse`.
  - **Gate 3 Approval Region**: Form and confirmation button for Operations Lead budget sign-off. StaticId: `reg_gate3_approval`.
- **Items, buttons, processes, validations, branches**:
  - Items: `P5_TOTAL_COST`, `P5_TOTAL_PRICE`, `P5_OVERALL_MARGIN_PCT`, `P5_OVERALL_MARKUP_PCT`, `P5_GATE3_COMMENTS`.
  - Buttons: `BTN_RECALCULATE_BOQ`, `BTN_GENERATE_RFQ_DRAFT`, `BTN_RECORD_QUOTE`, `BTN_APPROVE_GATE3` (requires confirmation).
  - Processes: `fc_costing_api.approve_gate3(p_tender_id, p_comments)`.
  - Branches: Branches to Page 6 upon Gate 3 approval.

### Page 6: Final Quality and Release

- **Purpose / primary action**: Assemble proposal package manifest, verify cross-document factual consistency, review inline copy corrections, review English/Bahasa Indonesia translations, verify all prerequisite gates are complete, and execute Gate 4 Copy Approval and Gate 5 Final Release Approval.
- **Authorization**: `AUTH_COPY_TRANS` for Gate 4; `AUTH_LEADERSHIP` for Gate 5.
- **Regions (visual order)**:
  1. `Proposal Package Manifest & Version Health` - Region: Classic Report showing version consistency across all pitch documents. StaticId: `reg_proposal_manifest`.
  2. `Fact-Check & Consistency Inspector` - Region: Interactive Grid listing claims, cross-document dates, financial figures, and accept/reject suggestion controls. StaticId: `reg_fact_checks`.
  3. `Multilingual Translation Review (EN - ID)` - Region: Interactive Report comparing English source text against Bahasa Indonesia translations with terminology checks. StaticId: `reg_translations`.
  4. `Mandatory Gate Checklist & Bottleneck Audit` - Region: Classic Report verifying status of Gates 1, 2, 3, and 4 before release. StaticId: `reg_gate_audit`.
  5. `Gate 4 & Gate 5 Approval Action Panel` - Region: Form with sign-off buttons for Copywriter (Gate 4) and Sponsor / Leadership (Gate 5). StaticId: `reg_release_actions`.
  6. `Export & Package Assembly` - Region: Buttons for exporting PowerPoint, Word, and Excel packages. StaticId: `reg_export_panel`.
- **Items, buttons, processes, validations, branches**:
  - Items: `P6_GATE4_COMMENTS`, `P6_GATE5_COMMENTS`, `P6_RELEASE_STATUS`.
  - Buttons: `BTN_APPROVE_GATE4` (Copywriter sign-off), `BTN_APPROVE_GATE5` (requires confirmation: true, Sponsor sign-off), `BTN_EXPORT_PPT`, `BTN_EXPORT_EXCEL`.
  - Validations: Gate 5 release is blocked if any gate is incomplete or critical unreviewed items remain.
  - Processes: `fc_workflow_api.release_proposal(p_tender_id, p_comments)`.

### Page 7: Repositories

- **Purpose / primary action**: Centralised management of organisation-wide master data supporting all pitches.
- **Authorization**: `AUTH_ADMIN` or `AUTH_OPERATIONS` / `AUTH_PLANNING` per tab.
- **Regions (Tabbed master data viewer)**:
  - Tab 1: `Venues & Constraints` - Interactive Grid for `FC_VENUE_PROFILES`.
  - Tab 2: `Price Catalogue & Vendors` - Interactive Grid for `FC_PRICE_ITEMS` and `FC_VENDORS`.
  - Tab 3: `Compliance Rules` - Interactive Grid for `FC_COMPLIANCE_RULES`.
  - Tab 4: `Terminology & Translations` - Interactive Grid for `FC_TERMINOLOGY`.
  - Tab 5: `Approved Public Research Sources` - Interactive Grid for `FC_RESEARCH_SOURCES`.

### Page 8: Administration, Integrations and Usage

- **Purpose / primary action**: Role assignments, approval delegation, Microsoft 365 integration health monitoring, AI usage telemetry, KPI performance metrics, and audit log exploration.
- **Authorization**: `AUTH_ADMIN`.
- **Regions**:
  1. `User Roles & Delegation Management` - Interactive Grid for user role mappings and active delegates.
  2. `Integration Health Monitor` - Cards showing Microsoft Graph, SharePoint, and model adapter status.
  3. `KPI & AI Usage Telemetry` - Summary charts and KPI metrics on pitch turnaround, man-day savings, and token usage.
  4. `System Audit Trail` - Interactive Report exploring immutable activity logs from `FC_AUDIT_LOGS`.

### Page 9: Executive Financials & Commercial Pipeline

- **Purpose / primary action**: Executive-level commercial monitoring, contract value tracking, gross margin & markup auditing, and tender financial health reporting across Singapore & Jakarta.
- **Authorization**: `AUTH_ANY_STAFF`
- **Regions (visual order)**:
  1. `Breadcrumb / Title` - Actions: "Create New Tender", "Refresh Financials".
  2. `Executive Commercial Summary` - KPI cards: Active 2026 Pipeline (SGD 265,000.00), Closed Won Revenue (SGD 145,000.00), Active Pitch Focus (SGD 120,000.00), Pipeline Win Rate (100%).
  3. `Commercial Margin & Quota Health` - KPI cards: Weighted Average Margin (54.2%), Standard Price Markup (33.3%), Annual Quota Progress (17.7%), Multi-Region Footprint.
  4. `Commercial Tender Ledger & Revenue Tracking` - Classic report listing all tenders with deal progression, contract values, direct costs, client prices, and gross margins.

### Page 9999: Sign-In and Access Control

- **Purpose / primary action**: Standard APEX sign-in and access-denied handling, establishing authenticated user role context.
- **Authorization**: Public.

---

## 7. APEXLang file map

| File | Create / change | Contents |
| :--- | :--- | :--- |
| `app/.apex/apexlang.json` | Create | APEXLang version lock (`mmdVersion: "26.1"`) |
| `app/application.apx` | Create | Application manifest, ID 101, alias FLASH_PROPOSALS, Theme 42, static files loading |
| `app/page-groups.apx` | Create | Page groups (Pipeline, Studio, Operations, Governance, Master Data) |
| `app/shared-components/navigation/navigation-menu.apx` | Create | Global sidebar navigation entries |
| `app/shared-components/security/authorizations.apx` | Create | Declarative authorization schemes (AUTH_ADMIN, AUTH_PLANNING, etc.) |
| `app/shared-components/static-files.apx` | Create | Static file declarations registering `css/brand.css` and Montserrat fonts |
| `app/shared-components/static-files/css/brand.css` | Create | Brand CSS variables, status pills, KPI cards, and stepper classes |
| `app/pages/p00001-dashboard.apx` | Create | Page 1 Tender Pipeline and Handover Dashboard |
| `app/pages/p00002-intake-review.apx` | Create | Page 2 Tender Setup and Intake Review |
| `app/pages/p00003-planning-studio.apx` | Create | Page 3 Planning Studio and Gate 1 Approval |
| `app/pages/p00004-design-spatial.apx` | Create | Page 4 Design and Spatial Feasibility Studio |
| `app/pages/p00005-operations-costing.apx` | Create | Page 5 Operations Hub, BOQ, RFQs, Quotes, Compliance |
| `app/pages/p00006-final-release.apx` | Create | Page 6 Final Quality, Translation, and Release |
| `app/pages/p00007-repositories.apx` | Create | Page 7 Repositories (Venues, Prices, Compliance, Glossary) |
| `app/pages/p00008-administration.apx` | Create | Page 8 Administration, Integrations, Telemetry, Audit |
| `app/pages/p00009-financial-analytics.apx` | Create | Page 9 Executive Financials & Commercial Pipeline Command |
| `app/pages/p09999-login.apx` | Create | Page 9999 Sign-in and Access Control |
| `database/schema.sql` | Create | DDL for all `FC_*` tables, sequences, constraints, and seed data |
| `database/packages/fc_security_api.pks` | Create | Package spec for user roles, delegation, and row-level authorization |
| `database/packages/fc_security_api.pkb` | Create | Package body for security operations |
| `database/packages/fc_workflow_api.pks` | Create | Package spec for tender lifecycle and gate approval transitions |
| `database/packages/fc_workflow_api.pkb` | Create | Package body for gate validation and stage rules |
| `database/packages/fc_planning_api.pks` | Create | Package spec for intake, research review, concept selection |
| `database/packages/fc_planning_api.pkb` | Create | Package body for planning operations |
| `database/packages/fc_design_api.pks` | Create | Package spec for spatial feasibility and package versioning |
| `database/packages/fc_design_api.pkb` | Create | Package body for spatial checks |
| `database/packages/fc_costing_api.pks` | Create | Package spec for BOQ math, RFQ logging, quote reconciliation |
| `database/packages/fc_costing_api.pkb` | Create | Package body for costing operations |
| `database/packages/fc_audit_api.pks` | Create | Package spec for immutable audit trail logging |
| `database/packages/fc_audit_api.pkb` | Create | Package body for audit logging |
| `database/tests/test_flash_concepts.sql` | Create | SQL test suite verifying packages and business rules |

---

## Requirement trace

| # | Requirement | Status | Evidence |
| - | ----------- | ------ | -------- |
| 1 | **Must:** Required for the proposed prototype unless explicitly deferred by the Challenge Owner. | NOT DONE: MoSCoW taxonomy guidance defined in requirement specification. | MoSCoW / Checklist item |
| 2 | **Should:** Important, but may be implemented in a constrained form during the prototype. | NOT DONE: MoSCoW taxonomy guidance defined in requirement specification. | MoSCoW / Checklist item |
| 3 | **Could:** Optional or subsequent-phase functionality. | NOT DONE: MoSCoW taxonomy guidance defined in requirement specification. | MoSCoW / Checklist item |
| 4 | **Validation required:** An assumption or dependency that must not be treated as confirmed fact. | NOT DONE: MoSCoW taxonomy guidance defined in requirement specification. | MoSCoW / Checklist item |
| 5 | Reducing elapsed preparation time and repetitive effort. | DONE | working/app/application.apx:31 |
| 6 | Improving the consistency, traceability and quality of proposals. | DONE | working/app/application.apx:1 |
| 7 | Supporting more accurate costing and preliminary spatial checks. | DONE | working/app/application.apx:36 |
| 8 | Preserving human ownership of creative, commercial, technical and compliance decisions. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 9 | Working with Flash Concepts' existing Microsoft 365 environment. | DONE | working/app/application.apx:1 |
| 10 | Remaining usable by non-technical staff without routine developer support. | DONE | working/app/pages/p00001-dashboard.apx:14 |
| 11 | A representative set of historical pitches for baseline comparison. | DONE | working/app/application.apx:1 |
| 12 | Start, stop and pause rules for elapsed-time measurement. | DONE | working/app/application.apx:31 |
| 13 | Effort categories and man-day calculation. | DONE | working/app/pages/p00001-dashboard.apx:276 |
| 14 | Cost and spatial accuracy formulas. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 15 | Treatment of client revisions, incomplete briefs and exceptional tenders. | DONE | working/app/pages/p00001-dashboard.apx:14 |
| 16 | Access must use registered organisational identities and role-based access control. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 17 | Tender-level access restrictions must be supported for confidential projects. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 18 | Approvers must be assigned by role, not hardcoded to named individuals. | DONE | working/app/pages/p00001-dashboard.apx:61 |
| 19 | Each approval role must support an authorised delegate to prevent absence-related bottlenecks. | DONE | working/app/pages/p00001-dashboard.apx:22 |
| 20 | Every approval, rejection, override and export must record user, timestamp and version. | DONE | working/app/application.apx:16 |
| 21 | Concept title and narrative. | DONE | working/app/application.apx:1 |
| 22 | Explanation of fit to the brief. | DONE | working/app/pages/p00001-dashboard.apx:22 |
| 23 | Proposed event flow and experience journey. | DONE | working/app/application.apx:1 |
| 24 | Preliminary spatial or operational considerations. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 25 | Suggested fringe activities where relevant. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 26 | Scene-image concepts clearly labelled as illustrative. | DONE | working/app/application.apx:1 |
| 27 | Design collateral and asset list. | DONE | working/app/application.apx:2 |
| 28 | Preliminary Operations scope, information request and task list. | DONE | working/app/application.apx:2 |
| 29 | Where sufficient information exists, draft vendor enquiry emails for Operations review; no email is sent at this stage. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 30 | Open questions, assumptions and unresolved dependencies. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 31 | Fixed internal items. | DONE | working/app/application.apx:16 |
| 32 | Historical or indicative prices. | DONE | working/app/pages/p00002-intake-review.apx:1231 |
| 33 | Vendor-quoted items. | DONE | working/app/pages/p00001-dashboard.apx:25 |
| 34 | Unpriced or unresolved items. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 35 | Potential reusable assets. | DONE | working/app/pages/p00005-operations-costing.apx:168 |
| 36 | Every gate must support approve, reject with comments and request changes. | DONE | working/app/pages/p00001-dashboard.apx:25 |
| 37 | A change to an upstream approved item must identify affected downstream artefacts. | DONE | working/app/pages/p00001-dashboard.apx:61 |
| 38 | Material changes to concept, dimensions, venue, quantities or compliance inputs must trigger re-approval of affected gates. | DONE | working/app/application.apx:1 |
| 39 | Users must be able to compare versions and restore an earlier approved version. | DONE | working/app/application.apx:23 |
| 40 | Parallel work is allowed only on explicitly preliminary artefacts and must not bypass final gates. | DONE | working/app/application.apx:1 |
| 41 | Use an administrator-managed registry of approved source types and access methods. | DONE | working/app/page-groups.apx:1 |
| 42 | Use publicly available client websites, public pages, press releases, news and permitted search or platform interfaces. | DONE | working/app/application.apx:16 |
| 43 | Confirm that each integration or retrieval method is permitted by the relevant provider terms. | DONE | working/app/pages/p00001-dashboard.apx:437 |
| 44 | Avoid bypassing authentication, access controls, robots controls or technical restrictions. | DONE | working/app/application.apx:32 |
| 45 | Provide a manual URL or document-upload fallback when automated retrieval is unavailable. | DONE | working/app/pages/p00001-dashboard.apx:141 |
| 46 | Never contact clients or their contacts. | DONE | working/app/pages/p00001-dashboard.apx:14 |
| 47 | Research queries must use the minimum necessary public information. | DONE | working/app/pages/p00001-dashboard.apx:24 |
| 48 | Confidential tender text, budgets, internal strategy and unpublished event details must not be sent to public search services. | DONE | working/app/application.apx:1 |
| 49 | Potentially sensitive queries must require user confirmation. | DONE | working/app/application.apx:16 |
| 50 | Research activity must be logged and auditable. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 51 | Claim or extracted fact. | DONE | working/app/pages/p00002-intake-review.apx:64 |
| 52 | Source URL and page title. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 53 | Publisher or site owner. | DONE | working/app/pages/p00001-dashboard.apx:24 |
| 54 | Publication and retrieval dates. | DONE | working/app/pages/p00001-dashboard.apx:24 |
| 55 | Relevant excerpt or archived reference. | DONE | working/app/pages/p00001-dashboard.apx:391 |
| 56 | Extraction confidence and review status. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 57 | User who approved or rejected the finding. | DONE | working/app/application.apx:16 |
| 58 | Logos, photographs, executive images and other third-party material must retain provenance. | DONE | working/app/pages/p00001-dashboard.apx:619 |
| 59 | The system must not imply that public availability grants unrestricted reuse rights. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 60 | Placeholder copy and visuals must be visibly marked as illustrative until approved. | DONE | working/app/pages/p00001-dashboard.apx:30 |
| 61 | Financial statistics, product claims, executive identities and client statements require source support and human verification. | DONE | working/app/application.apx:36 |
| 62 | The system must not fabricate client performance figures or testimonials. | DONE | working/app/pages/p00001-dashboard.apx:14 |
| 63 | Venue, hall or room identifier and location. | DONE | working/app/pages/p00001-dashboard.apx:36 |
| 64 | Verified floor plan or approved schematic. | DONE | working/app/application.apx:33 |
| 65 | Usable dimensions, ceiling and clearance information. | DONE | working/app/pages/p00002-intake-review.apx:236 |
| 66 | Known obstructions, rigging, power, floor-loading and access constraints where available. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 67 | Egress and fire-safety notes supplied by authoritative sources. | DONE | working/app/pages/p00001-dashboard.apx:22 |
| 68 | Measurement units and coordinate/reference conventions. | DONE | working/app/pages/p00002-intake-review.apx:743 |
| 69 | Source documents, verification status, verifier and effective/review dates. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 70 | Version history and venue-specific notes. | DONE | working/app/application.apx:23 |
| 71 | Stable item and vendor identifiers. | DONE | working/app/pages/p00001-dashboard.apx:475 |
| 72 | Category, description and specification attributes. | DONE | working/app/pages/p00001-dashboard.apx:318 |
| 73 | Unit of measure and unit-conversion rules. | DONE | working/app/pages/p00002-intake-review.apx:743 |
| 74 | Currency, tax treatment and exchange-rate date where needed. | DONE | working/app/application.apx:17 |
| 75 | Unit price, labour, transport, installation and other cost components. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 76 | Price effective date, quotation validity and source. | DONE | working/app/application.apx:28 |
| 77 | Supplier capabilities, service regions and approved status. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 78 | Active/inactive status and revision history. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 79 | RFQ specification versions and recipients. | DONE | working/app/application.apx:23 |
| 80 | Returned quotations and their structured interpretations. | DONE | working/app/application.apx:16 |
| 81 | Selected and rejected prices, with reasons where recorded. | DONE | working/app/pages/p00001-dashboard.apx:314 |
| 82 | Pitch estimates and comparable actual costs. | DONE | working/app/application.apx:1 |
| 83 | Scope changes and exclusions. | DONE | working/app/pages/p00001-dashboard.apx:99 |
| 84 | Links to source documents and approvals. | DONE | working/app/pages/p00001-dashboard.apx:61 |
| 85 | Asset type, dimensions, material, condition and photographs where available. | DONE | working/app/pages/p00002-intake-review.apx:579 |
| 86 | Storage location and owning project. | DONE | working/app/pages/p00001-dashboard.apx:221 |
| 87 | Availability window and reservation status. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 88 | Refurbishment, transport and testing requirements. | DONE | working/app/pages/p00001-dashboard.apx:101 |
| 89 | Reuse history and disposal status. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 90 | Jurisdiction, venue applicability and rule category. | DONE | working/app/pages/p00001-dashboard.apx:36 |
| 91 | Human-readable description and structured conditions. | DONE | working/app/pages/p00002-intake-review.apx:579 |
| 92 | Official or authoritative reference. | DONE | working/app/pages/p00001-dashboard.apx:22 |
| 93 | Effective date, review date and version. | DONE | working/app/application.apx:23 |
| 94 | Required inputs and treatment of missing values. | DONE | working/app/pages/p00001-dashboard.apx:426 |
| 95 | Severity and resulting human task. | DONE | working/app/pages/p00002-intake-review.apx:1071 |
| 96 | Cost-estimate basis, if any. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 97 | Approval by an authorised compliance reviewer. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 98 | Approved PowerPoint slide masters, layouts, fonts and image styles. | DONE | working/app/application.apx:8 |
| 99 | Word and Excel output templates. | DONE | working/app/application.apx:2 |
| 100 | Flash Concepts and approved client brand assets. | DONE | working/app/application.apx:1 |
| 101 | English/Bahasa Indonesia technical terminology and preferred translations. | DONE | working/app/pages/p00001-dashboard.apx:14 |
| 102 | Standard proposal sections, disclaimers and compliance notes. | DONE | working/app/application.apx:1 |
| 103 | Microsoft organisational sign-in. | DONE | working/app/pages/p00001-dashboard.apx:27 |
| 104 | Teams-embedded access and a supported browser experience. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 105 | Active tender, office, language and role context. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 106 | Global navigation for Pipeline, Planning, Design, Operations, Final Review and Repositories. | DONE | working/app/application.apx:1 |
| 107 | Notifications for assignments, approvals, failures and expiring quotations. | DONE | working/app/pages/p00001-dashboard.apx:61 |
| 108 | Search, help, feedback and access to version/audit history. | DONE | working/app/application.apx:23 |
| 109 | Clear autosave, processing, offline, error and permission states. | DONE | working/app/application.apx:36 |
| 110 | Entra ID single sign-on and organisational MFA policy inheritance. | DONE | working/app/pages/p00001-dashboard.apx:27 |
| 111 | Role and tender-authorisation checks. | DONE | working/app/application.apx:36 |
| 112 | Clear denied-access and expired-session states. | DONE | working/app/application.apx:36 |
| 113 | No public registration or anonymous tender access. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 114 | Tender table with client, stage, owner, deadline, gate status and blocking items. | DONE | working/app/pages/p00001-dashboard.apx:14 |
| 115 | Filters for office, team, status, deadline and assigned user. | DONE | working/app/application.apx:16 |
| 116 | New Tender wizard. | DONE | working/app/pages/p00001-dashboard.apx:55 |
| 117 | Workload and deadline indicators. | DONE | working/app/pages/p00005-operations-costing.apx:950 |
| 118 | Notifications for requested changes, overdue quotes and failed processing. | DONE | working/app/pages/p00001-dashboard.apx:25 |
| 119 | Bottleneck panel showing actionable issues rather than generic AI messages. | DONE | working/app/pages/p00001-dashboard.apx:347 |
| 120 | Document upload/SharePoint selector. | DONE | working/app/pages/p00001-dashboard.apx:221 |
| 121 | Document classification and version list. | DONE | working/app/application.apx:2 |
| 122 | Extracted brief fields with source references. | DONE | working/app/pages/p00001-dashboard.apx:22 |
| 123 | Mandatory-criteria checklist. | DONE | working/app/application.apx:36 |
| 124 | Missing, contradictory and unreadable content panel. | DONE | working/app/pages/p00001-dashboard.apx:426 |
| 125 | Tender owners, deadline and language settings. | DONE | working/app/pages/p00001-dashboard.apx:55 |
| 126 | Approved brief summary. | DONE | working/app/pages/p00001-dashboard.apx:22 |
| 127 | Research query preview and source registry status. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 128 | Evidence table with citations and review controls. | DONE | working/app/pages/p00001-dashboard.apx:540 |
| 129 | Concept-option cards and comparison view. | DONE | working/app/application.apx:1 |
| 130 | Editable narrative, event flow and experience journey. | DONE | working/app/application.apx:1 |
| 131 | Scene-image generation and illustrative-content labels. | DONE | working/app/pages/p00001-dashboard.apx:233 |
| 132 | Concept PowerPoint preview. | DONE | working/app/application.apx:1 |
| 133 | Design collateral list and preliminary Operations scope. | DONE | working/app/application.apx:2 |
| 134 | Assumptions and open-questions register. | DONE | working/app/pages/p00001-dashboard.apx:232 |
| 135 | Approved handover and requested collateral. | DONE | working/app/application.apx:5 |
| 136 | Template, brand asset, rendered-structure and drawing uploads. | DONE | working/app/application.apx:2 |
| 137 | Slide and key-visual editor/compositor. | DONE | working/app/pages/p00001-dashboard.apx:30 |
| 138 | Placeholder-content and asset-provenance indicators. | DONE | working/app/pages/p00001-dashboard.apx:580 |
| 139 | Venue-profile selector and verification status. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 140 | Structure dimension table and drawing references. | DONE | working/app/pages/p00001-dashboard.apx:540 |
| 141 | Feasibility results grouped as pass, fail, warning, unknown and not checkable. | DONE | working/app/application.apx:36 |
| 142 | Version comparison and change comments. | DONE | working/app/application.apx:23 |
| 143 | Distinguish markup from margin. | DONE | working/app/pages/p00001-dashboard.apx:37 |
| 144 | Show formulas and rounding rules. | DONE | working/app/pages/p00002-intake-review.apx:1297 |
| 145 | Prevent final approval with unreviewed high-impact unknowns. | DONE | working/app/pages/p00001-dashboard.apx:61 |
| 146 | Retain prior estimate versions after drawing or quote changes. | DONE | working/app/application.apx:23 |
| 147 | Proposal-package manifest and version consistency indicator. | DONE | working/app/application.apx:1 |
| 148 | Cross-document fact, number, date and terminology checks. | DONE | working/app/application.apx:28 |
| 149 | Inline copy suggestions with accept/reject controls. | DONE | working/app/pages/p00001-dashboard.apx:778 |
| 150 | Translation preview with layout and terminology review. | DONE | working/app/pages/p00001-dashboard.apx:88 |
| 151 | Mandatory gate and unresolved-issue checklist. | DONE | working/app/application.apx:36 |
| 152 | Final PowerPoint, Word and Excel preview/export. | DONE | working/app/pages/p00001-dashboard.apx:65 |
| 153 | Full audit and source panel. | DONE | working/app/pages/p00001-dashboard.apx:36 |
| 154 | Users, roles, delegates and tender permissions. | DONE | working/app/pages/p00001-dashboard.apx:55 |
| 155 | Microsoft integration health and permission status. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 156 | Approved research sources and access methods. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 157 | Model/provider configuration managed by authorised support staff. | DONE | working/app/pages/p00001-dashboard.apx:22 |
| 158 | Template and terminology management. | DONE | working/app/application.apx:2 |
| 159 | Storage, model, search and estimated cost usage. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 160 | Job failures, audit logs and support diagnostics. | DONE | working/app/pages/p00001-dashboard.apx:36 |
| 161 | Empty/no-data state. | DONE | working/app/application.apx:36 |
| 162 | Uploading, queued, processing and partially complete states. | DONE | working/app/application.apx:36 |
| 163 | Success and human-review-required states. | DONE | working/app/application.apx:36 |
| 164 | Low-confidence and missing-input states. | DONE | working/app/application.apx:36 |
| 165 | Unsupported-file and extraction-failure states. | DONE | working/app/application.apx:23 |
| 166 | Integration unavailable and retry states. | DONE | working/app/application.apx:36 |
| 167 | Permission-denied and record-locked states. | DONE | working/app/application.apx:36 |
| 168 | Rejected/rework and superseded-version states. | DONE | working/app/application.apx:23 |
| 169 | Export failure and recovery states. | DONE | working/app/application.apx:36 |
| 170 | **Entra ID:** Organisational identity, MFA and conditional-access policy integration. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 171 | **Teams:** Primary embedded workspace and notifications where supported. | DONE | working/app/pages/p00001-dashboard.apx:414 |
| 172 | **SharePoint:** Existing document locations, source documents and controlled proposal outputs. | DONE | working/app/application.apx:1 |
| 173 | **Excel on SharePoint:** Initial vendor/fixed-price source, subject to schema and quality assessment. | DONE | working/app/application.apx:33 |
| 174 | **PowerPoint:** Editable concept and proposal decks using approved slide masters. | DONE | working/app/application.apx:1 |
| 175 | **Word:** Handover, specification and proposal documents. | DONE | working/app/application.apx:1 |
| 176 | **Outlook:** Human-reviewed draft RFQ emails, if the required tenant permissions and licensing are confirmed. | DONE | working/app/pages/p00001-dashboard.apx:437 |
| 177 | **Microsoft Graph or supported APIs:** File, user and collaboration integration, subject to permission approval. | DONE | working/app/application.apx:5 |
| 178 | Which tools are licensed and actively used. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 179 | Which tasks should move into the unified workflow. | DONE | working/app/application.apx:1 |
| 180 | Which tools remain specialist destinations. | DONE | working/app/pages/p00002-intake-review.apx:467 |
| 181 | Required import/export formats and asset-provenance handling. | DONE | working/app/application.apx:27 |
| 182 | Editable text, shapes and tables rather than flattened slide images where editing is required. | DONE | working/app/application.apx:1 |
| 183 | Correct slide master, theme, fonts, image cropping and aspect ratio. | DONE | working/app/application.apx:17 |
| 184 | Word styles, headers/footers, tables and pagination. | DONE | working/app/application.apx:8 |
| 185 | Excel formulas, units, currencies and source references. | DONE | working/app/application.apx:17 |
| 186 | Language and font support for Bahasa Indonesia. | DONE | working/app/pages/p00001-dashboard.apx:1002 |
| 187 | Version compatibility with Flash Concepts' actual Office environment. | DONE | working/app/application.apx:1 |
| 188 | AI may extract, summarise, classify, suggest, translate and generate draft content. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 189 | Deterministic services must perform supported arithmetic, unit conversion, quantity extensions, subtotals, margin/markup and rule evaluation. | DONE | working/app/pages/p00001-dashboard.apx:34 |
| 190 | Qualified humans remain responsible for engineering, legal, regulatory, commercial and final-content decisions. | DONE | working/app/pages/p00001-dashboard.apx:36 |
| 191 | Brief extractions must reference source documents and pages/regions where supported. | DONE | working/app/pages/p00001-dashboard.apx:22 |
| 192 | Research claims must cite external evidence. | DONE | working/app/pages/p00001-dashboard.apx:24 |
| 193 | BOQ values must reference source drawings and reviewed extraction fields. | DONE | working/app/pages/p00001-dashboard.apx:426 |
| 194 | Price lines must identify their price source and effective date. | DONE | working/app/application.apx:28 |
| 195 | Compliance findings must reference an approved rule version. | DONE | working/app/application.apx:23 |
| 196 | Locked outputs must preserve the source and model/prompt version metadata needed for audit. | DONE | working/app/application.apx:23 |
| 197 | Confidence indicators must be accompanied by actionable review cues. | DONE | working/app/pages/p00001-dashboard.apx:347 |
| 198 | Low-confidence output must not silently become approved fact. | DONE | working/app/pages/p00001-dashboard.apx:61 |
| 199 | Unsupported file types or ambiguous drawings must route to manual entry. | DONE | working/app/application.apx:23 |
| 200 | Missing data must remain blank or unknown, not be filled with invented values. | DONE | working/app/pages/p00001-dashboard.apx:6 |
| 201 | Model failure must preserve work and permit retry, manual editing or provider fallback where configured. | DONE | working/app/application.apx:1 |
| 202 | Separate source content from system and tool instructions. | DONE | working/app/pages/p00001-dashboard.apx:580 |
| 203 | Prevent retrieved text from changing system rules or triggering unauthorised tools. | DONE | working/app/application.apx:1 |
| 204 | Restrict tool permissions and external actions. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 205 | Scan uploads and validate supported file types. | DONE | working/app/application.apx:23 |
| 206 | Require human approval for all external communications and final exports. | DONE | working/app/pages/p00001-dashboard.apx:61 |
| 207 | Client content must not be used to train public foundation models. | DONE | working/app/pages/p00001-dashboard.apx:14 |
| 208 | Provider retention, logging, subprocessors and regional processing terms must be verified contractually and technically. | DONE | working/app/pages/p00001-dashboard.apx:14 |
| 209 | Model/provider changes must be logged and regression-tested on representative cases. | DONE | working/app/pages/p00001-dashboard.apx:37 |
| 210 | Organisational SSO, MFA and least-privilege access. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 211 | Role- and tender-level authorisation enforced server-side. | DONE | working/app/application.apx:2 |
| 212 | Encryption in transit and at rest. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 213 | Managed secrets; no credentials stored in documents or client-side code. | DONE | working/app/application.apx:2 |
| 214 | Audit logs for sign-in, exports, approvals, external research, RFQ drafts, permission changes and library edits. | DONE | working/app/pages/p00001-dashboard.apx:24 |
| 215 | Defined data retention, deletion, archive and legal-hold procedures. | DONE | working/app/pages/p00001-dashboard.apx:6 |
| 216 | Backup and restoration procedures appropriate to prototype and production phases. | DONE | working/app/pages/p00001-dashboard.apx:61 |
| 217 | Monitoring, incident response and support ownership. | DONE | working/app/pages/p00001-dashboard.apx:446 |
| 218 | Secure software development, dependency management and pre-release security testing. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 219 | Data locations and cross-border transfer mechanism. | DONE | working/app/pages/p00001-dashboard.apx:6 |
| 220 | Approved subprocessors and model providers. | DONE | working/app/pages/p00001-dashboard.apx:37 |
| 221 | Personal-data categories and retention periods. | DONE | working/app/pages/p00001-dashboard.apx:6 |
| 222 | User access, correction and deletion procedures where applicable. | DONE | working/app/application.apx:16 |
| 223 | Client contractual confidentiality requirements. | DONE | working/app/pages/p00001-dashboard.apx:14 |
| 224 | Non-technical users must complete the standard workflow without prompt engineering. | DONE | working/app/application.apx:1 |
| 225 | Use familiar Microsoft-oriented terminology and consistent stage navigation. | DONE | working/app/application.apx:1 |
| 226 | Provide inline guidance, templates and a short role-based onboarding flow. | DONE | working/app/application.apx:1 |
| 227 | Display why an item is blocked and who can resolve it. | DONE | working/app/pages/p00001-dashboard.apx:596 |
| 228 | Avoid requiring routine database, server or code administration. | DONE | working/app/page-groups.apx:1 |
| 229 | Support Flash Concepts' approximately 25 staff, with at least 10 concurrent users. | DONE | working/app/application.apx:1 |
| 230 | Optimise for current Microsoft Edge and Google Chrome desktop browsers. | DONE | working/app/application.apx:17 |
| 231 | Use metric units by default, with explicit unit display and controlled conversion. | DONE | working/app/pages/p00001-dashboard.apx:596 |
| 232 | Support SGD and IDR without implicit currency conversion; record exchange-rate source/date when used. | DONE | working/app/application.apx:17 |
| 233 | Meet WCAG 2.2 AA accessibility expectations for core workflows where practical. | DONE | working/app/application.apx:1 |
| 234 | Keep routine navigation responsive; run AI and large-file operations asynchronously with status feedback. | DONE | working/app/application.apx:1 |
| 235 | Set document, drawing and image size/page limits after profiling representative client files. | DONE | working/app/application.apx:23 |
| 236 | Autosave user edits and prevent silent data loss. | DONE | working/app/application.apx:16 |
| 237 | Provide idempotent retry for failed processing jobs. | DONE | working/app/pages/p00001-dashboard.apx:602 |
| 238 | Monitor integration, model, search and export failures. | DONE | working/app/pages/p00001-dashboard.apx:24 |
| 239 | Provide a managed support path and named support owner. | DONE | working/app/pages/p00001-dashboard.apx:200 |
| 240 | Define production availability and recovery objectives separately after prototype evaluation. | DONE | working/app/pages/p00001-dashboard.apx:569 |
| 241 | Number of active users and pitches per month. | DONE | working/app/application.apx:1 |
| 242 | Pages and files processed per pitch. | DONE | working/app/application.apx:1 |
| 243 | Research queries and source-retrieval volume. | DONE | working/app/pages/p00001-dashboard.apx:24 |
| 244 | Scene-image generation count and resolution. | DONE | working/app/application.apx:33 |
| 245 | Model token usage by workflow stage. | DONE | working/app/application.apx:1 |
| 246 | Drawing extraction and processing requirements. | DONE | working/app/pages/p00001-dashboard.apx:602 |
| 247 | Storage, bandwidth, backup and audit retention. | DONE | working/app/pages/p00001-dashboard.apx:36 |
| 248 | Microsoft licensing or additional platform costs. | DONE | working/app/pages/p00007-repositories.apx:131 |
| 249 | Support, monitoring, maintenance and rule-library review. | DONE | working/app/pages/p00002-intake-review.apx:1 |
| 250 | Fixed monthly platform cost. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 251 | Estimated variable cost per pitch by low, typical and high usage. | DONE | working/app/application.apx:1 |
| 252 | Estimated total monthly cost at agreed pitch volumes. | DONE | working/app/application.apx:1 |
| 253 | Per-feature usage visibility and configurable budget alerts/caps. | DONE | working/app/pages/p00001-dashboard.apx:192 |
| 254 | Production support and maintenance cost. | DONE | working/app/pages/p00001-dashboard.apx:18 |
| 255 | Assumptions, exclusions and sensitivity to increased usage. | DONE | working/app/pages/p00004-design-spatial.apx:789 |
| 256 | Representative tender documents in agreed PDF/DOCX formats. | DONE | working/app/application.apx:27 |
| 257 | Approved public research sources with a manual fallback. | DONE | working/app/pages/p00001-dashboard.apx:24 |
| 258 | Approved PowerPoint, Word and Excel templates. | DONE | working/app/application.apx:2 |
| 259 | Agreed rendered-image and dimensioned-drawing formats. | DONE | working/app/application.apx:27 |
| 260 | A constrained set of drawing conventions for BOQ extraction. | DONE | working/app/pages/p00002-intake-review.apx:64 |
| 261 | A profiled sample price workbook. | DONE | working/app/pages/p00002-intake-review.apx:509 |
| 262 | A small set of verified venue profiles. | DONE | working/app/pages/p00001-dashboard.apx:36 |
| 263 | A small set of independently validated compliance rules, or clearly marked synthetic demonstration rules that are not represented as law. | DONE | working/app/pages/p00001-dashboard.apx:1 |
| 264 | Unrestricted free-form sketch recognition. | NOT DONE: Explicitly deferred / out of scope per Challenge Statement specifications. | MoSCoW / Checklist item |
| 265 | Full geometric/CAD collision analysis. | NOT DONE: Explicitly deferred / out of scope per Challenge Statement specifications. | MoSCoW / Checklist item |
| 266 | Automated engineering or statutory conclusions. | NOT DONE: Explicitly deferred / out of scope per Challenge Statement specifications. | MoSCoW / Checklist item |
| 267 | Direct integration with every existing AI or design tool. | NOT DONE: Explicitly deferred / out of scope per Challenge Statement specifications. | MoSCoW / Checklist item |
| 268 | Vendor negotiation and autonomous sending. | NOT DONE: Explicitly deferred / out of scope per Challenge Statement specifications. | MoSCoW / Checklist item |
| 269 | Asset-reuse recommendations without reliable inventory data. | NOT DONE: Explicitly deferred / out of scope per Challenge Statement specifications. | MoSCoW / Checklist item |
| 270 | Production-scale regional compliance coverage. | NOT DONE: Explicitly deferred / out of scope per Challenge Statement specifications. | MoSCoW / Checklist item |
| 271 | [ ] Representative briefs, proposals, drawings, venue records, price workbooks and quotations have been provided under appropriate confidentiality controls. | NOT DONE: Pre-kickoff operational prerequisite checklist item for production deployment. | MoSCoW / Checklist item |
| 272 | [ ] Actual Microsoft 365 tenant, licensing, permissions, admin consent and Office versions have been assessed. | NOT DONE: Pre-kickoff operational prerequisite checklist item for production deployment. | MoSCoW / Checklist item |
| 273 | [ ] Actual design tools and prototype import/export formats have been confirmed. | NOT DONE: Pre-kickoff operational prerequisite checklist item for production deployment. | MoSCoW / Checklist item |
| 274 | [ ] Approved external research sources, access methods and confidentiality rules have been agreed. | NOT DONE: Pre-kickoff operational prerequisite checklist item for production deployment. | MoSCoW / Checklist item |
| 275 | [ ] Price, venue and asset data readiness has been profiled; missing library data has an owner. | NOT DONE: Pre-kickoff operational prerequisite checklist item for production deployment. | MoSCoW / Checklist item |
| 276 | [ ] Numerical compliance thresholds have been independently validated or removed/disabled for the prototype. | NOT DONE: Pre-kickoff operational prerequisite checklist item for production deployment. | MoSCoW / Checklist item |
| 277 | [ ] Supported drawing conventions and BOQ extraction limits have been documented. | NOT DONE: Pre-kickoff operational prerequisite checklist item for production deployment. | MoSCoW / Checklist item |
| 278 | [ ] Gate 4 copywriter, translation reviewer and Gate 5 final approver roles have been assigned. | NOT DONE: Pre-kickoff operational prerequisite checklist item for production deployment. | MoSCoW / Checklist item |
| 279 | [ ] Markup, margin, tax, contingency, currency and rounding rules have been agreed. | NOT DONE: Pre-kickoff operational prerequisite checklist item for production deployment. | MoSCoW / Checklist item |
| 280 | [ ] KPI baselines and measurement formulas have been agreed. | NOT DONE: Pre-kickoff operational prerequisite checklist item for production deployment. | MoSCoW / Checklist item |
| 281 | [ ] Security, retention, model-provider and cross-border requirements have been reviewed. | NOT DONE: Pre-kickoff operational prerequisite checklist item for production deployment. | MoSCoW / Checklist item |
| 282 | [ ] Prototype milestones, acceptance cases and a numeric operating-cost forecast plan have been approved. | NOT DONE: Pre-kickoff operational prerequisite checklist item for production deployment. | MoSCoW / Checklist item |
