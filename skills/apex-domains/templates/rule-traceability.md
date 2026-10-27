# Business Rule Traceability

| Rule ID | Statement | Type | Data object | PL/SQL operation | APEX page/validation | Authorization | Test / acceptance | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BR-... | ... | constraint | ... | ... | ... | ... | ... | proposed |

## Status values

- `proposed` — agreed in business terms, not designed.
- `designed` — implementation home chosen.
- `implemented` — code exists.
- `verified` — test or acceptance evidence exists.
- `deferred` — intentionally out of scope with a reason.

## Rules

- Every accepted rule must have one primary implementation home.
- A rule enforced in more than one place needs a reason and a synchronization note.
- A rule without a test is not verified.
- Update the status only with evidence.
