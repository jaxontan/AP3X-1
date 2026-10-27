# Oracle APEX Harness Rules

- Read `AGENTS.md` at the project root at the start of every task.
- For APEX, business-design, PL/SQL, or APEXLang work, read `skills/apex-domains/SKILL.md` and `skills/apex-delivery/SKILL.md`.
- Confirm APEX 26.1 or 26.2 before using component syntax. Never mix versions.
- Model the business domain, rules, and page map before writing pages.
- Keep business logic in PL/SQL packages; page processes orchestrate.
- Validate with `scripts/validate-apex-app.ps1` and require `Validation successful`.
- Deploy only with explicit approval and a `-WhatIf` preview.
- Do not request, print, or store API keys. Use a local or free model.
- Do not place credentials, connection strings, or wallet contents in files.
