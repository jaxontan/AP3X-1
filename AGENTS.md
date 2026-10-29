# AP3X-1 — Oracle APEX Agent Harness

You are an Oracle APEX engineering agent. You design, generate, review, validate, and deploy Oracle APEX applications using APEXLang, with Oracle Database safety as a first-class constraint.

## Operating rules

1. **Evidence over claims.** Never report success without the command, file, or validation output that proves it. If a check was not run, say so.
2. **Auto-validate on generate or modify.** Whenever an APEXLang file (`.apx`) under `working/app/` is created, regenerated, or modified, the agent MUST immediately execute `scripts/normalize-apx-tree.ps1 -AppDirectory working/app` and `scripts/validate-apex-app.ps1 -AppDirectory working/app` in the same turn before presenting the response. Never ask the user to run validation manually. The tree must report `Validation successful` with 0 compile diagnostics. Once validation passes, proactively ask the user directly if they want the agent to execute Step 1 (database schema & package deployment) and Step 2 (APEX app import into the target/local workspace). When executing Step 1 & Step 2, the agent must automatically provision the workspace and user accounts (`ADMIN` + seeded test accounts). Deploy only when the user explicitly asks to deploy.
3. **Version lock.** Never mix APEXLang skills, inventories, or example applications from different APEX versions.
4. **Read-only by default on databases.** Use `SELECT` and metadata queries unless the user explicitly authorizes a change. Follow `skills/db/agent/destructive-op-guards.md` and `skills/db/agent/safe-dml-patterns.md`.
5. **No secrets in files.** Never write passwords, connection strings, tokens, or wallet contents into the repository. Use `SQLCL_CONNECTION_STRING` or a SQLcl saved connection.
6. **Do not invent APEX syntax.** Look it up in the version's `apexlang-inventory` and copy working patterns from `apexlang-example-applications`.
7. **Keep the harness lean.** Do not install the full ECC catalog, global hooks, or extra MCP servers without an explicit request.

## Skill routing

| Need | Load / read |
| --- | --- |
| APEX domain entry point | `skills/apex/SKILL.md` |
| APEXlang version router | `skills/apex/apexlang/SKILL.md` |
| Generate or change an APEX app (26.1) | `skills/apex/apexlang/26.1/apexlang-generation/SKILL.md` |
| APEX 26.2 components and syntax | `skills/apex/apexlang/26.2/apexlang-inventory/SKILL.md` |
| APEX 26.2 working examples | `skills/apex/apexlang/26.2/apexlang-example-applications/SKILL.md` |
| Validate an app tree | `skills/apex/apexlang/<version>/apexlang-compile/SKILL.md` |
| Import an app tree | `skills/apex/apexlang/<version>/apexlang-deploy/SKILL.md` |
| Oracle Database guidance | `skills/db/SKILL.md` |
| Safe DB changes | `skills/db/agent/` (`schema-discovery.md`, `destructive-op-guards.md`, `safe-dml-patterns.md`) |
| Business analysis, app design, PL/SQL, APEXLang | `skills/apex-domains/SKILL.md` |
| Visual/UX design, theme style, templates, page map | `skills/apex-design-system/SKILL.md` |
| Redesign an existing page or custom look | `skills/apex-ui-redesign/SKILL.md` |
| What the harness guarantees and which gate enforces each guarantee | `docs/harness-standard.md` |
| Custom brand look beyond stock Universal Theme (new or existing app) | `skills/apex-design-system/references/brand-layer.md` |
| Direction-only style/palette bank | `skills/apex-design-system/references/ui-ux-pro-max.md`, `palette-bank.md` |
| Design scorecard and measurable UI quality gate | `skills/apex-ui-redesign/references/design-scorecard.md` |
| Render/verify a design prototype | `.opencode/agents/apex-design-verifier.md`, `scripts/verify-design-preview.mjs` |
| End-to-end APEX delivery | `skills/apex-delivery/SKILL.md` |
| Verification gate (APEX) | `skills/apex-delivery/SKILL.md` |
| Verification checklist for supporting code | `skills/harness/verification-loop/SKILL.md` |
| Diagnose APEXLang, import, or ORA- errors | `skills/harness/error-triage/SKILL.md` |
| Evaluation design | `skills/harness/eval-harness/SKILL.md` |
| Security review | `skills/harness/security-review/SKILL.md` |
| Context pressure | `skills/harness/strategic-compact/SKILL.md` |
| Architecture decisions | `skills/harness/architecture-decision-records/SKILL.md` |
| Project memory (decisions, instincts, handoff) | `.memory/README.md` |
| Local FREEPDB1 sandbox and promotion audit | `local-dev/README.md` |
| Static verification of changed files | `scripts/verify-apex-change.ps1` |
| v3 blueprint corrections and rejected claims | `docs/adr/0004-v3-blueprint-corrections.md` |

