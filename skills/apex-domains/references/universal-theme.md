# Universal Theme and APEX UI Design

Use this reference when a page map becomes APEXLang. The version-specific `apexlang-inventory` and `apexlang-example-applications` remain authoritative for component names, template options, and exact syntax. This reference is the design contract.

## 1. Theme baseline

- Use Oracle APEX Universal Theme (Theme 42) as the structural base, with the closest supported stock style.
- Universal Theme is the floor, not the ceiling. When the user asks for a custom or nicer look, or `requirement.md` gives design direction, implement it with the brand layer in `skills/apex-design-system/references/brand-layer.md` (`brand.css` tokens mapped onto `--ut-*` variables, `brand-*` classes, optional custom theme style). Falling back to a stock style instead of the requested look is a requirement miss.
- Do not import Bootstrap, Tailwind, or another CSS framework. APEX already ships a supported design system, and a second framework creates conflicts and upgrade risk.
- Do not build a custom grid when Universal Theme layout or `u-*` utility classes can express the design.
- Keep custom CSS in `brand.css`, token-driven and prefixed `brand-`; keep custom JavaScript small, named, and justified in the page map.

## 2. Templates and references

- Reference page, region, button, and dialog templates with the APEXLang `@/...` syntax used by the target version, for example `@/standard` or the exact name in the inventory.
- Do not invent a template name or a template option. Confirm it in the version's inventory or working example.
- Use component references (`@component-static-id`) for shared authorizations, LOVs, and regions. Do not duplicate a shared component inline.
- Prefer native region types and template options over custom HTML. A region that only exists to hold a hand-written grid is a design smell.

## 3. Layout and utility classes

- Use Universal Theme utility classes such as `u-flex`, `u-color-*`, `u-text-*`, `u-padding-*`, and `u-gap-*` for small adjustments.
- Use template options for spacing, alignment, and appearance before writing CSS.
- For a dashboard, define the row plan explicitly: one two-up row followed by one three-up row is a common deterministic layout for five cards or charts. Do not rely on an arbitrary sequence of equal-width regions.
- Do not use inline `style="..."` attributes in generated markup. They bypass the theme, are hard to audit, and often break responsive behavior. Put the rule in `brand.css` and attach a class through `cssClasses`.
- Test at narrow and wide widths. A page that only works at desktop width is not complete.

## 4. Accessibility

- Every input has a visible or programmatically associated label. Do not use a placeholder as the only label.
- Every image has meaningful alternative text, or is marked decorative when it conveys no information.
- Do not rely on color alone for status. Pair color with text or an icon.
- Interactive controls are reachable and operable by keyboard.
- Error messages identify the field and the corrective action, not just "Invalid value."
- Dialogs have a clear title, a primary action, and a cancel path.

## 5. Compiler-truth rules

The vendored 26.1 generation skill includes rule IDs and repair recipes. The critique checklist is at `skills/apex/apexlang/26.1/apexlang-generation/references/workflows/apex-generation/agents/30-agent-critique.md`; machine-readable repairs are in `assets/validator-fix-recipes.json`. Apply at least these when relevant:

- `METRIC_CARD_STANDARD_TEMPLATE_FORBIDDEN_001` — do not wrap a dashboard Metric Card in the standard region template.
- `SMART_FILTER_RESULTS_REGION_REQUIRED_001` — a Smart Filter or Faceted Search must bind to a results region.
- `INTERACTIVE_REPORT_LINK_COLUMN_TYPE_FORBIDDEN_001` — use the declarative link target rather than a legacy link column type.
- `CLASSIC_REPORT_HIDDEN_COLUMN_HEADING_FORBIDDEN_001` and `CLASSIC_REPORT_COMPONENT_APPEARANCE_REQUIRED_001` — hidden Classic Report columns need the required appearance handling.
- `DASHBOARD_LAYOUT_ROW_PLAN_REQUIRED_001` — dashboard row placement must be deterministic.
- `SQL_PLSQL_LOB_COMPARISON_KEY_FORBIDDEN_001` — do not use a LOB or JSON column in `DISTINCT`, `GROUP BY`, `ORDER BY`, or a key comparison that raises `ORA-22848`.

Do not copy a rule ID from this document into a validation message without checking the version's recipe. Rule IDs can change between APEXLang releases.

## 6. Data and performance

- Page regions should select only the columns they display. Do not use `SELECT *` in a published page.
- Use declarative filters, pagination, and server-side conditions where possible.
- A report that loads a large table without a filter, pagination, or a bounded query is not production-ready.
- Put row-level authorization in the query or a package API, not only in a button condition.
- Use an Interactive Report link only when the link target and authorization are explicit.
- Keep page processes thin: read items, call one package operation, map the result to a page message.

## 7. Validation gate

Before calling a page done:

1. Confirm every page, region, button, and process has the intended authorization.
2. Confirm every interactive item has a label, help text where needed, and an error state.
3. Run `scripts/validate-apex-app.ps1 -AppDirectory <app>` and require `Validation successful`.
4. If the 26.1 generation runtime is available, run `apexctl.mjs apexlang validate --app-path <app>` from the generation skill root and resolve blocking problems.
5. Review the page at a narrow width and with keyboard navigation.
6. Report what was verified and what still requires a browser or commercial-environment test.
