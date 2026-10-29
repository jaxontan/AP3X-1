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
- For visual prototypes, read `skills/apex-design-system/assets/universal-theme-42/upstream-skill.md`, `components-reference.md`, and the matching file under `tokens/`.
- For screenshots, read `skills/apex/apexlang/26.1/apexlang-generation/references/domains/page-components/screenshot-to-layout/component-mapping.md` (26.1) and translate the rules to the target version's inventory.
- For runtime layout defects, read `skills/apex/apexlang/26.1/apexlang-generation/references/domains/debugging/runtime-ui-verification.md`.

## 2. Non-negotiables

1. **Version lock.** Never mix 26.1 and 26.2 components, templates, or properties.
2. **Inventory truth.** Every component, template, template option, and property you name must exist in the target version's `apexlang-inventory` or a working example. If you cannot find it, say so and stop; do not invent a name or value.
3. **Requirement authority.** Follow the user's page numbers, page purposes, and region order. Do not renumber or merge pages for convenience.
4. **Native first.** Prefer native regions, items, buttons, reports, and template options. Do not import Bootstrap, Tailwind, or another CSS framework. Do not build a page whose layout is raw HTML in a Static Content region.
5. **No hand-written theme markup in pages.** Use templates and template options. Universal Theme template markup belongs in the theme/template layer, not in page regions.
6. **No inline styles or event handlers in generated page markup.** Do not emit `style="..."`, `onclick="..."`, `onchange="..."`, or `javascript:` URLs in `.apx`, regions, or Template Components. Bind behavior with buttons, Dynamic Actions, or declarative actions. Theme placeholders such as `#JAVASCRIPT#` are substituted by APEX and are not hand-written page code. The one exception is a throwaway prototype under `working/design-preview/`, which may use inline CSS variables; it must never be pasted into a page.
7. **Deterministic `staticId`.** Every component that supports `staticId` gets a stable, semantic, lowercase kebab-case ID. Use it for navigation, JavaScript, Dynamic Actions, and tests. Do not rename it after implementation.
8. **Accessible by default.** Every input has a label, every image has alt text or is decorative, status is not conveyed by color alone, dialogs have a title and cancel path, and keyboard operation is preserved.
9. **Designer does not edit `.apx`.** Produce the design package and hand off; implementation and validation belong to `apex`.

## 3. Theme and style selection

- Use Universal Theme. Read `theme.md` and `style.md` in the target inventory before naming a base theme or style.
- In 26.1 and 26.2 the inventory enumerates the supported styles: `Vita`, `iris`, `redwood-light`, `vita-dark`, `vita-red`, and `vita-slate`. Treat that list as the closed set; do not add a style name from a blog post or prototype.
- Bind the theme with the version's contract: `baseTheme` (for example `ut-26.1` or `ut-26.2`) and `currentThemeStyle`. Do not use a stale theme `version` field as a substitute.
- Select one style for the application. Do not mix style traits, and do not copy hex values from external research, screenshots, or prototypes.
- Prefer Theme Roller variables and Universal Theme tokens. If custom CSS is genuinely required, justify it, scope it, and use `var(--ut-*)`, `var(--a-*)`, or `color-mix(in srgb, var(--ut-...), ...)` instead of hardcoded hex.
- Verify any CSS variable or token against the target instance or the version's documented output before shipping. If the target instance is unavailable, label the choice as an assumption.

### 3.1 Visual prototype mode

Use this mode when the user asks for a mockup, a screenshot recreation, a "make it look like" exploration, or a style comparison. The prototype communicates the look; it is not the application.

- Write the prototype to `working/design-preview/<name>/` as standalone HTML/CSS. Never write it into `.apx`, a Static Content region, or a Template Component.
- Start from the vendored Universal Theme 42 assets:
  - `assets/universal-theme-42/tokens/` — baseline and style deltas.
  - `assets/universal-theme-42/components-reference.md` — authentic class and markup patterns.
  - `assets/universal-theme-42/upstream-skill.md` — token layers and Theme Roller derivation.
- Load exactly one baseline plus at most one delta, or one standalone style file. Never combine deltas. Map upstream file names to inventory style names: `vita-light` → `Vita`, `vita-dark` → `Vita - Dark`, `vita-red` → `Vita - Red`, `vita-slate` → `Vita - Slate`, `iris` → `iris`, `redwood` → `redwood-light`. Confirm the active style in the target app.
- Use `var(--ut-*)` and `var(--a-*)` for color, spacing, and surfaces. Do not hand-pick hex values. For a custom brand style, produce the `@g_*` `.less` file and a reviewed CSS preview, then verify it in Theme Roller.
- Token values in the vendored assets are an independent, hand-derived reference, not Oracle's compiled output. Verify contrast and computed values in a browser or the target instance.
- After the user approves the prototype, translate it: choose the native region type, items, buttons, and template options from the target inventory; apply the `staticId` plan; discard the prototype HTML.
- State in the handoff whether the prototype was approved, rejected, or not reviewed.

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
- Keyboard focus order follows the visual order.
- Dialogs have a title, a primary action, and a cancel path.
- Use logical layout properties or Universal Theme utilities so the page survives RTL rendering.
- Select only displayed columns. Add filters, pagination, or a bounded query to any large report.
- Lazy-load secondary tabs and heavy regions where the version supports it.
- Keep page processes thin: call a package API rather than embedding multi-table logic.

## 9. Handoff package

Return this package, in order:

1. **Design brief** — problem, actors, goals, assumptions, open questions.
2. **Style decision** — base theme, style, and why; custom CSS only with justification.
3. **Visual prototype** — path under `working/design-preview/`, status (approved, rejected, not reviewed), and the style file used. Omit when no prototype was requested.
4. **Page map** — per section 4.
5. **Component map** — per section 5, with the native primitive for each region.
6. **Template and template-option decisions** — exact names from the inventory.
7. **`staticId` plan** — per section 7.
8. **Acceptance criteria** — what a reviewer can check on the running page.
9. **APEXLang file map** — pages and shared components to create or change.
10. **Risks and unknowns** — what could not be verified without the target instance.

Then hand off:

- Architecture, data model, or PL/SQL questions → `apex-planner`.
- Implementation and validation → `apex` using `skills/apex-delivery/SKILL.md`.

## 10. Design review checklist

- [ ] Version is 26.1 or 26.2 and every referenced component exists in that inventory.
- [ ] Page numbers, purposes, and row plan match `requirement.md`.
- [ ] One style, bound through `baseTheme` and `currentThemeStyle`.
- [ ] No raw HTML layout, no second CSS framework, no inline styles or handlers in deployable markup.
- [ ] Any prototype is under `working/design-preview/`, uses one style file, and is not referenced by the app.
- [ ] The approved prototype was translated to native components; no prototype HTML was copied.
- [ ] Every region maps to a native primitive or a justified `staticContent` placeholder.
- [ ] Every template and template option is declared in the inventory.
- [ ] Every supported component has a stable `staticId`.
- [ ] Labels, alt text, keyboard path, and dialogs are designed.
- [ ] Every page has an empty state and an error state.
- [ ] Handoff names the implementer and the validation gate.

## Reference map

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