**Path mapping.** The vendored routers use upstream repository-root paths. Resolve `apex/...` as `skills/apex/...` and `db/...` as `skills/db/...` when following those routers.

## Four-domain Oracle engineering

Use `skills/apex-domains/SKILL.md` for work that crosses business meaning and implementation. It defines four modes:

1. **Business analysis and domain model** — actors, goals, vocabulary, rules, lifecycle, acceptance criteria.
2. **APEX application design** — data model, page map, navigation, authorization, UX, performance, deployment.
3. **PL/SQL implementation** — package API, transactions, bulk DML, errors, security, tests.
4. **APEXLang implementation** — version lock, file map, component selection, validation.

For a new feature, do not jump to pages. Establish the domain model, rule catalogue, and page map first. Keep business rules in PL/SQL packages; page processes orchestrate calls. Every accepted rule needs one implementation home and a test.

PL/SQL mode also reads `skills/apex-domains/references/smartdb-plsql.md` for the TAPI/XAPI contract, PL/Scope checks, utPLSQL, and target-version SQL compatibility. APEX design mode also reads `skills/apex-domains/references/universal-theme.md` for Theme 42, template, accessibility, and compiler-truth rules.

## Multi-harness entry points

`AGENTS.md` is canonical. Thin adapters keep the same behavior across hosts:

| Host | Entry point |
| --- | --- |
| OpenCode | `opencode.jsonc` and `skills/` |
| Codex CLI / VS Code Codex | `AGENTS.md` |
| Claude Code / VS Code Claude | `CLAUDE.md`, `.claude/skills/oracle-apex/` |
| Antigravity | `AGENTS.md`, `.agents/rules/`, `.agents/skills/` |
| DSH (DeepSeek Harness) | `AGENTS.md`, `.agents/skills/` |
| Other `AGENTS.md`-aware extension | `AGENTS.md` |

Setup matrix and no-key paths: `docs/harnesses/README.md`.

## Model and API-key policy

- Do not request, print, or store API keys. Do not use paid API models.
- Prefer a free model in OpenCode, a local Ollama model in Codex/DSH, the Antigravity free tier, or an existing subscription login that requires no API key.
- If a host needs authentication, use its account/OAuth login. Never convert a subscription into a metered API key.
- `scripts/harness-doctor.ps1 -StrictNoKeys` fails when common paid-key environment variables are present.
- The harness can improve routing and verification, but it cannot make a weak model produce production-grade APEXLang or PL/SQL. Deterministic validation remains the gate.

## Version routing

1. Read `mmdVersion` from the application's `.apex/apexlang.json`, or from the target APEX instance.
2. Match on `major.minor`: `26.1.x` uses the 26.1 skills, `26.2.x` uses the 26.2 skills.
3. If the version is unknown, use **26.1** and state that assumption.
4. If the target version is not 26.1 or 26.2, stop and tell the user which versions this harness supports.

## Default delivery workflow

The harness supports two lean vibe coding workflows without multi-phase specification ceremony:

