---
name: Oracle APEX Delivery
description: End-to-end delivery workflow for Oracle APEX applications built with APEXLang. Route the APEX version, load the right inventory and examples, generate or edit the app tree, validate with SQLcl, review, deploy only with approval, and verify. Use for new APEX apps, page or component changes, validation failures, or deployment.
metadata:
  harness: oracle-apex
---

# Oracle APEX Delivery

Use this skill for any task that creates, changes, validates, deploys, or verifies an Oracle APEX application in this harness.

## 0. Preconditions

Confirm these before generating or deploying:

- Target APEX version: `26.1` or `26.2`.
- Target application directory, or an explicit request to create a new app.
- Destination APEX workspace name, for a new app or a deployment.
- `SQLCL_BIN` points to a working SQLcl executable (`tools\sqlcl\bin\sql.exe` by default).
- `JAVA_HOME` points to JDK 21.
- `SQLCL_CONNECTION_STRING` is set only when a database connection is needed. Never print or commit it.

Run `. .\scripts\set-env.ps1` and `.\scripts\harness-doctor.ps1` if the environment is uncertain.

## 1. Route the APEX version

1. Read `mmdVersion` from the app's `.apex/apexlang.json`, or from the target instance.
2. Match on `major.minor`.
3. If unknown, use 26.1 and say so.
4. Read `skills/apex/apexlang/SKILL.md`, then the matching `26.1/SKILL.md` or `26.2/SKILL.md`.
5. Do not load files from the other version.

## 2. Load only the context you need

| Task | Read |
| --- | --- |
| New app from requirements and schema | `26.1/apexlang-generation/SKILL.md` and its workflow references |
| Component syntax or properties | `<version>/apexlang-inventory/SKILL.md` |
| Working patterns | `<version>/apexlang-example-applications/SKILL.md` |
| Validation | `<version>/apexlang-compile/SKILL.md` |
| Deployment | `<version>/apexlang-deploy/SKILL.md` |

For 26.2 there is no `apexlang-generation` skill. Author with the 26.2 inventory and examples; do not copy 26.1 generation assets into a 26.2 app.

## 3. Plan before building

For a new app, follow the Greenfield Vibe Coding workflow; for an existing app, follow Brownfield Vibe Coding (`AGENTS.md`, "Default delivery workflow"). If `working/page-design/requirement.md` exists, treat it as authoritative for page numbers, layout, regions, items, and component choices; do not invent an alternative architecture.

The plan is written to `working/page-design/application-design.md` using `docs/templates/application-design.template.md`, with `Status: DRAFT`. Stop for user approval before generating SQL or `.apx`. Never edit `requirement.md`.

The plan must include:

- Actors, authorization schemes, and page access.
- Data model and supporting objects.
- Page map: page number, purpose, regions, items, buttons, processes, validations, branches.
- APEXLang file map: every `.apx` file to create or change.
- Visual design: base style, brand layer level, tokens, brand classes (`skills/apex-design-system/references/brand-layer.md`).
- Business rule → PL/SQL enforcement mapping.
- Requirement trace: one row per `requirement.md` bullet, `PLANNED` before build, `DONE` with `file:line` or `NOT DONE: <reason>` after.
- Validation and acceptance checks.

After the build, update the trace and set `Status: IMPLEMENTED`. Report the count of `DONE` and `NOT DONE` rows in the final summary; any row still `PLANNED` means delivery is incomplete.

Use the `apex-planner` subagent when the design is unclear or spans multiple pages.

## 4. Build

- Follow the application's existing structure and naming.
- Read the version's inventory before inventing a component or property.
- Copy patterns from the version's example applications, not from memory.
- Keep each change scoped. Do not refactor unrelated pages.
- For database objects, follow the `db` skill and default to read-only verification.

## 5. Validate: hard gate

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-apex-app.ps1 -AppDirectory <app-directory>
```

The script first checks that every `.apx` file uses UTF-8 without a BOM and LF line endings. SQLcl's APEXLang parser rejects CRLF with misleading `token recognition error at: '\r\n'` messages and treats a BOM as source text. If either is found, normalize the tree and re-run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/normalize-apx-tree.ps1 -AppDirectory <app-directory>
```

Pass criteria:

- The command exits 0, and
- the output contains `Validation successful`, and
- the output has no `FILE_IGNORED`, compile diagnostics, or `ORA-` errors.

If validation fails:

1. Read the full output; do not truncate the error.
2. Use `skills/harness/error-triage/SKILL.md` to parse File, Line, Column, Type, and Error.
3. Fix the reported file and line.
4. Re-run validation.
5. Stop after three attempts on the same diagnostic and report the evidence instead of guessing.
6. Do not deploy a tree that has not passed.

The Oracle wrapper scripts call `apex validate -input` in SQLcl `/nolog` mode. No database connection is required for validation.

