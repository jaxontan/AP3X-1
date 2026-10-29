# Brand Layer: Custom Look for APEX Apps

Universal Theme is the **floor, not the ceiling**. Users may ask for a distinctive, branded, "nicer than stock" look, and the agent must deliver it. This reference defines how to do that in a way that compiles, survives upgrades, and stays accessible.

Use it whenever `requirement.md` contains a design direction (colours, mood, shadows, radius, typography, badge style, "playful", "premium", a screenshot, a brand reference), or the user asks for a look beyond the default theme. It applies to **new apps and existing apps alike**.

## 1. Authority order

1. The user's design direction in `working/page-design/requirement.md` or the current request. User-supplied hex values, fonts, radii, and shadows are **requirements**, not suggestions. Never drop them silently.
2. Accessibility contract (WCAG 2.2 AA). If a user colour fails contrast for a role, keep the colour and adjust *its usage* (darker shade for text, use as fill with contrasting text, use for borders/accents only). Report the adjustment; do not swap in a different brand.
3. The target version's inventory for every APEX component, template, template option, and property.
4. Universal Theme defaults, for everything the user did not specify.

The "do not copy hex from external research" rule still applies to direction banks, screenshots you were not asked to match, and prototypes. It never overrides colours the user gave.

## 2. Freedom levels

Pick the lowest level that fully delivers the requested look. State the choice in the design brief.

| Level | What you may change | Mechanism |
| --- | --- | --- |
| L1 Brand tokens | Primary/accent colours, surfaces, radius, shadows, fonts | `brand.css` overriding `--ut-*` / `--a-*` variables |
| L2 Brand components | Badges, KPI tiles, hero, cards, empty states, status pills, form polish | L1 + scoped `brand-*` classes applied through `cssClasses`, template options, and Template Components |
| L3 Custom theme style | A named, selectable style with Theme Roller config | Theme `style` component with `css.fileUrls` and `themeRollerAttributes` |
| L4 Custom templates | Distinctive layout language: editorial pages, bespoke shells | Custom page/region/list templates (explicit approval required; see `skills/apex-ui-redesign/SKILL.md` path C) |

Default when the requirement contains *any* design direction: **L2**.

## 3. L1/L2 implementation (validated on APEXLang 26.1)

### 3.1 Files

```text
app/shared-components/static-files/css/brand.css   # the only place brand hex values live
app/shared-components/static-files.apx              # registers the file
app/application.apx                                 # loads it on every page
```

Register the file in `static-files.apx`:

```apx
file "css/brand.css" (
    mimeType: text/css
    charSet: utf-8
)
```

Load it app-wide in `application.apx` (app-level `css.fileUrls`, present in the 26.1 and 26.2 inventories):

```apx
css {
    fileUrls: #APP_FILES#css/brand.css?v=#APP_VERSION#
}
```

Do not use `#MIN#` unless you also ship a `brand.min.css`; otherwise the runtime requests a file that does not exist.

### 3.2 `brand.css` structure

```css
/* 1. Brand tokens: the ONLY hex values in the app. Names = roles, not colours. */
:root {
  --brand-primary: #7C3AED;
  --brand-primary-strong: #5B21B6;   /* text-safe shade for 4.5:1 on light ground */
  --brand-accent: #A855F7;
  --brand-on-primary: #FFFFFF;
  --brand-surface: #FAF8FF;
  --brand-radius: 12px;
  --brand-shadow: 0 1px 2px rgb(17 12 34 / .06), 0 8px 24px rgb(76 29 149 / .08);
}

/* 2. Map tokens onto Universal Theme variables so every native component follows. */
:root {
  --ut-palette-primary: var(--brand-primary);
  --ut-palette-primary-contrast: var(--brand-on-primary);
  --ut-link-text-color: var(--brand-primary-strong);
  --ut-focus-outline-color: var(--brand-accent);
  --ut-region-border-radius: var(--brand-radius);
  --ut-component-border-radius: var(--brand-radius);
  --a-button-border-radius: calc(var(--brand-radius) - 4px);
  --a-field-input-border-radius: calc(var(--brand-radius) - 4px);
  --a-field-input-focus-border-color: var(--brand-primary);
}

/* 3. Dark mode: redefine tokens, never the component rules. */
@media (prefers-color-scheme: dark) { :root { /* ... */ } }

/* 4. Brand components: every class is prefixed brand-, scoped, and token-driven. */
.brand-card   { border-radius: var(--brand-radius); box-shadow: var(--brand-shadow); }
.brand-pill   { border-radius: 999px; }
.brand-kpi    { /* ... */ }

/* 5. Motion respects the user. */
@media (prefers-reduced-motion: reduce) { .brand-card { transition: none; } }
```

