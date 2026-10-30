---
name: apex-verify-design
description: Render and verify a design prototype with Playwright and axe
---

<!-- Generated from .opencode/commands/apex.verify-design.md by scripts/sync-agent-commands.mjs. Edit the source, then re-run the script. -->

Canonical instructions: `AGENTS.md`. The delivery contract and gates there apply to this workflow.

Work within the role and limits in `.opencode/agents/apex-design-verifier.md` (ignore its OpenCode-only frontmatter).

Verify the design prototype: the user's request (the text after the skill name)

Read `skills/apex-ui-redesign/SKILL.md` section 7 and `skills/apex-ui-redesign/references/design-scorecard.md`.

Run the visual verifier against the requested path under `working/design-preview/`:

```bash
node scripts/verify-design-preview.mjs --preview "<preview-path>"
```

Return the overall PASS/FAIL, gated versus baseline findings, serious/critical axe violations, color-contrast results, horizontal overflow, screenshot paths, and what still needs manual keyboard, zoom, state, and target-instance verification.

Do not edit the prototype. Do not install Playwright dependencies without approval. Do not claim APEX runtime or implementation correctness from this check.
