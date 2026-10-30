# Brand Layer: Custom Look for APEX Apps

Universal Theme is the **floor, not the ceiling**. Users may ask for a distinctive, branded, "nicer than stock" look, and the agent must deliver it. This reference defines how to do that in a way that compiles, survives upgrades, and stays accessible.

Use it whenever `requirement.md` contains a design direction (colours, mood, shadows, radius, typography, badge style, "playful", "premium", a screenshot, a brand reference), or the user asks for a look beyond the default theme. It applies to **new apps and existing apps alike**.

## 1. Authority order

1. The user's design direction in `working/page-design/requirement.md` or the current request. User-supplied hex values, fonts, radii, and shadows are **requirements**, not suggestions. Never drop them silently.
2. The user's **design reference** website, captured with `scripts/capture-design-reference.mjs` and read per `references/design-reference.md`. Its measured colours, type character, radius, shadow, and density are requirements for everything the user did not state explicitly.
3. Accessibility contract (WCAG 2.2 AA). If a user or reference colour fails contrast for a role, keep the colour and adjust *its usage* (darker shade for text, use as fill with contrasting text, use for borders/accents only). Report the adjustment; do not swap in a different brand.
4. The target version's inventory for every APEX component, template, template option, and property.
5. Universal Theme defaults, for everything the user and the reference did not specify.

The "do not copy hex from external research" rule still applies to direction banks, screenshots you were not asked to match, and prototypes. It never overrides colours the user gave or a reference site the user chose.

Before choosing tokens, read `references/craft.md`: its lever list (header, ground and surfaces, typography, primary action, region chrome) decides whether the app looks designed or looks like stock APEX with a new accent colour.

## 2. Freedom levels

Pick the lowest level that fully delivers the requested look. State the choice in the design brief.

| Level | What you may change | Mechanism |
| --- | --- | --- |
| L1 Brand tokens | Primary/accent colours, surfaces, radius, shadows, fonts | `brand.css` overriding `--ut-*` / `--a-*` variables |
| L2 Brand components | Badges, KPI tiles, hero, cards, empty states, status pills, form polish | L1 + scoped `brand-*` classes applied through `cssClasses`, template options, and Template Components |
| L3 Custom theme style | A named, selectable style with Theme Roller config | Theme `style` component with `css.fileUrls` and `themeRollerAttributes` |
| L4 Custom templates | Distinctive layout language: editorial pages, bespoke shells | Custom page/region/list templates (explicit approval required; see `skills/apex-ui-redesign/SKILL.md` path C) |

Default when the requirement contains *any* design direction: **L2**.

## 3. L1/L2 implementation (validated against the APEX 26.1 and 26.2 theme CSS)

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

### 3.2 Generate `brand.css`; never hand-write it

Always generate `brand.css` with the brand kit, with or without a reference site:

```bash
node scripts/build-brand-kit.mjs --reference working/page-design/design/reference/reference.json   # from a captured reference
node scripts/build-brand-kit.mjs --init --set colors.primary=#7C3AED --set colors.action=#7C3AED      # no reference
node scripts/build-brand-kit.mjs --kit working/page-design/design/brand/brand-kit.json               # rebuild after editing decisions
```

Why a generator and not a template to copy:

