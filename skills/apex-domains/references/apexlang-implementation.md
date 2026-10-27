# APEXLang Implementation

Use this reference when a design is approved and must become an APEX application tree. The Oracle `apex` and `apexlang` skills remain authoritative for syntax, properties, and component inventories.

## 1. Version lock

Read the version from:

1. The application's `.apex/apexlang.json` (`mmdVersion`).
2. Or the target APEX instance.

Then route:

- `26.1.x` → `skills/apex/apexlang/26.1/SKILL.md`.
- `26.2.x` → `skills/apex/apexlang/26.2/SKILL.md`.
- Unknown → use 26.1 and state the assumption.

Never mix inventories, examples, or component properties from different versions.

## 2. Application tree

A new application publishes only runtime artifacts:

```text
applications/<app-name>/
├── .apex/
│   └── apexlang.json
├── application.apx
├── deployments/
├── page-groups.apx
├── pages/
├── shared-components/
└── supporting-objects/
```

Keep `.apx` files at LF line endings. Do not copy template docs or `scaffold-example/` containers into the app root.

## 3. Implementation order

1. Database objects and reference data.
2. PL/SQL package specifications and bodies.
3. Application definition and shared components.
4. Authentication and authorization schemes.
5. Page groups and navigation.
6. Pages in actor-goal order: home, list, form, detail, approval, administration.
7. Page processes, validations, and branches.
8. Supporting objects.
9. Validation and review.

Implementing pages before the package API is a common cause of business logic leaking into page processes.

## 4. Mapping the design to APEXLang

| Design element | APEXLang target |
| --- | --- |
| Application identity | `application.apx` |
| Page groups/navigation | `page-groups.apx`, shared lists |
| Authentication | `shared-components/authentications.apx` |
| Authorization schemes | `shared-components/authorizations.apx` |
| LOVs, lists, templates | `shared-components/` |
| Page and regions | `pages/pXXXXX-*.apx` |
| Form/report items | page region and item blocks |
| Buttons and actions | page button blocks |
| Processes | page process blocks calling PL/SQL packages |
| Validations | page validation blocks with rule IDs |
| Branches | page branch blocks |
| Build options | `shared-components/build-options.apx` |
| Supporting objects | `supporting-objects/` |

Use the version's `apexlang-inventory` to confirm the exact component and property names. Use the version's example applications for working patterns.

## 5. Business logic placement

- **Page validation** — immediate, field-level feedback and simple UI rules.
- **Page process** — orchestration: read items, call one package operation, map success/error to page messages.
- **PL/SQL package** — calculations, workflow transitions, multi-table writes, authorization checks for non-APEX callers, bulk operations.
- **Database constraint** — integrity that must survive every caller.
- **Authorization scheme** — page/region/button visibility and capability checks.
- **Dynamic action** — UI behavior only; never the sole enforcement of a business rule.

Page processes should not contain long SQL or multi-step business logic. Pass explicit values to the package; do not make the package read `:APP_USER` or page items.

## 6. Syntax discipline

- Copy property names from the inventory. Do not invent or guess a property.
- Prefer the smallest component that satisfies the design.
- Keep page numbers and aliases stable after release.
- Use consistent naming for pages, items, buttons, processes, and validations.
- Put rule IDs in validation names or comments so traceability survives.
- Do not hard-code environment URLs, workspace names, or application IDs.
- Do not embed credentials, API keys, or connection strings.
- Keep custom CSS/JavaScript minimal and justified.
- Preserve existing app structure and conventions when editing.

## 7. Validation gate

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-apex-app.ps1 -AppDirectory <app-directory>
```

The gate:

1. Rejects CRLF `.apx` files.
2. Runs SQLcl `apex validate`.
3. Requires `Validation successful`.

If CRLF is reported:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/normalize-apx-tree.ps1 -AppDirectory <app-directory>
```

Then re-run validation. Do not claim success from a clean editor or a partial output.

## 8. Common failures

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `token recognition error at: '\r\n'` | CRLF line endings | Normalize to LF, revalidate |
| Missing required property | Incomplete component block | Read the inventory definition and add the property |
| Invalid property | Wrong version or invented name | Check the matching inventory; do not guess |
| Page not reachable | Missing branch/navigation entry | Add the branch or navigation list entry |
| Process not firing | Wrong sequence, condition, or button action | Check page rendering/processing order and server-side condition |
| Authorization not enforced | UI-only check | Add the authorization scheme and package-level check |
| Validation not shown | Wrong page item or condition | Verify item name, validation sequence, and error message |

## 9. Implementation checklist

- Version confirmed and locked.
- Business rules and page map available.
- PL/SQL package API exists before page processes.
- Every page has a purpose, authorization, primary action, and error/empty state.
- Page processes are thin orchestration calls.
- Validations carry rule IDs and user-safe messages.
- No hard-coded environment values or secrets.
- LF line endings.
- SQLcl validation passed.
- Review completed with `apex-reviewer`.
- Deployment previewed with `-WhatIf` and only run with explicit approval.
