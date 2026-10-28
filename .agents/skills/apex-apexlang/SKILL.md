---
name: apex-apexlang
description: Implement approved APEXLang changes (.apx) and validate with SQLcl.
---

# APEX APEXLang Implementation

Implement the approved Oracle APEX change.

Read `skills/apex-domains/SKILL.md`, `skills/apex-domains/references/apexlang-implementation.md`, and `skills/apex-delivery/SKILL.md`.

Before editing:

1. Resolve the application directory and confirm it exists.
2. Read `mmdVersion` from `.apex/apexlang.json` and route to 26.1 or 26.2.
3. Confirm the design artifacts: domain model, rule catalogue, and page map. If they are missing for a non-trivial feature, ask for them or run `/apex-design` first.
4. Load only the matching version's inventory and example applications.

When editing:

- Prefer the smallest correct change.
- Keep page processes thin; call PL/SQL packages for business logic.
- Use only properties that exist in the matching inventory.
- Preserve existing page numbers, aliases, and app structure.
- Keep `.apx` files at UTF-8 without a BOM and LF line endings.
- Do not hard-code environment values or secrets.

Then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-apex-app.ps1 -AppDirectory "<app-directory>"
```

Treat the change as done only when the command exits 0 and prints `Validation successful` with no `FILE_IGNORED`, compile diagnostics, or `ORA-` errors.
