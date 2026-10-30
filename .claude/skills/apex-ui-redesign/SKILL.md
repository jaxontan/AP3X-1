---
name: apex-ui-redesign
description: Redesign an existing APEX page or app, including a custom non-default look
argument-hint: "[target or request]"
---

<!-- Generated from .opencode/commands/apex.ui-redesign.md by scripts/sync-agent-commands.mjs. Edit the source, then re-run the script. -->

Canonical instructions: `AGENTS.md`. The delivery contract and gates there apply to this workflow.

Work within the role and limits in `.opencode/agents/apex-designer.md` (ignore its OpenCode-only frontmatter).

Redesign: $ARGUMENTS

Read `skills/apex-ui-redesign/SKILL.md` and `skills/apex-ui-redesign/references/design-scorecard.md`. Audit and score the current UI before proposing changes. Route the APEX version from `.apex/apexlang.json` or the target instance and verify every template, option, and component in that version's `apexlang-inventory`. Honor `working/page-design/requirement.md` when present.

For a visual redesign, create `before.html` and `after.html` under the same `working/design-preview/<name>/` directory and score both against the scorecard. Do not claim browser verification; hand the directory to `apex-design-verifier` with `/apex-verify-design <path>`.

Return the audit, before/after scorecards, the visual direction, the custom-UI path decision (A/B/C/D), the prototype path under `working/design-preview/`, the verification handoff, the inventory-verified `.apx` change map, `staticId` plan, accessibility and upgrade risks, and what was not verified.

Do not edit `.apx`, SQL, or PL/SQL. Never paste prototype HTML into the app. Use UI UX Pro Max and the local palette bank for direction only.
