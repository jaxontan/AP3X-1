# Project Memory

This directory is for durable, project-specific context that is not already in an ADR and is not live database metadata.

Read it at the start of a long-running task, and update only the file that owns the fact:

- `decisions.md` — project-specific decisions that do not warrant an ADR.
- `instincts.md` — evidence-backed patterns and repeated fixes. Every entry needs a date, evidence, and scope.
- `session-handoff.md` — current feature state, last validation, open risks, and the next action.

Rules:

1. Do not store passwords, connection strings, tokens, wallet contents, or `.env` values.
2. Do not cache table or column lists. Query the live parsing schema through SQLcl MCP.
3. Do not store generated SQL output, full `.apx` files, or logs. Link to the artifact or command instead.
4. Mark stale entries as superseded; do not silently rewrite history.
5. Architecture decisions that are hard to reverse belong in `docs/adr/`, not here.