- **Vita hard-codes colours on selectors.** The hot button (`.t-Button--hot` and its simple/link/noUI variants) and the side-nav current/selected/hover rows carry literal colours in the Vita style. A `brand.css` that only overrides `--ut-palette-primary` at `:root` leaves every primary button stock blue and the selected nav row charcoal. The kit re-declares those selectors from an index of the real theme CSS (`assets/ut-css/<version>/scoped-rules.json`).
- **Only real variables work.** The kit checks every `--ut-*`/`--a-*` it writes against the variables the APEX theme CSS for that version actually reads (`assets/ut-css/<version>/consumed-vars.txt`, built from Oracle's CDN by `scripts/refresh-ut-css-vars.mjs`). The delivery gate applies the same check to the app's `brand.css`.
- **Contrast is computed, not hoped for.** Text-safe shades, button label colours, nav selection, and subtle status-badge tints are derived to meet WCAG 2.2 AA; `kit-report.md` lists every pair and the build fails on any miss.
- **Typography is real.** `--a-base-font-family` (the variable APEX reads for the UI font) points at a self-hosted open-licence font from `scripts/fetch-open-font.mjs`; heading weight is applied to region titles and the page title.

The generated file has six sections: `@font-face`, brand tokens (the only colour literals), the Universal Theme variable mapping, hot-button rules, side-nav rules, heading weight, and reduced motion. Copy it and its fonts into the app unchanged:

```text
working/page-design/design/brand/css/brand.css  -> app/shared-components/static-files/css/brand.css
working/page-design/design/brand/fonts/*.woff2  -> app/shared-components/static-files/fonts/
```

Register each font in `static-files.apx` with `mimeType: font/woff2`. `brand.css` references fonts as `../fonts/<file>`, which resolves inside the application's static files.

Brand component classes (`brand-pill`, `brand-kpi`, …) are optional extras for what template options cannot express. Put them in a separate, hand-reviewed section only when a page uses them; every `brand-*` class defined must be used and vice versa.

### 3.3 Applying the look to components

- Attach brand classes with the `cssClasses` property in the group the inventory lists for that component (for example: region `componentAppearance`/card groups, page item `advanced`, button `appearance`). Look the group up; do not guess.
- Prefer native visuals first: `u-color-N`, `u-success`/`u-danger`, `t-Badge`, template options, the Badge column variant, and the `metricCard` Template Component. Add `brand-*` classes on top for the parts the native option cannot express (shadow, radius, pill shape, gradient, spacing rhythm).
- Data-driven styling (status badges, category icons) comes from view columns such as `status_css_class` and `status_icon`. **If you create a styling column, a page must consume it.** An unused styling column is a defect.
- Status is never conveyed by colour alone: a badge carries text and, optionally, an icon.
- Icons must exist in the version's Font APEX index (`skills/apex/apexlang/<version>/apexlang-generation/assets/indexes/font-apex-icon-index.json` for 26.1). An unknown icon class renders blank.

### 3.4 Still forbidden

- `style="..."`, `onclick=`, `javascript:` in `.apx`, region HTML, or Template Components. Put the rule in `brand.css` and attach a class.
- Hex values outside the token block of `brand.css`.
- A second CSS framework (Bootstrap, Tailwind, etc.) or remote font/CSS imports that break CSP. Web fonts go in static files, and only open-licence fonts: never ship a reference site's proprietary font files.
- Whole pages built from raw HTML in a Static Content region. Rich *content* (a policy text) is fine when it uses classes, not inline styles.
- Overriding Universal Theme internals by deep selectors (`.t-Body .t-Region > div > ...`). Override variables or attach a class.

## 4. L3: custom theme style

Use when the brand must be a named, selectable style or be edited later in Theme Roller.

- Create a theme `style` component (inventory: `app/theme/style`) whose `subscription.master` is the closest stock style, with `css.fileUrls` pointing at the brand stylesheet and `themeRollerAttributes.jsonConfig` carrying the Theme Roller variables.
- Set it as `currentThemeStyle`. Keep `brand.css` as the source of the tokens so L1/L2 classes continue to work.
- Validate, then open Theme Roller on the target instance to confirm the variables load.

## 5. Design brief additions

Every design brief that uses this reference records:

1. **Design direction trace**: one row per design bullet in the requirement (colour, badge, icon, shadow, label style, currency, tone, design reference) with the implementing file and line, or `NOT DONE: <reason>`.
2. Freedom level (L1–L4) and why.
3. Token table: role, value, source (user / derived / UT default), contrast result.
4. Brand class inventory: class, purpose, where used.
5. Dark-mode and reduced-motion behaviour.

## 6. Verification

- `scripts/validate-apex-app.ps1` must pass (it proves the files compile, not the look).
- `scripts/verify-delivery.ps1 -ProjectDirectory working` must pass. It enforces sections 3.2–3.4 and the trace mechanically: hex only on `--brand-*` lines, requirement colours present, brand classes defined and used, icons real, styling columns consumed, only variables the theme CSS reads, hot buttons re-declared, fonts shipped and registered, and (with a design reference) the app `brand.css` identical to the generated kit plus a passing design score.
- `node scripts/score-design.mjs --preview <prototype> --kit <brand-kit.json>` must print `DESIGN SCORE PASS` (85+ and no blocker). Run it again on the deployed page with `--url`.
- Run the design scorecard and `scripts/verify-design-preview.mjs` on a prototype that loads the same `brand.css`, or on the deployed page.
- Check that no requirement design bullet is missing from the trace, every `brand-*` class in `brand.css` is used, and every class used in `.apx` exists in `brand.css`.
- If a browser is not available, mark the visual result `NOT VERIFIED`; never claim the look from code alone.
