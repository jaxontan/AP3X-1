---
name: oracle-apex
description: Oracle APEX engineering in this repository. Routes business analysis, domain modeling, APEX application design, PL/SQL implementation, and APEX 26.1/26.2 APEXLang work to the canonical harness skills, with validation and deployment gates.
---

# Oracle APEX Bridge

This project is an Oracle APEX agent harness. The canonical instructions are in `AGENTS.md` at the project root.

## Load in this order

1. `skills/apex-domains/SKILL.md` — the four-domain workflow: business analysis, application design, PL/SQL, APEXLang.
2. `skills/apex-delivery/SKILL.md` — version routing, validation, review, and deployment gates.
3. `skills/apex/apexlang/SKILL.md` — choose APEX 26.1 or 26.2; never mix versions.
4. `skills/db/SKILL.md` — Oracle Database, SQL, and PL/SQL references.

## Non-negotiables

- Business rules before pages.
- PL/SQL packages own business logic; page processes orchestrate.
- No invented APEX syntax. Use the matching inventory and examples.
- `.apx` files use LF; SQLcl must print `Validation successful`.
- No deployment without explicit approval and a `-WhatIf` preview.
- No credentials or API keys in files.

## No API key policy

This harness is designed to run without paid API keys. Use a local or free model through the host harness. Do not request or store API keys. See `docs/harnesses/README.md`.