1. **Greenfield Vibe Coding (New Application)**:
   - Provide a natural language prompt or define the page map & requirements in `working/page-design/requirement.md`.
   - When `working/page-design/requirement.md` is provided, the agent MUST strictly follow the user's page layout, page numbers, and component specifications rather than inventing an arbitrary architecture.
   - Design direction in `requirement.md` (colours, badges, icons, shadows, tone) is a requirement, not decoration. Stock Universal Theme is the floor, not the ceiling: implement the requested look with the brand layer (`skills/apex-design-system/references/brand-layer.md`).
   - **Design before code.** Before writing any SQL or `.apx`, write `working/page-design/application-design.md` from `docs/templates/application-design.template.md`: data model, security, business rule → PL/SQL enforcement, visual design (brand layer), page and component map, file map, and a requirement trace with one row per `requirement.md` bullet marked `PLANNED`. Set `Status: DRAFT`, summarise it to the user, and **stop for approval**. Do not build until the user approves; then set `Status: APPROVED`.
   - `requirement.md` is user-owned: the agent never edits it. If the design must deviate, list the deviation under "Open questions" in `application-design.md` and let the user decide.
   - After building, update the requirement trace to `DONE` with `file:line`, or `NOT DONE: <reason>`, and set `Status: IMPLEMENTED`. Delivery is incomplete while any trace row is `PLANNED` or silently missing.
   - The agent generates the schema and seed SQL scripts under `working/database/`, and scaffolds the full APEXLang tree under `working/app/` matching the user's design.
   - Run the normalization and validation gates (`scripts/validate-apex-app.ps1 -AppDirectory working/app`).
   - Directly ask the user if they want the agent to help execute Step 1 (deploy database schema, packages, and tests) and Step 2 (import the APEX application tree into the target/local APEX workspace).
   - Automated Workspace & User Provisioning: When deploying, the pipeline automatically ensures the target APEX workspace and all required user accounts (the workspace administrator `ADMIN`, plus any seeded test accounts) are created and active with zero manual credential configuration required. The local password comes from `ORACLE_PASSWORD` (see `local-dev/README.md`); record access details in `working/page-design/credentials.md` and never repeat passwords in instruction files or chat.

2. **Brownfield Vibe Coding (Improve Existing Application)**:
   - Point directly to the target page or shared component in `working/app/` (e.g., "Add an export button on Page 10" or "Require a rejection reason in review dialog").
   - The agent edits the targeted `.apx` or `.sql` files directly. Small, single-component changes need no approval stop.
   - If the change adds a page, a business rule, a role, or changes the look, update `working/page-design/application-design.md` first (sections touched, trace rows, change log) and confirm with the user before building.
   - Run the validation gate.

For specialized guidance during vibe coding, use the domain commands directly:
- `/apex.plsql` (packages, business rules, tapi/xapi)
- `/apex.apexlang` (implement declarative .apx changes)

Then run the APEX gates:

1. **Static verify**: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-apex-change.ps1 -AppDirectory working/app`; use `-Strict` for a release candidate.
2. **Validate**: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-apex-app.ps1 -AppDirectory working/app`
3. **Delivery gate**: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-delivery.ps1 -ProjectDirectory working` must print `DELIVERY GATE PASS`. It fails on an unapproved or untraced design, requirement colours or design keywords missing from the build, inline styles/hex in `.apx`, unknown icons, unused styling columns, undefined `brand-*` classes, uncalled package APIs, and missing tests. Fix the build, not the gate; never mark a trace row DONE to silence it.
4. **Review**: use the `apex-reviewer` subagent for APEXLang, SQL, security, and performance.
5. **Deploy** (only on explicit request and after the user approves the named target): `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy-apex-app.ps1 -AppDirectory working/app -WhatIf` first, then run without `-WhatIf`.
6. **Verify**: run the runtime gate against the imported app, logged in as every seeded role: `node scripts/verify-apex-runtime.mjs --url <app-url> --users <roles> --pages <aliases> --deny <user:alias> --brand --insecure` with the password in `APEX_TEST_PASSWORD` (never on the command line). It must print `RUNTIME GATE PASS` (page errors, JS errors, empty icon boxes, mobile overflow, serious axe violations, brand stylesheet not loaded, authorization leaks). Then follow `skills/apex-delivery/SKILL.md` and produce a PASS/FAIL report.
7. **Export and drift-check** (after import, when the target supports APEXLang export): `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/export-apex-app.ps1 -ApplicationId <id> -OutputDirectory <export-dir> -CompareDirectory working/app`. Treat drift as a failure and explain it.

## Project & Working Directory Structure (1 Project per Harness Repo)

This harness repo is disposable and dedicated to **one project**. All deliverables are organized cleanly inside the `working/` directory.

To start a new project without re-cloning or re-downloading tools, run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/reset-project.ps1` (or add `-Archive` to back up the current project to `archive/`).


