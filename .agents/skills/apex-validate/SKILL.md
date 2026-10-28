---
name: apex-validate
description: Validate an APEXLang application directory with SQLcl.
---

# APEX Validate

Validate the Oracle APEX application.

1. Resolve the application directory.
2. Confirm the app's APEX version from `.apex/apexlang.json` and load the matching `apexlang-compile` skill.
3. Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-apex-app.ps1 -AppDirectory "<app-directory>"
```

4. Report the full validation output.
5. Treat the result as PASS only when the command exits 0 and the output contains `Validation successful` with no `FILE_IGNORED`, compile diagnostics, or `ORA-` errors.
6. If it fails, list the failing `.apx` files and the exact errors. Follow `skills/harness/error-triage/SKILL.md` to resolve.
