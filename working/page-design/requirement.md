# Product, Workflow and Prototype Specification
## AI-Enabled Pitch and Proposal Workflow for B2B Events

**Challenge Owner:** Flash Concepts (Singapore and Jakarta)
**Programme:** DBS Spark GenAI Programme, in partnership with IMDA and Enterprise Singapore
**Document version:** 2.0.0
**Status:** Proposed for stakeholder and technical validation
**Supersedes:** Version 1.0.0
**Revision date:** 3 November 2026
**Prototype demonstration:** Singapore; date and detailed milestones to be agreed with the Challenge Owner

---

## 1. Document Purpose

This document defines the product, user workflow, website requirements, data dependencies, integration boundaries, governance controls, prototype scope and acceptance criteria for an AI-enabled pitch and proposal solution for Flash Concepts.

It is intended to guide:

1. Stakeholder validation and technical discovery.
2. Prototype design and development.
3. Solution evaluation and user acceptance testing.
4. Future production planning, subject to prototype results.

### 1.1 Requirement Language

- **Must:** Required for the proposed prototype unless explicitly deferred by the Challenge Owner.
- **Should:** Important, but may be implemented in a constrained form during the prototype.
- **Could:** Optional or subsequent-phase functionality.
- **Validation required:** An assumption or dependency that must not be treated as confirmed fact.

### 1.2 Delivery Principle

The prototype must demonstrate one complete, auditable workflow from an approved tender brief to a reviewed final proposal. It must prioritise reliable, constrained functionality over broad but unreliable automation.

---

## 2. Business Context and Objectives

Flash Concepts is a B2B event management company with approximately 25 staff across Singapore and Jakarta. Most projects are won through competitive, unpaid pitches involving Planning, Design and Operations. A typical pitch currently takes approximately two weeks and involves around five people.

The current workflow is predominantly sequential:

1. Planning researches the client, interprets the brief and develops the concept.
2. Design produces pitch visuals and dimensioned structural material.
3. Operations prepares specifications, obtains quotations and finalises costs.

Coordination is distributed across Microsoft Teams, SharePoint and Office documents. AI tools are used in an ad-hoc manner, with limited workflow continuity and no in-house IT support.

### 2.1 Product Objective

Create a unified, cloud-based workspace that assists Planning, Design and Operations to transform a client brief into a comprehensive event proposal while:

- Reducing elapsed preparation time and repetitive effort.
- Improving the consistency, traceability and quality of proposals.
- Supporting more accurate costing and preliminary spatial checks.
- Preserving human ownership of creative, commercial, technical and compliance decisions.
- Working with Flash Concepts' existing Microsoft 365 environment.
- Remaining usable by non-technical staff without routine developer support.

### 2.2 Out-of-Scope Decisions

The following are explicitly outside the solution's authority:

| Capability | System boundary |
| :--- | :--- |
| Bid/no-bid decision | Leadership decides whether to pursue a tender. The system starts after that decision. |
| Direct client outreach | No automated contact with clients, their contacts or tender committees. |
| Detailed 3D modelling and rendering | Remains in the design team's specialist tools. The system may ingest rendered outputs and dimensioned drawings. |
| Autonomous ordering or purchasing | Not permitted. |
| Autonomous vendor negotiation | Not permitted. |
| Autonomous external email sending | Not permitted. The system may create drafts for human review and sending. |
| Statutory applications or certification | The system flags potential requirements only; qualified parties retain responsibility. |
| Final creative, copy or commercial approval | Always remains with authorised Flash Concepts staff. |

---

## 3. Success Measures and Measurement Plan

The business targets originate from the challenge brief. Prototype acceptance must be distinguished from longer-term business outcomes.

| Measure | Target | Measurement approach |
| :--- | :--- | :--- |
| Overall pitch turnaround | At least 50% reduction | Elapsed working time from brief intake after bid approval to final proposal release, compared with an agreed historical baseline. |
| Total team effort | 10–30% reduction in man-days | Record Planning, Design and Operations effort using timesheets or a lightweight per-stage effort confirmation. |
| Concept development | From 3–4 days to under 1 working day | Measure from brief intake readiness to Gate 1 approval, excluding time waiting for missing client information. |
| Design production | At least 2–3 man-days saved per pitch | Compare equivalent historical and assisted pitches using agreed effort categories. |
| Cost estimate accuracy | At least 20% improvement | Compare pitch estimates with like-for-like quoted or executed costs, excluding approved scope changes. Define the baseline error and improvement formula before the pilot. |
| Spatial accuracy | At least 15% improvement from the 70–80% benchmark | Compare approved proposal dimensions with execution records, excluding documented client or venue change requests. |
| Annual revenue | 30–50% increase over 1–2 years | Business outcome; not a prototype acceptance test. |
| Customer retention | 30–50% improvement over 1–2 years | Business outcome; measure using an agreed customer-retention definition. |
| Employee engagement or retention | 10–30% improvement | Internal surveys and retention measures; not inferred solely from system telemetry. |

### 3.1 Baseline Requirement

Before the pilot, Flash Concepts and the delivery team must agree:

- A representative set of historical pitches for baseline comparison.
- Start, stop and pause rules for elapsed-time measurement.
- Effort categories and man-day calculation.
- Cost and spatial accuracy formulas.
- Treatment of client revisions, incomplete briefs and exceptional tenders.

---

## 4. Users, Roles and Permissions

