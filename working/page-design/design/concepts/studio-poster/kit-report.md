# Brand Kit Report

- APEX version: 26.2
- Reference: https://www.flashconcepts.com.sg/
- Font: Montserrat (reference uses Montserrat, an open-licence font); files: 400, 500, 600, 700
- Header: light; nav: light; buttons: pill; radius: 4px; depth: flat
- Universal Theme variables set: 87 (all verified against the APEX 26.2 theme CSS)
- Hard-coded Vita colour rules re-declared: 12 (hot buttons and side navigation)

## Contrast

| Pair | Foreground | Background | Ratio | Minimum | Result |
| --- | --- | --- | ---: | ---: | --- |
| ink on surface | `#121212` | `#E9F2E9` | 16.36:1 | 7:1 | PASS |
| muted on surface | `#646764` | `#E9F2E9` | 5:1 | 4.5:1 | PASS |
| primary text on surface | `#1F794B` | `#E9F2E9` | 4.71:1 | 4.5:1 | PASS |
| on-primary on primary | `#121212` | `#3BE891` | 11.72:1 | 4.5:1 | PASS |
| on-action on action (button label) | `#121212` | `#3BE891` | 11.72:1 | 4.5:1 | PASS |
| action text on surface | `#1F794B` | `#E9F2E9` | 4.71:1 | 4.5:1 | PASS |
| header text on header | `#121212` | `#E9F2E9` | 16.36:1 | 4.5:1 | PASS |
| logo on header | `#1F794B` | `#E9F2E9` | 4.71:1 | 3:1 | PASS |
| nav text on nav | `#121212` | `#E9F2E9` | 16.36:1 | 4.5:1 | PASS |
| selected nav text | `#1F794B` | `#D8F1E0` | 4.51:1 | 4.5:1 | PASS |
| focus ring on ground | `#2AA768` | `#FFFFFF` | 3.08:1 | 3:1 | PASS |
| nav text on hover | `#121212` | `#DEE7DE` | 14.8:1 | 4.5:1 | PASS |
| success label on success | `#FFFFFF` | `#1F7A4D` | 5.32:1 | 4.5:1 | PASS |
| warning label on warning | `#FFFFFF` | `#B25E09` | 4.67:1 | 4.5:1 | PASS |
| danger label on danger | `#FFFFFF` | `#C62828` | 5.62:1 | 4.5:1 | PASS |
| info label on info | `#FFFFFF` | `#1D5FB4` | 6.27:1 | 4.5:1 | PASS |
| success text on success tint (subtle badge) | `#1D7047` | `#D5E6D9` | 4.67:1 | 4.5:1 | PASS |
| warning text on warning tint (subtle badge) | `#964F08` | `#E4E3D3` | 4.75:1 | 4.5:1 | PASS |
| danger text on danger tint (subtle badge) | `#BE2626` | `#E6DED6` | 4.52:1 | 4.5:1 | PASS |
| info text on info tint (subtle badge) | `#1D5FB4` | `#D5E3E4` | 4.76:1 | 4.5:1 | PASS |

All contrast pairs pass.
