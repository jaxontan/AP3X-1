---
description: Design an APEX page or app (layout, theme, templates, page map) before implementation
agent: apex-designer
---

Design the following Oracle APEX work: $ARGUMENTS

Read `skills/apex-design-system/SKILL.md` and `skills/apex-design-system/references/craft.md`, and follow the handoff package. Route the APEX version from `.apex/apexlang.json` or the target instance. If `working/page-design/requirement.md` exists, follow its page numbers and layout exactly.

Run the design pipeline in `.opencode/agents/apex-designer.md` step by step. Foundation: capture the design reference (if the requirement or this request names one; see `skills/apex-design-system/references/design-reference.md`), generate the brand kit with `scripts/build-brand-kit.mjs`, and fetch the font. Creative loop (`skills/apex-design-system/references/creative-direction.md`): write the brief, create three genuinely different concepts with their own page compositions and `components.css`, render each with `scripts/render-design-concept.mjs`, critique your own screenshots and revise at least once, render the board, present it with a recommendation, and stop for the user's choice. Then converge and score with `scripts/score-design.mjs` until it prints `DESIGN SCORE PASS`. Never hand-write `brand.css`. Never put the reference company's name or product words in the app.

Do not edit `.apx`, SQL, or PL/SQL. Do not invent components, templates, template options, theme styles, or tokens; verify every name in the target version's `apexlang-inventory` or a working example. Write the result to `working/page-design/application-design.md` using `docs/templates/application-design.template.md` with `Status: DRAFT`, including the brand layer decisions and a requirement trace row for every `requirement.md` bullet. Do not edit `requirement.md`. Then summarise the design, list open questions, and ask the user to approve before implementation.
