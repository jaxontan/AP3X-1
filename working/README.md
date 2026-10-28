# Working Directory

This directory is the dedicated home for all deliverables of your Oracle APEX application project.

When vibe coding with your assistant (or building manually), all project assets are organized cleanly here:

```text
working/
├── page-design/                  # User-defined page map and UI architecture
│   └── requirement.md            # Authoritative page map, regions, items & rules
├── database/                     # Oracle Database artifacts
│   ├── schema.sql                # Tables, constraints, indexes, and seed data
│   ├── packages/                 # TAPI & XAPI business logic packages (pks / pkb)
│   └── tests/                    # utPLSQL test suites
└── app/                          # Declarative APEXLang application tree
    ├── .apex/                    # apexlang.json version lock
    ├── application.apx           # Application manifest
    ├── deployments/              # Deployment target configs
    ├── page-groups.apx           # Navigation groups
    ├── pages/                    # Page definition files (p00001-*.apx, etc.)
    ├── shared-components/        # Authorizations, lists, LOVs, themes, templates
    └── supporting-objects/       # Export scripts and install manifests
```

---

## Automatic Validation

Whenever an `.apx` file in `working/app/` is created or modified by your assistant, the harness automatically normalizes line endings and runs SQLcl `apex validate`.

You can also run validation manually at any time:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate-apex-app.ps1 -AppDirectory working/app
```

Or watch files in real time as you edit:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/watch-apex-app.ps1
```
