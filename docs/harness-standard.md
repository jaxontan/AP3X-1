# Harness Standard

What this harness guarantees, how each guarantee is enforced, and how we know the enforcement works. A rule that only exists in prose is marked **guidance**; everything else fails a script.

## 1. Guarantees

| # | Guarantee | Enforced by | Proven by (`scripts/test-harness.ps1`) |
| --- | --- | --- | --- |
| G1 | The user's intent is never overwritten | `requirement.md` is user-owned; agents write `application-design.md` | adapter contract check |
| G2 | No code before an approved design | `verify-delivery.ps1`: design must be `APPROVED`/`IMPLEMENTED` | "rejects an unapproved design", "rejects a missing design" |
| G3 | Nothing in the requirement is silently dropped | `verify-delivery.ps1`: one trace row per requirement bullet; every row `DONE` with a real `file:line` or `NOT DONE: <reason>` | "rejects PLANNED trace rows" |
| G4 | The user's look is delivered, not a stock fallback | `verify-delivery.ps1`: requirement colours in `brand.css`, `brand.css` loaded and registered, design keywords evidenced; `verify-apex-runtime.mjs --brand` | "rejects a dropped brand colour", "passes a traced, branded project" |
| G5 | Styling stays maintainable | `verify-delivery.ps1`: no inline `style`/handlers/`javascript:`/hex in `.apx`; hex only on `--brand-*` lines; `brand-*` classes defined and used | "rejects inline style", "rejects an undefined brand class" |
| G6 | No broken visuals | `verify-delivery.ps1`: icon names in the Font APEX index, no empty hero icon box, no icon on text-only buttons, every view styling column used; `verify-apex-runtime.mjs`: no visible empty icon slots | "rejects an unknown icon", "rejects a hero with an empty icon box", "rejects an icon on a text-only button" |
| G7 | Business rules are enforced, not just displayed | `verify-delivery.ps1`: every public package subprogram is called; tests exist; `deploy-project.ps1` runs the tests and requires 0 failures | "rejects an uncalled package API" |
| G8 | The app compiles | `validate-apex-app.ps1`: `Validation successful`, no diagnostics, no `ORA-`, UTF-8 without BOM, LF | validate/normalize tests |
| G9 | Deploys are safe | `deploy-apex-app.ps1`: `-WhatIf`, `ConfirmImpact=High`, `ORA-` = failure; approval per named target | deploy tests |
| G10 | The running app works for every role | `verify-apex-runtime.mjs`: login per role, page and JS errors, mobile overflow, axe serious/critical, authorization leaks via `--deny` | parse, usage, refuses to run without a password env var |
| G11 | All agents follow the same rules | Delivery contract block in every adapter (Claude, OpenCode, Antigravity, Codex/DSH via `AGENTS.md`) | "agent adapters carry the delivery contract" |
| G12 | No secrets in the repository or chat | `verify-apex-change.ps1` secret patterns; passwords only via environment variables and `credentials.md` | guidance + static scan |

## 2. Gate order for a delivery

1. `scripts/verify-apex-change.ps1 -AppDirectory working/app` — changed-file hygiene and secrets.
2. `scripts/validate-apex-app.ps1 -AppDirectory working/app` — `Validation successful`.
3. `scripts/verify-delivery.ps1 -ProjectDirectory working` — `DELIVERY GATE PASS`.
4. Deploy with approval (`-WhatIf` first).
5. `node scripts/verify-apex-runtime.mjs ... --brand` — `RUNTIME GATE PASS` for every role.

## 3. Known limits (guidance, not yet enforced)

- Design quality beyond defects (hierarchy, spacing, typography) is scored by the design scorecard with screenshots; it is reviewed, not computed.
- Design keyword detection covers pill, shadow, floating, badge, gradient, radius, dark mode. Other design wishes rely on the requirement trace and review.
- The gates prove a test exists for the package, not that every business rule has its own test; the reviewer checks rule-to-test mapping in `application-design.md` section 4.
- There is no benchmark suite yet that builds fixed requirements end to end and scores the result across harness versions.

## 4. Changing the standard

Every new guarantee needs: the enforcing check, a failing self-test case, and a row in this table. A guarantee without a test is guidance and must be labelled as such.
