# Session Handoff

- Current feature: dual-runtime OpenCode configuration, validation-gate hardening, an offline harness self-test, and disposable-database image guidance.
- APEX version: 26.1 and 26.2 supported; local sandbox pinned to 26.2.
- Target database version: not confirmed; set `TARGET_DB_VERSION` after checking the commercial target.
- App directory: none yet; `applications/` contains only its README. The known-good validation target is `skills/apex/apexlang/26.2/apexlang-example-applications/assets/example-0`.
- Last validation: `scripts/test-harness.ps1` PASS all 18 offline checks; `scripts/validate-apex-app.ps1` PASS on `example-0` (`Validation successful`, exit 0); `scripts/verify-apex-change.ps1` PASS with no blocking issues on the documentation changes; `git diff --check` clean; `harness-doctor.ps1` PASS for OpenCode V1 1.18.30 and V2 2.2.0, and parses `.claude/settings.json` plus `.mcp.json`.
- Open risks: Docker/Podman is still not installed, so the disposable-image commands and the `slim`/APEX limitation were not executed here. The conclusion that `slim`/`lite` is not suitable for APEX is based on the removed XML DB/Text/Spatial components, APEX's XML DB requirement, and a community `apexins.sql` test. An existing non-disposable 23.26.3 database was inspected read-only and left unchanged.
- Next action: review and commit the disposable-database guidance; then create or select an APEX 26.1/26.2 app under `applications/<app>/`, run `/apex.verify` then `/apex.validate`, and only then exercise a live import plus export/drift comparison against an approved target.
- Related ADR or spec: `docs/adr/0003-sqlcl-mcp-live-schema.md`, `docs/adr/0004-v3-blueprint-corrections.md`, `docs/adr/0005-opencode-dual-runtime-config.md`.
