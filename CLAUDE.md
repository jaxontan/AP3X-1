# Claude Code Adapter

This repository is an Oracle APEX agent harness. `AGENTS.md` is the canonical instruction set. Read it first, then follow this adapter.

## Required reading by task

- Business analysis, domain model, application design, PL/SQL, or APEXLang: `skills/apex-domains/SKILL.md`.
- Any APEX creation, change, validation, or deployment: `skills/apex-delivery/SKILL.md`.
- APEX syntax: `skills/apex/apexlang/SKILL.md`, then the matching 26.1 or 26.2 skill.
- Oracle Database, SQL, or PL/SQL detail: `skills/db/SKILL.md`.
- APEXLang, import, or `ORA-` error diagnosis: `skills/harness/error-triage/SKILL.md`.
- Security review: `skills/harness/security-review/SKILL.md`.

A project skill bridge is available at `.claude/skills/oracle-apex/SKILL.md`.

## Non-negotiables

- Confirm the APEX version before using any component syntax.
- Build the domain model and page map before writing pages for a new feature.
- Keep business rules in PL/SQL packages; page processes orchestrate.
- Run `scripts/validate-apex-app.ps1` and require `Validation successful` with no `FILE_IGNORED`, compile diagnostics, or `ORA-` errors.
- `.apx` files must be UTF-8 without a BOM and use LF endings.
- Deploy only with explicit approval for the named target and a `-WhatIf` preview.
- Do not place credentials, connection strings, or wallet contents in the repository.

## No API key policy

- Keep `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, and `CLAUDE_CODE_OAUTH_TOKEN` unset for normal subscription login.
- Use `/login` with an existing Claude subscription. Claude Code does not have an official $0 local-model mode.
- If you do not have a Claude subscription, use Codex, Antigravity, DSH, or OpenCode with a local/free model instead.
- See `docs/harnesses/README.md` for the no-key matrix.

## Working style

Lead with the outcome, then evidence, then residual risks. Do not claim a file was validated or a database was changed unless the command output proves it.