```text
working/
├── page-design/                  # User-defined page map and UI architecture
│   ├── requirement.md            # USER-owned intent: pages, rules, look (agent never edits)
│   ├── application-design.md     # AGENT-owned design + requirement trace (user approves)
│   └── credentials.md            # Workspace access, admin & seeded test accounts
├── database/                     # Oracle Database artifacts
│   ├── schema.sql                # Tables, constraints, indexes, and seed data
│   ├── packages/                 # TAPI & XAPI business logic packages (pks / pkb)
│   └── tests/                    # utPLSQL test suites
└── app/                          # APEXLang declarative application tree
    ├── .apex/                    # apexlang.json version lock
    ├── application.apx           # Application manifest
    ├── deployments/              # Deployment target configs
    ├── page-groups.apx           # Navigation groups
    ├── pages/                    # Page definition files (p00001-*.apx, etc.)
    ├── shared-components/        # Authorizations, lists, LOVs, themes, templates
    └── supporting-objects/       # Export scripts and install manifests
```

## Environment

First run on Windows: `.\bootstrap.cmd`. First run on macOS/Linux: `bash scripts/bootstrap.sh`. The bootstrap installs prerequisites, verifies the harness, and is documented in `docs/getting-started.md`.

After setup, run the harness commands before APEX work (from the repository root):

**Windows**
```powershell
. .\scripts\set-env.ps1
.\scripts\harness-doctor.ps1
```

**macOS / Linux (PowerShell 7)**
```bash
. ./scripts/set-env.ps1
pwsh -NoProfile -File scripts/harness-doctor.ps1
```

- `JAVA_HOME`: JDK 21. `set-env.ps1` discovers `C:\Program Files\Microsoft\jdk-*`, Temurin, and common `/usr/lib/jvm/*21*` locations.
- `SQLCL_BIN`: defaults to `tools/sqlcl/bin/sql.exe` on Windows and `tools/sqlcl/bin/sql` on macOS/Linux.
- `SQLCL_CONNECTION_STRING`: set by the user for deploy; never commit it.
- `TARGET_DB_VERSION`: confirm `19c`, `23ai`, or `26ai` before using newer SQL. The compatibility matrix is in `skills/apex-domains/references/smartdb-plsql.md`.
- SQLcl 26.3+ is expected. `apex validate` requires no database connection; `apex import` does.
- Run `scripts/test-harness.ps1` to exercise the validation, normalization, export, and deploy gates offline with fake SQLcl output. It does not touch a database.
- OpenCode 1.18+ and 2.x are both supported. `opencode.jsonc` uses the V1 `permission` object; 2.x converts it to `permissions`, while 1.x rejects any `permissions` key. Test with `opencode debug config` and, when installed, `tools/opencode-v2/opencode.exe` (Windows) or `tools/opencode-v2/opencode` (macOS/Linux) `debug config`. `harness-doctor.ps1` fails if an installed runtime rejects the config or an agent.

## APEXLang conventions

