# PL/SQL Engineering for Business Logic

Use this reference when business rules must become database packages, procedures, functions, constraints, or jobs. The Oracle `db` skill tree remains the detailed reference; this is the implementation and review discipline.

## 1. Package design

One business capability should have one public package API. Keep the specification small and stable.

```sql
CREATE OR REPLACE PACKAGE order_api AUTHID DEFINER AS
  -- Public exceptions
  e_invalid_state   EXCEPTION;
  e_not_authorized  EXCEPTION;

  -- Public operations
  FUNCTION create_order(
    p_customer_id IN NUMBER,
    p_lines       IN order_line_tab
  ) RETURN NUMBER;

  PROCEDURE submit_order(
    p_order_id IN NUMBER,
    p_actor    IN VARCHAR2
  );

  PROCEDURE approve_order(
    p_order_id IN NUMBER,
    p_actor    IN VARCHAR2,
    p_comment  IN VARCHAR2 DEFAULT NULL
  );
END order_api;
/
```

Rules:

- The specification exposes business operations, not table CRUD for every table.
- Keep helpers private in the body unless another package genuinely needs them.
- Use subtypes or named types for business identifiers and collections.
- Use `AUTHID DEFINER` by default; use `AUTHID CURRENT_USER` only when the caller's privileges are the intended security boundary.
- Do not put session/APEX-specific items (`:APP_USER`, `:P1_ID`) in package APIs. Pass values explicitly.
- Name operations with business verbs: `submit_order`, `approve_invoice`, `close_period`.

## 2. Transactions

- The caller owns the transaction. A package procedure should not commit unless it is the documented top-level transaction owner.
- For APEX, the page process usually owns the transaction; a package call should either complete or raise.
- Use `SAVEPOINT` only for a deliberate partial-rollback design.
- Use autonomous transactions for logging or auditing only when the log must survive a rollback. Do not use them to hide transaction bugs.
- Avoid `COMMIT` inside a trigger.
- Make retries safe with idempotency keys or a state check.
- Lock rows explicitly when a workflow transition depends on current state:

```sql
SELECT status
  INTO l_status
  FROM orders
 WHERE order_id = p_order_id
   FOR UPDATE;
```

- Re-read state after locking and validate the transition. Do not trust a value read before the lock.

## 3. Set-based SQL and bulk DML

Prefer one SQL statement over a row-by-row loop.

```sql
-- Set-based update
UPDATE order_lines
   SET line_status = 'PRICED'
 WHERE order_id = p_order_id
   AND line_status = 'NEW';
```

For large collections:

```sql
DECLARE
  CURSOR c_lines IS
    SELECT line_id, amount
      FROM staging_lines
     WHERE batch_id = p_batch_id;

  TYPE t_lines IS TABLE OF c_lines%ROWTYPE;
  l_lines t_lines;
  C_LIMIT CONSTANT PLS_INTEGER := 500;
BEGIN
  OPEN c_lines;
  LOOP
    FETCH c_lines BULK COLLECT INTO l_lines LIMIT C_LIMIT;
    EXIT WHEN l_lines.COUNT = 0;

    FORALL i IN 1 .. l_lines.COUNT SAVE EXCEPTIONS
      UPDATE order_lines
         SET amount = l_lines(i).amount
       WHERE line_id = l_lines(i).line_id;
  END LOOP;
  CLOSE c_lines;
EXCEPTION
  WHEN OTHERS THEN
    IF c_lines%ISOPEN THEN
      CLOSE c_lines;
    END IF;
    RAISE;
END;
/
```

Rules:

- Always bound `BULK COLLECT` with `LIMIT`.
- Use `FORALL SAVE EXCEPTIONS` when a batch can contain bad rows; inspect `SQL%BULK_EXCEPTIONS`.
- Do not commit inside a loop unless the batch is explicitly restartable and documented.
- Use `MERGE` for upserts when the business key is clear; test concurrency.
- Use `RETURNING ... BULK COLLECT INTO` for multi-row DML when needed.
- Avoid `SELECT *` in production code; list columns.

## 4. Error handling

Every public operation needs a predictable error contract.

