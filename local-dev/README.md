# Local FREEPDB1 Development and Commercial Promotion

This directory is for the local-only half of the workflow: an Oracle Database Free `FREEPDB1` sandbox with full schema access, followed by a deliberately stricter audit before anything is promoted to a commercial database.

The sandbox is optional. It is not required for offline APEXLang validation, and the harness does not assume it is running.

## What is supported

- Local Oracle Database Free `FREEPDB1` with ORDS and APEX.
- Full local schema development, including DDL, PL/SQL compilation, APEX import, and disposable experiments.
- Read-only metadata snapshots and a promotion audit that can run against either local or commercial connections.
- Version lock at APEX 26.1 or 26.2. The local sandbox is pinned to **APEX 26.2**, matching the harness's 26.2 skills.

## Pick a sandbox

| Option | What runs | First start | Use when |
| --- | --- | --- | --- |
| 1. Docker Compose (recommended) | Database 26ai Free + ORDS 26.3 + APEX 26.2, two containers | 10-20 minutes | You want APEX 26.2 and a working URL with the least setup |
| 2. Database only | Database 26ai Free, no APEX | 2-5 minutes | You only need SQL and PL/SQL smoke tests |
| 3. `uc-local-apex-dev` | Database + ORDS + APEX, managed by an upstream installer | 20-40 minutes | You want a multi-container sandbox with upstream lifecycle scripts |

### Images and why they changed

APEX is **not** part of the database image. The compose stack uses the official ORDS image, which installs APEX from a mounted distribution on first start. The APEX version is therefore pinned by the downloaded APEX zip, not by an image tag.

| Use case | Image | Notes |
| --- | --- | --- |
| Database for APEX 26.2 | `container-registry.oracle.com/database/free:latest` | Oracle AI Database 26ai Free (currently release 23.26.3.0.0). Includes XML DB, which APEX needs. |
| ORDS and APEX install | `container-registry.oracle.com/database/ords:26.3.0` | ORDS 26.3. On first start it installs ORDS into `FREEPDB1` and APEX from `/opt/oracle/apex`. |
| APEX distribution | `apex_26.2.zip` from `download.oracle.com/otn_software/apex/` | About 337 MB. Downloaded by `scripts/get-apex-26.2.ps1`. |
| All-in-one, APEX 26.1.x only | `ghcr.io/oracle/adb-free:latest-26ai` | Convenient single container, but it ships the APEX version Oracle baked in (release 26.9.4.2 ships APEX 26.1.5). It cannot be pinned to 26.2. |
| Not for this harness | `container-registry.oracle.com/database/adb-free:latest` | This tag is the **19c** image, not 26ai. The previous compose file used it by mistake. |
| Database and PL/SQL only | `gvenzl/oracle-free:23.26.3-slim` | Smallest image (~800 MB). No APEX. |
| Not for APEX | `gvenzl/oracle-free:slim`, `container-registry.oracle.com/database/free:latest-lite` | Removes Oracle Text, Spatial/Locator, MLE, RMAN, `wrap`, and XML DB files. APEX requires XML DB; community testing reports `apexins.sql` stops at that prerequisite check. |

`gvenzl/oracle-free:slim` is about 809 MB compressed, `latest` about 1.1 GB, and `full` about 2.1 GB. For reproducible environments, pin `23.26.3` or a digest instead of `latest`.

The database image is the only unpinned component. `free:latest` currently resolves to the 26ai Free release `RDBMS_23.26.3.0.0DBRU_LINUX.X64_260704`. To pin it, replace the image with that tag, or record the digest:

```powershell
docker image inspect container-registry.oracle.com/database/free:latest --format '{{index .RepoDigests 0}}'
```


## Option 1: APEX 26.2 with Docker Compose (recommended)

This starts two containers on a private network:

- `db`: Oracle AI Database 26ai Free, PDB `FREEPDB1`, port `1521`.
- `ords`: ORDS 26.3, installs APEX 26.2 on first start, port `8181`.

Everything binds to `127.0.0.1` only. It is a laptop sandbox, not a server.

### 1. Install and start Docker

