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

See `skills/apex-design-system/references/brand-layer.md` and `skills/apex-design-system/references/craft.md`.

### 5.1 Design reference

See `skills/apex-design-system/references/design-reference.md`. Write "none supplied" if the requirement has no reference URL.

- **Reference URL**:
- **Capture**: `working/page-design/design/reference/` (date, desktop and mobile screenshots viewed: yes / no)
- **Brand kit**: `working/page-design/design/brand/brand-kit.json` (generated `css/brand.css`; contrast: see `kit-report.md`)
- **Design score**: `working/design-preview/<name>/score/score.md` (total /100, PASS / FAIL, rounds)
- **Character in one sentence**:
- **Signature element translated into APEX**:
- **Borrowed** (colour roles, type character, shape, depth, density):
- **Not copied** (logos, imagery, copy, font files, markup):
- **Font substitution** (reference font → open-licence font → why):

Prototype vs reference iteration log:

| Round | Score | Biggest differences from the reference (from `compare-desktop.png`) | `brand-kit.json` / spec changes |
| --- | ---: | --- | --- |
| 1 | | | |
| 2 | | | |

Remaining differences accepted, and why:

### 5.2 Style decision

- **Base theme / stock style** (the floor, not the design):
- **Freedom level**: L1 tokens / L2 brand components / L3 custom style / L4 custom templates, and why
- **Tone and signature element**:

Signature elements: one row for every visual or interactive element the requirement names (live clock, chart, ring, confirmation dialog, spinner, legend, week strip, KPI tile). Each needs a concrete mechanism. "CSS class" alone is not a mechanism for anything that moves or holds data.

| Element (requirement wording) | Page | Mechanism (APEX component, Dynamic Action, page JS, `brand-*` class) | Data source |
| --- | --- | --- | --- |
| | | | |

Token table (name tokens by role, e.g. `--brand-primary`, not by colour, e.g. `--brand-teal`):

Lever decisions (`craft.md` §2): header, ground and surfaces, typography, primary action, region chrome, navigation, reports, status, empty states, home page. One line each: what changes, or why it stays default.

| Token | Value | Source (user / reference / derived / UT default) | Contrast check |
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

The cited line must be the line that implements the requirement: the region, column, process, rule, or CSS declaration, not a brace, a code fence, or a `layout {` line. `verify-delivery.ps1` fails a row when the cited line is structural, or when nothing within 15 lines mentions the requirement's identifiers or key words. A row that is only partly built is `NOT DONE: <what is missing>`, not `DONE`.

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
