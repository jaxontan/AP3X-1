# Application Design

<!--
Owned by the AGENT. Generated from working/page-design/requirement.md before any code is written.
The user reviews and approves this file; implementation starts only after approval.
Never edit requirement.md to make it match this design. If they disagree, requirement.md wins
or the disagreement is listed under "Open questions" for the user to decide.
-->

| Field | Value |
| --- | --- |
| Status | DRAFT / APPROVED / IMPLEMENTED |
| Approved by / date | |
| Requirement source | `working/page-design/requirement.md` (last read: YYYY-MM-DD) |
| APEX version | 26.1 / 26.2 (from `.apex/apexlang.json`) |
| Application ID / alias | |
| Workspace | |

---

## 1. Design brief

- **Problem and goal**:
- **Actors and roles**:
- **Assumptions** (anything not stated in `requirement.md`):
- **Open questions** (block approval until answered):

## 2. Data model

| Table / view | Purpose | Key columns | Constraints and triggers |
| --- | --- | --- | --- |
| | | | |

## 3. Security model

| Authorization scheme | Rule | Implemented by |
| --- | --- | --- |
| | | |

Row-level security per page/report:

## 4. Business rules → enforcement

Every rule in `requirement.md` section "Business Rules & Validations". Each rule is enforced in the PL/SQL package; page validations are for UX only.

| Rule | PL/SQL enforcement (package.procedure) | Page validation / UI behaviour | Test |
| --- | --- | --- | --- |
| R1 | | | |

## 5. Visual design (brand layer)

See `skills/apex-design-system/references/brand-layer.md`.

- **Base theme / stock style**:
- **Freedom level**: L1 tokens / L2 brand components / L3 custom style / L4 custom templates, and why
- **Tone and signature element**:

Token table:

| Token | Value | Source (user / derived / UT default) | Contrast check |
| --- | --- | --- | --- |
| `--brand-primary` | | | |

Brand class inventory:

| Class | Purpose | Used on |
| --- | --- | --- |
| `brand-` | | |

Dark mode and reduced motion:

## 6. Page map and component map

Repeat per page, in `requirement.md` order. Page numbers must match `requirement.md`.

### Page N: Name

- **Purpose / primary action**:
- **Authorization**:
- **Regions (visual order)**:

| Region | APEX region type / template | Template options / `cssClasses` | `staticId` |
| --- | --- | --- | --- |
| | | | |

- **Items, buttons, processes, validations, branches**:
- **Empty / error / loading states**:
- **Navigation in / out**:

## 7. APEXLang file map

| File | Create / change | Contents |
| --- | --- | --- |
| `app/application.apx` | | |
| `app/shared-components/static-files/css/brand.css` | | |

## 8. Requirement trace

**Every bullet in `requirement.md`**: overview, design direction, each page element, each rule. One row each. Filled with `PLANNED` before approval, then updated to file:line after implementation. Nothing may be silently dropped.

| # | Requirement (quoted or paraphrased) | Status | Implemented at (file:line) | Notes |
| --- | --- | --- | --- | --- |
| 1 | | PLANNED / DONE / NOT DONE: reason | | |

## 9. Acceptance checks

What a reviewer can check on the running app, per role.

- [ ]

## 10. Change log

| Date | Change | Reason |
| --- | --- | --- |
| | Initial design | |
