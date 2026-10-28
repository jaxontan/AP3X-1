---
name: apex-verify
description: Run static verification on changed APEX, SQL, and PL/SQL files against harness rules.
---

# APEX Verify

Run static verification on changed APEX, SQL, and PL/SQL files.

1. Resolve the application directory or run repository-wide.
2. Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-apex-change.ps1 -AppDirectory "<app-directory>"
```

(Omit `-AppDirectory` for a repository-wide check.)

3. For a release candidate, re-run with `-Strict` and require a clean PASS.
4. Note: Static check does not replace the APEX compiler. Always run `/apex-validate <app-directory>` as well.
