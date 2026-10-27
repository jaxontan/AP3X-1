# Business Analysis and Domain Modeling

Use this reference when requirements are expressed in business language, when stakeholders disagree, or when the data model is not obvious. The goal is to remove ambiguity before pages and packages are designed.

## 1. Discovery interview

Ask only the questions that change the design. Group them by concern.

### Actors and goals

- Who performs the work? List every role, including read-only, approver, administrator, and external user.
- What does each role need to accomplish, not just which screens they want?
- Who is allowed to see, create, change, delete, approve, or export each object?
- Which actions are self-service, delegated, or four-eyes?

### Process and lifecycle

- What triggers the process?
- What are the states from creation to closure, including cancelled, rejected, expired, and reopened?
- Which transitions are allowed, by whom, and with what evidence?
- What happens on failure, retry, duplicate submission, or partial completion?
- Are there deadlines, SLAs, reminders, or escalations?

### Data and identity

- What is the natural key? What is the stable business identifier?
- Which data is reference data, master data, transactional data, or audit data?
- What must be unique, mandatory, or immutable after creation?
- What is the retention period, and what must be archived or purged?
- Which personal, financial, or regulated data is present?

### Rules and calculations

- Which rules are constraints, derivations, authorizations, or workflow gates?
- Where does each rule come from: law, policy, contract, or habit?
- What are the exceptions, thresholds, rounding rules, and effective dates?
- Which rules must be enforced even if a user calls an API directly?

### Volume, concurrency, and integration

- Expected rows per year, peak transactions, and largest report.
- How many users, and what concurrency must be supported?
- Which systems produce or consume the data?
- Is the integration real-time, batch, or event-driven?
- What is the source of truth when systems disagree?

### Reporting and audit

- Which decisions need evidence or an audit trail?
- Which reports are operational, regulatory, or analytical?
- What is the time window for each report?
- Who can export data, and what must be masked?

## 2. Domain model

Produce a model, not a table list. For each entity record:

| Field | Meaning |
| --- | --- |
| Entity | Business noun, singular, in domain language |
| Identity | Natural key and surrogate key decision |
| Attributes | Business attributes and their meaning |
| Relationships | Cardinality and optionality |
| Lifecycle | States and allowed transitions |
| Invariants | Facts that must always be true |
| Reference data | Controlled vocabularies and effective dating |
| Audit | Who/what/when must be retained |

Use aggregates to mark transactional consistency boundaries. For example, an order and its lines usually form one aggregate; a customer is a separate aggregate referenced by ID.

### Modeling checks

- Can the model represent the exception cases, not just the happy path?
- Are many-to-many relationships resolved with a meaningful business entity?
- Are status and state transitions explicit, rather than a free-text field?
- Are effective dates and history needed, or is current-state-only sufficient?
- Is soft delete appropriate, or does it break uniqueness and reporting?
- Are monetary amounts stored with currency and rounding policy?

## 3. Business rule catalogue

Every rule gets an ID and one primary implementation home. Use this format:

```text
BR-<AREA>-<NNN>
Statement: ...
Type: constraint | derivation | authorization | workflow | validation
Source: policy / contract / law / stakeholder
Trigger: ...
Precondition: ...
Outcome: ...
Exception: ...
Implementation: table constraint | package operation | APEX validation | authorization scheme | job
Test: ...
Status: proposed | accepted | implemented | verified
```

### Rule types

- **Constraint** — must never be false. Prefer database constraints for integrity that must survive every caller.
- **Derivation** — calculated from other data. Implement once in PL/SQL or a view, not in every page.
- **Authorization** — who may perform an action on which object. Implement with an authorization scheme plus a package-level check for non-APEX callers.
- **Workflow** — allowed state transition. Implement in a package operation with row locking and an audit record.
- **Validation** — user-facing input check. Keep it close to the page for feedback, but repeat critical integrity checks in the database or package.

### Rule quality

- A rule must be testable with a concrete input and expected outcome.
- A rule must state its exception path.
- A rule must not depend on a page item name unless it is inherently a UI rule.
- A rule that changes over time needs effective dates or a policy table.

## 4. Acceptance criteria

Write acceptance criteria in Given/When/Then form and tie them to rule IDs.

```text
AC-ORDER-001 (BR-ORDER-004)
Given an order in DRAFT owned by the current user
When the user submits it with at least one line
Then the order becomes SUBMITTED, an audit row is written, and the user sees a confirmation
```

Cover:

- Happy path.
- Empty state.
- Invalid input.
- Unauthorized actor.
- Duplicate or concurrent submission.
- Partial failure and retry.
- Boundary values and rounding.
- Accessibility and error-message clarity.

## 5. Non-functional requirements

Capture the requirements that shape architecture:

- Volume and growth.
- Peak concurrency.
- Response-time targets.
- Availability and maintenance windows.
- Audit retention and legal hold.
- Data residency and encryption.
- Backup and recovery objectives.
- Accessibility standard.
- Browser and mobile support.
- Localization, time zones, and currency.

## 6. Traceability

Maintain a matrix from business rule to:

1. Data object or constraint.
2. PL/SQL operation.
3. APEX page, validation, or authorization scheme.
4. Test or acceptance criterion.
5. Status.

Use `templates/rule-traceability.md`. A rule without a test is not done. A rule implemented in two places needs a reason and a synchronization plan.

## 7. Assumptions and open questions

Separate facts from assumptions. For every open question, state:

- The decision needed.
- The default assumption if no answer is available.
- The design impact if the assumption is wrong.
- Who can answer it.

Never silently invent a business rule. If a requirement is ambiguous, encode the safest assumption and mark it for confirmation.
