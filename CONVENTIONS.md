# Aider Adapter

This repository is an Oracle APEX agent harness. `AGENTS.md` is the canonical instruction set. Aider does not discover instruction files on its own, so `.aider.conf.yml` loads this file and `AGENTS.md` as read-only context on every run. Read both before the first edit.

## Required reading by task

Aider has no skill auto-discovery. Add the matching files with `/read` (reference) or `/add` (editable) before starting work.

- Business analysis, domain model, application design, PL/SQL, or APEXLang: `skills/apex-domains/SKILL.md`.
- Visual/UX design, page mapping, custom look, or redesign: `skills/apex-design-system/SKILL.md`, `skills/apex-ui-redesign/SKILL.md`, and `skills/apex-ui-redesign/references/design-scorecard.md`.
- Any visual decision: `skills/apex-design-system/references/craft.md`.
- A design reference website (URL in `requirement.md` or the request): `skills/apex-design-system/references/design-reference.md`; capture it with `node scripts/capture-design-reference.mjs --url <url>` and view the screenshots before designing.
- Any design direction in `requirement.md` (colours, badges, shadows, tone), new app or existing: `skills/apex-design-system/references/brand-layer.md`. Stock Universal Theme is the floor, not the ceiling; user-supplied brand values are requirements.
- Any APEX creation, change, validation, or deployment: `skills/apex-delivery/SKILL.md`.
- APEX syntax: `skills/apex/apexlang/SKILL.md`, then the matching 26.1 or 26.2 skill.
- Oracle Database, SQL, or PL/SQL detail: `skills/db/SKILL.md`.
- APEXLang, import, or `ORA-` error diagnosis: `skills/harness/error-triage/SKILL.md`.
- Security review: `skills/harness/security-review/SKILL.md`.

## Aider mechanics in this repository

- `/read <path>` loads reference material. `/add <path>` loads files Aider may edit. `/drop` frees context.
- Aider has no MCP client, so the `oracle-sqlcl` server is unavailable. Run metadata queries through `/run` with `tools/sqlcl/bin/sql` (`tools/sqlcl/bin/sql.exe` on Windows) or `scripts/sqlcl-mcp.mjs` is not usable here.
- `.apx` has no tree-sitter grammar. It does not appear in the repo map and Aider's built-in linter cannot parse it, so `/add` the page files explicitly and never assume a silent edit was valid.
- `/test` runs `test-cmd` from `.aider.conf.yml` (`scripts/validate-apex-app.ps1`). Run it after every `.apx` change.
- Aider commits each edit by default. Review the diff, and use `/undo` if the gate fails.
- There are no subagents in Aider. Do the review inline, then let the deterministic gates decide.

## Non-negotiables

- Confirm the APEX version before using any component syntax.
- Build the domain model and page map before writing pages for a new feature. Write them to `working/page-design/application-design.md` from `docs/templates/application-design.template.md` (design, rule-to-PL/SQL mapping, brand layer, requirement trace) and get user approval before writing SQL or `.apx`. Never edit `working/page-design/requirement.md`; it is user-owned.
- Keep business rules in PL/SQL packages; page processes orchestrate.
- Run `scripts/validate-apex-app.ps1` and require `Validation successful` with no `FILE_IGNORED`, compile diagnostics, or `ORA-` errors.
- Run `scripts/verify-delivery.ps1 -ProjectDirectory working` and require `DELIVERY GATE PASS` before reporting delivery.
- `.apx` files must be UTF-8 without a BOM and use LF endings. `.aider.conf.yml` sets `line-endings: lf`; do not override it.
- Deploy only with explicit approval for the named target and a `-WhatIf` preview.
- Do not place credentials, connection strings, or wallet contents in the repository.

## Delivery contract

Canonical source: `AGENTS.md`.

- `working/page-design/requirement.md` is user-owned: read it, never edit it.
- Before writing SQL or `.apx`, write `working/page-design/application-design.md` from `docs/templates/application-design.template.md` and stop for user approval.
- Custom look: `skills/apex-design-system/references/brand-layer.md`. Stock Universal Theme is the floor, not the ceiling; user brand values are requirements.
- Gates: `scripts/validate-apex-app.ps1` must print `Validation successful`; `scripts/verify-delivery.ps1 -ProjectDirectory working` must print `DELIVERY GATE PASS`. Fix the build, never the trace.

## No API key policy

- Aider defaults to OpenAI and Anthropic models and reads `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` from the environment. Do not use a paid key with this harness.
- Use a local model instead: `ollama serve`, then `aider --model ollama/<model>`.
- Do not put API keys in `.aider.conf.yml` and do not commit `.env`.
- If you need a hosted model, use an existing subscription login in a host that supports one. See `docs/harnesses/README.md` for the no-key matrix.

## Working style

Lead with the outcome, then evidence, then residual risks. Do not claim a file was validated or a database was changed unless the command output proves it.
