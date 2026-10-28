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
