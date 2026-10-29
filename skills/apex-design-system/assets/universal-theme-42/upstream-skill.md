---
name: oracle-apex-ut-ui
description: "Use this skill whenever the user wants to generate, style, or reference HTML/CSS that matches Oracle APEX's Universal Theme 42 design system (Vita, Vita Dark, Vita Red, Vita Slate, Iris, Redwood, or Standard Theme Styles). Triggers include: any mention of 'Oracle APEX', 'APEX theme', 'Universal Theme', 'Vita', 'Vita Emerald', 'Theme Roller', 'APEX region/component' (Alert, Card, Interactive Report, Wizard, etc.), or requests to build a dashboard, admin UI, or component that should 'look like APEX' or use APEX design tokens. Also use when asked to create a new custom APEX Theme Style, when styling should use var(--ut-*) / var(--a-*) CSS custom properties instead of hardcoded colors, or when working with files under tokens/ (vita-light.css, vita-dark.css, vita-red.css, vita-slate.css, iris.css, redwood.css, standard.css, vita-emerald.css/.less) or components-reference.md from this package. Do NOT use for generic web design requests with no APEX/Universal Theme context."
license: MIT — see LICENSE in this repository. Oracle APEX and Universal Theme 42 remain Oracle's property; token values here are an independent, hand-derived reference.
---

# Oracle APEX Universal Theme skill

*(Package / repo slug: `Oracle-apex-ut-UI.skill`)*

**Purpose:** A pre-reference package any AI (Claude, GPT, Gemini, local LLM, etc.) can be
given so it produces HTML/CSS/layouts that visually and structurally match Oracle APEX's
Universal Theme 42, "Vita" style family — without needing an actual APEX instance.

**Source of truth (official, live):**
- Getting Started / live component gallery: `https://oracleapex.com/ords/r/apex_pm/ut/getting-started`
- Theme Style LESS sources (Oracle CDN, APEX 26.1 / Theme 42 26.1):
  - Vita (light, default): `https://static.oracle.com/cdn/apex/26.1.2/themes/theme_42/26.1/less/theme/Vita.less`
  - Vita Dark: `https://static.oracle.com/cdn/apex/26.1.2/themes/theme_42/26.1/less/theme/Vita-Dark.less`
  - Vita Red: `https://static.oracle.com/cdn/apex/26.1.2/themes/theme_42/26.1/less/theme/Vita-Red.less`
  - Vita Slate: `https://static.oracle.com/cdn/apex/26.1.2/themes/theme_42/26.1/less/theme/Vita-Slate.less`
  - Iris: `https://static.oracle.com/cdn/apex/26.1.2/themes/theme_42/26.1/less/theme/Iris.less`
  - Redwood: `https://static.oracle.com/cdn/apex/26.1.2/themes/theme_42/26.1/less/theme/Redwood.less` and `Redwood-Theme.less`
  - Legacy Theme Standard (pre-Theme-42, different architecture): `https://static.oracle.com/cdn/apex/26.1.2/app_ui/css/Core.css` and `Theme-Standard.css`
  - Icon font: `https://static.oracle.com/cdn/apex/26.1.2/libraries/font-apex/2.5.1/css/font-apex.css`
  - Theme JS (sticky widgets, nav behavior): `https://static.oracle.com/cdn/apex/26.1.2/themes/theme_42/26.1/js/theme42.js`, `https://static.oracle.com/cdn/apex/26.1.2/libraries/apex/minified/widget.stickyWidget.min.js`

