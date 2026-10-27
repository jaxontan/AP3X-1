---
name: apex-domains
description: Four-domain Oracle APEX engineering. Use for business analysis and domain modeling, APEX application design, PL/SQL implementation and review, and APEXLang coding. Covers translating business rules into tables and PL/SQL packages, designing page maps and authorization, writing set-based PL/SQL, and implementing APEX 26.1/26.2 APEXLang that passes SQLcl validation.
---

# Oracle APEX Four-Domain Engineering

This skill connects business intent to a working Oracle APEX application. Use it when the task is broader than a single component: when requirements must become a domain model, a page design, a PL/SQL API, and an APEXLang tree.

The version-specific Oracle skills remain authoritative for syntax and component properties. This skill is authoritative for **how the four domains fit together**.

## Non-negotiables

1. **Business meaning before syntax.** Identify actors, goals, rules, data, lifecycle, exceptions, and acceptance criteria before choosing pages or tables.
2. **One business rule, one implementation home.** A rule is either a data constraint, a PL/SQL API operation, a page-level validation, an authorization rule, or a workflow transition. Do not duplicate it in several places.
3. **PL/SQL owns business logic.** Page processes should validate input and call a package. Complex calculations, multi-table writes, and workflow transitions belong in PL/SQL.
4. **Version lock.** Use APEX 26.1 or 26.2 consistently. Read the version from `.apex/apexlang.json` or the target instance.
5. **No invented syntax.** Copy component syntax from the matching `apexlang-inventory` and working patterns from that version's examples.
6. **Evidence before claims.** APEX changes are not done until SQLcl prints `Validation successful`. Database changes require a reviewable SQL script and a rollback path.
7. **Least privilege and no secrets.** Do not place credentials, connection strings, wallet contents, or API keys in the repository or in model context.

## Four modes

| Mode | Use when | Produce | Read first |
| --- | --- | --- | --- |
| A. Business analysis and domain model | The request is vague, uses business language, or has rules that are not yet precise | Business specification, actors, domain model, rule catalogue, acceptance criteria, traceability matrix | `references/business-analysis.md`, `templates/business-spec.md`, `templates/domain-model.md` |
| B. APEX application design | The business model exists and needs pages, navigation, roles, and processes | Architecture, data model review, page map, authorization model, UX and performance notes, deployment notes | `references/application-design.md`, `templates/page-map.md`, `checklists/design-review.md` |
| C. PL/SQL implementation | Rules must become packages, procedures, functions, constraints, or batch jobs | Package spec/body, transaction design, error handling, tests, SQL tuning notes | `references/plsql-engineering.md`, `skills/db/plsql/` and `skills/db/sql-dev/` |
| D. APEXLang implementation | The design is approved and must become an APEX application tree | `.apx` pages and components, shared components, supporting objects, validation evidence | `references/apexlang-implementation.md`, `skills/apex/apexlang/SKILL.md` |

A real task often uses all four modes in order: A → B → C → D. Do not skip A and B merely because the user asked for code.

## Workflow

1. **Restate the business problem.** Name the actor, the goal, the trigger, the data, and the outcome. List assumptions and open questions.
2. **Build the domain model.** Entities, relationships, lifecycle states, invariants, reference data, and audit needs.
3. **Write the rule catalogue.** Give every rule an ID such as `BR-ORDER-001`. Classify it as constraint, derivation, authorization, workflow, or validation.
4. **Design the data model.** Tables, keys, constraints, indexes, sequences/identity, audit columns, and retention.
5. **Design the PL/SQL API.** Public package operations, transaction boundaries, error model, bulk operations, and tests.
6. **Design the APEX experience.** Roles, page map, navigation, regions, items, buttons, processes, validations, branches, and messages.
7. **Implement in the correct order.** Database objects → PL/SQL packages → APEX shared components → pages → validation.
8. **Verify.** Run SQLcl validation, execute PL/SQL tests where a database is available, and walk every acceptance criterion.

## Definition of done

- Every actor has a role and an authorization scheme.
- Every business rule has an ID, an implementation home, and a test.
- Every table has a primary key, required constraints, and an audit/retention decision.
- Every multi-table write has an explicit transaction boundary and a failure path.
- Every PL/SQL package has a specification, private helpers, and a stable error contract.
- Every page has a purpose, a primary action, an empty state, and an error state.
- Every APEXLang tree has LF line endings and passes `apex validate`.
- The final report states what was verified and what was not.

## Anti-patterns

- Starting with page numbers before understanding the domain.
- Putting multi-table business rules in a page process or dynamic action.
- Repeating the same rule in a database constraint, a page validation, and a package.
- Row-by-row DML in a loop when a set-based statement or `FORALL` is appropriate.
- `WHEN OTHERS THEN NULL`, or logging without re-raising when the caller must know.
- Hard-coded role names, IDs, or environment-specific URLs.
- Using an APEX 26.2 property in a 26.1 tree, or the reverse.
- Claiming success from a clean editor while validation was not run.

## Output contract

When asked to **analyze or design**, return:

1. Business summary and assumptions.
2. Domain model.
3. Rule catalogue.
4. Data model and PL/SQL API outline.
5. Page map and authorization model.
6. Open questions and risks.
7. Implementation order.

When asked to **implement**, return:

1. Files and objects changed.
2. Business rules covered.
3. Validation/test evidence.
4. What remains unverified.
5. Deployment prerequisites.

## Reference map

- `references/business-analysis.md` — discovery, domain model, rule catalogue, acceptance criteria.
- `references/application-design.md` — APEX architecture, page map, security, UX, performance, deployment.
- `references/plsql-engineering.md` — package design, transactions, bulk DML, errors, SQL, security, tests.
- `references/apexlang-implementation.md` — version routing, file map, component mapping, validation.
- `templates/` — business spec, domain model, page map, rule traceability.
- `checklists/design-review.md` — review gate before implementation.
- `skills/db/SKILL.md` — Oracle Database router, including `plsql/`, `sql-dev/`, `performance/`, and `security/`.
- `skills/apex/apexlang/SKILL.md` — APEX version router and version-specific inventories/examples.
