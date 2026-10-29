---
description: Create a visual Universal Theme prototype and a declarative APEXLang translation plan
agent: apex-designer
---

Create a visual prototype for: $ARGUMENTS

Read `skills/apex-design-system/SKILL.md` section 3.1. Route the APEX version from `.apex/apexlang.json` or the target instance. If `working/page-design/requirement.md` exists, follow its page numbers and layout.

Use exactly one style file from `skills/apex-design-system/assets/universal-theme-42/tokens/` plus `components-reference.md`. Write the prototype to `working/design-preview/<name>/index.html` with any local CSS. Keep it standalone and out of the application.

Return:

1. Prototype path and the style file used.
2. Token and theme mapping (upstream file name to inventory style name).
3. Page, region, item, and button translation plan using names verified in the target inventory.
4. `staticId` plan.
5. What the prototype does not prove (runtime behavior, authorization, data, accessibility).
6. Open questions.

Never paste prototype HTML into `.apx`, a Static Content region, or a Template Component.
