# Claude Code Adapter

This repository is an Oracle APEX agent harness. `AGENTS.md` is the canonical instruction set. Read it first, then follow this adapter.

## Required reading by task

- Business analysis, domain model, application design, PL/SQL, or APEXLang: `skills/apex-domains/SKILL.md`.
- Visual/UX design, page mapping, custom look, or redesign: `skills/apex-design-system/SKILL.md`, `skills/apex-ui-redesign/SKILL.md`, and `skills/apex-ui-redesign/references/design-scorecard.md`.
- Any design direction in `requirement.md` (colours, badges, shadows, tone), new app or existing: `skills/apex-design-system/references/brand-layer.md`. Stock Universal Theme is the floor, not the ceiling; user-supplied brand values are requirements.
- Prototype rendering or accessibility evidence: `.opencode/agents/apex-design-verifier.md` and `scripts/verify-design-preview.mjs`.
- Any APEX creation, change, validation, or deployment: `skills/apex-delivery/SKILL.md`.
- APEX syntax: `skills/apex/apexlang/SKILL.md`, then the matching 26.1 or 26.2 skill.
- Oracle Database, SQL, or PL/SQL detail: `skills/db/SKILL.md`.
- APEXLang, import, or `ORA-` error diagnosis: `skills/harness/error-triage/SKILL.md`.
- Security review: `skills/harness/security-review/SKILL.md`.

A project skill bridge is available at `.claude/skills/oracle-apex/SKILL.md`. Workflow skills `/apex-design`, `/apex-plsql`, `/apex-apexlang`, `/apex-verify`, `/apex-review`, `/apex-deploy`, and the others in `.claude/skills/apex-*/` are generated from `.opencode/commands/` by `scripts/sync-agent-commands.mjs`; edit the source, not the copies.

## Non-negotiables

- Confirm the APEX version before using any component syntax.
- Build the domain model and page map before writing pages for a new feature. Write them to `working/page-design/application-design.md` (template in `docs/templates/`) and get user approval before building. Never edit `requirement.md`; it is user-owned.
- Keep business rules in PL/SQL packages; page processes orchestrate.
- Run `scripts/validate-apex-app.ps1` and require `Validation successful` with no `FILE_IGNORED`, compile diagnostics, or `ORA-` errors.
- Run `scripts/verify-delivery.ps1 -ProjectDirectory working` and require `DELIVERY GATE PASS` before reporting delivery.
- `.apx` files must be UTF-8 without a BOM and use LF endings.
- Deploy only with explicit approval for the named target and a `-WhatIf` preview.
- Do not place credentials, connection strings, or wallet contents in the repository.

## Delivery contract

Canonical source: `AGENTS.md`. `scripts/test-harness.ps1` fails if this block drifts out of an adapter.

- `working/page-design/requirement.md` is user-owned: read it, never edit it.
- Before writing SQL or `.apx`, write `working/page-design/application-design.md` from `docs/templates/application-design.template.md` (design, rule-to-PL/SQL mapping, brand layer, requirement trace) and stop for user approval.
- Custom look: `skills/apex-design-system/references/brand-layer.md`. Stock Universal Theme is the floor, not the ceiling; user brand values are requirements.
- Gates: `scripts/validate-apex-app.ps1` must print `Validation successful`; `scripts/verify-delivery.ps1 -ProjectDirectory working` must print `DELIVERY GATE PASS`. Fix the build, never the trace.

## No API key policy

- Keep `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, and `CLAUDE_CODE_OAUTH_TOKEN` unset for normal subscription login.
- Use `/login` with an existing Claude subscription. Claude Code does not have an official $0 local-model mode.
- If you do not have a Claude subscription, use Codex, Antigravity, DSH, or OpenCode with a local/free model instead.
- See `docs/harnesses/README.md` for the no-key matrix.

## Working style

Lead with the outcome, then evidence, then residual risks. Do not claim a file was validated or a database was changed unless the command output proves it.