```sql
BEGIN
  ...
EXCEPTION
  WHEN e_invalid_state THEN
    RAISE_APPLICATION_ERROR(-20010, 'Order is not in a submittable state.');
  WHEN DUP_VAL_ON_INDEX THEN
    RAISE_APPLICATION_ERROR(-20011, 'The order already exists.');
  WHEN OTHERS THEN
    log_error(
      p_scope   => 'ORDER_API.SUBMIT_ORDER',
      p_message => SQLERRM,
      p_backtrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
    );
    RAISE;
END;
```

Rules:

- Never use `WHEN OTHERS THEN NULL`.
- Log `SQLCODE`, `SQLERRM`, `DBMS_UTILITY.FORMAT_ERROR_BACKTRACE`, the operation, and a correlation ID.
- Convert technical errors into user-safe messages at the API boundary.
- Re-raise when the caller must know the operation failed.
- Use named exceptions for business failures.
- Keep `RAISE_APPLICATION_ERROR` ranges documented per package.
- Do not expose table names, SQL text, or stack traces to end users.

## 5. SQL correctness

- Use bind variables; never concatenate literals from user input.
- Qualify columns when joining.
- Handle `NO_DATA_FOUND` and `TOO_MANY_ROWS` deliberately.
- Use `EXISTS` for existence checks; use `IN` carefully with nullable subqueries.
- Use `NULLS LAST`/`NULLS FIRST` for deterministic ordering.
- Use explicit `DATE`/`TIMESTAMP` semantics and time zones.
- Use `NUMBER` with precision/scale for money and measurements.
- Use `VARCHAR2` with byte or char semantics explicitly when it matters.
- Avoid implicit conversions in predicates and joins.
- Test boundary values, nulls, duplicates, and concurrent updates.

For tuning, use `skills/db/performance/explain-plan.md`, `awr-reports.md`, and `ash-analysis.md`. For SQL patterns, use `skills/db/sql-dev/sql-patterns.md` and `sql-tuning.md`.

## 6. Security

- Use bind variables and `DBMS_ASSERT` for dynamic identifiers.
- If dynamic SQL is unavoidable, use `DBMS_ASSERT.SIMPLE_SQL_NAME` or `ENQUOTE_NAME`, and bind all values.
- Grant only the privileges the package needs. Prefer definer-rights packages with a narrow grant surface.
- Do not grant direct table DML to application schemas when a package API is the contract.
- Do not store passwords or API keys in tables or code. Use a supported credential store.
- Use `AUTHID CURRENT_USER` only with a clear reason and tests.
- Audit privileged and state-changing operations.
- Review SQL injection, IDOR, and authorization bypass paths.

## 7. Testing

Every business rule needs a test at the lowest reliable level.

- **Constraint test** — insert/update invalid data and assert the expected Oracle error.
- **Package test** — call the public API with representative data and assert state, output, and audit rows.
- **Concurrency test** — two sessions attempt the same transition; one succeeds, one gets a deterministic error.
- **Batch test** — include good and bad rows; assert `SQL%BULK_EXCEPTIONS` and restart behavior.
- **APEX acceptance test** — role-based page walk with validation messages and empty/error states.

Use a transaction that rolls back after the test where possible. If a test must commit, use a dedicated test schema and clean up deterministically. The Oracle `db` tree may include testing guidance; search it before inventing a framework.

## 8. Business rule mapping

For each rule ID, record:

| Rule | Type | Data | PL/SQL operation | Error code | Test |
| --- | --- | --- | --- | --- | --- |
| BR-ORDER-004 | workflow | orders.status | `order_api.submit_order` | -20010 | `test_submit_only_draft` |
| BR-ORDER-007 | derivation | order_lines.amount | `order_api.price_order` | n/a | `test_price_rounding` |
| BR-ORDER-009 | authorization | orders.owner_id | package check + APEX scheme | -20012 | `test_other_user_cannot_submit` |

A rule implemented in a trigger, a constraint, a package, and a page validation needs a written reason. Prefer one enforcement point plus UI feedback.

## 9. Review checklist

- Specification is minimal and business-oriented.
- Public operations have clear transaction ownership.
- No unbound dynamic SQL.
- No `WHEN OTHERS THEN NULL`.
- Bulk operations are bounded and restartable.
- Row locks protect workflow transitions.
- Errors are logged with backtrace and mapped to user-safe messages.
- Tests cover happy path, invalid state, unauthorized actor, duplicate, boundary, and concurrency.
- SQL is set-based and uses indexed predicates.
- Privileges follow least privilege.
- Business rule traceability is complete.
