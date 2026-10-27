# Provenance and Installed Components

Recorded: 2026-10-27

This harness composes three upstream layers: Oracle domain skills, a spec-driven delivery process, and a small set of agent-harness meta-skills. This file records exactly what was installed, from where, and under which license.

## 1. Oracle Skills (domain layer)

- Repository: https://github.com/oracle/skills
- Commit: `014cdb29f12dfa6a689bbe8a80ee1c5f0bf15be1`
- License: Universal Permissive License v1.0 (`skills/ORACLE-LICENSE.txt`)
- Installed paths:
  - `skills/apex/` — APEX domain router, APEXlang 26.1 and 26.2 skills, component inventories, and example applications.
  - `skills/db/` — Oracle Database guidance: SQL, PL/SQL, SQLcl, ORDS, security, performance, migrations, Data Guard, VecDB, and agent-safe workflows.
- Method: sparse shallow clone of the `apex` and `db` directories, copied from upstream. Two platform adaptations are documented below: LF normalization for `.apx` files and a path-mapping note at the top of each router. Do not otherwise edit vendored files; update by re-running the sparse clone and reapplying those adaptations.

APEXlang routing:

- `skills/apex/apexlang/SKILL.md` selects 26.1 or 26.2 from `mmdVersion`.
- 26.1 includes `apexlang-generation`, `apexlang-compile`, `apexlang-deploy`, `apexlang-inventory`, and `apexlang-example-applications`.
- 26.2 includes compile, deploy, inventory, and example applications. It has no generation skill; author with 26.2 inventory and examples only.

### Windows line endings

The upstream clone was checked out on Windows with CRLF conversion. SQLcl 26.3's `apex validate` rejects CRLF `.apx` files with misleading `token recognition error at: '\r\n'` messages, so all 456 `.apx` files under `skills/` were normalized to LF. Only line endings changed; no APEX content was edited.

`.gitattributes` now enforces `*.apx text eol=lf`, and `scripts/validate-apex-app.ps1` checks for CRLF before invoking SQLcl. Use `scripts/normalize-apx-tree.ps1` on any app tree that was created or checked out with CRLF.

### Router path mapping

The upstream `apex/SKILL.md` and `db/SKILL.md` routers use repository-root paths such as `apex/apexlang/SKILL.md` and `db/agent/schema-discovery.md`. In this harness those trees live under `skills/`. A short mapping note was added at the top of each router, and `AGENTS.md` repeats the rule. No routing entries or skill content were otherwise changed.

## 2. GitHub Spec Kit (process layer)

- Repository: https://github.com/github/spec-kit
- Version: `specify-cli 1.2.3`
- Commit: `ee94598c3c87ae231027b22fb2be2b5a13e8820f`
- License: MIT (`docs/licenses/spec-kit-LICENSE.txt`)
- Installed with: `uv tool install specify-cli`
- Initialized with: `specify init --here --force --non-interactive --integration opencode --script ps`
- Generated paths:
  - `.specify/` — templates, PowerShell scripts, memory, workflows.
  - `.opencode/commands/speckit.*.md` — constitution, specify, clarify, plan, tasks, implement, analyze, checklist, converge, and taskstoissues commands.

Spec Kit is installed globally as a `uv` tool. The project files are committed. Re-run `specify init` only when upgrading and after reviewing the diff.

## 3. ECC (agent-harness meta layer)

- Repository: https://github.com/affaan-m/ECC
- Version: 2.2.3
- Commit: `25278e7d7b6cf6e6a4e7a6c8e10f14ff22f0eb5b`
- License: MIT (`skills/harness/ECC-LICENSE.txt`)
- Method: curated copy of 10 self-contained skills into `skills/harness/`. The full catalog was not installed. `context-budget` was evaluated and removed because its router targets Codex/Claude Code context meters that OpenCode does not expose.

Installed skills:

| Skill | Why it is here |
| --- | --- |
| `agent-harness-construction` | Design the agent's action space and observations. |
| `agent-self-evaluation` | Structured reflection after non-trivial tasks. |
| `architecture-decision-records` | Durable ADRs for hard-to-reverse choices. |
| `context-and-decisions` | Keep domain language separate from architecture decisions. |
| `eval-harness` | Eval-driven development and regression suites. |
| `iterative-retrieval` | Progressive context retrieval for subagents. |
| `security-review` | Security checklist for user input, auth, and secrets. |
| `strategic-compact` | Compact at task boundaries rather than arbitrarily. |
| `tdd-workflow` | Test-first discipline for supporting code. |
| `verification-loop` | Six-phase verification report. |

