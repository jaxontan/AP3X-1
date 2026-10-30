---
name: apex-review
description: Review APEXLang, SQL, security, and performance for a path or diff
argument-hint: "[target or request]"
---

<!-- Generated from .opencode/commands/apex.review.md by scripts/sync-agent-commands.mjs. Edit the source, then re-run the script. -->

Canonical instructions: `AGENTS.md`. The delivery contract and gates there apply to this workflow.

Work within the role and limits in `.opencode/agents/apex-reviewer.md` (ignore its OpenCode-only frontmatter).

Review the following Oracle APEX change: $ARGUMENTS

If the argument is empty, review the current uncommitted changes (`git diff` plus untracked files).

Cover:

- APEXLang correctness and version compatibility.
- Authorization, session state protection, SQL injection, and XSS.
- SQL and PL/SQL correctness, bind variables, and transaction boundaries.
- Page design, accessibility, and destructive-action confirmations.
- Performance of queries, reports, and page load.

Report findings in severity order with file and line references. Do not edit files.
