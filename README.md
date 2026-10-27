# Oracle APEX Agent Harness

A multi-harness engineering environment for Oracle APEX. It pairs with OpenCode, Codex, Claude Code / VS Code Claude, Antigravity, DSH, and other `AGENTS.md`-aware agents without requiring a paid API key.

It combines:

- **Four-domain Oracle engineering** — business analysis and domain modeling, APEX application design, PL/SQL implementation, and APEXLang coding.
- **Oracle domain skills** — APEX 26.1/26.2 APEXLang generation, validation, deployment, inventories, and example apps, plus the Oracle Database skill tree.
- **Spec-driven delivery** — GitHub Spec Kit commands for specification, planning, tasks, implementation, and convergence.
- **Harness meta-skills** — a curated set of ECC skills for verification, eval, security review, context management, and decision records.
- **Thin host adapters** — one canonical `AGENTS.md`, with bridges for Claude Code, Antigravity, and DSH so behavior does not diverge by editor.
- **Local-to-commercial workflow** — an optional `FREEPDB1` sandbox, SQLcl MCP for live schema discovery, and a read-only promotion audit before touching a commercial database.
- **Project memory** — `.memory/` templates for decisions, evidence-backed instincts, and session handoffs.

## Quick start (OpenCode)

```powershell
cd <path-to-this-repo>
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-opencode-v2.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
. .\scripts\set-env.ps1
.\scripts\harness-doctor.ps1
opencode
```

If the execution policy blocks dot-sourcing, the `Set-ExecutionPolicy -Scope Process` line applies only to the current PowerShell window. You can also run individual scripts with `powershell -NoProfile -ExecutionPolicy Bypass -File <script>`.