Variable names in section 2 must exist in `skills/apex-design-system/assets/universal-theme-42/tokens/` or be verified on the target instance. Report any variable you could not verify.

### 3.3 Applying the look to components

- Attach brand classes with the `cssClasses` property in the group the inventory lists for that component (for example: region `componentAppearance`/card groups, page item `advanced`, button `appearance`). Look the group up; do not guess.
- Prefer native visuals first: `u-color-N`, `u-success`/`u-danger`, `t-Badge`, template options, the Badge column variant, and the `metricCard` Template Component. Add `brand-*` classes on top for the parts the native option cannot express (shadow, radius, pill shape, gradient, spacing rhythm).
- Data-driven styling (status badges, category icons) comes from view columns such as `status_css_class` and `status_icon`. **If you create a styling column, a page must consume it.** An unused styling column is a defect.
- Status is never conveyed by colour alone: a badge carries text and, optionally, an icon.
- Icons must exist in the version's Font APEX index (`skills/apex/apexlang/<version>/apexlang-generation/assets/indexes/font-apex-icon-index.json` for 26.1). An unknown icon class renders blank.

### 3.4 Still forbidden

- `style="..."`, `onclick=`, `javascript:` in `.apx`, region HTML, or Template Components. Put the rule in `brand.css` and attach a class.
- Hex values outside the token block of `brand.css`.
- A second CSS framework (Bootstrap, Tailwind, etc.) or remote font/CSS imports that break CSP. Web fonts go in static files.
- Whole pages built from raw HTML in a Static Content region. Rich *content* (a policy text) is fine when it uses classes, not inline styles.
- Overriding Universal Theme internals by deep selectors (`.t-Body .t-Region > div > ...`). Override variables or attach a class.

## 4. L3: custom theme style

Use when the brand must be a named, selectable style or be edited later in Theme Roller.

- Create a theme `style` component (inventory: `app/theme/style`) whose `subscription.master` is the closest stock style, with `css.fileUrls` pointing at the brand stylesheet and `themeRollerAttributes.jsonConfig` carrying the Theme Roller variables.
- Set it as `currentThemeStyle`. Keep `brand.css` as the source of the tokens so L1/L2 classes continue to work.
- Validate, then open Theme Roller on the target instance to confirm the variables load.

## 5. Design brief additions

Every design brief that uses this reference records:

1. **Design direction trace**: one row per design bullet in the requirement (colour, badge, icon, shadow, label style, currency, tone) with the implementing file and line, or `NOT DONE: <reason>`.
2. Freedom level (L1–L4) and why.
3. Token table: role, value, source (user / derived / UT default), contrast result.
4. Brand class inventory: class, purpose, where used.
5. Dark-mode and reduced-motion behaviour.

## 6. Verification

- `scripts/validate-apex-app.ps1` must pass (it proves the files compile, not the look).
- `scripts/verify-delivery.ps1 -ProjectDirectory working` must pass. It enforces sections 3.3–3.4 and the trace mechanically: hex only on `--brand-*` lines, requirement colours present, brand classes defined and used, icons real, styling columns consumed.
- Run the design scorecard and `scripts/verify-design-preview.mjs` on a prototype that loads the same `brand.css`, or on the deployed page.
- Check that no requirement design bullet is missing from the trace, every `brand-*` class in `brand.css` is used, and every class used in `.apx` exists in `brand.css`.
- If a browser is not available, mark the visual result `NOT VERIFIED`; never claim the look from code alone.
