# APEX Application Design

Use this reference after the business model is understood and before APEXLang pages are written. The output is an application design that a builder can implement without re-deciding architecture.

## 1. Architecture

Use these layers consistently:

```text
APEX UI
  pages, regions, items, buttons, validations, branches, dynamic actions
      |
      v
PL/SQL API
  packages own business rules, transactions, bulk operations, and errors
      |
      v
Oracle Database
  tables, constraints, indexes, views, sequences, jobs, audit
      |
      v
Integration
  ORDS/REST, external services, queues, files, scheduled jobs
```

Rules:

- Pages orchestrate; packages decide.
- A page process may validate UI input and call one package operation. It should not contain a multi-table business transaction.
- A dynamic action may refresh or show/hide UI. It must not be the only enforcement of a business rule.
- Authorization is enforced in the UI and again in the package for non-APEX callers.

## 2. Data model review

Before page design, confirm:

- Primary keys and natural keys.
- Foreign keys and delete behavior.
- Unique constraints, check constraints, and nullable rules.
- Status/state model and allowed transitions.
- Audit columns: created/updated by and at, plus a business audit table when required.
- Optimistic locking: version number, `ORA_ROWSCN`, or explicit `WHERE` guard.
- Effective dating for reference data and rules.
- Indexes justified by query patterns, not by column count.
- Retention, archive, and purge.
- Sequences or identity columns and how APEX forms obtain new IDs.

Prefer database constraints for integrity. Prefer package operations for workflow and cross-table rules. Do not make a constraint that depends on session state or a page item.

## 3. Roles and authorization

Build a role matrix:

| Role | Can view | Can create | Can change | Can approve | Can export | Scope |
| --- | --- | --- | --- | --- | --- | --- |
| ... | ... | ... | ... | ... | ... | own/team/all |

For each role define:

- APEX authentication scheme.
- Authorization schemes, named by capability, not by page.
- Data scope: own, team, organization, all.
- Sensitive operations that require re-authentication or four-eyes approval.
- What happens when authorization changes mid-session.

Do not hard-code role names in pages. Use authorization schemes and package checks. Test with at least two roles and one unauthorized actor.

## 4. Page map

Design the page map before writing pages. For each page record:

| Field | Meaning |
| --- | --- |
| Page number | Stable number and name |
| Purpose | One sentence tied to an actor goal |
| Role/authorization | Who can open it and what they can do |
| Entry points | Navigation, link, redirect, or modal |
| Regions | Report, form, chart, tree, map, content |
| Items | Business fields and their source |
| Buttons/actions | Primary, secondary, destructive |
| Processes | Package calls and transaction boundaries |
| Validations | UI rules and rule IDs |
| Branches | Success, error, cancel, back |
| Empty/error state | What the user sees with no data or a failure |
| Accessibility | Labels, focus, keyboard path, messages |

Use `templates/page-map.md`.

### Page patterns

- **Dashboard** — summary cards and actionable exceptions, not a wall of charts.
- **Interactive Report/Grid** — searchable list with saved views, export policy, and row actions.
- **Form** — create/edit with optimistic locking, inline validation, and a clear cancel path.
- **Master-detail** — parent form plus child grid; preserve unsaved state carefully.
- **Wizard** — only for genuinely staged processes; persist drafts if the process is long.
- **Approval** — explicit state transition, evidence, comments, and audit.
- **Administration** — reference data with effective dates and impact warnings.

## 5. Navigation and UX

- The home page should answer: what needs attention, what can I do, and where do I go next?
- Use consistent page names, breadcrumbs, and back/cancel behavior.
- Destructive actions need confirmation and a clear consequence statement.
- Empty states should explain how to create the first record.
- Error messages should say what happened, which field or rule failed, and what to do next.
- Forms should keep user input on validation failure.
- Reports should paginate and avoid selecting unnecessary columns.
- Use the Universal Theme before custom CSS. Custom CSS needs a reason and an accessibility check.
- Test keyboard-only navigation, labels, focus order, and color contrast.

## 6. Security

- Use APEX authentication; do not build a custom login page unless required.
- Use authorization schemes for capabilities and data scope.
- Enable Session State Protection for items that drive queries or writes.
- Escape substituted text; never concatenate user input into SQL or HTML.
- Use bind variables and `DBMS_ASSERT` for dynamic identifiers.
- Validate file uploads by type, size, and content; store outside the web root when appropriate.
- Avoid exposing internal IDs or error details to end users.
- Mask sensitive data in reports and exports.
- Log privileged actions and failed authorization attempts.
- Review IDOR: every URL/item that selects a record must be scoped by authorization.

## 7. Performance

- Design reports around indexed predicates and stable sort keys.
- Avoid N+1 queries in regions and dynamic actions.
- Use APEX collections for multi-step UI state only when a real table is not appropriate.
- Prefer set-based SQL and package bulk operations.
- Check execution plans for the largest reports and writes.
- Avoid functions in `WHERE` clauses on indexed columns unless a function-based index is justified.
- Limit initial page load; lazy-load secondary regions.
- Use materialized views or summary tables for expensive aggregates, with a refresh strategy.
- Measure with representative data volumes, not toy data.

## 8. Integration

- Define the contract: endpoint, method, payload, idempotency, retries, timeout, and error mapping.
- Store credentials in a secure credential store, never in a page or repository.
- Use ORDS for database-backed REST services when appropriate.
- Make batch jobs restartable and idempotent.
- Record correlation IDs and integration status for troubleshooting.
- Decide whether the integration is the source of truth or a projection.

## 9. Deployment design

- Target APEX version and workspace.
- Application ID and aliases.
- Supporting objects and installation order.
- Build options for optional features.
- Environment-specific substitutions and their owners.
- Seed/reference data and idempotent migration scripts.
- Rollback plan: application export, schema changes, and data changes.
- Post-deployment verification steps.

## 10. Design review gate

Before implementation, run `checklists/design-review.md`. The design is ready when:

- Every actor goal maps to a page or an API operation.
- Every business rule has one implementation home and a test.
- Every page has an authorization decision and an error/empty state.
- The data model has keys, constraints, audit, and retention decisions.
- The PL/SQL API has operation names, transaction boundaries, and an error contract.
- The deployment path is known and reversible.
