# Design Review Checklist

Run this before implementation and again before deployment.

## Business

- [ ] Actors, goals, and permissions are explicit.
- [ ] Domain vocabulary is consistent.
- [ ] Every business rule has an ID, type, source, and exception path.
- [ ] Every rule has one primary implementation home.
- [ ] Acceptance criteria cover happy path, empty, invalid, unauthorized, duplicate, concurrent, and failure cases.
- [ ] Assumptions and open questions are visible.

## Data

- [ ] Primary keys, natural keys, foreign keys, unique constraints, and checks are defined.
- [ ] Nullability and default values are intentional.
- [ ] State transitions are explicit.
- [ ] Audit, retention, archive, and purge decisions are made.
- [ ] Monetary amounts have precision, scale, and currency.
- [ ] Indexes are justified by query patterns.
- [ ] Sensitive data is identified and protected.

## PL/SQL

- [ ] Public package API is business-oriented and minimal.
- [ ] Transaction ownership is explicit.
- [ ] Workflow transitions lock and re-check state.
- [ ] Bulk operations are bounded and restartable.
- [ ] Error handling logs backtrace and raises when required.
- [ ] Dynamic SQL is avoided or safely bound.
- [ ] Privileges follow least privilege.
- [ ] Tests cover constraints, API operations, concurrency, and batch failures.

## APEX design

- [ ] Every page maps to an actor goal.
- [ ] Every page has an authorization decision.
- [ ] Navigation, breadcrumbs, and back/cancel behavior are defined.
- [ ] Primary, secondary, and destructive actions are clear.
- [ ] Empty and error states are designed.
- [ ] Forms preserve input on validation failure.
- [ ] Reports paginate and select only needed columns.
- [ ] Session State Protection is enabled where needed.
- [ ] Accessibility and keyboard flow are checked.

## APEXLang

- [ ] APEX version is confirmed and locked.
- [ ] Component syntax comes from the matching inventory.
- [ ] File map and implementation order are known.
- [ ] No hard-coded environment values or secrets.
- [ ] `.apx` files use LF.
- [ ] SQLcl validation passes.
- [ ] Deployment is previewed with `-WhatIf` and explicitly approved.

## Release

- [ ] Supporting objects and installation order are defined.
- [ ] Seed/reference data is idempotent.
- [ ] Rollback plan exists.
- [ ] Post-deployment verification steps exist.
- [ ] Residual risks are stated.
