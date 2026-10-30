---
name: apex-verify
description: Run static verification on changed APEX, SQL, and PL/SQL files
---

<!-- Generated from .opencode/commands/apex.verify.md by scripts/sync-agent-commands.mjs. Edit the source, then re-run the script. -->

Canonical instructions: `AGENTS.md`. The delivery contract and gates there apply to this workflow.

Work within the role and limits in `.opencode/agents/apex.md` (ignore its OpenCode-only frontmatter).

Verify the current change: the user's request (the text after the skill name)

If an application directory is supplied, verify only that tree and enforce its `.apex/apexlang.json` version lock. If it is empty, verify all changed files in the repository and say that the app-scoped version check was skipped.

Do this:

1. Resolve the application directory or confirm that the check is repository-wide. Do not guess an app path.
2. Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-apex-change.ps1 -AppDirectory "<app-directory>"
```

Omit `-AppDirectory` for a repository-wide check.

3. Report the full output, including warnings.
4. Treat the result as PASS only when the command exits 0. A PASS with warnings is not a clean release gate; list every warning and decide whether it is relevant.
5. For a release candidate, re-run with `-Strict` and require a clean PASS.
6. This static check does not replace the APEX compiler. For an app tree, the APEX compiler validates automatically on generate or modify.
