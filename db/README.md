# Database Artifacts

This is a routing note, not a second database source tree.

- Application database objects belong under `applications/<app-name>/supporting-objects/` (or the app's existing convention).
- Oracle Database guidance, SQL patterns, PL/SQL, testing, SQLcl, and migrations live under `skills/db/`.
- Local `FREEPDB1` setup, snapshots, and the read-only promotion audit live under `local-dev/`.
- SQLcl Projects configuration is `.dbtools/project.config.json`, created by `project init`. It is not `.pdk/project.json`.
- Do not create a parallel root `apex/` tree. APEXLang applications live under `applications/<app-name>/`.

The v3 blueprint's `db/src`, `db/dist`, and `db/tests` layout is not adopted. Use SQLcl Projects if a project needs an export/stage/release tree, and record the decision before creating a new layout.
