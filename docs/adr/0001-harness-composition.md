# ADR-0001: Compose the harness from Oracle skills, Spec Kit, and curated ECC skills

- Status: Accepted; MCP deferral superseded by ADR-0003
- Date: 2026-10-27

## Context

The workspace is an Oracle APEX agent harness running on OpenCode. It needs three different kinds of capability:

1. Oracle-specific knowledge: APEXLang 26.1/26.2, APEX component syntax, validation, deployment, and Oracle Database safety.
2. A delivery process: requirements, specification, architecture, tasks, implementation, and convergence.
3. Harness-level discipline: verification, evaluation, security review, context management, and durable decisions.

Installing every available skill would create a large, overlapping routing surface. The harness also has to work on Windows with SQLcl, which is a Unix-oriented toolchain upstream.

## Decision

- Vendor the `apex` and `db` trees from `oracle/skills`, pinned by commit, under `skills/`.
- Use GitHub Spec Kit with its native OpenCode integration for the specification and planning workflow.
- Copy 10 self-contained ECC meta-skills into `skills/harness/`; do not install the full ECC catalog, hooks, or global OpenCode configuration. A Codex/Claude-specific context-meter skill was evaluated and excluded.
- Add one Oracle-specific delivery skill, `skills/apex-delivery/`, that connects the domain skills to the Spec Kit workflow and the SQLcl gates.
- Keep the OpenCode configuration project-local: `opencode.jsonc`, `.opencode/agents/`, and `.opencode/commands/`.
- Install JDK 21 system-wide and SQLcl locally under `tools/` (gitignored), with PowerShell wrappers for validation and deployment.
- Normalize vendored `.apx` files to LF and enforce LF in `.gitattributes`, because SQLcl's APEX parser rejects CRLF.

## Alternatives considered

- **Full ECC install.** Rejected: 311 skills and 71 agents are mostly general software engineering, require a global config, and would dilute APEX routing. The curated subset covers the harness needs.
- **Oracle skills only.** Rejected: no specification process, no eval or verification discipline, and no clear deployment gate.
- **Spec Kit only.** Rejected: no Oracle domain knowledge, no SQLcl validation, and no database safety rules.
- **MCP database server first.** Deferred: a live database tool is useful, but it adds a credential-bearing service before the basic validate/deploy loop is proven. SQLcl wrappers are the smaller first step. Superseded by ADR-0003 after the offline validate/deploy loop was proven.

## Consequences

- The harness is small enough to reason about and has one obvious route for APEX work.
- Vendored Oracle skills must be updated from source, not edited in place.
- ECC meta-skills are generic and occasionally mention Claude Code; their checklists are guidance, while `AGENTS.md` and `skills/apex-delivery/` are authoritative for APEX.
- Windows requires LF normalization and PowerShell wrappers; the upstream bash scripts are not the primary path.
- There is no autonomous memory or hook runtime. If those become necessary, evaluate them as a separate ADR rather than enabling ECC globally.
