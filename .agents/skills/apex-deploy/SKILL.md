---
name: apex-deploy
description: Preview or run an APEXLang application import into an Oracle APEX instance with SQLcl.
---

# APEX Deploy

Deploy the Oracle APEX application.

1. Confirm explicit approval from user before deploying.
2. Confirm the application directory and APEX version.
3. Confirm `SQLCL_CONNECTION_STRING` is set in environment (never print it).
4. Run validation first with `scripts/validate-apex-app.ps1`.
5. Preview import plan with `-WhatIf`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy-apex-app.ps1 -AppDirectory "<app-directory>" -WhatIf
```

6. Confirm user approval for target database.
7. Run the import:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy-apex-app.ps1 -AppDirectory "<app-directory>"
```

8. Export and drift check if supported:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/export-apex-app.ps1 -ApplicationId <id> -OutputDirectory <export-directory> -CompareDirectory "<app-directory>"
```
