---
name: apex-design-system
description: Visual and UX design for Oracle APEX 26.1 and 26.2. Turns a requirement or screenshot into a design brief, page map, theme and template decisions, component mapping, staticId plan, and an APEXLang handoff that uses the target version's inventory as compiler truth. Use before implementation when the task is about layout, theme style, templates, navigation, dashboards, or page composition.
---

# Oracle APEX Design System

Use this skill before implementation when the work is about **how the app should look and behave**, not how the `.apx` syntax is written. It produces a design package that `apex-planner` or `apex` can implement without re-deciding the design.

Do not use this skill for data modeling, PL/SQL, APEXLang syntax, validation, deployment, or debugging. Route those to `skills/apex-domains/SKILL.md`, `skills/apex-delivery/SKILL.md`, or `skills/harness/error-triage/SKILL.md`.

## 1. Preconditions

Confirm, or state the assumption:

- Target APEX version is `26.1` or `26.2` (read `.apex/apexlang.json` or the target instance).
- The application directory exists, or the user asked for a new app.
- `working/page-design/requirement.md` is the authoritative source for page numbers, layout, regions, items, and rules when it exists. Read it before designing.
- Read `skills/apex/apexlang/<version>/apexlang-inventory/SKILL.md` and the component files you intend to reference.
- Read `skills/apex-domains/references/universal-theme.md` for the design contract.
- For a redesign or measurable design review, read `skills/apex-ui-redesign/references/design-scorecard.md`.
- For visual prototypes, read `skills/apex-design-system/assets/universal-theme-42/upstream-skill.md`, `components-reference.md`, and the matching file under `tokens/`.
- Always read `references/craft.md` before a visual decision: it defines what good looks like and the levers that stop an APEX app looking default.
- If the requirement or request names a **design reference** website, read `references/design-reference.md` and capture it with `node scripts/capture-design-reference.mjs --url <url>` before choosing a style. Look at the screenshots; do not design from the numbers alone.
- If the requirement or request contains any design direction (colours, mood, badges, shadows, typography, "playful", "premium", a brand, reference site, or screenshot), read `references/brand-layer.md`. It applies to new apps, not only redesigns.
- If using an external direction bank, read `references/ui-ux-pro-max.md` and `references/palette-bank.md`.
- For screenshots, read `skills/apex/apexlang/26.1/apexlang-generation/references/domains/page-components/screenshot-to-layout/component-mapping.md` (26.1) and translate the rules to the target version's inventory.
- For runtime layout defects, read `skills/apex/apexlang/26.1/apexlang-generation/references/domains/debugging/runtime-ui-verification.md`.

## 2. Non-negotiables

1. **Version lock.** Never mix 26.1 and 26.2 components, templates, or properties.
2. **Inventory truth.** Every component, template, template option, and property you name must exist in the target version's `apexlang-inventory` or a working example. If you cannot find it, say so and stop; do not invent a name or value.
3. **Requirement authority.** Follow the user's page numbers, page purposes, region order, **and design direction**. Do not renumber or merge pages for convenience. User-specified colours, badge styles, icons, shadows, label styles, tone, and a design reference website are requirements; every one must appear in the design direction trace (`references/brand-layer.md` §5) as implemented or `NOT DONE: <reason>`.
4. **Native structure, custom look.** Build structure from native regions, items, buttons, reports, and template options. The *look* is free: stock Universal Theme is the floor, not the ceiling. Deliver custom branding through the brand layer (`references/brand-layer.md`). Do not import Bootstrap, Tailwind, or another CSS framework. Do not build a page whose layout is raw HTML in a Static Content region.
5. **No hand-written theme markup in pages.** Use templates and template options. Universal Theme template markup belongs in the theme/template layer, not in page regions.
6. **No inline styles or event handlers in generated page markup.** Do not emit `style="..."`, `onclick="..."`, `onchange="..."`, or `javascript:` URLs in `.apx`, regions, or Template Components. Styling goes in `brand.css` and is attached with `cssClasses`; behaviour goes in buttons, Dynamic Actions, or declarative actions. Theme placeholders such as `#JAVASCRIPT#` are substituted by APEX and are not hand-written page code. The one exception is a throwaway prototype under `working/design-preview/`, which may use inline CSS variables; it must never be pasted into a page.
7. **Deterministic `staticId`.** Every component that supports `staticId` gets a stable, semantic, lowercase kebab-case ID. Use it for navigation, JavaScript, Dynamic Actions, and tests. Do not rename it after implementation.
8. **Accessible by default.** Every input has a label, every image has alt text or is decorative, status is not conveyed by color alone, dialogs have a title and cancel path, and keyboard operation is preserved.
9. **Designer does not edit `.apx`.** Produce the design package and hand off; implementation and validation belong to `apex`.

