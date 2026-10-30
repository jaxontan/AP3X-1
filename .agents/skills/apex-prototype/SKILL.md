---
name: apex-prototype
description: Create a visual Universal Theme prototype and a declarative APEXLang translation plan
---

<!-- Generated from .opencode/commands/apex.prototype.md by scripts/sync-agent-commands.mjs. Edit the source, then re-run the script. -->

Canonical instructions: `AGENTS.md`. The delivery contract and gates there apply to this workflow.

Work within the role and limits in `.opencode/agents/apex-designer.md` (ignore its OpenCode-only frontmatter).

Create a visual prototype for: the user's request (the text after the skill name)

Read `skills/apex-design-system/SKILL.md` section 3.1, `skills/apex-design-system/references/craft.md`, and `skills/apex-ui-redesign/references/design-scorecard.md`. Route the APEX version from `.apex/apexlang.json` or the target instance. If `working/page-design/requirement.md` exists, follow its page numbers and layout.

If a design reference URL is given (here or in `requirement.md`), first run `node scripts/capture-design-reference.mjs --url <url>` and follow `skills/apex-design-system/references/design-reference.md`. Borrow the look, never the logos, images, copy, font files, or markup.

Run the design pipeline in `.opencode/agents/apex-designer.md`: generate the brand kit (`scripts/build-brand-kit.mjs --reference ...` or `--init`), fetch the font, write `working/page-design/design/prototype-spec.json` with this app's content, render with `node scripts/render-design-prototype.mjs --brand working/page-design/design/brand --spec working/page-design/design/prototype-spec.json --out working/design-preview/<name>`, and score with `node scripts/score-design.mjs --preview working/design-preview/<name> --kit working/page-design/design/brand/brand-kit.json` until `DESIGN SCORE PASS`. Iterate by editing `brand-kit.json` or the spec, never CSS or HTML. Keep the prototype out of the application. Open `score/compare-desktop.png` and `score/design-mobile.png`. Use UI UX Pro Max and the local palette bank for direction only.

Return:

1. Prototype path, the brand kit path, and the design reference (or "none supplied") with the iteration log.
2. Design score (total, failed checks, rounds) and the design scorecard, with one-line evidence per dimension.
3. Verification handoff: `/apex-verify-design working/design-preview/<name>`.
4. `brand-kit.json` decisions and the `kit-report.md` contrast summary.
5. Page, region, item, and button translation plan using names verified in the target inventory.
6. `staticId` plan.
7. What the prototype does not prove (runtime behavior, authorization, data, keyboard path, 200% zoom, target-instance rendering).
8. Open questions.

Never paste prototype HTML into `.apx`, a Static Content region, or a Template Component.
