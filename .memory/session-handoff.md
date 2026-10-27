# Session Handoff

- Current feature: v3 harness upgrade (local FREEPDB1 workflow, SQLcl MCP, verification, memory, theme/PLSQL references).
- APEX version: 26.1 and 26.2 supported; local sandbox pinned to 26.2.
- Target database version: not confirmed; set `TARGET_DB_VERSION` after checking the commercial target.
- App directory: none yet; `applications/` contains only its README.
- Last validation: `scripts/verify-apex-change.ps1 -Strict` PASS (39 changed files); `harness-doctor.ps1` reports ready; `opencode2 mcp list` shows `oracle-sqlcl` and `shopify-dev-mcp` connected. `apex validate` was not run because no app tree or live APEX instance is present.
- Open risks: Docker/Podman is absent, so `local-dev` was preflighted but not executed; `local-dev` SQL was reviewed statically because SQLcl's non-interactive console failed in the automation shell; `uc-apx` remains unlicensed and unused; tree-sitter PL/SQL is not a gate.
- Next action: create or select an APEX 26.1/26.2 app under `applications/<app>/`, run `/apex.verify` then `/apex.validate`, and only then exercise the sandbox and promotion audit.
- Related ADR or spec: `docs/adr/0003-sqlcl-mcp-live-schema.md`, `docs/adr/0004-v3-blueprint-corrections.md`.
