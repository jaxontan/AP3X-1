# Local FREEPDB1 Development and Commercial Promotion

This directory is for the local-only half of the workflow: an Oracle Database Free `FREEPDB1` sandbox with full schema access, followed by a deliberately stricter audit before anything is promoted to a commercial database.

The sandbox is optional. It is not required for offline APEXLang validation, and the harness does not assume it is running.

## What is supported

- Local Oracle Database Free `FREEPDB1` with ORDS and APEX.
- Full local schema development, including DDL, PL/SQL compilation, APEX import, and disposable experiments.
- Read-only metadata snapshots and a promotion audit that can run against either local or commercial connections.
- Version lock at APEX 26.1 or 26.2. The sandbox is pinned to the `26-2` branch so it matches the harness's 26.2 skills.

## Prerequisites

- Docker Desktop or Podman with Compose.
- Git and Git Bash (the upstream installer is a shell script).
- SQLcl 26.3 and JDK 21, as installed by `scripts/install-sqlcl.ps1`.
- `curl` or `wget`, and `unzip`.
- At least 4 GB RAM, 3 CPUs, and 35 GB free disk.

Upstream: <https://github.com/United-Codes/uc-local-apex-dev> (MIT). The upstream default branch is `26-4`; do not use it with this harness. Use `26-2` or `26-1`.

## Install the sandbox

Preview the plan first:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install-local-apex.ps1
```

Run it only when the prerequisites are satisfied:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install-local-apex.ps1 -Execute
```

The script clones the pinned branch into `%LOCALAPPDATA%\OracleApexHarness\uc-local-apex-dev` and runs the upstream `install.sh`. It does not create, read, or print a password. The upstream installer reads `.env` or prompts for `ORACLE_PASSWORD`.

The upstream documentation reports a 20-40 minute first install. When it completes, the APEX URL is normally:

```text
http://localhost:8181/ords/apex
```

Use the `INTERNAL` workspace and `ADMIN` user. The password is the one supplied to the installer.

## Save named connections

Do not put passwords in this repository, in prompts, or in MCP configuration. Save SQLcl connections interactively:

```text
sql /nolog
conn -save apex_local -savepwd
```

Enter the local parsing-schema credentials at the prompt. For commercial promotion, save a separate least-privilege, read-only connection:

```text
conn -save apex_commercial_ro -savepwd
```

The SQLcl MCP server uses these saved names. `list-connections` shows them; `connect` activates one.

## Snapshot local metadata

Run the read-only snapshot as the local application schema:

```powershell
sql /nolog -name apex_local @local-dev/snapshot-pdb.sql APP
```

The first positional argument is the schema name, without quotes. The script writes CSV files named `snapshot_<schema>.*.csv` in the current directory. Review the snapshot before promotion; do not commit generated snapshots.

## Audit a commercial target

Run the read-only audit against the commercial connection:

```powershell
sql /nolog -name apex_commercial_ro @local-dev/promotion-audit.sql APP
```

Pass the schema name without quotes. The audit reports database and APEX versions, invalid objects, disabled constraints and triggers, unusable indexes, tables without primary keys, unindexed foreign keys, grants to `PUBLIC`, public synonyms, database links, directories, scheduler jobs, Java classes, stale materialized views, high-risk session privileges, and a small 19c compatibility check for 23ai/26ai-only column types. It does not change anything.

## Optional merge-safe APEX export

If the same app is edited both in the repository and in APEX Builder, do not overwrite either side blindly. Use a separate Git worktree and a three-way merge:

1. Export the current target or sandbox app into a scratch directory, outside the application tree.
2. Create a worktree for the export branch: `git worktree add ..\apex-export <branch>`.
3. Diff the exported tree against the branch, merge only reviewed changes, and keep `.apx` files at LF.
4. Validate the merged tree with `scripts/verify-apex-change.ps1 -Strict` and `scripts/validate-apex-app.ps1`.
5. Re-import only after explicit approval, and keep the export as a rollback artifact.

The harness does not ship an automatic sync or destructive merge script. The v3 blueprint's `apex-sync.sh` and the unlicensed `uc-apx` workflow are not adopted; see `docs/adr/0004-v3-blueprint-corrections.md`.

## Promotion rules

1. Treat the local database as disposable. Snapshot or clone the PDB before a risky schema experiment.
2. Run `scripts/verify-apex-change.ps1 -AppDirectory <app>` and `scripts/validate-apex-app.ps1 -AppDirectory <app>` before import.
3. Run `local-dev/promotion-audit.sql` against the target, not only against local.
4. Review the target's Oracle Database version before using 23ai/26ai-only syntax. Local `FREEPDB1` is newer than many commercial 19c targets.
5. Preview every import with `scripts/deploy-apex-app.ps1 -WhatIf`. Import only with explicit approval.
6. On a shared or commercial database, use read-only discovery by default. Full local DBA access is not a production default.
7. Never commit `.env`, wallet files, saved connection files, generated snapshots, or passwords.

## What is not verified here

The preview mode was executed on this machine and correctly reported only the missing Docker/Podman prerequisite. Docker is not installed, so the sandbox installer has not been executed with `-Execute`, and the SQL scripts have not been run against a live database.

The SQL scripts are read-only and use Oracle dictionary views documented in `skills/db/`; run them against a disposable local database before relying on the output. SQLcl's command-line console failed to initialize under the non-interactive automation shell on this machine (`java.io.IOException: Incorrect function`), so the scripts were reviewed statically rather than executed here. The SQLcl MCP path is separate and connected successfully. The upstream `uc-local-apex-dev` project, not this harness, owns the container lifecycle.
