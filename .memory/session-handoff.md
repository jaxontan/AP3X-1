# Session Handoff

- Current feature: dual-runtime OpenCode configuration, validation-gate hardening, and an offline harness self-test.
- APEX version: 26.1 and 26.2 supported; local sandbox pinned to 26.2.
- Target database version: not confirmed; set `TARGET_DB_VERSION` after checking the commercial target.
- App directory: none yet; `applications/` contains only its README. The known-good validation target is `skills/apex/apexlang/26.2/apexlang-example-applications/assets/example-0`.
- Last validation: `scripts/test-harness.ps1` PASS all 18 offline checks; `scripts/validate-apex-app.ps1` PASS on `example-0` (`Validation successful`, exit 0); `scripts/verify-apex-change.ps1 -Strict` PASS on 33 changed files; `harness-doctor.ps1` PASS for OpenCode V1 1.18.30 and V2 2.2.0, and parses `.claude/settings.json` plus `.mcp.json`.
- Open risks: no live FREEPDB1 or commercial connection, so import was tested only with `-WhatIf`. Export and drift comparison were exercised end-to-end with a temporary fake SQLcl: matching tree returned 0, one modified file returned 1 with the drift path. CRLF/BOM rejection and normalization were tested on copies of `example-0`.
- Next action: create or select an APEX 26.1/26.2 app under `applications/<app>/`, run `/apex.verify` then `/apex.validate`, and only then exercise a live import plus export/drift comparison against an approved target.
- Related ADR or spec: `docs/adr/0003-sqlcl-mcp-live-schema.md`, `docs/adr/0004-v3-blueprint-corrections.md`, `docs/adr/0005-opencode-dual-runtime-config.md`.
