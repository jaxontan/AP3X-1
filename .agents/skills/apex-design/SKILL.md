---
name: apex-design
description: Analyze business requirements and produce domain, rule, page-map, and PL/SQL design artifacts for Oracle APEX.
---

# APEX Design

Design the Oracle APEX solution.

Read `skills/apex-domains/SKILL.md` and the relevant references under `skills/apex-domains/references/`.

Produce:

1. Business summary, actors, goals, assumptions, and open questions.
2. Domain model with entities, relationships, lifecycle, invariants, reference data, audit, and retention.
3. Business rule catalogue with IDs, types, sources, exceptions, and one implementation home per rule.
4. Data model outline with keys, constraints, indexes, and concurrency decisions.
5. PL/SQL API outline with package operations, transaction boundaries, error contract, bulk operations, and tests.
6. APEX page map with roles, authorization, navigation, regions, items, buttons, processes, validations, branches, empty/error states, and accessibility notes.
7. APEXLang file map and implementation order.
8. Validation and acceptance strategy.
9. Risks and the exact missing input to resolve each one.

Use the templates in `skills/apex-domains/templates/`. Do not edit files or run shell commands during design.