## 5b. Delivery gate: hard gate

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-delivery.ps1 -ProjectDirectory working
```

Pass criteria: exit 0 and `DELIVERY GATE PASS`. The gate checks the whole project, not a diff: requirement trace completeness and evidence, brand colours and design keywords from `requirement.md`, inline styles and hex in `.apx`, brand class wiring, Font APEX icon names, unused view styling columns, uncalled package APIs, and test presence. Fix the build; never edit the trace to silence a finding. Report every `NOT DONE` row it lists.

## 6. Review

Use the `apex-reviewer` subagent for:

- APEXLang correctness and version compatibility.
- Authorization, session state protection, SQL injection, XSS.
- SQL and PL/SQL correctness and performance.
- Page design, accessibility, and destructive-action confirmations.

Fix critical and high findings before deployment. Record accepted risks in the final report.

## 7. Deploy: approval gate

Deploy only when the user explicitly asks to deploy in the current request.

1. Show the plan first:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy-apex-app.ps1 -AppDirectory <app-directory> -WhatIf
```

2. Confirm the target connection and get explicit approval for that target without printing the secret.
3. Run the import:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy-apex-app.ps1 -AppDirectory <app-directory>
```

The script provisions the target workspace and its `ADMIN` user when they do not exist, enables supporting-object installation, has `ConfirmImpact = 'High'`, and prompts before importing. Do not suppress the prompt with `-Confirm:$false` unless the user approved this exact target.

4. Treat any `ORA-` output as failure, even if the process exit code is 0.
5. Report the application ID, workspace, and any import warnings.
6. Ensure any project-defined seeded test accounts exist and are active; the import provisions only the workspace and `ADMIN`. Record the workspace URL, `ADMIN`, and test accounts in `working/page-design/credentials.md`, and link that file instead of pasting credentials into chat.
7. Export and compare when the target supports APEXLang export:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/export-apex-app.ps1 -ApplicationId <id> -OutputDirectory <export-directory> -CompareDirectory <app-directory>
```

Treat drift as a failure and explain the differing files.

The deploy script enables automatic installation of supporting objects and then runs `apex import -input`.

## 8. Verify

After deployment, verify in this order:

1. The application opens at the expected URL and login works.
2. Authorization: a low-privilege user cannot reach admin pages or actions.
3. Core flows: create, read, update, and delete for each changed entity.
4. Validation and error messages appear as designed.
5. The changed pages render without JavaScript errors.
6. Supporting objects installed as expected.
7. For visual changes, the `apex-design-verifier` report and screenshots exist, the scorecard passes, and the implemented theme/style matches the approved direction.

Automate checks 1, 2, 5 and 7 with the runtime gate, logging in as every seeded role and listing every page the role must not reach:

```powershell
$env:APEX_TEST_PASSWORD = '<from working/page-design/credentials.md>'
node scripts/verify-apex-runtime.mjs --url https://localhost:8443/ords/r/<workspace>/<alias> --users EMP1,MGR1,FIN1 --pages home,<page-alias> --deny EMP1:<admin-page-alias> --brand --insecure
```

It must print `RUNTIME GATE PASS`. It writes screenshots per user, page and viewport plus `report.md` under `working/runtime-verification/`. Use `--brand` whenever the app has a brand layer.

When the app has a brand kit (`working/page-design/design/brand/brand-kit.json`), score the deployed home page against it as well; the prototype score does not prove the deployed look:

```powershell
node scripts/score-design.mjs --url https://localhost:8443/ords/r/<workspace>/<alias>/home --kit working/page-design/design/brand/brand-kit.json --user EMP1 --insecure --out working/design-preview/deployed/score
```

It must print `DESIGN SCORE PASS`. Implement the look exactly as the design handoff says: copy the kit's `css/brand.css` and `fonts/*.woff2` into `app/shared-components/static-files/` unchanged, register them in `static-files.apx` (`text/css`, `font/woff2`), and load `brand.css` app-wide. The delivery gate rejects a hand-edited `brand.css`.

Report `PASS`, `PARTIAL`, or `FAIL` with evidence. Do not claim a UI check that was not performed. Prototype rendering does not prove the deployed APEX page renders the same way.

## Failure playbook

| Symptom | Action |
| --- | --- |
| `SQLCL_BIN` missing | Run `. .\scripts\set-env.ps1`; verify `tools\sqlcl\bin\sql.exe` exists. |
| Java not found | Set `JAVA_HOME` to the installed JDK 21; re-run `harness-doctor.ps1`. |
| Validation reports `token recognition error at: '\r\n'` | The tree has CRLF line endings. Run `scripts/normalize-apx-tree.ps1`, then re-validate. |
| Validation reports a BOM error or `FILE_IGNORED` | The tree has a BOM, an unsupported encoding, or a skipped `.apx` file. Normalize the tree and treat a repeat as failure. |
| Validation output has no success marker, or has compile diagnostics | Treat as failure; read the reported `.apx` errors and follow `skills/harness/error-triage/SKILL.md`. |
| `ORA-` during import | Stop, capture the full error, and check the target schema, workspace, and privileges. |
| Version mismatch | Re-route with `mmdVersion`; never patch a 26.1 app with 26.2-only syntax. |
| App directory missing | Ask for the exact directory or permission to create a new app; do not guess. |
