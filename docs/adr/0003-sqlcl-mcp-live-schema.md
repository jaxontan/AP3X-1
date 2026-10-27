# ADR-0003: Use SQLcl MCP for live schema discovery and local database work

- Status: Accepted
- Date: 2026-10-28
- Supersedes: the MCP deferral in ADR-0001

## Context

ADR-0001 deferred a live database tool until the offline validate/deploy loop was proven. SQLcl 26.3 provides the MCP server and the `apex validate` path; the local sandbox and target database are still separate, explicitly approved steps. The target workflow is:

1. Develop against a local Oracle Database Free `FREEPDB1` instance with full schema access.
2. Promote validated artifacts to a commercial Oracle Database and APEX environment.

Static mode prompts and cached schema notes cannot prevent column, constraint, and APEX dictionary guesses. SQLcl 25.2+ includes a built-in MCP server with `list-connections`, `connect`, `disconnect`, `run-sql`, and `run-sqlcl` tools. It uses pre-saved SQLcl connections, so credentials do not belong in agent prompts or repository files.

## Decision

- Enable the SQLcl MCP server as `oracle-sqlcl`:
  - OpenCode v2: `mcp.servers.oracle-sqlcl` in `opencode.jsonc`.
  - Claude Code: `.mcp.json`.
  - Other hosts: follow `skills/db/sqlcl/sqlcl-mcp-server.md` and the host's MCP configuration.
- Start SQLcl with `-R 1`. This allows SQL, PL/SQL, DDL, and most SQLcl commands while blocking host/OS escapes. `-R 0` is an explicit opt-in for a disposable local sandbox, not the default.
- Use SQLcl saved connections created with `conn -save <name> -savepwd`. Never put a password, connection string, wallet, or TNS secret in a repository file or prompt.
- Use MCP for live discovery and local iteration. Query `USER_TAB_COLUMNS`, `USER_CONSTRAINTS`, `USER_DEPENDENCIES`, `USER_ERRORS`, and the `APEX_APPLICATION_*` views at task start. Do not cache column lists in memory files.
- Keep deterministic gates: `scripts/validate-apex-app.ps1` for `.apx` trees, `scripts/verify-apex-change.ps1` for changed files, SQLcl Projects for release artifacts, and explicit approval for import and destructive SQL.
- On a shared or commercial database, use a least-privilege parsing-schema connection and read-only discovery by default. Full local access is a `FREEPDB1` development convenience, not a production default.

## Alternatives considered

- **Keep direct SQLcl shell wrappers only.** Rejected as the only path: they remain useful for offline validation and deployment, but they require the agent to assemble shell commands and cannot expose structured schema metadata as cleanly.
- **Read-only MCP connection only.** Rejected for local development: it prevents the agent from compiling packages and iterating on a free PDB. It remains the recommended default for shared and commercial targets.
- **`-R 0` by default.** Rejected: it gives the model host command execution. `-R 1` keeps full SQL capability without that escape.
- **Vendor `uc-apx`.** Rejected: the repository has no license, so it cannot be bundled or treated as a required gate. It remains an optional external tool for users who have a commercial license.
- **Use `tree-sitter-plsql` as an AST gate.** Rejected as a required gate: the grammar is incomplete and unchanged since 2023, and the proposed query node names are unverified. Static checks in `scripts/verify-apex-change.ps1` cover the highest-value anti-patterns; real compiler and test evidence remain authoritative.

## Consequences

- The agent can inspect the live parsing schema before generating code, which removes a major source of hallucinated columns and constraints.
- The SQLcl JVM adds startup time to MCP sessions; the OpenCode server has a 60-second startup timeout.
- SQLcl maintains its own MCP logs and connection metadata; review them according to the target's audit policy.
- Saved passwords live in the user's SQLcl connection store (`~/.dbtools`), outside the repository. Protecting that store is an operating-system responsibility.
- The MCP server is an additional context consumer. Keep only `oracle-sqlcl` enabled unless another server has a specific APEX need.
- Local full access can create artifacts that depend on local privileges. `local-dev/promotion-audit.sql` and the version-locked validation gate reduce that risk but do not replace a commercial-environment test.