OpenCode v2 is required: `opencode.jsonc` uses the v2 `permissions` ruleset, which v1 rejects. `install-opencode-v2.ps1` places a project-local v2 binary under `tools\opencode-v2\`; `set-env.ps1` puts it first on `PATH` and also provides an `opencode2` shim.

The default agent is `apex`. The default model is a zero-cost OpenCode model. The project constitution is already initialized at `.specify/memory/constitution.md`; start a non-trivial feature with:

```text
/speckit.specify <feature description>
/speckit.clarify
/speckit.plan
/speckit.tasks
/speckit.implement
```

For a smaller domain task, use the targeted commands:

```text
/apex.design <business feature>      # domain model, rules, page map, PL/SQL API outline
/apex.plsql <business rules>          # package implementation or review
/apex.apexlang <app-directory>        # APEXLang implementation for an approved design
```

Then run the gates:

```text
/apex.verify <app-directory>
/apex.validate <app-directory>
/apex.review <app-directory>
```

Deploy only after an explicit request:

```text
/apex.deploy <app-directory>
```

## Harness pairing

| Host | Project entry point | Zero-API-key path |
| --- | --- | --- |
| OpenCode | `opencode.jsonc`, `skills/` | Free model pinned in `opencode.jsonc` |
| Codex CLI / VS Code Codex | `AGENTS.md` | `codex --oss --local-provider ollama` |
| Claude Code / VS Code Claude | `CLAUDE.md`, `.claude/skills/oracle-apex/` | `/login` with an existing Claude subscription |
| Antigravity | `AGENTS.md`, `.agents/rules/`, `.agents/skills/` | Google login and the free tier |
| DSH (DeepSeek Harness) | `AGENTS.md`, `.agents/skills/` | `ollama launch dsh` or a local-provider plugin |
| Other agent extension | `AGENTS.md` | Depends on the host and model |

No API key is required by this harness. Existing paid-key environment variables are never used by the harness; `scripts/harness-doctor.ps1 -StrictNoKeys` reports them (names only, never values) and fails the check. Claude Code has no official $0 local-model mode; use a subscription login or choose Codex, Antigravity, DSH, or OpenCode for a free/local path.

Full setup commands, caveats, and model-quality notes: [`docs/harnesses/README.md`](docs/harnesses/README.md).

## Four-domain workflow

For a new feature, do not jump to pages. Work in this order:

1. **Business analysis** — actors, goals, vocabulary, rules, lifecycle, exceptions, acceptance criteria.
2. **Domain model** — entities, relationships, invariants, reference data, audit, retention.
3. **APEX design** — roles, authorization, page map, navigation, empty/error states, performance.
4. **PL/SQL API** — package operations, transaction boundaries, error contract, bulk DML, tests.
5. **APEXLang implementation** — version-locked components, thin page processes, validation.

The orchestration skill is `skills/apex-domains/SKILL.md`. It includes references for each domain, templates for the business spec, domain model, page map, and rule traceability, plus a design-review checklist. PL/SQL work also reads `references/smartdb-plsql.md` for TAPI/XAPI, PL/Scope, utPLSQL, and 19c/26ai compatibility. APEX design also reads `references/universal-theme.md` for Theme 42, template, accessibility, and compiler-truth rules.

Every accepted business rule gets an ID, one primary implementation home, and a test. Business logic belongs in PL/SQL packages; page processes orchestrate package calls and map errors to page messages.

## Local database and promotion

`local-dev/README.md` documents the optional `uc-local-apex-dev` sandbox pinned to APEX 26.2, the read-only `snapshot-pdb.sql`, and the 23-section `promotion-audit.sql`. The installer previews the plan by default; `-Execute` is required to clone and start the sandbox. Docker or Podman is required, and this workflow has not been executed on a machine without Docker.

SQLcl MCP is the live schema boundary. Query the catalog at task start with `oracle-sqlcl`; do not cache table or column lists in `.memory/` or skills. Local `FREEPDB1` may use full schema access for development, but commercial and shared targets are read-only by default.

The v3 blueprint is adopted selectively. `docs/adr/0004-v3-blueprint-corrections.md` records the rejected claims: `uc-apx` has no license, `.pdk/project.json` is not the SQLcl Projects path, tree-sitter PL/SQL is not a verified gate, and the default `26-4` sandbox branch does not match this harness's 26.1/26.2 lock.

## Layout

```text
Apex-harness/
├── AGENTS.md                 # Canonical operating rules and routing
├── CLAUDE.md                 # Claude Code / VS Code Claude adapter
├── opencode.jsonc            # Free-model defaults, agents, skills, permissions
├── .claude/skills/           # Claude Code project skill bridge
├── .agents/
│   ├── skills/               # DSH/Antigravity skill bridge
│   └── rules/                # Antigravity rule bridge
├── .opencode/
│   ├── agents/               # apex, apex-planner, apex-reviewer, oracle-dba, harness-optimizer
│   └── commands/             # speckit.* and apex.* commands
├── .specify/                 # Spec Kit templates, scripts, memory, workflows
├── .memory/                  # Decisions, evidence-backed instincts, session handoff
├── skills/
│   ├── apex/                 # Vendored Oracle APEX + APEXLang skills
│   ├── db/                   # Vendored Oracle Database skills
│   ├── apex-domains/         # Four-domain workflow, references, templates, checklist
│   ├── apex-delivery/        # End-to-end APEX delivery gate
│   └── harness/              # Curated ECC meta-skills
├── applications/             # Generated APEXLang apps (runtime artifacts only)
├── local-dev/                # Optional FREEPDB1 sandbox + promotion audit
├── db/README.md              # Database artifact routing note
├── scripts/
│   ├── set-env.ps1           # JAVA_HOME, SQLcl + OpenCode v2 PATH, SQLCL_BIN
│   ├── harness-doctor.ps1    # Tool, file, adapter, environment, and key checks
│   ├── verify-apex-change.ps1 # Changed-file static verification gate
│   ├── validate-apex-app.ps1 # APEX validate gate (checks LF first)
│   ├── normalize-apx-tree.ps1 # Convert CRLF .apx files to LF
│   ├── deploy-apex-app.ps1   # APEX import gate with -WhatIf
│   ├── install-sqlcl.ps1     # Reproducible SQLcl + JDK setup
│   ├── install-opencode-v2.ps1 # Project-local OpenCode v2 binary
│   └── install-local-apex.ps1  # Preview-first FREEPDB1 sandbox wrapper
├── tools/sqlcl/              # Local SQLcl 26.3 (gitignored)
└── docs/
    ├── PROVENANCE.md         # Exact sources, commits, licenses, decisions
    ├── references.md         # Cookbook review and external links
    ├── harnesses/            # No-key setup matrix for each host
    └── licenses/
