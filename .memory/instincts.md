# Project Instincts

Record only patterns that have been observed more than once or that prevented a real failure. An instinct without evidence is a guess and does not belong here.

## Entry template

### Short name

- Date:
- Scope:
- Pattern:
- Evidence:
- Corrective action:
- Confidence: low / medium / high
- Supersedes:

## Current entries

### SQLcl can exit 0 with APEXLang compile errors

- Date: 2026-10-28
- Scope: APEXLang validation with SQLcl 26.3.0.0
- Pattern: `apex validate` can print `APEXlang Compile Errors` and still return exit code 0. CRLF and BOM trees produce syntax diagnostics but no `Validation successful` marker.
- Evidence: a copied `example-0` tree with CRLF in `pages/p00001-home.apx` returned `SQLCL_EXIT=0` plus many `Type: SYNTAX` diagnostics. A BOM in `application.apx` produced `token recognition error at: '﻿app '`.
- Corrective action: `scripts/validate-apex-app.ps1` now checks LF and BOM before SQLcl and fails on compile diagnostics, `Error:`, `FILE_IGNORED`, and `ORA-` output even when the exit code is 0. `normalize-apx-tree.ps1` strips a UTF-8 BOM and converts CRLF to LF.
- Confidence: high
- Supersedes: none
### Dynamic SQL guards in APEX authorization schemes prevent ORA-06550 Day 0 crashes

- Date: 2026-10-28
- Scope: APEX authorization schemes referencing application tables (`shared-components/authorizations.apx`)
- Pattern: Static SQL queries (`select ... into ... from custom_table`) inside APEX authorization schemes fail at parse/compilation time with `ORA-06550: PL/SQL: ORA-00942: table or view does not exist` if the application is accessed before schema tables are created. Because it is a parse-time error, runtime exception handlers (`WHEN NO_DATA_FOUND` / `WHEN OTHERS`) cannot catch it, causing unhandled APEX crashes (`APEX.AUTHORIZATION.UNHANDLED_ERROR`).
- Evidence: Runtime import of an APEX application crashed with `ORA-06550 / ORA-00942` on custom authorization schemes when the underlying user profile table had not yet been created in the target schema.
- Corrective action: In APEX authorization schemes, check dictionary table presence (`select count(*) into l_count from user_tables where table_name = '...'`) and execute queries against custom tables via dynamic SQL (`execute immediate ... into ... using ...`). Include a safe bootstrap fallback or handle `sqlcode = -942` gracefully.
- Confidence: high
- Supersedes: none