Keep those four links handy — they are the canonical, always-current definition. This
skill distills them into something usable directly in a browser (plain CSS custom
properties) plus a class/component cheat-sheet, because the .less files require Oracle's
build pipeline (Theme Roller) to compile correctly (they use LESS functions like
`contrast()`, `mix()`, `desaturate()`, `fade()` and an override pattern that only resolves
correctly inside APEX's own LESS compiler).

---

## 1. How Vita's token system actually works

Universal Theme 42 is a **two-layer CSS variable system**:

1. **`--a-*` variables** — low-level "Application UI" component tokens (buttons, cards,
   checkboxes, menus, grid views, chips, dialogs, spinners, etc.). These rarely change
   between Theme Styles; they define spacing, sizing, radii, font-sizes.
2. **`--ut-*` variables** — "Universal Theme" tokens that carry the actual *brand identity*
   (header color, region color, body background, primary palette, shadows, borders). These
   are what changes between Vita / Vita Dark / Vita Red / Vita Slate / your own custom style.
3. A small set of **`@g_*` LESS "Theme Roller" variables** are the *only* things a human
   (or Theme Roller) edits. Everything else is derived from them via LESS color functions
   (`contrast`, `mix`, `lighten`, `darken`, `desaturate`, `fade`). This is the mechanism
   used to create "a new style to the same standard" — see §4.

### Golden rule for any AI generating Vita-style UI
Never hard-code colors in component markup. Always reference the CSS custom property
(e.g. `var(--ut-palette-primary)`, `var(--a-button-background-color)`), the same way real
APEX-rendered pages do. That's what makes the output swappable across Vita / Vita Dark /
Vita Red / Vita Slate / a custom style just by swapping the `:root` block.

---

## 2. Core token map (Vita — light, default)

Use `tokens/vita-light.css` in this package — a ready-to-`<link>` (or inline `<style>`)
stylesheet containing the full resolved `:root { --ut-...; --a-...; }` variable set for
baseline Vita. Load it first, then layer component CSS on top using `var(--token-name)`.

Key tokens an AI will reach for constantly:

| Token | Meaning | Vita (light) value |
|---|---|---|
| `--ut-palette-primary` | Brand accent / primary action color | `#056AC8` |
| `--ut-palette-primary-contrast` | Text color on primary | `#FFFFFF` |
| `--ut-header-background-color` | Top header bar | `#056AC8` |
| `--ut-header-text-color` | Header text/icons | `#FFFFFF` |
| `--ut-body-background-color` | Page background | `#FDFDFD` |
| `--ut-body-text-color` | Default body text | `#1A1A1A` |
| `--ut-region-background-color` | Card/region surface | `#FFFFFF` |
| `--ut-region-header-background-color` | Region title bar | `#F7FBFF` |
| `--ut-component-border-color` | Generic hairline border | `rgba(0,0,0,.10)` |
| `--ut-component-border-radius` | Corner radius (regions/cards) | `.25rem` (4px) |
| `--ut-shadow-sm` / `--ut-shadow-md` / `--ut-shadow-lg` | Elevation shadows | see file |
| `--ut-palette-success` / `-warning` / `-danger` / `-info` | Status colors | `#278701` / `#FFC628` / `#CB1100` / `#056AC8` |
| `--ut-link-text-color` | Hyperlink color | `#056AC8` |
| `--ut-focus-outline-color` | Focus ring | `#056AC8` |
| `--a-button-background-color` | Default button fill | `#F0F0F0`-ish (mixed with region bg) |
| `--a-button-border-radius` | Button corner radius | `.125rem` (2px) |
| `--a-button-padding-y` / `-x` | Button padding | `.5rem .75rem` |
| `--a-field-input-border-radius` | Input corner radius | `.125rem` |
| `--a-field-input-background-color` | Input fill | slightly tinted off-white |
| `--ut-nav-width` | Left nav tree width | `15rem` |
| `--ut-header-height` | Header bar height | `3rem` |

Full list (300+ tokens covering buttons, cards, chips, checkboxes, date pickers, faceted
search, file drop, grid view, menus, popup LOV, splitter, star rating, switches, toolbars,
tree view, dialogs, tooltips, diagrams, chat, QR code, calendar, etc.) is in
`tokens/vita-light.css`.

---

## 3. Component class cheat-sheet (Universal Theme 42 naming conventions)

When generating markup, use these real APEX class prefixes so the HTML is structurally
authentic (and portable back into an actual APEX page template):

- `t-Body`, `t-Body-nav`, `t-Body-content`, `t-Body-actions` — page shell
- `t-Header`, `t-Header-logo`, `t-Header-nav`, `t-Header-search` — top bar
- `t-Region`, `.t-Region--card`, `.t-Region-header`, `.t-Region-headerItems`,
  `.t-Region-body`, `.t-Region-buttons` — region/card container
- `t-Button`, `.t-Button--hot`, `.t-Button--warning`, `.t-Button--success`,
  `.t-Button--danger`, `.t-Button--primary`, `.t-Button--simple`, `.t-Button--link`,
  `.t-Button--noUI`, `.t-Button--header`, `.t-Button--icon` — buttons & states
- `t-Alert`, `.t-Alert--success`, `.t-Alert--warning`, `.t-Alert--danger`, `.t-Alert--info` — alerts
- `t-Badge` — status pill
- `t-Form-fieldContainer`, `t-Form-label`, `t-Form-inputContainer`,
  `apex-item-text`, `apex-item-select`, `apex-item-textarea` — form items
- `t-Card`, `a-CardView`, `.a-CardView-card`, `.a-CardView-title`,
  `.a-CardView-icon` — card views
- `t-Report`, `a-IRR`, `t-Report-header`, `t-Report-wrap` — interactive reports
- `t-TreeView`, `a-TreeView`, `.a-TreeView-content` — nav tree / hierarchy widgets
- `t-Breadcrumb`, `t-Breadcrumb-item` — breadcrumbs
- `t-Tabs`, `.t-Tabs-item`, `.is-active` — tabs
- `t-Dialog`/`ui-dialog` — modal dialogs (jQuery UI-based)
- `t-WizardProgress` — wizard step indicator
- `a-Icon`, `fa-*` / `icon-*` — icon font hooks

Full markup patterns and working examples of each are in `components-reference.md`.

---

## 4. Making "a new style to the same standard" (custom Theme Style)

Oracle's own approach (see `Vita-Red.less`) is deliberately minimal: **override only 5–10
of the `@g_*` "Theme Roller" LESS variables at the top of the file**, then re-import the
base Vita file. Everything else (buttons, forms, IRs, shadows, states, spacing) cascades
automatically from those few variables via LESS color math. That is the "standard" to
replicate for a new style.

The variables that matter, in order of visual impact:

```less
@g_Accent-BG:        #0E9F6E;  // primary brand color — drives header, links, focus ring,
                                 // hot buttons, primary state, nav accent, badges
@g_Link-Base:         @g_Accent-BG;  // hyperlink color (often left = accent)
@g_Focus:             @g_Accent-BG;  // focus ring color
@g_Nav_Style:          dark;    // 'dark' or 'light' left nav / header menu
@g_Body-Title-BG:      #ffffff; // breadcrumb/title bar background (optional)
@g_Container-BorderRadius: .375rem; // region/card corner radius
@g_Button-BorderRadius:    .375rem; // button corner radius
@g_Form-BorderRadius:      .375rem; // input corner radius
```

This package includes a working example new style: **"Vita Emerald"**
(`tokens/vita-emerald.less` + a browser-ready `tokens/vita-emerald.css`), built exactly
the way `Vita-Red.less` is built — an emerald/teal accent (`#0E9F6E`), same navigation and
layout mechanics as base Vita, slightly more rounded corners (6px vs Oracle's default 2–4px)
for a softer, modern feel.

**To use it for real inside APEX:** paste `vita-emerald.less` into
*Theme Roller → Style → (create new / edit custom LESS)*, or add it as a new Theme Style's
custom LESS file, then let APEX's Theme Roller compile it — that guarantees pixel-perfect,
fully-computed colors (contrast-checked automatically by Oracle's `contrast()` function).

**To use it outside APEX (plain HTML/CSS, prototypes, other AI tools):** load
`tokens/vita-emerald.css` — the colors have been pre-resolved by hand following the same
LESS math Oracle uses (`contrast`, `mix`, `desaturate`, `darken`/`lighten`), so it's ready
to `<link>` directly with no build step. Treat it as a close approximation for prototyping;
re-verify exact hex values against Theme Roller before shipping to production.

---

## 5. Recommended workflow for an AI given only this skill

1. Load `tokens/vita-light.css` (or `vita-dark.css` / `vita-red.css` / `vita-emerald.css`)
   as the `:root` variable layer.
2. Build markup using the class names in §3 / `components-reference.md`.
3. Style everything with `var(--token-name)` — never literal hex codes — so the same
   markup automatically re-skins if the `:root` block is swapped.
4. For anything not covered (a token that doesn't exist yet), fall back to the nearest
   semantically-equivalent `--ut-component-*` or `--a-*` token rather than inventing a new
   hardcoded color, to stay consistent with the design system.
5. When asked for "a new style", follow §4: pick a new `@g_Accent-BG` (and optionally
   radius/nav-style), derive the rest the same way `vita-emerald.css` does, rather than
   redesigning the whole system from scratch.

---

## 6. Files in this package

```
Oracle-apex-ut-UI.skill/
├── SKILL.md                       ← this file
├── components-reference.md        ← class names + markup patterns + usage notes
├── example.html                   ← live demo: header, nav, region/cards, buttons,
│                                     alerts, badges, form, table — using the tokens
├── docs/                          ← GitHub Pages landing/demo site (see repo README)
└── tokens/
    ├── vita-light.css             ← baseline Vita (light) — full resolved token set
    ├── vita-dark.css              ← Vita Dark deltas (official)
    ├── vita-red.css               ← Vita Red deltas (official)
    ├── vita-slate.css             ← Vita Slate deltas (official)
    ├── iris.css                   ← Iris deltas (official, Redwood-family "Sky" pillar)
    ├── redwood.css                ← Redwood deltas (official, flagship design system)
    ├── standard.css                ← Legacy Theme Standard — best-effort approximation only
    ├── vita-emerald.less           ← NEW custom style, Oracle Theme-Roller-ready LESS source
    └── vita-emerald.css            ← NEW custom style, browser-ready resolved tokens
```

All delta files (everything except `vita-light.css` and the `vita-emerald.*` pair) load
**after** `vita-light.css` and only override what changes for that style — same markup,
different `:root` values. `standard.css` is the one exception: it approximates a
pre-Theme-42 legacy theme that doesn't actually share Theme 42's token architecture, so
treat it as a rough visual reference rather than an authoritative source.
