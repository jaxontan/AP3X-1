# Design Craft: What Good Looks Like in an APEX App

The scorecard tells you whether a design passes. This file tells you how to make it good. Read it
before every visual decision. It applies with or without a design reference.

## 1. The bar

A good business app looks **intentional**: someone chose the colours, the type, the spacing, and
the one thing that makes it memorable. A bad one looks like the defaults plus a colour swap.

Before handing off, ask: if the user saw this next to the reference site (or next to a polished
SaaS product), would they say it belongs in the same league? If not, keep going.

## 2. Why APEX apps look generic, and the levers that fix it

Stock Universal Theme signals "default APEX" through a handful of surfaces. Changing the accent
colour alone leaves all of them in place. Work the levers in this order; the first five carry
most of the look.

Levers 1-8 are set by the brand kit (`scripts/build-brand-kit.mjs`) from the decisions in
`brand-kit.json` (`header.style`, `nav.style`, `colors`, `font`, `shape`, `depth`); change the
decision and rebuild, never the CSS. Levers 9-10 are page design: they live in the page map and
the prototype spec. `scripts/score-design.mjs` measures most of them.

| # | Lever | Default tell | Fix through |
| --- | --- | --- | --- |
| 1 | Header | Generic coloured bar, small logo text | `--ut-header-*` tokens: brand or neutral ground, real height, one clear shadow or border |
| 2 | Page ground vs surfaces | Flat grey body, grey-bordered regions | `--ut-body-background-color` + `--ut-region-*`: deliberate ground/surface contrast, one depth language (shadow *or* border, not both) |
| 3 | Typography | System font, thin small headings | `--brand-font-ui` on `body`; heavier, larger region and page titles via `brand-*` classes |
| 4 | Primary action | Default hot button | `--ut-palette-primary` + `--a-button-*` radius/padding matching the reference shape |
| 5 | Region chrome | Every region has a header bar, border, and icon | Remove chrome where content speaks for itself (template options), keep it for real panels |
| 6 | Navigation | Dense tree with default icons | `--ut-body-nav-*` / `--ut-header-menubar-*`; fewer, clearer entries |
| 7 | Reports | Default grey header row, tight cells | `--ut-report-*` / `--a-gv-header-*`; quieter header, 40px rows, right-aligned numbers |
| 8 | Status | Coloured text only | Pill badges with text and icon (`t-Badge`, `brand-pill`) |
| 9 | Empty states | "No data found" | A sentence and a next action |
| 10 | Home page | A stack of equal-width regions | Hierarchy: a title zone, a KPI row, then the work |

Only use variables present in `assets/universal-theme-42/tokens/` or verified on the target
instance.

## 3. Colour

- **60/30/10.** About 60% ground, 30% surfaces and neutrals, 10% brand. Brand colour is for
  wayfinding (header or nav), the primary action, and status. Never paint every region.
- **One primary action colour per screen.** If the reference has two brand colours, give each a
  job (for example red = brand/header, yellow = call to action) and keep the jobs consistent.
- **Neutrals carry the app.** Ink near `#1A1A1A`–`#333333`, muted text at 4.5:1 or better, borders
  barely visible. Tint the neutrals slightly toward the brand hue if the reference does.
- **Contrast is non-negotiable, the colour is too.** If a brand colour fails 4.5:1 for text, keep it
  for fills, borders, and large text, and derive a darker text-safe shade.

## 4. Typography

- At most two families; usually one is enough.
- A clear jump between levels: for example 32 / 24 / 18 / 15–16 / 13. Headings 600–800 weight,
  body 400, numbers tabular in reports.
- Line height 1.4–1.6 for body, 1.1–1.25 for headings. Tighten heading tracking slightly when the
  font is heavy.
- Measure 45–75 characters for paragraphs; data screens can run wider.

## 5. Space and density

- One spacing scale (4/8 px base). Section gaps 24–32 px, panel padding 16–24 px.
- Align everything to a few vertical edges. Ragged left edges look amateur faster than any colour.
- Data apps are denser than marketing sites. Keep the reference's *feel* (generous or tight) but
  do not copy hero-sized padding into a report page.

## 6. Shape and depth

- One radius family (for example 6 / 10 / 999 for inputs / cards / pills). Match the reference.
- One depth language. Soft shadow cards on a white ground, *or* flat panels with hairline borders
  on a tinted ground. Mixing both looks unfinished.
- Shadows are soft and low-contrast: `0 1px 2px` plus a wider, fainter blur.

## 7. The generic-AI tells to avoid

- Identical rounded cards in a 3-column grid for everything.
- Purple or blue gradients that no requirement asked for.
- ALL-CAPS eyebrow labels over every heading.
- Emoji or decorative icons on every region title.
- An accent colour applied to every surface.
- Hover animation on every card.
- Placeholder copy such as "Lorem ipsum" or "Welcome to your dashboard!".

## 8. Self-review before handoff

Open the rendered screenshots (desktop and mobile) and answer in the brief:

1. What is the primary action on each key screen, and is it the most prominent element?
2. Which of the ten levers in section 2 did you change, and which did you leave as default and why?
3. With a reference: the five biggest differences from the reference screenshot, and which you fixed.
4. What would a senior product designer change next? Fix it if it is within scope.
