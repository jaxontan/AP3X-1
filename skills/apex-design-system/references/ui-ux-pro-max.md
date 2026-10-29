# UI UX Pro Max: Direction-Only Integration

Optional external design bank: [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill), MIT License.

Use it to widen the **design direction** search, not to generate APEX markup. It is not part of the harness runtime and is not required for validation.

## Use for

- Product-type language: SaaS, fintech, healthcare, public sector, logistics, education, support desk.
- Style names and mood: minimal, editorial, data-dense, calm, utilitarian, warm.
- Palette roles and colour mood, before any APEX token mapping.
- Typography mood, font pairing ideas, and density expectations.
- Anti-patterns and UX guidelines.
- A second opinion when the requirement is visually underspecified.

Record in the design brief:

```text
Direction source: UI UX Pro Max (MIT), <style or palette name>
Borrowed: <palette mood / style cue / anti-pattern>
Not borrowed: HTML, CSS, Tailwind, React, fonts, animation, or component code
```

## Do not use for

- APEX component, template, template-option, or property names. The version inventory is the only source of truth.
- Generated HTML/CSS/JS, Tailwind, React, shadcn, or page markup. None of it belongs in `.apx`, a Static Content region, or a Template Component.
- CDN font imports, icon packs, animation libraries, or a second CSS framework.
- Copying hex values directly into deployable Theme Roller CSS or `.apx`.
- Claiming contrast, accessibility, responsiveness, or APEX fit without browser and inventory evidence.

## Translation rule

1. Use the bank to choose one visual idea and a 4-6 role palette.
2. Map the roles to a supported Universal Theme style, or to a custom Theme Roller `@g_*` style with explicit approval.
3. Use `var(--ut-*)` and `var(--a-*)` in prototypes; do not hand-pick deployable hex.
4. Run the design scorecard before and after.
5. Verify the result with `scripts/verify-design-preview.mjs` and the target APEX inventory.
6. Discard the prototype. Implement only native templates, components, and options.

If the external bank is unavailable, use the local role-based `palette-bank.md`. It is a starting point, not Oracle output and not a substitute for contrast testing.
