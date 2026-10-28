---
name: oracle-apex
description: Oracle APEX engineering bridge for this repository. Use for business analysis, domain modeling, APEX application design, PL/SQL, SQL, and APEX 26.1/26.2 APEXLang work. Routes to the canonical AGENTS.md and the four-domain skill.
---

# Oracle APEX Bridge

The canonical instructions are `AGENTS.md` at the project root.

For any Oracle APEX, business-design, PL/SQL, or APEXLang task, read:

1. `skills/apex-domains/SKILL.md`
2. `skills/apex-delivery/SKILL.md`
3. `skills/apex/apexlang/SKILL.md` (then 26.1 or 26.2)
4. `skills/db/SKILL.md` when database detail is needed

Rules:

- Model the business domain before designing pages.
- Keep business rules in PL/SQL packages; page processes orchestrate.
- Do not invent APEX syntax; use the matching inventory and examples.
- Validate with `scripts/validate-apex-app.ps1` and require `Validation successful` with no `FILE_IGNORED`, compile diagnostics, or `ORA-` errors.
- `.apx` files must be UTF-8 without a BOM and use LF endings.
- Deploy only with explicit approval for the named target and a `-WhatIf` preview.
- Diagnose APEXLang or database errors with `skills/harness/error-triage/SKILL.md`; stop after three fix attempts on the same diagnostic.
- No API keys, connection strings, or wallet contents in files.