Not installed, deliberately:

- The full 311-skill catalog and 71 agents. It is mostly general software engineering and would dilute APEX routing.
- ECC runtime hooks, the `ecc-universal` plugin, AgentShield, and the unified-memory CLI. They require a global OpenCode config and a separate runtime.
- ECC's `database-reviewer` agent. It is PostgreSQL/Supabase-focused; the Oracle `db` skills are authoritative here.
- Global ECC install. It writes to `~/.config/opencode` and can duplicate skills, commands, and hooks.

ECC skills are generic and occasionally mention Claude Code-specific commands. Treat their checklists as guidance and substitute the APEX gates in `AGENTS.md` and `skills/apex-delivery/SKILL.md`.

## 4. Runtime tools

| Tool | Version | Location | Source |
| --- | --- | --- | --- |
| Microsoft OpenJDK 21 | 21.0.13 | `C:\Program Files\Microsoft\jdk-21.0.13.21-hotspot` | `winget install Microsoft.OpenJDK.21` |
| Oracle SQLcl | 26.3.0 | `tools\sqlcl` | https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip |
| Node.js | 24.19.0 | system | pre-existing |
| Python | 3.12.10 | system | pre-existing |
| uv | 0.12.19 | system | pre-existing |
| OpenCode | 2.0.32 | system | pre-existing |

`tools/` is gitignored because SQLcl is a 124 MB binary distribution. Recreate it with `scripts/install-sqlcl.ps1`.

## 5. Reviewed but not vendored

### srinivaskikkuru/Developer-Cookbook

- Repository: https://github.com/srinivaskikkuru/Developer-Cookbook
- Commit: `def7c9298096e8f85fd02645e5d0c995349a9d76`
- Contents: Oracle APEX development standards, APEX authentication/authorization notes, JavaScript standards, HTML/CSS guidance, Oracle SQL and PL/SQL standards, and common Oracle utility packages.
- Decision: not copied into the harness. The repository has no license file, so redistribution is not clearly permitted. A summary and links are in `docs/references.md`. Adopt the standards by reference or ask the author for a license before vendoring.

## 6. Updating

Update Oracle skills:

```powershell
git clone --depth 1 --filter=blob:none --sparse https://github.com/oracle/skills.git $env:TEMP\oracle-skills
git -C $env:TEMP\oracle-skills sparse-checkout set apex db
Copy-Item -Recurse -Force $env:TEMP\oracle-skills\apex .\skills\apex
Copy-Item -Recurse -Force $env:TEMP\oracle-skills\db .\skills\db
Copy-Item $env:TEMP\oracle-skills\LICENSE.txt .\skills\ORACLE-LICENSE.txt

# Reapply harness adaptations after the copy:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\normalize-apx-tree.ps1 -AppDirectory .\skills\apex
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\normalize-apx-tree.ps1 -AppDirectory .\skills\db
# Re-add the path-mapping note at the top of skills\apex\SKILL.md and
# skills\db\SKILL.md if the copy overwrote it (see section 1 above).
```

After updating, validate one 26.1 and one 26.2 example application again. Re-adding the Oracle trees also replaces the APEX license notice; keep `skills/ORACLE-LICENSE.txt` current.

Update Spec Kit:

```powershell
uv tool upgrade specify-cli
specify self check
```

Update curated ECC skills: re-clone ECC, review the diff for the 10 selected skill directories, then copy only those directories. Keep the MIT license notice.

## 7. Local harness extensions

These files are authored for this harness, not copied from an upstream catalog:

- `skills/apex-domains/` — four-domain workflow, references, templates, and design-review checklist.
- `skills/apex-delivery/` — APEX delivery and verification gates.
- `CLAUDE.md`, `.claude/skills/oracle-apex/SKILL.md` — Claude Code and VS Code Claude adapter.
- `.agents/skills/oracle-apex.md`, `.agents/rules/oracle-apex.md` — DSH and Antigravity adapters.
- `.opencode/agents/` and `.opencode/commands/apex.*` — OpenCode roles and APEX commands.
- `docs/harnesses/README.md` — host pairing matrix and no-API-key setup.
- `docs/adr/0002-multi-harness-and-four-domains.md` — rationale for the adapter and four-domain design.

The harness does not require an API key. Host login state and local models are environment concerns; no credentials are stored in the repository.