- Windows or macOS: install Docker Desktop and start it.
- Linux: install Docker Engine and make sure your user can run `docker compose`.
- Confirm it works:

  ```powershell
  docker version
  docker compose version
  ```

**Requirements:** about 20 GB free disk (the two images are ~16 GB), 4 GB RAM minimum, 8 GB recommended, and **ports 1521 and 8181 free**.

### 2. Download APEX 26.2

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/get-apex-26.2.ps1
```

The script downloads `apex_26.2.zip` (about 337 MB), checks the download size, and extracts it to `local-dev/apex/`. That folder must contain `apexins.sql` and `images/`; the ORDS container reads it on first start. The script is safe to re-run and skips the download when the distribution is already present. Both the zip and the extracted folder are git-ignored.

### 3. Set the password (optional)

The compose file has a local default password. To use your own, create `local-dev/.env`:

```powershell
Copy-Item local-dev\.env.example local-dev\.env
```

Edit `ORACLE_PASSWORD`. It is used for `SYS`, `ORDS_PUBLIC_USER`, and `APEX_PUBLIC_USER`. It does **not** create the APEX `ADMIN` user; you create that user once after the first install (step 5). Use upper case, lower case, a digit, and a special character, or the APEX install rejects it.

Never commit `local-dev/.env`.

### 4. Start the stack

```powershell
cd local-dev
docker compose up -d
```

The first run pulls ~16 GB of images. The database reports healthy after a few minutes; ORDS then installs ORDS and APEX, which takes another 10-20 minutes. Watch it with:

```powershell
docker compose logs -f ords
```

Wait for `The Oracle APEX has been installed` in the ORDS log, followed by the ORDS startup messages. Press `Ctrl+C` to stop following the log; the containers keep running.

### 5. Create the APEX administrator (one time)

The ORDS container installs APEX but does not create the APEX `ADMIN` user. Create it once, from `local-dev`:

```powershell
docker compose exec -it ords sql /nolog
```

At the SQLcl prompt:

```text
conn sys/<your ORACLE_PASSWORD>@//db:1521/FREEPDB1 as sysdba
@/opt/oracle/apex/apxchpwd.sql
exit
```

`apxchpwd.sql` asks for a username (press Enter for `ADMIN`), an email, and a password. The script lives in the APEX 26.2 distribution mounted in the ORDS container, so this works without copying files into the database container.

### 6. Open APEX

| What | Value |
| --- | --- |
| APEX instance administration | <http://localhost:8181/ords/apex_admin> |
| APEX workspace login | <http://localhost:8181/ords/apex> |
| ORDS landing page | <http://localhost:8181/ords/> |
| Instance administrator | `ADMIN`, password set in step 5 |
| Database | `localhost:1521`, service `FREEPDB1` |
| Database users | `SYS` / `SYSTEM` / `PDBADMIN`, password `ORACLE_PASSWORD` |

Sign in to `apex_admin` as `ADMIN`, then create a workspace for your app (for example `MYWORKSPACE` with a workspace administrator). After that, sign in to the workspace at `/ords/apex`. The `INTERNAL` workspace is for instance administration only; application work belongs in your own workspace.

### Stop, reset, and upgrade

```powershell
cd local-dev

# Stop, keep the database and the APEX install
docker compose down

