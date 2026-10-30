# Oracle APEX Harness Rules

- Read `AGENTS.md` at the project root at the start of every task.
- For APEX, business-design, PL/SQL, or APEXLang work, read `skills/apex-domains/SKILL.md` and `skills/apex-delivery/SKILL.md`.
- For visual/UX design, page mapping, custom look, or redesign, read `skills/apex-design-system/SKILL.md`, `skills/apex-ui-redesign/SKILL.md`, and `skills/apex-ui-redesign/references/design-scorecard.md` before changing layout, theme, templates, or custom CSS. Use `scripts/verify-design-preview.mjs` for rendered evidence.
- Confirm APEX 26.1 or 26.2 before using component syntax. Never mix versions.
- Respect user's page design: When `working/page-design/requirement.md` is present, strictly adhere to the user's page numbers, names, layout, and component flow. Do not invent an arbitrary page architecture.
- Design before code: write `working/page-design/application-design.md` from `docs/templates/application-design.template.md`, get the user's approval, then build. Never edit `requirement.md`; keep the requirement trace in `application-design.md` up to date (`DONE` with file:line, or `NOT DONE: <reason>`).
- Keep business logic in PL/SQL packages; page processes orchestrate.
- Read the package `.pks` before calling it from `.apx`: assign a FUNCTION's result (`l_id := pkg.f(...)`), call a PROCEDURE as a statement, and use the spec's exact parameter names. `apex validate` does not compile this code; `verify-delivery.ps1` does check it.
- Design fidelity is not optional: build every element `requirement.md` names (chart, live clock, confirmation, spinner, legend, status pills), and cite the line that implements it in the trace. Never fill KPI items with hard-coded numbers. If something is not built, mark it `NOT DONE: <reason>`.
- Auto-validate on generate or modify: Every time any .apx file under working/app/ is created, regenerated, or modified, the agent MUST immediately execute `scripts/normalize-apx-tree.ps1` and `scripts/validate-apex-app.ps1` in the same turn before reporting to the user. Require `Validation successful` with no `FILE_IGNORED`, compile diagnostics, or `ORA-` errors. Never ask the user to validate manually.
- Proactive deployment offer: Once application generation and validation pass, proactively ask the user directly if they want the agent to automatically execute Step 1 (database schema & package deployment) and Step 2 (APEX app import into target/local workspace). When deploying, the pipeline automatically provisions the target APEX workspace, administrator account (ADMIN; password from ORACLE_PASSWORD, recorded in working/page-design/credentials.md), and seeded test accounts with no manual credential setup required.
- Maintain credentials in file: Record and maintain application and workspace access credentials in `working/page-design/credentials.md`. Do not dump the credentials card in every output turn; reference or link to `working/page-design/credentials.md` upon initial deployment or when explicitly asked.
- `.apx` files must be UTF-8 without a BOM and use LF endings.
- Deploy only with explicit approval for the named target and a `-WhatIf` preview.
- Diagnose APEXLang or database errors with `skills/harness/error-triage/SKILL.md`; stop after three fix attempts on the same diagnostic.
- Do not request, print, or store API keys. Use a local or free model.
- Do not place credentials, connection strings, or wallet contents in files.
- Delivery gate: before reporting delivery, run `scripts/verify-delivery.ps1 -ProjectDirectory working` and require `DELIVERY GATE PASS`.

## Delivery contract

Canonical source: `AGENTS.md`. `scripts/test-harness.ps1` fails if this block drifts out of an adapter.

- `working/page-design/requirement.md` is user-owned: read it, never edit it.
- Before writing SQL or `.apx`, write `working/page-design/application-design.md` from `docs/templates/application-design.template.md` (design, rule-to-PL/SQL mapping, brand layer, requirement trace) and stop for user approval.
- Custom look: `skills/apex-design-system/references/brand-layer.md`. Stock Universal Theme is the floor, not the ceiling; user brand values are requirements.
- Gates: `scripts/validate-apex-app.ps1` must print `Validation successful`; `scripts/verify-delivery.ps1 -ProjectDirectory working` must print `DELIVERY GATE PASS`. Fix the build, never the trace.
