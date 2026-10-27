# ADR-0004: Adopt the v3 blueprint selectively and correct its unverified claims

- Status: Accepted
- Date: 2026-10-28

## Context

The v3 blueprint proposes a nine-layer harness that combines Spec Kit, ECC, Oracle Skills, `uc-apx`, `uc-local-apex-dev`, tree-sitter PL/SQL, SQLcl Projects, Universal Theme rules, and a FreePDB-to-commercial promotion gate. Several parts are valuable and several parts conflict with verified repository facts or with the harness's safety rules.

Verified facts:

- `United-Codes/uc-apx` has no license. It cannot be vendored, copied, or made a mandatory gate. Its commands may be used only as an optional external tool by a user who has a separate license.
- `United-Codes/uc-local-apex-dev` is MIT, but its default branch is `26-4`. This harness supports APEX 26.1 and 26.2, so the sandbox must pin `26-1` or `26-2`.
- SQLcl 26.3 Projects creates `.dbtools/project.config.json`, not `.pdk/project.json`. The `PROJECT` command family is present; use `help project` in the target SQLcl session for the exact subcommands.
- SQLcl 26.3 has a `skills sync` command, but running it would overwrite the version-locked vendored skills unless it is explicitly scoped and reviewed.
- The official `oracle/skills` 26.1 generation skill expects `tools/apexctl.mjs`. That directory was missing from the initial vendored copy and has now been restored from the pinned upstream commit.
- `andreasmaierde/tree-sitter-plsql` is stale and incomplete, and the proposed `njank/tree-sitter-plsql` link is not a verified fork. It cannot be a required AST gate.
- The harness is Windows-first. Bash hooks and a Makefile are not reliable defaults on this machine.
- The canonical project layout is `applications/<app>/`, `.specify/`, `specs/`, and `skills/`. The v3 `.specs/`, parallel `apex/` and `db/` trees, and duplicate `.agents/skills/` would fragment the source of truth.
- The plugin `@0xsero/open-queue` is a v1 plugin and does not load in OpenCode v2. It is not part of the harness.

## Decision

Adopt the v3 ideas that are verifiable and compatible:

1. **Local sandbox.** Keep the optional `uc-local-apex-dev` workflow under `local-dev/`, pinned to `26-2`, with a preview-by-default installer and read-only snapshot/promotion SQL. Do not run it as part of validation.
2. **Live schema boundary.** Keep SQLcl MCP as the live schema tool, with saved connections and `-R 1`. Do not cache schema metadata in memory files.
3. **Official deterministic tooling.** Use the restored `apexctl.mjs` plus the version-specific `apexlang-inventory`, examples, and SQLcl `apex validate`. Do not invent component properties.
4. **SmartDB and tests.** Add the `smartdb-plsql` reference: TAPI/XAPI separation, PL/Scope checks, utPLSQL, transaction ownership, and target-version SQL compatibility.
5. **Universal Theme.** Add the `universal-theme` reference: Theme 42, `@/` templates, `u-*` utilities, accessibility, and the compiler-truth rule IDs that actually exist in the vendored 26.1 skill.
6. **Memory.** Add `.memory/` templates for decisions, evidence-backed instincts, and session handoff. Do not add an ECC runtime, a global plugin, or an unverified agent-memory service.
7. **Verification.** Use the PowerShell `scripts/verify-apex-change.ps1` and `/apex.verify` command. Do not add Bash-only hooks as the primary gate.
8. **Promotion.** Use `local-dev/promotion-audit.sql` and SQLcl Projects with the real `.dbtools` path. Treat the audit as necessary but not sufficient; the target environment test remains authoritative.
9. **Version compatibility.** Record the target Oracle Database version and use the 19c/26ai compatibility matrix in `smartdb-plsql.md` before using newer SQL syntax.

Reject or defer:

- **Mandatory `uc-apx`.** Rejected because there is no license. It may be documented as an optional external accelerator, but no harness gate may depend on it.
- **`.pdk/project.json`.** Rejected as factually wrong. Use `.dbtools/project.config.json`.
- **Unverified tree-sitter AST gate.** Rejected until a grammar is built, pinned, tested, and covered by a regression suite. No `.scm` file ships as a gate.
- **Parallel `.specs/`, `apex/`, `db/` trees.** Rejected. Use the existing Spec Kit and application layout.
- **Bash hooks and a Makefile as the primary interface.** Rejected on Windows. PowerShell is the primary interface; a Makefile may be added later as an optional convenience.
- **Full ECC/AgentShield/global plugin install.** Rejected. The harness stays lean and project-local.
- **Unverified merge-safe sync script.** The worktree/3-way-merge idea is documented as an optional workflow, but no destructive sync script is shipped until it is tested against a live APEX instance.

## Alternatives considered

- **Adopt v3 wholesale.** Rejected: it would add unlicensed tooling, false paths, unverified parsers, and destructive automation that has not been tested.
- **Ignore v3.** Rejected: the local sandbox, SmartDB discipline, PL/Scope, Universal Theme rules, and promotion audit are useful and fit the harness.
- **Vendor `uc-apx` under a guessed license.** Rejected: a missing license is not permission.

## Consequences

- The harness gains a coherent local-to-commercial workflow without depending on unlicensed or unverified tools.
- `local-dev/` is documented and preflighted but not executed on this machine because Docker is absent. This limitation must be stated in reports.
- `apexctl.mjs` is now present at the pinned 26.1 generation path; the 26.2 tree still has no generation skill, so 26.2 authoring uses the inventory and examples.
- The `.memory/` files are templates, not an autonomous memory service. The agent must read and update them deliberately.
- Future adoption of `uc-apx`, tree-sitter, or a merge-safe sync must be recorded in a new ADR with a license, version, test evidence, and rollback path.