## 3. Theme and style selection

- Use Universal Theme. Read `theme.md` and `style.md` in the target inventory before naming a base theme or style.
- In 26.1 and 26.2 the inventory enumerates the supported styles: `Vita`, `iris`, `redwood-light`, `vita-dark`, `vita-red`, and `vita-slate`. Treat that list as the closed set of *stock* styles to subscribe to; do not add a style name from a blog post or prototype. A custom style you define yourself (brand layer L3) subscribes to one of these.
- Bind the theme with the version's contract: `baseTheme` (for example `ut-26.1` or `ut-26.2`) and `currentThemeStyle`. Do not use a stale theme `version` field as a substitute.
- Select one base style for the application, the closest stock match to the requested look. The stock style is the floor the brand layer builds on, not the design. Do not copy hex values from external research or from screenshots/prototypes the user did not ask you to match.
- **A design reference sets the look.** When the user names a reference website, its captured colours, type character, shape, depth, and density are the target (`references/design-reference.md`). Borrow the look, never its logos, images, copy, font files, or markup.
- **User-supplied brand values win.** When the requirement gives colours, radius, shadows, or fonts, implement them through the brand layer (`references/brand-layer.md`): brand tokens live once in `app/shared-components/static-files/css/brand.css`, mapped onto `--ut-*` / `--a-*` variables, and loaded app-wide with the app-level `css.fileUrls`. Choosing a stock style instead of the requested palette is a requirement miss.
- Outside the brand token block, use `var(--ut-*)`, `var(--a-*)`, `var(--brand-*)`, or `color-mix(...)`; never hardcoded hex.
- Pick a freedom level (L1 tokens, L2 brand components, L3 custom theme style, L4 custom templates). Default to **L2** whenever the requirement contains any design direction.
- **Generate `brand.css`; never hand-write it.** Use `scripts/build-brand-kit.mjs` (`--reference`, `--init`, or `--kit`). Vita hard-codes the hot-button and side-nav colours on selectors, so a hand-written `:root` override leaves primary buttons stock blue; the kit re-declares them and uses only variables the real theme CSS reads (`references/brand-layer.md` §3.2).
- Verify any CSS variable or token against the target instance or the version's documented output before shipping. If the target instance is unavailable, label the choice as an assumption.

### 3.1 Visual prototype mode

Use this mode when the user asks for a mockup, a screenshot recreation, a "make it look like" exploration, or a style comparison. The prototype communicates the look; it is not the application.