| Role | Primary responsibilities | Default permissions |
| :--- | :--- | :--- |
| Leadership / Tender Sponsor | Bid decision outside the system; final commercial release | View assigned tenders; final release approval if delegated |
| Planning Lead | Brief validation, research approval, concept selection and handover | Edit Planning stage; approve Gate 1 |
| Designer | Visual development, render ingestion and preliminary feasibility review | Edit Design stage; approve Gate 2 |
| Operations Lead | BOQ, costing, RFQs, quote reconciliation and compliance review | Edit Operations stage; approve Gate 3 |
| Copywriter | Fact-check, copy quality and final written-content approval | Review all proposal content; approve Gate 4 |
| Translation Reviewer | Review Bahasa Indonesia or other required translations | Review translation tasks assigned to the user |
| Compliance Reviewer | Approve rule sources and rule versions; may be internal or external | Manage compliance rules without editing commercial proposals |
| System Administrator | Users, templates, integrations, libraries, usage and support settings | Administration without automatic access to all tender content |
| Read-only Auditor | Review approvals, sources and exported records | Read authorised audit records |

### 4.1 Permission Rules

- Access must use registered organisational identities and role-based access control.
- Tender-level access restrictions must be supported for confidential projects.
- Approvers must be assigned by role, not hardcoded to named individuals.
- Each approval role must support an authorised delegate to prevent absence-related bottlenecks.
- Every approval, rejection, override and export must record user, timestamp and version.

---

## 5. End-to-End Workflow

### 5.1 Workflow States

`Draft → Intake Review → Planning → Gate 1 Review → Design → Gate 2 Review → Operations Estimate → RFQ / Quote Reconciliation → Gate 3 Review → Copy and Localisation Review → Final Release Review → Released / Archived`

A stage may also enter `Blocked`, `Changes Requested` or `On Hold`.

### 5.2 Detailed Workflow

#### Stage 0 — Leadership Bid Decision

1. Leadership decides whether Flash Concepts will pursue the tender.
2. This decision remains outside the system.
3. An authorised user creates a tender workspace only after approval to proceed.

#### Stage 1 — Tender Intake and Brief Review

1. Upload or select the brief and supporting documents from SharePoint.
2. Classify each document and retain its source and version.
3. Extract dates, venue, audience, deliverables, mandatory criteria, submission requirements and known constraints.
4. Display extracted fields alongside source-page references.
5. Identify missing or contradictory information without inventing values.
6. Planning confirms the intake summary before research or concept generation.

#### Stage 2 — Public Client and Event Research

1. Generate proposed public research queries from approved, non-confidential fields.
2. Show queries before execution where confidential information could be exposed.
3. Retrieve only from approved public sources and permitted access methods.
4. Cover the client's past events, company background, ongoing initiatives, products, USPs and relevant brand information where public evidence is available.
5. Present claims with source citations, retrieval dates and confidence indicators.
6. Planning accepts, edits or rejects each material research finding.
7. No direct client or contact outreach is permitted.

#### Stage 3 — Concept Development and Internal Handover

1. Generate two or three differentiated concept options.
2. Each option must include:
   - Concept title and narrative.
   - Explanation of fit to the brief.
   - Proposed event flow and experience journey.
   - Preliminary spatial or operational considerations.
   - Suggested fringe activities where relevant.
   - Scene-image concepts clearly labelled as illustrative.
3. Generate an editable PowerPoint concept deck using an approved template.
4. Planning selects and refines a concept; the system does not select it autonomously.
5. Generate team-specific handover documents:
   - Design collateral and asset list.
   - Preliminary Operations scope, information request and task list.
   - Where sufficient information exists, draft vendor enquiry emails for Operations review; no email is sent at this stage.
   - Open questions, assumptions and unresolved dependencies.

**Gate 1 — Planning Approval**

The Planning Lead must approve the selected concept, source-supported research, handover contents and known assumptions. Downstream work may begin only on approved items. A preliminary Operations brief may be released without implying that final dimensions are approved.

#### Stage 4 — Design and Preliminary Spatial Feasibility

1. Design receives the approved handover and collateral list.
2. Upload or select brand assets, templates, key visuals, rendered 3D structure images and dimensioned drawings.
3. Generate draft 2D slide layouts and key-visual compositions.
4. Combine approved rendered structure images with graphic content without attempting to replace detailed 3D modelling.
5. Use clearly marked placeholder content where approved client material is unavailable.
6. Run preliminary spatial checks against a verified venue profile.
7. Display passed, failed, unknown and not-checkable conditions separately.
8. Allow designers to revise dimensions and record assumptions.
9. Produce an editable PowerPoint draft and controlled drawing package for Operations.

**Gate 2 — Design Approval**

The Designer must approve visual outputs, dimensions and the drawing package. The approval covers proposal preparation only and does not constitute engineering or statutory approval.

#### Stage 5 — BOQ, Costing and RFQ Preparation

1. Ingest the Gate 2 drawing package.
2. Extract components, dimensions, materials, colours and quantities from supported drawing formats.
3. Show extracted values with source location and confidence.
4. Require review of low-confidence, missing or ambiguous values.
5. Map reviewed components to internal price items using item codes, units and currencies.
6. Use deterministic calculations for quantities, extensions, subtotals, tax, contingency and margin/markup.
7. Clearly separate:
   - Fixed internal items.
   - Historical or indicative prices.
   - Vendor-quoted items.
   - Unpriced or unresolved items.
   - Potential reusable assets.
