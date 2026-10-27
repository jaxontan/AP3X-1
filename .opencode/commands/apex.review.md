---
description: Review APEXLang, SQL, security, and performance for a path or diff
agent: apex-reviewer
---

Review the following Oracle APEX change: $ARGUMENTS

If the argument is empty, review the current uncommitted changes (`git diff` plus untracked files).

Cover:

- APEXLang correctness and version compatibility.
- Authorization, session state protection, SQL injection, and XSS.
- SQL and PL/SQL correctness, bind variables, and transaction boundaries.
- Page design, accessibility, and destructive-action confirmations.
- Performance of queries, reports, and page load.

Report findings in severity order with file and line references. Do not edit files.