- Render the prototype with `scripts/render-design-prototype.mjs` from a content spec; do not hand-write prototype HTML. It uses real Universal Theme markup, Oracle's real theme CSS for the version, and the kit's `brand.css`, so it shows what the app will look like. Never copy it into `.apx`, a Static Content region, or a Template Component.
- The renderer loads Oracle's real Universal Theme CSS for the target version (from Oracle's CDN) plus the kit's `brand.css`, so the prototype shows the Vita style as APEX ships it. The vendored assets under `assets/universal-theme-42/` are a hand-derived reference for markup patterns and Theme Roller derivation only; the authoritative variable list is `assets/ut-css/<version>/`.
- Do not hand-pick hex values beyond the brand kit's tokens. For a named custom theme style (brand layer L3), produce the `@g_*` `.less` file and verify it in Theme Roller.
- Score it with `node scripts/score-design.mjs --preview <dir> --kit <brand-kit.json>` and open `score/compare-desktop.png` and `score/design-mobile.png`. Iterate by changing `brand-kit.json` or the spec until `DESIGN SCORE PASS` (`references/design-reference.md` §2). Never describe a look you have not seen.
- After the user approves the prototype, translate it: choose the native region type, items, buttons, and template options from the target inventory; apply the `staticId` plan; discard the prototype HTML.
- State in the handoff whether the prototype was approved, rejected, or not reviewed.

### 3.2 Design quality gate

Use `skills/apex-ui-redesign/references/design-scorecard.md` before and after a visual change. The scorecard defines the 0-5 anchors, quality bars, and before/after protocol.

- **Numeric gate:** `node scripts/score-design.mjs --preview <dir> --kit <brand-kit.json>` must print `DESIGN SCORE PASS` (85+/100, no failed blocker). It measures fidelity to the kit/reference, craft rules, stock-APEX tells, and axe, and lists a fix for every failed check.
- Required dimensions: hierarchy, spacing, typography, colour and contrast, density and responsive fit, states, and accessibility.
- Minimum gate: accessibility at least 4/5, no dimension below 3/5, total at least 24/35, no mobile overflow.
- Contract: normal text meets WCAG 2.2 AA 4.5:1; large text, UI boundaries, and focus indicators meet 3:1. Status is never conveyed by colour alone.
- A numeric score is invalid without screenshots and a verifier report. If the verifier cannot run, mark the item `PARTIAL` or `NOT VERIFIED`.
- The designer may run only the design pipeline scripts (capture, brand kit, font, render, score, preview verifier), to look at the reference and its own work while iterating. The independent sign-off belongs to the `apex-design-verifier` subagent or the user.
- Optional direction banks such as UI UX Pro Max are direction-only. Never copy their HTML/CSS/Tailwind/React output into APEX; see `references/ui-ux-pro-max.md`.

## 4. Page map

For every page, record:

- Page number and purpose (from `requirement.md` when present).
- Primary action and entry points.
- Authorization scheme and the roles that can reach it.
- Region list in visual order, with region type and purpose.
- Items, buttons, processes, validations, and branches.
- Empty state, error state, and loading behavior.
- Navigation: how the page is reached and where it returns.

Preserve the user's row plan. Do not collapse a two-column row into a stack, and do not turn a dashboard into an arbitrary sequence of equal-width regions.

## 5. Component mapping

- Derive the layout tree first, then choose the narrowest safe native primitive for each region. Mapping must not move, resize, merge, or delete regions that the requirement or screenshot established.
- Tabular data: Interactive Report by default. Use Interactive Grid only when inline editing is clearly required.
- KPI strip: one grouped `themeTemplateComponent/metricCard` region backed by one normalized query returning multiple rows. Do not create one region per metric unless each metric has its own visible container.
- Entity, media, or navigation cards: one grouped native `cards` region with one query returning multiple rows.
- Forms: a form region with real page items, not a static mock-up.
- Search and filter strips: real page items and real buttons.
- Tab containers: keep the requirement's tab count and enable lazy loading where the version supports it. Confirm the template option in the inventory first.
- Unknown or bespoke widget: use a `staticContent` placeholder with a descriptive label and sentence. Do not emit fake HTML, fake chart markup, or decorative DOM.
- AI search: only use `defaultSearchMode` with `searchModeAI` when the target inventory exposes it for that region type. Do not claim AI features that the inventory does not define.

## 6. Templates and template options

