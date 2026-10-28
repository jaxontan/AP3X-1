# Oracle APEX Harness Rules

- Read `AGENTS.md` at the project root at the start of every task.
- For APEX, business-design, PL/SQL, or APEXLang work, read `skills/apex-domains/SKILL.md` and `skills/apex-delivery/SKILL.md`.
- Confirm APEX 26.1 or 26.2 before using component syntax. Never mix versions.
- Model the business domain, rules, and page map before writing pages.
- Keep business logic in PL/SQL packages; page processes orchestrate.
- Validate with `scripts/validate-apex-app.ps1` and require `Validation successful` with no `FILE_IGNORED`, compile diagnostics, or `ORA-` errors.
- `.apx` files must be UTF-8 without a BOM and use LF endings.
- Deploy only with explicit approval for the named target and a `-WhatIf` preview.
- Diagnose APEXLang or database errors with `skills/harness/error-triage/SKILL.md`; stop after three fix attempts on the same diagnostic.
- Do not request, print, or store API keys. Use a local or free model.
- Do not place credentials, connection strings, or wallet contents in files.
