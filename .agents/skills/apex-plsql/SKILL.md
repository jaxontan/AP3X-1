---
name: apex-plsql
description: Implement or review PL/SQL packages for Oracle APEX business rules, transaction boundaries, and data integrity.
---

# APEX PL/SQL

Implement or review the PL/SQL package for APEX business rules.

Read `skills/apex-domains/SKILL.md`, `skills/apex-domains/references/plsql-engineering.md`, and the relevant files under `skills/db/plsql/` and `skills/db/sql-dev/`.

Before writing code:

1. Identify the business rules and their IDs.
2. Confirm the schema, tables, constraints, and existing package APIs.
3. Decide the transaction owner and error contract.
4. Confirm whether the task is implementation, review, or migration.

When implementing:

- Prefer a business-oriented package API over table CRUD.
- Keep page/APEX-specific values out of package signatures; pass explicit parameters.
- Use bind variables, set-based SQL, bounded bulk DML, and explicit transaction ownership.
- Handle errors with logging and re-raise; never use `WHEN OTHERS THEN NULL`.
- Add tests or verification steps for every rule.
- Do not run DDL or destructive DML without explicit approval and a rollback plan.
- Do not request or use API keys.

Report changed objects, rules covered, test/verification evidence, and residual risks.