8. Generate detailed specifications and draft vendor RFQ emails.
9. Suggest vendors only when supported by the approved vendor directory or an approved research process.

No RFQ is sent automatically.

#### Stage 6 — Vendor Quotation and Reconciliation

1. An authorised user reviews and sends RFQs through the approved email workflow.
2. Record RFQ recipients, sent date, requested response date and attached specification version.
3. Register returned quotations manually or through a controlled import.
4. Extract quoted items, exclusions, validity, currency, tax, lead time and assumptions where supported.
5. Compare quotes with the estimate and flag missing, duplicated or inconsistent scope.
6. Operations selects or rejects quotations; no automated negotiation occurs.
7. Update the cost estimate and retain all prior versions.
8. If drawings change, invalidate affected BOQ and quote mappings and request re-review.

#### Stage 7 — Compliance Review

1. Evaluate the approved design and event details against active, approved rules for the relevant jurisdiction and venue.
2. Each finding must include the rule, source, effective date, triggering inputs, uncertainty and required human action.
3. Include estimated compliance costs only when a supported cost basis exists.
4. Unknown rules or insufficient data must produce an explicit review task, not a pass.
5. Do not submit statutory applications.

**Gate 3 — Operations Approval**

The Operations Lead must review BOQ items, quotations, exclusions, compliance findings, cost basis and commercial calculations before approving the proposal budget.

#### Stage 8 — Copy Quality, Fact-Check and Localisation

1. Assemble the current proposal content from Planning, Design and Operations.
2. Check spelling, grammar, terminology, dates, names, numbers and cross-document consistency.
3. Verify factual claims against the brief, approved research or internal records.
4. Mark unsupported statements for revision; do not label uncertain content as verified.
5. Translate required documents while preserving layout, units, tables and technical terminology.
6. A copywriter approves final English copy.
7. A competent reviewer approves translations used externally.

Translation assistance must also be available for internal handovers, task lists and vendor specifications before Gate 4 when required for Singapore–Jakarta collaboration. Internal translations must retain source text and terminology controls; externally used translations require competent human review.

**Gate 4 — Copy and Localisation Approval**

The Copywriter and, where applicable, Translation Reviewer approve the final content. Rejected content returns to the owning stage with comments.

#### Stage 9 — Final Proposal Assembly and Release

1. Generate the final editable PowerPoint, Word and Excel outputs as required.
2. Preview the complete proposal package, including appendices, assumptions, budget and compliance notes.
3. Confirm that all mandatory gates are complete and no critical unresolved items remain.
4. An authorised final approver releases or exports the proposal.
5. Human users remain responsible for submission to the client.

**Gate 5 — Final Release Approval**

The system must prevent final release if required approvals are incomplete, the proposal contains unresolved critical errors, or documents belong to inconsistent versions.

#### Stage 10 — Archive and Learning

1. Store the released proposal, sources, approvals, costs and document versions.
2. Record actual effort and turnaround.
3. After quotations or project execution, capture comparable actual costs and spatial deviations.
4. Update libraries only through authorised review; do not silently train models on client material.

### 5.3 Rework and Change Control

- Every gate must support approve, reject with comments and request changes.
- A change to an upstream approved item must identify affected downstream artefacts.
- Material changes to concept, dimensions, venue, quantities or compliance inputs must trigger re-approval of affected gates.
- Users must be able to compare versions and restore an earlier approved version.
- Parallel work is allowed only on explicitly preliminary artefacts and must not bypass final gates.

---

## 6. External Research Requirements

### 6.1 Approved Research Model

The feature is a **human-supervised public research assistant**, not an unrestricted crawler.

The solution must:

- Use an administrator-managed registry of approved source types and access methods.
- Use publicly available client websites, public pages, press releases, news and permitted search or platform interfaces.
- Confirm that each integration or retrieval method is permitted by the relevant provider terms.
- Avoid bypassing authentication, access controls, robots controls or technical restrictions.
- Provide a manual URL or document-upload fallback when automated retrieval is unavailable.
- Never contact clients or their contacts.

### 6.2 Confidentiality Controls

- Research queries must use the minimum necessary public information.
- Confidential tender text, budgets, internal strategy and unpublished event details must not be sent to public search services.
- Potentially sensitive queries must require user confirmation.
- Research activity must be logged and auditable.

### 6.3 Evidence and Citation Model

Every material research finding must retain, where available:

- Claim or extracted fact.
- Source URL and page title.
- Publisher or site owner.
- Publication and retrieval dates.
- Relevant excerpt or archived reference.
- Extraction confidence and review status.
- User who approved or rejected the finding.

A generated statement without adequate support must be labelled as an inference, suggestion or unsupported claim.

### 6.4 Public Assets and Placeholder Content

- Logos, photographs, executive images and other third-party material must retain provenance.
- The system must not imply that public availability grants unrestricted reuse rights.
- Placeholder copy and visuals must be visibly marked as illustrative until approved.
- Financial statistics, product claims, executive identities and client statements require source support and human verification.
- The system must not fabricate client performance figures or testimonials.

---

## 7. Data Libraries and Source-of-Truth Rules

### 7.1 Venue Constraint Library

Each venue profile should contain:

- Venue, hall or room identifier and location.
- Verified floor plan or approved schematic.
- Usable dimensions, ceiling and clearance information.
- Known obstructions, rigging, power, floor-loading and access constraints where available.
- Egress and fire-safety notes supplied by authoritative sources.
- Measurement units and coordinate/reference conventions.
- Source documents, verification status, verifier and effective/review dates.
- Version history and venue-specific notes.