# Stop and delete the database volume. The next start reinstalls ORDS and APEX.
docker compose down -v
```

To move to another APEX version later, download and extract that distribution into `local-dev/apex/`, then run `docker compose down -v` and start again. A new APEX version needs a clean database volume; do not reuse the old one.

If you used the previous `adb-free` compose file, remove its container and volume first. The old container was also named `apex-disposable-db` and the old volume is usually `local-dev_adb-data`:

```powershell
docker rm -f apex-disposable-db
docker volume rm local-dev_adb-data
```

The new project is named `apex-26-2` and uses its own volumes (`apex-26-2_db-data`, `apex-26-2_ords-config`).

### Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| `port is already allocated` for 1521 or 8181 | Another Oracle container or a local listener is using the port. Stop it, or change the host side of the mapping in `docker-compose.yml`. |
| ORDS container keeps restarting | It exited three times and gave up. Run `docker compose logs ords`. The usual cause is too little free RAM during the APEX install, or `local-dev/apex/apexins.sql` missing. Fix the cause, then `docker compose down -v` and start again. |
| `http://localhost:8181/ords/apex` returns 404 | APEX was not installed. Check that `local-dev/apex/apexins.sql` exists and that the ORDS log shows the APEX install. If the folder was empty on first start, stop with `down -v`, download APEX, and start again. |
| APEX login fails | `ADMIN` is the instance administrator and only exists after step 5. Use `/ords/apex_admin` for `ADMIN`, and `/ords/apex` for a workspace user. If `ADMIN` does not exist, run `apxchpwd` again. |
| `/ords/apex` says there is no workspace | Sign in to `/ords/apex_admin` as `ADMIN` and create a workspace first. |
| `sql: command not found` in the ORDS container | Copy the distribution to the database container and use `sqlplus`: `docker cp local-dev/apex apex-26-2-db:/tmp/apex`, then `docker compose exec -it db sqlplus sys/<password>@//localhost:1521/FREEPDB1 as sysdba @/tmp/apex/apxchpwd.sql`. |
| The `ords:26.3.0` tag cannot be pulled | Use `container-registry.oracle.com/database/ords:latest` in `docker-compose.yml`. At the time of writing it resolves to 26.3.0. |
| `docker compose` is not a command | Docker Compose v2 ships with Docker Desktop. On Linux, install the Compose plugin; `docker-compose` (v1) is not supported by this file. |
| Apple Silicon | Both `database/free:latest` and `database/ords:26.3.0` publish `linux/arm64` images, so Docker Desktop on Apple Silicon works. Make sure Docker Desktop itself is the Apple Silicon build. |

## Option 2: Database-only smoke test (no APEX)

If you only need SQL and PL/SQL testing without APEX, use the slim image. Run from `local-dev` so the `.env` file is picked up:

```powershell
docker volume create oracle-free-data
docker run --name oracle-free `
  -p 1521:1521 `
  --env-file .env `
  -v oracle-free-data:/opt/oracle/oradata `
  -d gvenzl/oracle-free:23.26.3-slim
```

Add `ORACLE_PASSWORD` to `local-dev/.env` before starting. Wait for `DATABASE IS READY TO USE` in `docker logs -f oracle-free` before connecting. Do not reuse a database volume across 26ai point releases without testing; the upstream image notes that migrations can require a fresh volume.

## Option 3: Dedicated APEX 26.2 Sandbox (`uc-local-apex-dev`)

For a dedicated APEX 26.2 sandbox orchestrated with independent DB and ORDS containers and upstream lifecycle scripts, use the supported sandbox workflow below. Do not substitute `slim` or `latest-lite`.

### Prerequisites for Option 3

- Docker Desktop or Podman with Compose.
- Git and Git Bash (the upstream installer is a shell script).
- SQLcl 26.3 and JDK 21, as installed by `scripts/install-sqlcl.ps1`.
- `curl` or `wget`, and `unzip`.
- At least 4 GB RAM, 3 CPUs, and 35 GB free disk.

Upstream: <https://github.com/United-Codes/uc-local-apex-dev> (MIT). The upstream default branch is `26-4`; do not use it with this harness. Use `26-2` or `26-1`.

### Install the sandbox

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

Docker is not installed on this machine, so the compose stack and `scripts/get-apex-26.2.ps1` have not been executed end to end. The image tags, multi-arch manifests, ORDS environment variables, and the APEX 26.2 download URL were checked against the Oracle Container Registry API and Oracle release notes, but the first `docker compose up -d` on a machine with Docker remains the real test.

The SQL scripts are read-only and use Oracle dictionary views documented in `skills/db/`; run them against a disposable local database before relying on the output. SQLcl's command-line console failed to initialize under the non-interactive automation shell on this machine (`java.io.IOException: Incorrect function`), so the scripts were reviewed statically rather than executed here. The SQLcl MCP path is separate and connected successfully. The upstream `uc-local-apex-dev` project, not this harness, owns the container lifecycle for Option 3.
