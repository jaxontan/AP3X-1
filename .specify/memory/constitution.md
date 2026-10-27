# Oracle APEX Agent Harness Constitution

## Core Principles

### I. Evidence Before Claims (NON-NEGOTIABLE)

Every completion claim must be backed by a command, file, or validation output. If a check was not run, say so. A clean diff is not evidence that an APEX application compiles, deploys, or works.

### II. Validate Before Deploy (NON-NEGOTIABLE)

Every generated or edited APEXLang tree must pass `apex validate` before import. `.apx` files must use LF line endings. Deployment requires explicit user approval and a `-WhatIf` preview. Any `ORA-` output during import is a failure, even when the process exits 0.

### III. Version Lock (NON-NEGOTIABLE)

One application uses one APEXLang version, read from `.apex/apexlang.json` or the target instance. 26.1 and 26.2 inventories, examples, and syntax never mix. If the version is unknown, use 26.1 and state the assumption.

### IV. Database Safety

Read-only by default. Discover the schema before writing SQL. Do not run `DROP`, `TRUNCATE`, unqualified `DELETE`, or `ALTER SYSTEM` without explicit approval and a rollback or backup plan. Prefer bind variables, set-based SQL, and explicit transaction boundaries. Never place credentials, connection strings, or wallet contents in the repository.

### V. Least Privilege

The primary `apex` agent builds. Planning, review, and DBA agents are read-only. Destructive shell and database commands require confirmation. Secrets are excluded from model context. Vendored Oracle skills are immutable; update them from source rather than editing them.

### VI. Specification-Driven Change

Non-trivial work follows Spec Kit: constitution, specify, clarify when needed, plan, tasks, implement. The plan names every `.apx` file and every database object. Small changes may skip the full flow but still require validation and review.

### VII. Small, Reversible Changes

Prefer the smallest correct change that satisfies the specification. Do not refactor unrelated pages or rename existing components. Record hard-to-reverse decisions in `docs/adr/` using the architecture decision record skill.

## APEX Delivery Constraints

- App source lives under `applications/<app>/` and publishes only runtime artifacts: `.apex/`, `application.apx`, `deployments/`, `page-groups.apx`, `pages/`, `shared-components/`, and `supporting-objects/`.
- `.apx` files use LF line endings; CRLF trees are rejected before SQLcl runs.
- APEX 26.1 uses the generation skill. APEX 26.2 has no generation skill; use its inventory and example applications only.
- Authentication, authorization, session state, and user-input handling changes require a security review.
- Supporting objects are installed only through the approved deployment gate.

## Workflow

1. Route the APEX version.
2. Specify the change.
3. Plan the architecture, data model, and APEXLang file map.
4. Implement with the version's inventory and example applications.
5. Normalize line endings.
6. Validate with SQLcl.
7. Review with `apex-reviewer`.
8. Preview deployment with `-WhatIf`.
9. Deploy only on explicit approval.
10. Verify and report `PASS`, `PARTIAL`, or `FAIL`.

## Quality Gates

- SQLcl prints `Validation successful`.
- No CRLF `.apx` files remain.
- No critical or high review findings are left unexplained.
- No secrets appear in files, command output, or logs.
- `scripts/harness-doctor.ps1` passes before delivery.
- The final report includes evidence and residual risks.

## Governance

This constitution supersedes ad hoc preferences. Amendments require an ADR in `docs/adr/` and a matching update to `AGENTS.md`. The `harness-optimizer` agent may propose changes but must not edit vendored Oracle skills. Version 1.0.0, ratified 2026-10-27.