Unknown values must remain unknown. A preliminary spatial check must not assume a venue is compliant because data is missing.

### 7.2 Vendor and Price Library

The existing SharePoint Excel workbook is an initial source, subject to data profiling.

Required normalisation includes:

- Stable item and vendor identifiers.
- Category, description and specification attributes.
- Unit of measure and unit-conversion rules.
- Currency, tax treatment and exchange-rate date where needed.
- Unit price, labour, transport, installation and other cost components.
- Price effective date, quotation validity and source.
- Supplier capabilities, service regions and approved status.
- Active/inactive status and revision history.

The prototype may use an automatically refreshed read index for search and performance, but must not require staff to maintain duplicate manual databases. A locked proposal must retain a snapshot of the prices used.

### 7.3 Historical Project and Quotation Store

The system must progressively store:

- RFQ specification versions and recipients.
- Returned quotations and their structured interpretations.
- Selected and rejected prices, with reasons where recorded.
- Pitch estimates and comparable actual costs.
- Scope changes and exclusions.
- Links to source documents and approvals.

This store supports future estimating; it does not imply that historical prices are currently complete.

### 7.4 Reusable Asset Library

Asset reuse is conditional on usable inventory data.

Each asset record should include:

- Asset type, dimensions, material, condition and photographs where available.
- Storage location and owning project.
- Availability window and reservation status.
- Refurbishment, transport and testing requirements.
- Reuse history and disposal status.

An asset appearing in an old pitch is not sufficient evidence that it exists or is available.

### 7.5 Compliance Rule Library

Each rule must include:

- Jurisdiction, venue applicability and rule category.
- Human-readable description and structured conditions.
- Official or authoritative reference.
- Effective date, review date and version.
- Required inputs and treatment of missing values.
- Severity and resulting human task.
- Cost-estimate basis, if any.
- Approval by an authorised compliance reviewer.

Rules from earlier drafts, including numerical PE, LEW or sprinkler thresholds, are illustrative only and must remain disabled until independently validated and approved.

### 7.6 Template, Brand and Terminology Libraries

Maintain:

- Approved PowerPoint slide masters, layouts, fonts and image styles.
- Word and Excel output templates.
- Flash Concepts and approved client brand assets.
- English/Bahasa Indonesia technical terminology and preferred translations.
- Standard proposal sections, disclaimers and compliance notes.

---

## 8. Website Information Architecture and Page Requirements

### 8.1 Global Application Shell

The responsive desktop-first web application must provide:

- Microsoft organisational sign-in.
- Teams-embedded access and a supported browser experience.
- Active tender, office, language and role context.
- Global navigation for Pipeline, Planning, Design, Operations, Final Review and Repositories.
- Notifications for assignments, approvals, failures and expiring quotations.
- Search, help, feedback and access to version/audit history.
- Clear autosave, processing, offline, error and permission states.

### 8.2 Page 0 — Sign-In and Access

**Purpose:** Restrict access to authorised users.

**Requirements:**

- Entra ID single sign-on and organisational MFA policy inheritance.
- Role and tender-authorisation checks.
- Clear denied-access and expired-session states.
- No public registration or anonymous tender access.

### 8.3 Page 1 — Tender Pipeline and Handover Dashboard

**Purpose:** Provide a cross-office view of pitch status and bottlenecks.

**Main components:**

- Tender table with client, stage, owner, deadline, gate status and blocking items.
- Filters for office, team, status, deadline and assigned user.
- New Tender wizard.
- Workload and deadline indicators.
- Notifications for requested changes, overdue quotes and failed processing.
- Bottleneck panel showing actionable issues rather than generic AI messages.

**Key actions:** Create tender, assign roles, open workspace, delegate approval, filter and export status.

### 8.4 Page 2 — Tender Setup and Intake Review

**Purpose:** Establish a reliable common brief before AI-assisted work begins.

**Main components:**

- Document upload/SharePoint selector.
- Document classification and version list.
- Extracted brief fields with source references.
- Mandatory-criteria checklist.
- Missing, contradictory and unreadable content panel.
- Tender owners, deadline and language settings.

**Key actions:** Confirm field, edit extraction, request information internally, mark intake ready.

### 8.5 Page 3 — Planning Studio

**Purpose:** Research, concept development and internal handover.

**Main components:**

- Approved brief summary.
- Research query preview and source registry status.
- Evidence table with citations and review controls.
- Concept-option cards and comparison view.
- Editable narrative, event flow and experience journey.
- Scene-image generation and illustrative-content labels.
- Concept PowerPoint preview.
- Design collateral list and preliminary Operations scope.
- Assumptions and open-questions register.

**Key actions:** Run approved research, verify/reject fact, generate concepts, refine selected concept, export draft, approve Gate 1.

### 8.6 Page 4 — Design and Spatial Studio

**Purpose:** Produce editable 2D proposal material and run preliminary checks.

**Main components:**

- Approved handover and requested collateral.
- Template, brand asset, rendered-structure and drawing uploads.
- Slide and key-visual editor/compositor.
- Placeholder-content and asset-provenance indicators.
- Venue-profile selector and verification status.
- Structure dimension table and drawing references.
- Feasibility results grouped as pass, fail, warning, unknown and not checkable.
- Version comparison and change comments.

**Key actions:** Generate layouts, upload render, edit composition, run checks, revise dimensions, export drawing package, approve Gate 2.

