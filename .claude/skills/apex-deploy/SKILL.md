---
name: apex-deploy
description: Preview or run an APEXLang application import with SQLcl
argument-hint: "[target or request]"
disable-model-invocation: true
---

<!-- Generated from .opencode/commands/apex.deploy.md by scripts/sync-agent-commands.mjs. Edit the source, then re-run the script. -->

Canonical instructions: `AGENTS.md`. The delivery contract and gates there apply to this workflow.

Work within the role and limits in `.opencode/agents/apex.md` (ignore its OpenCode-only frontmatter).

Deploy the Oracle APEX application at: $ARGUMENTS

Deployment is a privileged action. Follow this gate exactly:

1. Confirm the user explicitly asked to deploy in this request. If not, stop and ask.
2. Confirm the application directory and APEX version.
3. Confirm `SQLCL_CONNECTION_STRING` is set. Never print the connection string.
4. Confirm the app passed `apex validate` in this session or run it first.
5. Show the import plan with `-WhatIf`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy-apex-app.ps1 -AppDirectory "<app-directory>" -WhatIf
```

6. If the user has not already approved the target database, ask for approval before the real import.
7. Run the import:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy-apex-app.ps1 -AppDirectory "<app-directory>"
```

The script prompts for confirmation because it uses `ConfirmImpact = 'High'`. Do not suppress the prompt with `-Confirm:$false` unless the user explicitly approved this exact target.

8. Report the application ID, workspace, warnings, and any `ORA-` errors. Treat `ORA-` output as failure even if the exit code is 0.
9. After import, export and compare when the target supports APEXLang export:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/export-apex-app.ps1 -ApplicationId <id> -OutputDirectory <export-directory> -CompareDirectory "<app-directory>"
```

Treat drift as a failure and explain the differing files.
