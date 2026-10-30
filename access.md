# Access credentials

Logins for the local APEX 26.2 sandbox in `local-dev/` (setup:
[`local-dev/README.md`](local-dev/README.md)). It is a local development
sandbox bound to `127.0.0.1`, so every account uses one simple password:

**`Oracle123!`**

To use a different password, set `ORACLE_PASSWORD` in `local-dev/.env` before
the first start (see `local-dev/.env.example`).

## Start

```powershell
cd local-dev
docker compose up -d
docker compose logs -f ords     # first run only: APEX install, 10-20 minutes
```

## APEX and ORDS

| What | Address | User | Password |
| :--- | :--- | :--- | :--- |
| APEX instance administration | http://localhost:8181/ords/apex_admin | `ADMIN` | `Oracle123!` |
| APEX workspace login | http://localhost:8181/ords/apex | Workspace `INTERNAL`, user `ADMIN` | `Oracle123!` |
| ORDS landing page | http://localhost:8181/ords/ | none | none |

Sign in to `apex_admin` as `ADMIN` and create a workspace for your app. Then
sign in at `/ords/apex` with that workspace's users.

## Database

Host `localhost`, port `1521`, service name `FREEPDB1`.

| User | Use | Password |
| :--- | :--- | :--- |
| `ADMIN` | DBA + APEX administrator, used by `scripts/deploy-project.ps1` | `Oracle123!` |
| `SYS` | DBA (connect `as sysdba`) | `Oracle123!` |
| `SYSTEM` | DBA | `Oracle123!` |
| `PDBADMIN` | PDB administrator | `Oracle123!` |
| `ORDS_PUBLIC_USER` | internal, used by ORDS | `Oracle123!` |
| `APEX_PUBLIC_USER`, `APEX_REST_PUBLIC_USER` | internal, used by APEX | `Oracle123!` |

```text
SQLcl / SQL*Plus   sql system/Oracle123!@localhost:1521/FREEPDB1
JDBC               jdbc:oracle:thin:@//localhost:1521/FREEPDB1
SQL Developer      host localhost, port 1521, service name FREEPDB1
```

## Deploying an app

`scripts/deploy-project.ps1` targets this sandbox by default (database user
`ADMIN`, service `FREEPDB1`). It creates the workspace, its schema, and the
workspace users, all with `Oracle123!`:

```powershell
powershell -File scripts\deploy-project.ps1 -Workspace DEMO -TestUsers EMP1
```

Then sign in at http://localhost:8181/ords/apex with workspace `DEMO`, user
`ADMIN` or `EMP1`, password `Oracle123!`.

## Changing the password later

Passwords are applied on the first start only. Change `ORACLE_PASSWORD` in
`local-dev/.env`, then reset the sandbox (this deletes the database):

```powershell
cd local-dev
docker compose down -v
docker compose up -d
```