### 8.7 Page 5 — Operations and Costing Hub

**Purpose:** Produce an auditable BOQ, obtain quotations and finalise costs.

**Tabs:**

1. **Drawing Extraction:** Components, source references, confidence and unresolved fields.
2. **BOQ and Pricing:** Item mapping, quantities, units, currencies, price basis and calculations.
3. **RFQs:** Specification sheets, vendor selection, draft emails and approval status.
4. **Quotations:** Returned quotes, scope comparison, exclusions, validity and selection.
5. **Compliance:** Rule findings, missing inputs, reviewer tasks and cost basis.
6. **Reuse:** Potential available assets and refurbishment/transport implications, if data is available.

**Commercial controls:**

- Distinguish markup from margin.
- Show formulas and rounding rules.
- Prevent final approval with unreviewed high-impact unknowns.
- Retain prior estimate versions after drawing or quote changes.

**Key actions:** Review extraction, map prices, generate RFQ, approve draft, record quote, reconcile scope, approve Gate 3.

### 8.8 Page 6 — Final Quality and Release

**Purpose:** Assemble, verify, translate and release the complete proposal.

**Main components:**

- Proposal-package manifest and version consistency indicator.
- Cross-document fact, number, date and terminology checks.
- Inline copy suggestions with accept/reject controls.
- Translation preview with layout and terminology review.
- Mandatory gate and unresolved-issue checklist.
- Final PowerPoint, Word and Excel preview/export.
- Full audit and source panel.

**Key actions:** Request changes, approve Gate 4, approve final release, export package, archive.

### 8.9 Page 7 — Repositories

**Purpose:** Manage the libraries that support all tenders.

**Sections:** Venues, prices, vendors, quotations, projects, reusable assets, compliance rules, templates, brand assets and terminology.

**Common requirements:** Search, filter, import, source display, verification status, effective date, version history, role-based editing and change approval.

### 8.10 Page 8 — Administration, Integrations and Usage

**Purpose:** Allow non-technical administration with managed technical support.

**Main components:**

- Users, roles, delegates and tender permissions.
- Microsoft integration health and permission status.
- Approved research sources and access methods.
- Model/provider configuration managed by authorised support staff.
- Template and terminology management.
- Storage, model, search and estimated cost usage.
- Job failures, audit logs and support diagnostics.

Administrators must not need to edit prompts or code for routine operation.

### 8.11 Required Interaction States

Every AI-assisted page must specify and implement:

- Empty/no-data state.
- Uploading, queued, processing and partially complete states.
- Success and human-review-required states.
- Low-confidence and missing-input states.
- Unsupported-file and extraction-failure states.
- Integration unavailable and retry states.
- Permission-denied and record-locked states.
- Rejected/rework and superseded-version states.
- Export failure and recovery states.

AI processing must be asynchronous where appropriate, with visible progress and no silent loss of user work.

---

## 9. Functional Requirement Summary

| ID | Requirement | Prototype priority |
| :--- | :--- | :--- |
| F-001 | Organisational SSO, RBAC, tender permissions and audit | Must |
| F-101 | Brief ingestion, extraction, source references and intake review | Must |
| F-102 | Human-supervised public research with approved sources and citations | Must |
| F-103 | Concept options, narratives, event flows and illustrative scene images | Must |
| F-104 | Editable PowerPoint concept output, team handovers and preliminary draft vendor enquiries | Must |
| F-105 | Versioned Gate 1 approval and controlled downstream release | Must |
| F-201 | Editable 2D slide/key-visual generation using approved templates | Must |
| F-202 | Import rendered design-team structures for 2D composition | Must |
| F-203 | Preliminary spatial checks with explicit unknown/not-checkable states | Must, constrained |
| F-204 | Versioned venue library and source documentation | Must, constrained |
| F-205 | Gate 2 approval and controlled drawing package | Must |
| F-301 | Supported-format drawing extraction and reviewed BOQ generation | Must, constrained |
| F-302 | SharePoint Excel price mapping with units, currencies and price dates | Must, subject to data profiling |
| F-303 | Specifications and draft RFQ emails with no autonomous sending | Must |
| F-304 | Returned-quote capture, reconciliation and estimate versioning | Must |
| F-305 | Approved, versioned compliance findings and missing-input tasks | Must; validated rules, or clearly labelled synthetic rules for demonstration only |
| F-306 | Reusable-asset suggestions | Could; only with reliable inventory data |
| F-307 | Gate 3 budget approval and margin/markup transparency | Must |
| F-401 | Copy quality, fact support and cross-document consistency checks | Must |
| F-402 | English/Bahasa Indonesia translation of proposals, handovers and specifications with terminology and human review | Must |
| F-403 | Final package assembly, Gate 4 copy approval and Gate 5 release | Must |
| F-501 | KPI, effort, turnaround and AI-usage recording | Must |
| F-502 | Transparent prototype operating-cost reporting | Must |

---

## 10. Microsoft 365 and Tool Integration

### 10.1 Microsoft 365

The proposed architecture uses:

- **Entra ID:** Organisational identity, MFA and conditional-access policy integration.
- **Teams:** Primary embedded workspace and notifications where supported.
- **SharePoint:** Existing document locations, source documents and controlled proposal outputs.
- **Excel on SharePoint:** Initial vendor/fixed-price source, subject to schema and quality assessment.
- **PowerPoint:** Editable concept and proposal decks using approved slide masters.
- **Word:** Handover, specification and proposal documents.
- **Outlook:** Human-reviewed draft RFQ emails, if the required tenant permissions and licensing are confirmed.
- **Microsoft Graph or supported APIs:** File, user and collaboration integration, subject to permission approval.

