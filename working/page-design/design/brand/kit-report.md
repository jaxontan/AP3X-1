# Brand Kit Report

- APEX version: 26.2
- Reference: https://www.flashconcepts.com.sg/
- Font: Montserrat (reference uses Montserrat, an open-licence font); files: 400, 500, 600, 700
- Header: dark; nav: dark; buttons: rounded; radius: 8px; depth: soft
- Universal Theme variables set: 87 (all verified against the APEX 26.2 theme CSS)
- Hard-coded Vita colour rules re-declared: 12 (hot buttons and side navigation)

## Contrast

| Pair | Foreground | Background | Ratio | Minimum | Result |
| --- | --- | --- | ---: | ---: | --- |
| ink on surface | `#0F172A` | `#FFFFFF` | 17.85:1 | 7:1 | PASS |
| muted on surface | `#64748B` | `#FFFFFF` | 4.76:1 | 4.5:1 | PASS |
| primary text on surface | `#0C855D` | `#FFFFFF` | 4.64:1 | 4.5:1 | PASS |
| on-primary on primary | `#0F172A` | `#10B981` | 7.04:1 | 4.5:1 | PASS |
| on-action on action (button label) | `#0F172A` | `#10B981` | 7.04:1 | 4.5:1 | PASS |
| action text on surface | `#0C855D` | `#FFFFFF` | 4.64:1 | 4.5:1 | PASS |
| header text on header | `#FFFFFF` | `#0B101D` | 18.99:1 | 4.5:1 | PASS |
| logo on header | `#FFFFFF` | `#0B101D` | 18.99:1 | 3:1 | PASS |
| nav text on nav | `#FFFFFF` | `#0C1222` | 18.66:1 | 4.5:1 | PASS |
| selected nav text | `#FFFFFF` | `#292E3D` | 13.53:1 | 4.5:1 | PASS |
| focus ring on ground | `#0EA372` | `#F8FAFC` | 3.09:1 | 3:1 | PASS |
| nav text on hover | `#FFFFFF` | `#1D2331` | 15.71:1 | 4.5:1 | PASS |
| success label on success | `#0F172A` | `#10B981` | 7.04:1 | 4.5:1 | PASS |
| warning label on warning | `#0F172A` | `#F59E0B` | 8.31:1 | 4.5:1 | PASS |
| danger label on danger | `#0F172A` | `#EF4444` | 4.74:1 | 4.5:1 | PASS |
| info label on info | `#0F172A` | `#3B82F6` | 4.85:1 | 4.5:1 | PASS |
| success text on success tint (subtle badge) | `#0B7E58` | `#E7F8F2` | 4.62:1 | 4.5:1 | PASS |
| warning text on warning tint (subtle badge) | `#9D6507` | `#FEF5E7` | 4.52:1 | 4.5:1 | PASS |
| danger text on danger tint (subtle badge) | `#BF3636` | `#FDECEC` | 4.84:1 | 4.5:1 | PASS |
| info text on info tint (subtle badge) | `#2F68C5` | `#EBF3FE` | 4.81:1 | 4.5:1 | PASS |

All contrast pairs pass.