- Reference templates with the `@/...` syntax used by the target version's examples, and copy the exact reference spelling from the inventory or a working example.
- Every template option must be declared for that template. Do not guess labels, values, or spelling.
- Theme defaults (`componentDefaults`, `regionDefaults`, `dialogDefaults`) live in `theme.apx`. Page-level overrides must be explicit and justified.
- Button appearances (`hot`, `primary`, `simple`, `link`, `noUI`, and so on) are properties or template options, not hand-written CSS classes. Confirm the exact property in the button inventory.

## 7. `staticId` plan

Produce a table with: component, page, `staticId`, and consumer (navigation, JavaScript, Dynamic Action, test).

- Use semantic names such as `p10-orders-ir`, `p10-approve-btn`, `p10-status-badge`.
- Keep IDs unique across the application.
- Where the inventory marks `staticId` as required, a missing value is a design defect, not a detail.
- Do not use generated numeric IDs or display labels as identifiers.

## 8. Accessibility, RTL, and performance

- Labels are visible or programmatically associated; placeholders are not labels.
- Alt text is meaningful, or the image is explicitly decorative.
- Do not rely on color alone for status.
- Normal text meets WCAG 2.2 AA 4.5:1; large text, UI boundaries, and focus indicators meet 3:1. Verify custom pairs with the visual verifier.
- Pointer targets are at least 24x24 px, with 44x44 px preferred.
- Keyboard focus order follows the visual order; the page remains usable at 200% zoom.
- Dialogs have a title, a primary action, and a cancel path.
- Use logical layout properties or Universal Theme utilities so the page survives RTL rendering.
- Select only displayed columns. Add filters, pagination, or a bounded query to any large report.
- Lazy-load secondary tabs and heavy regions where the version supports it.
- Keep page processes thin: call a package API rather than embedding multi-table logic.

## 9. Handoff package

Write this package to `working/page-design/application-design.md` (template: `docs/templates/application-design.template.md`, `Status: DRAFT`), in this order:

1. **Design brief** — problem, actors, goals, assumptions, open questions.
2. **Style decision** — design reference (URL, character, borrowed / not copied, font substitution, iteration log) or "none supplied"; base theme, style, brand layer level, token table, and the `references/craft.md` §2 lever decisions.
3. **Visual prototype** — path under `working/design-preview/`, status (approved, rejected, not reviewed), and the style file used. Omit when no prototype was requested.
4. **Page map** — per section 4.
5. **Component map** — per section 5, with the native primitive for each region.
6. **Template and template-option decisions** — exact names from the inventory.
7. **`staticId` plan** — per section 7.
8. **Acceptance criteria** — what a reviewer can check on the running page.
9. **APEXLang file map** — pages and shared components to create or change.
10. **Risks and unknowns** — what could not be verified without the target instance.
11. **Requirement trace** — one row per `requirement.md` bullet (including every design-direction bullet), marked `PLANNED`; the implementer updates it to `DONE` with `file:line` or `NOT DONE: <reason>`.

Never edit `requirement.md`; it is user-owned. Put deviations under open questions and stop for user approval.

Then hand off:

- Architecture, data model, or PL/SQL questions → `apex-planner`.
- Implementation and validation → `apex` using `skills/apex-delivery/SKILL.md`.

## 10. Design review checklist

