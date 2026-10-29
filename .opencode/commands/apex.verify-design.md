---
description: Render and verify a design prototype with Playwright and axe
agent: apex-design-verifier
---

Verify the design prototype: $ARGUMENTS

Read `skills/apex-ui-redesign/SKILL.md` section 7 and `skills/apex-ui-redesign/references/design-scorecard.md`.

Run the visual verifier against the requested path under `working/design-preview/`:

```bash
node scripts/verify-design-preview.mjs --preview "<preview-path>"
```

Return the overall PASS/FAIL, gated versus baseline findings, serious/critical axe violations, color-contrast results, horizontal overflow, screenshot paths, and what still needs manual keyboard, zoom, state, and target-instance verification.

Do not edit the prototype. Do not install Playwright dependencies without approval. Do not claim APEX runtime or implementation correctness from this check.
