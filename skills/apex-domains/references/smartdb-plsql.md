# SmartDB PL/SQL: TAPI, XAPI, PL/Scope, and Tests

Use this reference when business rules must become a stable database API before any APEX page is generated. The Oracle `db` skills remain authoritative for SQL, PL/SQL, and testing details; this reference is the harness contract for the local `FREEPDB1` to commercial workflow.

## 1. Two package layers

Keep table access and business workflow separate:

| Layer | Name | Responsibility | Public operations |
| --- | --- | --- | --- |
| Table API (TAPI) | `<prefix>_<table>_tapi` | Single-row table maintenance and row locking | `insert_row`, `update_row`, `delete_row`, `lock_row`, `get_row` |
| Business API (XAPI) | `<prefix>_<domain>_api` | State transitions, calculations, multi-table writes, authorization checks | `submit_order`, `approve_invoice`, `close_period` |

Rules:

- The XAPI is the contract APEX pages, ORDS handlers, automations, and batch jobs call. Do not let each caller reimplement a transition.
- The TAPI uses `RETURNING ... INTO` to obtain generated keys. Do not follow an insert with a `SELECT` for the same key.
- Use `%TYPE` and `%ROWTYPE` for column-backed values. Do not repeat a column's type by hand.
- Pass page items and `APP_USER` as explicit typed parameters. Do not put `v('P1_ITEM')` or `:APP_USER` inside a reusable package.
- The caller owns the transaction. A reusable package procedure should not `COMMIT` unless it is documented as the top-level transaction owner.
- Use `FOR UPDATE` when a workflow decision depends on current row state; re-read the state after the lock.

## 2. Compiler and PL/Scope verification

Compile with warnings and PL/Scope enabled on the local database:

```sql
ALTER SESSION SET PLSQL_WARNINGS = 'ENABLE:ALL';
ALTER SESSION SET PLSCOPE_SETTINGS = 'IDENTIFIERS:ALL, STATEMENTS:ALL';
```

After compilation, inspect errors and warnings:

```sql
SELECT name, type, line, position, attribute, message_number, text
  FROM user_errors
 WHERE attribute IN ('ERROR', 'WARNING')
 ORDER BY name, sequence;
```

Find dynamic SQL that has no binds:

```sql
SELECT object_name, type, line, text
  FROM user_statements
 WHERE type = 'EXECUTE IMMEDIATE'
   AND has_binds = 'NO';
```

Do not claim a package is correct because it compiled. Compilation proves syntax, not business behavior. Run the XAPI tests.

## 3. Tests

Use the vendored utPLSQL guide at `skills/db/devops/database-testing.md`. A business rule needs a test at the lowest reliable level:

- Constraint test: invalid data raises the expected Oracle error.
- XAPI test: the public operation changes state, output, and audit rows as specified.
- Concurrency test: two sessions attempt the same transition; one succeeds and one fails deterministically.
- Batch test: good and bad rows are handled according to the documented restart behavior.
- APEX acceptance test: role-based page walk with validation, empty, and error states.

Prefer a transaction that rolls back after the test. If a test must commit, run it in a dedicated test schema and clean up deterministically.

## 4. Static analysis boundary

The harness does **not** treat `tree-sitter-plsql` as a required gate. The grammar is incomplete and has not been built or tested against this repo's packages. The proposed `njank/tree-sitter-plsql` link is not a verified fork. Do not add unverified `.scm` queries or claim an AST gate passed.

Use these evidence sources instead:

1. SQLcl `apex validate` for `.apx` trees.
2. Oracle compilation and `USER_ERRORS` for PL/SQL.
3. PL/Scope `USER_STATEMENTS` for dynamic SQL without binds.
4. `scripts/verify-apex-change.ps1` for changed-file anti-patterns.
5. `apexctl.mjs` and the version's `apexlang-inventory` for APEX component contracts.

If a team later adopts a tested tree-sitter grammar, record the version and query files in an ADR and make it a warning-only check until it has a regression suite.

## 5. Version compatibility

The local sandbox may be Oracle Database 26ai Free while the commercial target is 19c. Confirm the target version before using newer syntax. For a 19c target:

| Construct | 19c guidance |
| --- | --- |
| SQL `BOOLEAN` columns or predicates | Avoid in SQL; use `CHAR(1)` with a check constraint or `NUMBER(1)`, or keep booleans in PL/SQL. |
| `CREATE TABLE IF NOT EXISTS` and similar DDL | Avoid; manage existence with a migration tool or a reviewed PL/SQL check. |
| Multi-row `INSERT ... VALUES (...), (...)` | Avoid; use `INSERT ALL`, `INSERT ... SELECT`, or `FORALL`. |
| `SELECT` without `FROM` | Use `FROM dual`. |
| Table alias with `AS` | Use `FROM orders o`, not `FROM orders AS o`. |
| JSON Relational Duality Views | Not available; use relational views plus JSON generation functions. |
| `JSON` or `VECTOR` column types | Not available in 19c; use `VARCHAR2`/`CLOB` JSON or a supported vector deployment. |

The reverse also matters: do not use 19c-only workarounds in a 26ai-only application without a documented reason. Record the target version in the project constitution or `.memory/decisions.md`.

## 6. Review checklist

- The XAPI is the only public business contract; TAPI helpers are private where possible.
- Every public operation has a documented transaction owner.
- Every `SELECT ... INTO` handles `NO_DATA_FOUND` and `TOO_MANY_ROWS`.
- No `WHEN OTHERS THEN NULL`; errors are logged with backtrace and re-raised or mapped safely.
- No unbound dynamic SQL; identifiers use `DBMS_ASSERT`.
- Bulk DML uses bounded `BULK COLLECT` and `FORALL ... SAVE EXCEPTIONS` where appropriate.
- Workflow transitions lock and re-read state.
- Tests cover happy path, invalid state, unauthorized actor, duplicate, boundary, and concurrency.
- The target database version is known and the SQL is compatible with it.
- `USER_ERRORS` is clean and the XAPI tests pass before APEX pages are generated.