- [ ] Version is 26.1 or 26.2 and every referenced component exists in that inventory.
- [ ] Page numbers, purposes, and row plan match `requirement.md`.
- [ ] One base style, bound through `baseTheme` and `currentThemeStyle`.
- [ ] Every design bullet in `requirement.md` appears in the design direction trace as implemented (file:line) or `NOT DONE: <reason>`.
- [ ] A design reference, when given, was captured, its screenshots were viewed, and the prototype was compared side by side with it for at least two rounds.
- [ ] Every lever in `references/craft.md` §2 was decided explicitly; none was left at the default by accident.
- [ ] No reference logo, image, copy, proprietary font file, or markup was copied.
- [ ] User-supplied brand values are implemented in `brand.css` and loaded app-wide; no hex outside its token block.
- [ ] Every `brand-*` class used in `.apx` exists in `brand.css`, and every one defined is used.
- [ ] Every styling column a view exposes (status class, icon) is consumed by a page.
- [ ] Every icon class exists in the version's Font APEX index.
- [ ] No raw HTML layout, no second CSS framework, no inline styles or handlers in deployable markup.
- [ ] Any prototype is under `working/design-preview/`, uses one style file, and is not referenced by the app.
- [ ] The approved prototype was translated to native components; no prototype HTML was copied.
- [ ] The design scorecard was recorded before and after, with evidence, and meets the gate.
- [ ] The verifier report, screenshots, and axe results exist for desktop and mobile, or the gap is explicitly marked `PARTIAL`.
- [ ] Any external direction bank was used for direction only; no external HTML/CSS/framework output was copied.
- [ ] Every region maps to a native primitive or a justified `staticContent` placeholder.
- [ ] Every template and template option is declared in the inventory.
- [ ] Every supported component has a stable `staticId`.
- [ ] Labels, alt text, keyboard path, and dialogs are designed.
- [ ] Every page has an empty state and an error state.
- [ ] Handoff names the implementer and the validation gate.

## Reference map

- `skills/apex-ui-redesign/references/design-scorecard.md` — measurable design quality gate.
- `references/craft.md` — what good looks like; the levers that stop an APEX app looking default.
- `references/design-reference.md` — design from a reference website: capture, read, borrow, translate, compare.
- `scripts/capture-design-reference.mjs` — screenshots and measured style DNA of a reference website.
- `scripts/build-brand-kit.mjs` — generates a complete, contrast-safe `brand.css` from `brand-kit.json` decisions.
- `scripts/fetch-open-font.mjs` — self-hosted open-licence fonts (OFL/Apache only).
- `scripts/render-design-prototype.mjs` — prototype from a content spec with real Universal Theme markup and CSS.
- `scripts/score-design.mjs` — 0-100 design score with blockers and fixes; works on prototypes and deployed pages.
- `assets/ut-css/<version>/` — index of the real APEX theme CSS (variables read, stock values, hard-coded rules); refresh with `scripts/refresh-ut-css-vars.mjs`.
- `references/brand-layer.md` — custom look beyond stock Universal Theme: brand tokens, brand components, custom styles.
- `references/ui-ux-pro-max.md` — direction-only external bank rules.
- `references/palette-bank.md` — local palette starting points.
- `scripts/verify-design-preview.mjs` — Playwright and axe visual verifier.
- `skills/apex/apexlang/<version>/apexlang-inventory/SKILL.md` — component and property truth.
- `skills/apex/apexlang/<version>/apexlang-example-applications/SKILL.md` — working patterns.
- `skills/apex/apexlang/26.1/apexlang-generation/references/domains/page-components/screenshot-to-layout/component-mapping.md` — screenshot-to-region mapping.
- `skills/apex/apexlang/26.1/apexlang-generation/references/domains/debugging/runtime-ui-verification.md` — runtime layout verification.
- `skills/apex-domains/references/universal-theme.md` — theme, accessibility, and compiler-truth contract.
- `skills/apex-design-system/assets/universal-theme-42/upstream-skill.md` — Universal Theme 42 token system and Theme Roller derivation.
- `skills/apex-design-system/assets/universal-theme-42/components-reference.md` — Universal Theme 42 class and markup patterns.
- `skills/apex-design-system/assets/universal-theme-42/tokens/` — baseline and style token files.
- `skills/apex-design-system/assets/universal-theme-42/SOURCE.md` — upstream repository, commit, license, and limits.
- `skills/apex-ui-redesign/SKILL.md` — audit and redesign an existing page, including custom non-default looks.
- `skills/apex-delivery/SKILL.md` — validation and deployment gates.
