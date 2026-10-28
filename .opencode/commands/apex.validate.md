---
description: Validate an APEXLang application directory with SQLcl
agent: apex
---

Validate the Oracle APEX application at: $ARGUMENTS

Do this:

1. Resolve the application directory. If the argument is empty, ask for it; do not guess.
2. Confirm the app's APEX version from `.apex/apexlang.json` and load the matching `apexlang-compile` skill.
3. Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-apex-app.ps1 -AppDirectory "<app-directory>"
```

4. Report the full validation output.
5. Treat the result as PASS only when the command exits 0 and the output contains `Validation successful` with no `FILE_IGNORED`, compile diagnostics, or `ORA-` errors. The script enforces these checks, but report any warnings.
6. If it fails, list the failing `.apx` files and the exact errors. Do not edit files unless the user asked you to fix them.