Technical discovery must confirm tenant configuration, API permissions, admin consent, licensing and acceptable integration patterns before implementation.

### 10.2 Existing AI and Design Tools

Flash Concepts currently uses tools including Microsoft Copilot, ChatGPT, Gemini, Adobe Firefly and Claude in fragmented workflows. The solution is not required to integrate every tool.

During discovery, record:

- Which tools are licensed and actively used.
- Which tasks should move into the unified workflow.
- Which tools remain specialist destinations.
- Required import/export formats and asset-provenance handling.

No specific CAD or 3D application is assumed. Direct CAD/3D plug-ins are outside the initial prototype unless separately agreed; controlled file import/export is the default boundary.

### 10.3 File Fidelity

Office exports must be tested for:

- Editable text, shapes and tables rather than flattened slide images where editing is required.
- Correct slide master, theme, fonts, image cropping and aspect ratio.
- Word styles, headers/footers, tables and pagination.
- Excel formulas, units, currencies and source references.
- Language and font support for Bahasa Indonesia.
- Version compatibility with Flash Concepts' actual Office environment.

---

## 11. AI, Calculation and Safety Architecture

### 11.1 Separation of Responsibilities

- AI may extract, summarise, classify, suggest, translate and generate draft content.
- Deterministic services must perform supported arithmetic, unit conversion, quantity extensions, subtotals, margin/markup and rule evaluation.
- Qualified humans remain responsible for engineering, legal, regulatory, commercial and final-content decisions.

### 11.2 Grounding and Traceability

- Brief extractions must reference source documents and pages/regions where supported.
- Research claims must cite external evidence.
- BOQ values must reference source drawings and reviewed extraction fields.
- Price lines must identify their price source and effective date.
- Compliance findings must reference an approved rule version.
- Locked outputs must preserve the source and model/prompt version metadata needed for audit.

### 11.3 Confidence and Failure Handling

- Confidence indicators must be accompanied by actionable review cues.
- Low-confidence output must not silently become approved fact.
- Unsupported file types or ambiguous drawings must route to manual entry.
- Missing data must remain blank or unknown, not be filled with invented values.
- Model failure must preserve work and permit retry, manual editing or provider fallback where configured.

### 11.4 Untrusted Content and Prompt Injection

Tender documents, emails, drawings and web content must be treated as untrusted input.

The solution must:

- Separate source content from system and tool instructions.
- Prevent retrieved text from changing system rules or triggering unauthorised tools.
- Restrict tool permissions and external actions.
- Scan uploads and validate supported file types.
- Require human approval for all external communications and final exports.

### 11.5 Model Data Use

- Client content must not be used to train public foundation models.
- Provider retention, logging, subprocessors and regional processing terms must be verified contractually and technically.
- Model/provider changes must be logged and regression-tested on representative cases.

---

## 12. Security, Privacy and Governance

### 12.1 Required Controls

- Organisational SSO, MFA and least-privilege access.
- Role- and tender-level authorisation enforced server-side.
- Encryption in transit and at rest.
- Managed secrets; no credentials stored in documents or client-side code.
- Audit logs for sign-in, exports, approvals, external research, RFQ drafts, permission changes and library edits.
- Defined data retention, deletion, archive and legal-hold procedures.
- Backup and restoration procedures appropriate to prototype and production phases.
- Monitoring, incident response and support ownership.
- Secure software development, dependency management and pre-release security testing.

### 12.2 Privacy and Cross-Border Review

The design must support Singapore PDPA obligations and a review of other applicable requirements for Jakarta operations and cross-border processing.

Before production, confirm:

- Data locations and cross-border transfer mechanism.
- Approved subprocessors and model providers.
- Personal-data categories and retention periods.
- User access, correction and deletion procedures where applicable.
- Client contractual confidentiality requirements.

### 12.3 Compliance Disclaimer

System-generated spatial and statutory findings are preliminary decision support. They are not engineering certification, legal advice or evidence that an installation is safe or approved.

---

## 13. Non-Functional Requirements

### 13.1 Usability

- Non-technical users must complete the standard workflow without prompt engineering.
- Use familiar Microsoft-oriented terminology and consistent stage navigation.
- Provide inline guidance, templates and a short role-based onboarding flow.
- Display why an item is blocked and who can resolve it.
- Avoid requiring routine database, server or code administration.

### 13.2 Initial Design Targets

These are proposed prototype targets and should be confirmed during discovery:

- Support Flash Concepts' approximately 25 staff, with at least 10 concurrent users.
- Optimise for current Microsoft Edge and Google Chrome desktop browsers.
- Use metric units by default, with explicit unit display and controlled conversion.
- Support SGD and IDR without implicit currency conversion; record exchange-rate source/date when used.
- Meet WCAG 2.2 AA accessibility expectations for core workflows where practical.
- Keep routine navigation responsive; run AI and large-file operations asynchronously with status feedback.
- Set document, drawing and image size/page limits after profiling representative client files.

### 13.3 Reliability and Support

- Autosave user edits and prevent silent data loss.
- Provide idempotent retry for failed processing jobs.
- Monitor integration, model, search and export failures.
- Provide a managed support path and named support owner.
- Define production availability and recovery objectives separately after prototype evaluation.