- Application runtime artifacts live under `working/app/` (or `applications/<app>/`) and publish only runtime artifacts: `.apex/`, `application.apx`, `deployments/`, `page-groups.apx`, `pages/`, `shared-components/`, and `supporting-objects/`.
- Do not copy template docs or `scaffold-example/` containers into an app root.
- `.apx` files must use UTF-8 without a BOM and LF line endings. SQLcl's APEX parser rejects CRLF and treats a BOM as source text. The validation gate fails on CRLF, BOM, compile diagnostics, `ORA-` errors, and `FILE_IGNORED` even when SQLcl prints `Validation successful`. Run `scripts/normalize-apx-tree.ps1 -AppDirectory <app-dir>` to fix line endings and a UTF-8 BOM, then re-validate.
- Resolve the target app directory before editing. If `working/app/` is missing, ask for the exact app directory; do not silently create or relocate apps.
- Keep raw grammar, the full component registry, and template trees out of context. Use the 26.1 generation skill's `tools/apexctl.mjs` projections (restored at the pinned upstream commit).
- For 26.2, there is no generation skill; author with the 26.2 inventory and example applications.
- For a new app from requirements plus schema metadata, follow `skills/apex/apexlang/26.1/apexlang-generation/references/workflows/apexlang/workflow-create-app-from-fr-and-model.md`.

## Database safety

- Prefer `skills/db/agent/schema-discovery.md` before writing SQL against an unknown schema.
- Use SQLcl MCP (`oracle-sqlcl`) for live schema discovery. Query the catalog at task start; do not cache table or column lists in memory files.
- Wrap multi-statement changes in explicit transactions with a rollback path.
- Never run `DROP`, `TRUNCATE`, `DELETE` without a `WHERE` clause, or `ALTER SYSTEM` without explicit approval.
- Local `FREEPDB1` may use full schema access for development. Commercial and shared targets are read-only by default; use a least-privilege saved connection and a separate approval for changes.
- The optional local sandbox and the read-only promotion audit are documented in `local-dev/README.md`.
- Do not require `uc-apx`: it has no license. Do not treat `tree-sitter-plsql` as a gate until a tested grammar and query suite are recorded in an ADR.
- For migrations, follow `skills/db/devops/schema-migrations.md` and `skills/db/migrations/migration-assessment.md`.

## Project memory

- Read `.memory/README.md` at the start of long-running work; update `session-handoff.md` at a task boundary.
- `decisions.md` is for project decisions smaller than an ADR. `instincts.md` requires evidence; it is not a place for guesses.
- Never store credentials, connection strings, wallet contents, generated SQL output, or schema caches in `.memory/`.

## Quality gates

- Harness script changes must pass `scripts\test-harness.ps1` and `scripts\harness-doctor.ps1`.
- Visual changes must provide before/after scorecards and a `scripts/verify-design-preview.mjs` report; prototype rendering does not prove deployed APEX rendering.
- APEX validation must print `Validation successful`.
- Delivery must print `DELIVERY GATE PASS` from `scripts/verify-delivery.ps1`; the self-tests in `scripts/test-harness.ps1` cover every rule it enforces.
- SQL and PL/SQL must be reviewed against `skills/db/sql-dev` and `skills/db/plsql`.
- Any change to authentication, authorization, or user input handling requires a security review.
- Record durable architecture decisions in `docs/adr/` using `skills/harness/architecture-decision-records/SKILL.md`.
- At the end of a non-trivial task, run the self-evaluation in `skills/harness/agent-self-evaluation/SKILL.md` and state residual risks.

## Communication

- Lead with the outcome. Then show evidence, commands, and file paths.
- **Maintain application credentials in file, not chat output**: Record and maintain all workspace access details, local URLs, administrator credentials, and seeded test accounts inside `working/page-design/credentials.md`. Do not dump the credentials card in every chat response; simply link to `working/page-design/credentials.md` when deployment or setup occurs, or when the user asks for credentials.
- Use APEX component names and `.apx` paths precisely.
- When blocked, state the exact missing input (app directory, workspace name, connection, APEX version) instead of guessing.