```

## Agents

| Agent | Mode | Use |
| --- | --- | --- |
| `apex` | primary | Build, change, validate, and deploy APEX applications; translate business rules to PL/SQL and APEXLang. |
| `apex-planner` | subagent | Read-only business/domain analysis, solution architecture, page map, and implementation planning. |
| `apex-reviewer` | subagent | Read-only APEXLang, SQL/PLSQL, security, accessibility, performance, and traceability review. |
| `oracle-dba` | subagent | Read-only Oracle Database, SQL/PLSQL, migration, and performance review. |
| `harness-optimizer` | subagent | Improve the harness without touching vendored Oracle skills. |

## Safety model

- **Validation before deployment.** `apex validate` must print `Validation successful`. `.apx` files must use LF; CRLF trees are rejected before SQLcl runs. Changed files also pass `scripts/verify-apex-change.ps1`.
- **Explicit deployment approval.** The deploy script supports `-WhatIf` and never prints the connection string.
- **Database changes are gated.** Destructive shell patterns, `apex import`, `drop`, `truncate`, `delete`, `alter system`, and `git push` ask for confirmation through `opencode.jsonc`. Local `FREEPDB1` may use full schema access; commercial and shared targets are read-only by default.
- **Secrets stay out of context.** `.env`, `.pem`, `.key`, `.p12`, `.jks`, and Oracle wallet files are denied; `.env.example` remains readable. `.memory/` never stores credentials or schema caches.
- **No paid API keys.** Do not request, print, or store API keys. Use a free host tier, subscription login, or local model, and validate deterministically.
- **Business rules are traceable.** Every accepted rule has an ID, one implementation home, and a test; page processes do not become the only enforcement point.
- **Vendored skills are upstream content.** `skills/apex/**` and `skills/db/**` are updated from source. The only local adaptations are LF normalization for `.apx` files, the short router path-mapping notes, and the restored 26.1 generation `tools/` directory from the pinned commit.
- **Unlicensed and unverified tools stay optional.** `uc-apx` is not required because it has no license. tree-sitter PL/SQL is not a gate until a tested grammar and regression suite exist. See `docs/adr/0004-v3-blueprint-corrections.md`.

## Prerequisites

Required:

- OpenCode 2.x
- Node.js 18+
- Python 3.11+
- `uv` and `specify-cli` (Spec Kit)
- JDK 21
- SQLcl 26.3+

Optional hosts:

- Codex CLI (installed at the time of writing as `codex-cli 0.149.1`)
- Claude Code CLI and, if used, a Claude subscription
- Antigravity desktop app with a Google account
- DSH (developer preview)
- Ollama with a local coding model for Codex or DSH
- Docker Desktop or Podman Desktop for the optional `local-dev` sandbox

`scripts/install-sqlcl.ps1` installs SQLcl locally and JDK 21 via winget when Java is missing. `scripts/harness-doctor.ps1` verifies required tools, harness files, optional hosts, and paid-key environment variables. `scripts/install-local-apex.ps1` previews the sandbox setup and requires `-Execute` to make changes; it needs Docker or Podman.

## Provenance

See `docs/PROVENANCE.md` for commit hashes, licenses, installed paths, and the list of components deliberately not installed.

- Oracle skills: UPL-1.0
- Spec Kit: MIT
- ECC: MIT
- `uc-local-apex-dev`: MIT, optional sandbox pinned to `26-2`
- `uc-apx`: reviewed, not vendored (no license)
- Developer-Cookbook: reviewed, not vendored (no license)