---

## 14. Operating Cost and Scalability Model

A numeric cost forecast must be completed after provider selection and workload profiling. The specification must not imply that predictable billing exists without this analysis.

### 14.1 Cost Inputs

- Number of active users and pitches per month.
- Pages and files processed per pitch.
- Research queries and source-retrieval volume.
- Scene-image generation count and resolution.
- Model token usage by workflow stage.
- Drawing extraction and processing requirements.
- Storage, bandwidth, backup and audit retention.
- Microsoft licensing or additional platform costs.
- Support, monitoring, maintenance and rule-library review.

### 14.2 Required Forecast

Provide:

- Fixed monthly platform cost.
- Estimated variable cost per pitch by low, typical and high usage.
- Estimated total monthly cost at agreed pitch volumes.
- Per-feature usage visibility and configurable budget alerts/caps.
- Production support and maintenance cost.
- Assumptions, exclusions and sensitivity to increased usage.

`Estimated monthly cost = fixed platform and support cost + (monthly pitches × variable cost per pitch) + exceptional usage`

---

## 15. Prototype Scope and Delivery Milestones

### 15.1 Prototype Boundary

The prototype must demonstrate an end-to-end thin slice with controlled inputs:

- Representative tender documents in agreed PDF/DOCX formats.
- Approved public research sources with a manual fallback.
- Approved PowerPoint, Word and Excel templates.
- Agreed rendered-image and dimensioned-drawing formats.
- A constrained set of drawing conventions for BOQ extraction.
- A profiled sample price workbook.
- A small set of verified venue profiles.
- A small set of independently validated compliance rules, or clearly marked synthetic demonstration rules that are not represented as law.

### 15.2 Deferred or Conditional Functionality

- Unrestricted free-form sketch recognition.
- Full geometric/CAD collision analysis.
- Automated engineering or statutory conclusions.
- Direct integration with every existing AI or design tool.
- Vendor negotiation and autonomous sending.
- Asset-reuse recommendations without reliable inventory data.
- Production-scale regional compliance coverage.

### 15.3 Milestones and Exit Criteria

| Milestone | Deliverables | Exit criteria |
| :--- | :--- | :--- |
| M0 — Discovery and validation | Tool inventory, representative samples, data-profile report, research-source policy, rule-validation plan, KPI baseline and final prototype scope | P0 entry checklist approved |
| M1 — Foundation | SSO/RBAC, tender workspace, SharePoint connection, audit, templates and processing states | Authorised users can create and access controlled tenders |
| M2 — Planning slice | Intake review, cited research, concepts, Office output, handover and Gate 1 | Planning acceptance tests pass |
| M3 — Design and Operations slice | Render composition, preliminary checks, constrained BOQ, price mapping, RFQs, quote reconciliation and Gates 2–3 | Design and Operations acceptance tests pass |
| M4 — Quality and release | Fact/copy checks, translation review, final assembly, Gates 4–5 and archive | Complete proposal can be reviewed and released |
| M5 — Pilot and evaluation | Representative end-to-end runs, issue resolution, KPI report, cost forecast and production recommendation | Stakeholder demo and evaluation completed in Singapore |

Exact dates and resource commitments must be added to the submission/delivery plan after scope and data readiness are confirmed.

---

## 16. Prototype Acceptance Tests

| ID | Acceptance test | Expected result |
| :--- | :--- | :--- |
| AT-01 | Upload representative briefs | Required fields are extracted or explicitly marked missing, with source references and editable review. |
| AT-02 | Run approved public research | Material claims have citations and review status; no confidential query or direct outreach occurs. |
| AT-03 | Generate concepts and handover | Multiple differentiated options and an editable PowerPoint/handover are produced using approved templates. |
| AT-04 | Attempt to bypass Gate 1 | Downstream approved release is blocked; authorised review and delegation work correctly. |
| AT-05 | Import a design-team rendered structure | The render can be combined into an editable 2D proposal composition without performing 3D modelling. |
| AT-06 | Run known spatial test cases | Deterministic checks produce expected pass/fail results; missing data produces unknown/not-checkable states. |
| AT-07 | Process supported and unsupported drawings | Supported drawings yield reviewable extraction; unsupported input routes to manual handling without invented values. |
| AT-08 | Map BOQ to sample Excel prices | Units, currencies, price dates and unmatched items are visible; calculations are reproducible. |
| AT-09 | Generate and process an RFQ | Only a draft is created; human sending is recorded and a returned quote can be reconciled. |
| AT-10 | Change a drawing after quotation | Affected BOQ, quotes and approvals are flagged for review and prior versions remain available. |
| AT-11 | Evaluate compliance rules | Findings show rule version, source, trigger and missing inputs; unvalidated demonstration rules are clearly labelled. |
| AT-12 | Perform copy and translation review | Copywriter and translation reviewer approvals are enforced; layout and terminology remain reviewable. |
| AT-13 | Attempt final release with open critical issues | Release is blocked until required approvals and version consistency are achieved. |
| AT-14 | Test permissions and audit | Users cannot access unauthorised tenders/actions; approvals, exports and changes are auditable. |
| AT-15 | Simulate model/search/integration failures | Work is preserved, actionable errors appear and safe retry/manual paths are available. |
| AT-16 | Review usage and KPI reporting | Turnaround, effort and AI/resource usage can be exported for evaluation and cost forecasting. |

