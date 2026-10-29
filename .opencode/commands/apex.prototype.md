---
description: Create a visual Universal Theme prototype and a declarative APEXLang translation plan
agent: apex-designer
---

Create a visual prototype for: $ARGUMENTS

Read `skills/apex-design-system/SKILL.md` section 3.1 and `skills/apex-ui-redesign/references/design-scorecard.md`. Route the APEX version from `.apex/apexlang.json` or the target instance. If `working/page-design/requirement.md` exists, follow its page numbers and layout.

Use exactly one style file from `skills/apex-design-system/assets/universal-theme-42/tokens/` plus `components-reference.md`. Write the prototype to `working/design-preview/<name>/index.html` with any local CSS. Keep it standalone and out of the application. Use UI UX Pro Max and the local palette bank for direction only; never copy their HTML, CSS, framework, font, or animation code.

Return:

1. Prototype path and the style file used.
2. Design scorecard for the prototype, with one-line evidence per dimension.
3. Verification handoff: `/apex.verify-design working/design-preview/<name>`.
4. Token and theme mapping (upstream file name to inventory style name).
5. Page, region, item, and button translation plan using names verified in the target inventory.
6. `staticId` plan.
7. What the prototype does not prove (runtime behavior, authorization, data, keyboard path, 200% zoom, target-instance rendering).
8. Open questions.

Never paste prototype HTML into `.apx`, a Static Content region, or a Template Component.
