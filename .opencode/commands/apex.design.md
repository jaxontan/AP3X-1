---
description: Design an APEX page or app (layout, theme, templates, page map) before implementation
agent: apex-designer
---

Design the following Oracle APEX work: $ARGUMENTS

Read `skills/apex-design-system/SKILL.md` and follow its handoff package. Route the APEX version from `.apex/apexlang.json` or the target instance. If `working/page-design/requirement.md` exists, follow its page numbers and layout exactly.

Do not edit `.apx`, SQL, or PL/SQL. Do not invent components, templates, template options, theme styles, or tokens; verify every name in the target version's `apexlang-inventory` or a working example. Write the result to `working/page-design/application-design.md` using `docs/templates/application-design.template.md` with `Status: DRAFT`, including the brand layer decisions and a requirement trace row for every `requirement.md` bullet. Do not edit `requirement.md`. Then summarise the design, list open questions, and ask the user to approve before implementation.
