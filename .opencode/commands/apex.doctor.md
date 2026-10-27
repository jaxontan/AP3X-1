---
description: Check the APEX harness tools, files, and environment
---

Run the harness doctor and report the result:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/harness-doctor.ps1
```

For a strictly keyless setup, also run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/harness-doctor.ps1 -StrictNoKeys
```

The doctor reports paid-key variable names but never their values. It does not read or use the keys.

If anything is missing, explain the shortest safe fix. Do not install tools or change system settings without asking.
