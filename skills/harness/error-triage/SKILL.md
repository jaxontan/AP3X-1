---
name: error-triage
description: Diagnose Oracle APEXLang and Oracle Database errors from real compiler, validation, import, or SQLcl output. Use when validation fails, import fails, or a query raises ORA- errors. Prevents guessing syntax, limits repair attempts, and records only evidence-backed lessons.
---

# Error Triage

Use evidence from the current run. Never invent APEXLang syntax, property names, enum values, or ORA- causes.

## Inputs

- The exact failing command and its full output, including exit code.
- The application directory and the `mmdVersion` from `.apex/apexlang.json`.
- The target database version when the error is an `ORA-` error.

If the command or output is missing, ask for it before diagnosing.

## APEXLang Compiler Errors

SQLcl reports each diagnostic as:

```text
File: pages/p00001-home.apx
Line: 26
Column: 12
Type: INVALID_PROPERTY
Error: Invalid property: templateOptions
```

1. Parse every diagnostic into File, Line, Column, Type, and Error. Do not fix only the first one; later errors are often downstream of an earlier syntax error.
2. Read the failing line and enough surrounding context to identify the component, property group, and parent component.
3. Route by `Type`:
   - `SYNTAX` or token-recognition errors: verify LF endings and no BOM first, then read the grammar.
   - `INVALID_PROPERTY`: find the property in the component document and confirm the property belongs to that component and group.
   - `REFERENCE_NOT_FOUND`: find the referenced component, its identifier, and its `filePath` or shared-component scope. Check theme defaults before changing pages.
   - `MISSING_REQUIRED_PROPERTY`: read the component document for the required parameter and its group.
   - `FILE_IGNORED` or skipped-file warnings: treat the run as a failure even if SQLcl prints `Validation successful`.
4. Read the matching version's sources in this order:
   - Inventory and syntax: `skills/apex/apexlang/26.2/apexlang-inventory/SKILL.md` and the component document under `assets/`.
   - Grammar: the inline EBNF in the 26.2 inventory, or `skills/apex/apexlang/26.1/apexlang-generation/assets/grammar/apexlang.ebnf`.
   - Working patterns: `skills/apex/apexlang/<version>/apexlang-example-applications/`.
   - Known validator recipes: `skills/apex/apexlang/26.1/apexlang-generation/assets/validator-fix-recipes.json` when the app targets 26.1.
5. Build the valid-values list from the component document. Quote the exact property name and allowed enum values. If the document does not list a value, the value is not confirmed; do not emit it.
6. Make the smallest change. Fix syntax and required structure before optional properties.
7. Re-run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-apex-app.ps1 -AppDirectory "<app-directory>"
```

8. Stop after three repair attempts for the same diagnostic. Report the attempts, the exact outputs, and the unresolved question instead of trying more variants.

## Oracle Database Errors

For `ORA-` errors:

1. Capture the full error stack, the statement, bind values (redacted), and the database version.
2. Check the local database guidance under `skills/db/` for the object type, SQL pattern, or migration rule.
3. Use Oracle documentation at `docs.oracle.com` for the error code and version. Do not use blogs, forums, or search-result snippets as syntax authority.
4. Separate the database cause from the APEX symptom. Fix the database cause or map it to a user-safe APEX error; do not hide it with `WHEN OTHERS THEN NULL`.
5. For destructive or DDL operations, stop and require explicit approval, a migration path, and a rollback plan.

## Recording Lessons

Record a lesson in `.memory/instincts.md` only when the same command reproduced it and the fix passed validation. Include:

- the diagnostic type and a short symptom;
- the version and file path;
- the confirmed cause;
- the smallest fix;
- the validation output or command that proved it.

Do not record guesses, one-off typos, credentials, connection strings, or schema caches.

## Report Format

```text
Failure: <command and exit code>
Diagnostic: <Type> at <file>:<line>:<column>
Cause: <confirmed cause or "unconfirmed">
Source: <local file or docs.oracle.com page>
Fix: <smallest change>
Evidence: <validation output>
Residual risk: <remaining uncertainty>
```
