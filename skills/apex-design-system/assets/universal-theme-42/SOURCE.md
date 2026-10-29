# Universal Theme 42 Reference Assets

- Upstream: https://github.com/raju-bd/Oracle-apex-ut-UI.skill
- Commit: `e8a26ee885fc384a080c9504e4b3e543ee1419e9`
- License: MIT (see `LICENSE` in this directory)
- Author: Md. Mahfuzul Amin (Raju), 2026
- Vendored: 2026-10-29

## What was copied

- `upstream-skill.md` — upstream `SKILL.md`, renamed so it is not discovered as a second harness skill.
- `components-reference.md` — Universal Theme 42 class and markup reference.
- `tokens/` — `vita-light.css`, `vita-dark.css`, `vita-red.css`, `vita-slate.css`, `iris.css`, `redwood.css`, `standard.css`, `vita-emerald.css`, `vita-emerald.less`.
- `LICENSE` — upstream MIT license.

Not copied: the demo HTML, the bundled JavaScript, the build script, and the CNAME file. They are not needed for design reference and would add runtime code to the harness.

## Use and limits

- This is a **visual reference** for prototypes and custom Theme Roller styles, not a deployable APEX runtime.
- Token values are independently hand-derived from Oracle's Universal Theme sources. They are not Oracle's compiled LESS output. Verify any color, contrast, or computed value in Theme Roller or the target APEX instance before production.
- Prototype HTML may use inline CSS variables for speed. Never paste prototype HTML into an APEX region, Static Content region, or Template Component; translate the approved design to declarative APEXLang.
- Oracle APEX and Universal Theme remain Oracle's property. This directory is not an Oracle distribution.
