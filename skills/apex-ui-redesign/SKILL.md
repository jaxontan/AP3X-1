---
name: apex-ui-redesign
description: Audit and redesign the visual UI of an existing Oracle APEX 26.1/26.2 page or application, including custom non-default looks. Produces a before/after design direction, a standalone prototype, and an APEXLang change map that stays within APEX templates, Template Components, staticIds, accessibility, and CSP rules.
---

# Oracle APEX UI Redesign

Use this skill when the user wants an existing APEX page or app to look different, more premium, more branded, or less like the default Universal Theme. It handles both **restyling** (keep the structure, change the look) and **redesign** (change the layout and visual language).

Do not use this skill for data modeling, PL/SQL, APEXLang syntax discovery, or deployment. Route those to `skills/apex-domains/SKILL.md`, `skills/apex-delivery/SKILL.md`, and the version inventory.

## 1. Inputs

Collect, or state the assumption:

- Target application directory and the page or pages to redesign.
- The user's edit request: screenshots, brand references, words, competitor examples, or "make it premium".
- `working/page-design/requirement.md`, when it exists. It wins over aesthetic preferences for page purpose, page numbers, and required content.
- Target APEX version (`26.1` or `26.2`).
- Whether the app may keep Universal Theme or must use a custom theme. Do not assume "custom" means "no APEX templates"; confirm the level in section 3.
- Whether a browser or screenshot tool is available for before/after evidence.

## 2. Audit the current UI before changing it

Record concrete findings, not impressions:

- Theme and style: `baseTheme`, `currentThemeStyle`, and whether the app uses Universal Theme defaults.
- Page template and region templates; template options in use.
- Typography: families, scale, weights, line length, numeric alignment.
- Layout: page row plan, grid, density, alignment, whitespace, responsive behavior.
- Color: palette, contrast, status colors, hardcoded values, dark-mode behavior.
- States: hover, focus, active, disabled, loading, empty, error, success.
- Consistency: repeated components, one-off styles, duplicate CSS.
- Accessibility: labels, keyboard path, focus visibility, alt text, color-only status.
- Performance: oversized images, heavy CSS/JS, unbounded regions.
- Custom code: page-level CSS/JS, Template Components, plug-ins, and whether they are still maintained.

If a browser is available, capture before screenshots at desktop and mobile widths. If not, say the visual baseline was not verified.

## 3. Choose the custom-UI path

| Path | Use when | What changes | Main cost |
| --- | --- | --- | --- |
| A. Custom theme style | The structure is good; brand is mostly color, type, and surface | Theme Roller `@g_*` style, custom theme style CSS | Low; still looks structurally like Universal Theme |
| B. Custom templates and Template Components | The client wants a distinctive component language, cards, dashboards, or editorial layouts | Page/region/button templates and Template Components, declarative options | Medium; preserve APEX substitution strings, JS initialization, and accessibility |
| C. Fully custom theme | Brand cannot be expressed with APEX templates at all | Custom theme, templates, CSS/JS | High; you own navigation, dialogs, reports, accessibility, responsive behavior, and upgrades |
| D. Hybrid (default) | The user wants "outstanding" but still wants APEX | Custom style + Template Components + selected custom templates | Medium; best balance |

Rules:

- Default to **D** for a premium look with maintainable APEX behavior.
- Choose **C** only with explicit approval and a written statement of what APEX features will be lost or re-implemented.
- Never describe a raw HTML mock-up as a custom APEX theme. A theme is templates, styles, and assets that APEX renders; a prototype is evidence.
- Verify that every custom template, template option, or Theme Component you propose is expressible in the target version's `apexlang-inventory`.
- Do not propose a second CSS framework. Custom CSS must be scoped, named, and justified.

## 4. Define the visual direction

Write a short direction before any code:

- Subject, audience, and the page's primary job.
- One visual idea that belongs to this subject, not a generic dashboard.
- Palette: 4-6 named hex values with roles (ground, ink, accent, surface, border, status).
- Type: one or two families, the scale, weights, and line length.
- Layout: one-sentence concept and a small ASCII wireframe for the key screen.
- One signature element. Everything else stays quiet.
- What is deliberately *not* used: the generic AI tells (identical rounded card grids, gradient blobs, all-caps eyebrows, one accent color applied to every surface, motion on every card).
- How the direction behaves in dark mode, at mobile width, and with keyboard focus.
- For a custom brand, produce the Theme Roller `@g_*` `.less` file and a reviewed CSS preview; verify it in the target instance.

## 5. Prototype

- Write the prototype to `working/design-preview/<page>-redesign/` as standalone HTML/CSS.
- Show before and after for the same content, at desktop and mobile widths.
- For paths A, B, and D, start from the vendored Universal Theme 42 tokens and components reference so the prototype is buildable; for path C, define the custom token set explicitly.
- Prototype HTML may use inline CSS variables for speed. It is never copied into `.apx`, a Static Content region, or a Template Component.
- State which parts of the direction are not achievable in the target APEX version, and why.

## 6. Translate to APEX

Produce a change map, not just a picture:

- Page and region structure: native region types in visual order.
- Template changes: exact page/region/button template names from the inventory.
- Template options: exact option names and values, not guessed labels.
- Template Components: component name, attributes, data source, and refresh behavior.
- Custom CSS/JS: file location, scope, CSP-safe loading, and whether it is page-level or app-level.
- `staticId` for every component that supports it, especially anything targeted by JavaScript or tests.
- Authorization and session-state impact: a visual change must not bypass page or region authorization.
- Accessibility: focus order, labels, contrast, reduced motion, RTL.
- Upgrade statement: what will break on the next APEX or theme refresh, and how it will be maintained.

## 7. Verify

- Re-run the design checklist from `skills/apex-design-system/SKILL.md`.
- If a browser is available, compare before and after at desktop and mobile widths, check contrast, keyboard focus, and empty/error states.
- If a browser is not available, report `PARTIAL` and list exactly what was not verified.
- Do not claim a visual result from static code inspection alone.

## 8. Output contract

Return:

1. Audit findings, severity-ranked.
2. Visual direction and the custom-UI path decision (A, B, C, or D).
3. Prototype path and before/after status.
4. `.apx` change map with inventory-verified component, template, and option names.
5. `staticId` and custom CSS/JS plan.
6. Accessibility, responsive, and upgrade risks.
7. What was verified and what remains unverified.
8. Open questions.

## Reference map

- `skills/apex-design-system/SKILL.md` — design workflow, page map, component mapping, and prototypes.
- `skills/apex-design-system/assets/universal-theme-42/` — token and markup reference for prototypes.
- `skills/apex/apexlang/<version>/apexlang-inventory/SKILL.md` — component, template, and option truth.
- `skills/apex-domains/references/universal-theme.md` — theme and accessibility contract.
- `skills/apex-delivery/SKILL.md` — validation and deployment gates.
