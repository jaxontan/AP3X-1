# Project Decisions

Use this file for decisions that affect future work but are smaller than an ADR. Architecture decisions belong in `docs/adr/`.

| Date | Decision | Rationale | Evidence |
| --- | --- | --- | --- |
| 2026-10-28 | Use APEX 26.2 skills for the local sandbox | The harness supports 26.1 and 26.2; the sandbox is pinned to the `26-2` branch to avoid a version mismatch | `local-dev/README.md`, ADR-0003 |
| 2026-10-28 | Do not require `uc-apx` | The repository has no license, so it cannot be vendored or made a mandatory gate | `docs/adr/0004-v3-blueprint-corrections.md` |
| 2026-10-28 | Use the OpenCode V1 `permission` object for dual-runtime support | The installed V1 rejects `permissions`; V2.2 accepts and converts `permission`. One shared config avoids host drift | `docs/adr/0005-opencode-dual-runtime-config.md`; `opencode debug config` and `tools/opencode-v2/opencode.exe debug config` both exit 0 |
| 2026-10-28 | Use regular/full 26ai Free images for APEX; use `slim`/`lite` only for database-only work | Slim/lite remove XML DB, Oracle Text, and Spatial; APEX requires XML DB for a full development environment and its installer stops at that prerequisite | `local-dev/README.md`; gvenzl `ImageDetails.md`; Oracle APEX installation requirements |

## Template

| Date | Decision | Rationale | Evidence |
| --- | --- | --- | --- |
| YYYY-MM-DD | Short decision | Why it was made and what it prevents | Command, file, or ADR link |
