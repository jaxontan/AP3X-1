---
name: oracle-apex
description: Oracle APEX engineering in this repository. Routes business analysis, domain modeling, APEX application design, PL/SQL implementation, and APEX 26.1/26.2 APEXLang work to the canonical harness skills, with validation and deployment gates.
---

# Oracle APEX Bridge

This project is an Oracle APEX agent harness. The canonical instructions are in `AGENTS.md` at the project root.

## Load in this order

1. `skills/apex-domains/SKILL.md` — the four-domain workflow: business analysis, application design, PL/SQL, APEXLang.
2. `skills/apex-design-system/SKILL.md` — visual/UX design: page map, theme style, templates, component mapping, staticId plan, APEXLang handoff.
3. `skills/apex-ui-redesign/SKILL.md` — audit and redesign an existing page, including custom non-default looks.
4. `skills/apex-delivery/SKILL.md` — version routing, validation, review, and deployment gates.
5. `skills/apex/apexlang/SKILL.md` — choose APEX 26.1 or 26.2; never mix versions.
6. `skills/db/SKILL.md` — Oracle Database, SQL, and PL/SQL references.

## Non-negotiables

- Business rules before pages.
- PL/SQL packages own business logic; page processes orchestrate.
- No invented APEX syntax. Use the matching inventory and examples.
- `.apx` files use UTF-8 without a BOM and LF endings; SQLcl must print `Validation successful` with no `FILE_IGNORED`, compile diagnostics, or `ORA-` errors.
- Diagnose failures with `skills/harness/error-triage/SKILL.md`; stop after three fix attempts on the same diagnostic.
- No deployment without explicit approval for the named target and a `-WhatIf` preview.
- No credentials or API keys in files.

## No API key policy

This harness is designed to run without paid API keys. Use a local or free model through the host harness. Do not request or store API keys. See `docs/harnesses/README.md`.
