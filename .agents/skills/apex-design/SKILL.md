---
name: apex-design
description: Design an APEX page or app (layout, theme, templates, page map) before implementation
---

<!-- Generated from .opencode/commands/apex.design.md by scripts/sync-agent-commands.mjs. Edit the source, then re-run the script. -->

Canonical instructions: `AGENTS.md`. The delivery contract and gates there apply to this workflow.

Work within the role and limits in `.opencode/agents/apex-designer.md` (ignore its OpenCode-only frontmatter).

Design the following Oracle APEX work: the user's request (the text after the skill name)

Read `skills/apex-design-system/SKILL.md` and `skills/apex-design-system/references/craft.md`, and follow the handoff package. Route the APEX version from `.apex/apexlang.json` or the target instance. If `working/page-design/requirement.md` exists, follow its page numbers and layout exactly.

Run the design pipeline in `.opencode/agents/apex-designer.md` step by step: capture the design reference (if the requirement or this request names one; see `skills/apex-design-system/references/design-reference.md`), generate the brand kit with `scripts/build-brand-kit.mjs`, fetch the font, write the prototype spec, render with `scripts/render-design-prototype.mjs`, and score with `scripts/score-design.mjs` until it prints `DESIGN SCORE PASS`. Open `score/compare-desktop.png` and `score/design-mobile.png` before writing the style decision. Never hand-write `brand.css` or prototype HTML.

Do not edit `.apx`, SQL, or PL/SQL. Do not invent components, templates, template options, theme styles, or tokens; verify every name in the target version's `apexlang-inventory` or a working example. Write the result to `working/page-design/application-design.md` using `docs/templates/application-design.template.md` with `Status: DRAFT`, including the brand layer decisions and a requirement trace row for every `requirement.md` bullet. Do not edit `requirement.md`. Then summarise the design, list open questions, and ask the user to approve before implementation.
