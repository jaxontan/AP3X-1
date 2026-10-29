---
name: oracle-apex
description: Oracle APEX engineering bridge for this repository. Use for business analysis, domain modeling, APEX application design, PL/SQL, SQL, and APEX 26.1/26.2 APEXLang work. Routes to the canonical AGENTS.md and the four-domain skill.
---

# Oracle APEX Bridge

The canonical instructions are `AGENTS.md` at the project root.

For any Oracle APEX, business-design, PL/SQL, or APEXLang task, read:

1. `skills/apex-domains/SKILL.md`
2. `skills/apex-design-system/SKILL.md`
3. `skills/apex-ui-redesign/SKILL.md` and `skills/apex-ui-redesign/references/design-scorecard.md` when changing an existing look
4. `skills/apex-delivery/SKILL.md`
5. `skills/apex/apexlang/SKILL.md` (then 26.1 or 26.2)
6. `skills/db/SKILL.md` when database detail is needed

Rules:

- Model the business domain before designing pages.
- Keep business rules in PL/SQL packages; page processes orchestrate.
- Do not invent APEX syntax; use the matching inventory and examples.
- Validate with `scripts/validate-apex-app.ps1` and require `Validation successful` with no `FILE_IGNORED`, compile diagnostics, or `ORA-` errors.
- `.apx` files must be UTF-8 without a BOM and use LF endings.
- Deploy only with explicit approval for the named target and a `-WhatIf` preview.
- Diagnose APEXLang or database errors with `skills/harness/error-triage/SKILL.md`; stop after three fix attempts on the same diagnostic.
- No API keys, connection strings, or wallet contents in files.
- Visual changes require before/after scorecards and a `scripts/verify-design-preview.mjs` report; the designer cannot run the browser check.

## Delivery contract

Canonical source: `AGENTS.md`. `scripts/test-harness.ps1` fails if this block drifts out of an adapter.

- `working/page-design/requirement.md` is user-owned: read it, never edit it.
- Before writing SQL or `.apx`, write `working/page-design/application-design.md` from `docs/templates/application-design.template.md` (design, rule-to-PL/SQL mapping, brand layer, requirement trace) and stop for user approval.
- Custom look: `skills/apex-design-system/references/brand-layer.md`. Stock Universal Theme is the floor, not the ceiling; user brand values are requirements.
- Gates: `scripts/validate-apex-app.ps1` must print `Validation successful`; `scripts/verify-delivery.ps1 -ProjectDirectory working` must print `DELIVERY GATE PASS`. Fix the build, never the trace.