Business KPI targets should be evaluated over a suitable pilot and deployment period; they must not be claimed solely from a scripted prototype demonstration.

---

## 17. Key Risks and Mitigations

| Risk | Impact | Mitigation |
| :--- | :--- | :--- |
| Unverified regulatory thresholds | Unsafe or incorrect compliance advice | Disable unvalidated rules; authoritative sources, qualified review and versioned governance. |
| Free-form drawing variability | Incorrect BOQ and costs | Constrain prototype inputs, confidence/review controls, deterministic calculations and manual fallback. |
| Incomplete venue or price data | False pass results or unreliable estimates | Data profiling, verification states, unknown handling and source/effective-date tracking. |
| Public-source access restrictions | Research feature fails or violates provider terms | Approved source registry, permitted interfaces, query logging and manual fallback. |
| Confidential data in research queries | Client confidentiality breach | Query minimisation, sensitive-query preview, logging and technical restrictions. |
| Fabricated client facts or financial content | Reputational and commercial harm | Citations, unsupported-claim labels, placeholder marking and human verification. |
| SharePoint/Office permission or fidelity issues | Broken integration and unusable outputs | Early tenant validation and automated/manual Office fidelity testing on real templates. |
| Strict sequential gates create delays | Turnaround target not achieved | Controlled preliminary parallel work, delegates, clear blockers and selective re-approval. |
| AI or search usage causes cost spikes | Unsustainable operating cost | Usage metering, budget alerts/caps, caching where appropriate and transparent cost model. |
| No in-house IT | Poor adoption and unresolved failures | Managed support, simple administration, integration-health UI and role-based onboarding. |
| Cross-border data handling | Privacy or contractual exposure | Data-location, subprocessor and applicable-jurisdiction review before production. |

---

## 18. P0 Entry Checklist Before Development

Development may begin when the following are complete or explicitly time-boxed in the approved prototype plan:

- [ ] Representative briefs, proposals, drawings, venue records, price workbooks and quotations have been provided under appropriate confidentiality controls.
- [ ] Actual Microsoft 365 tenant, licensing, permissions, admin consent and Office versions have been assessed.
- [ ] Actual design tools and prototype import/export formats have been confirmed.
- [ ] Approved external research sources, access methods and confidentiality rules have been agreed.
- [ ] Price, venue and asset data readiness has been profiled; missing library data has an owner.
- [ ] Numerical compliance thresholds have been independently validated or removed/disabled for the prototype.
- [ ] Supported drawing conventions and BOQ extraction limits have been documented.
- [ ] Gate 4 copywriter, translation reviewer and Gate 5 final approver roles have been assigned.
- [ ] Markup, margin, tax, contingency, currency and rounding rules have been agreed.
- [ ] KPI baselines and measurement formulas have been agreed.
- [ ] Security, retention, model-provider and cross-border requirements have been reviewed.
- [ ] Prototype milestones, acceptance cases and a numeric operating-cost forecast plan have been approved.

---

## 19. Brief Traceability Matrix

| Brief requirement | Specification coverage |
| :--- | :--- |
| Brief analysis and internal handover | Stages 1 and 3; F-101, F-104; Pages 2 and 3 |
| Public client/event research; no outreach | Stage 2; Section 6; F-102 |
| Concept options in PowerPoint and scene images | Stage 3; F-103/F-104; Page 3 |
| 2D key visuals using design-team structures | Stage 4; F-201/F-202; Page 4 |
| Spatial feasibility and venue library | Stage 4; Sections 7.1 and 11; F-203/F-204 |
| Drawing recognition, BOQ and pricing | Stage 5; F-301/F-302; Page 5 |
| Detailed specifications and draft vendor emails | Stages 5–6; F-303/F-304 |
| Reuse opportunities | Section 7.4; F-306; conditional on inventory data |
| Compliance flagging and associated costs | Stage 7; Sections 7.5 and 12.3; F-305 |
| Copy quality and fact-checking | Stage 8; F-401; Page 6 |
| English/Bahasa Indonesia translation | Stage 8; F-402; terminology library |
| Microsoft 365 integration | Section 10 |
| Ease of use and no in-house IT | Sections 8, 13 and 15 |
| Human checkpoints | Gates 1–5 and Section 5.3 |
| Sustainable operating cost | Section 14 and F-502 |
| Security and registered-user access | Sections 4 and 12 |
| Prototype demonstration in Singapore | M5 and document control |
| Success metrics | Section 3 and AT-16 |

---

## 20. Revision Summary from Version 1.0.0

Version 2.0.0 introduces the following material changes:

1. Reframes public research as a human-supervised, source-governed capability.
2. Adds confidentiality controls for research queries and provenance controls for public assets.
3. Treats all unverified regulatory thresholds as disabled examples rather than confirmed law.
4. Adds quote-return ingestion, scope reconciliation and estimate versioning.
5. Adds rendered-structure ingestion for 2D design composition.
6. Distinguishes preliminary spatial checks from professional engineering conclusions.
7. Adds copywriter, translation and final-release approval gates.
8. Adds rework, delegation, change-impact and version-consistency workflows.
9. Defines required libraries, data provenance and unknown-value handling.
10. Expands website requirements to include intake, final review, repositories, administration and failure states.
11. Separates AI extraction/generation from deterministic commercial and rule calculations.
12. Adds prompt-injection controls, operational security, acceptance tests and a measurable prototype boundary.
13. Replaces unsupported tool and delivery-date assumptions with explicit discovery dependencies.
