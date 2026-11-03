# Creative Direction: Designing Like a Product Designer, Not a Theme Picker

`craft.md` is the floor: contrast, spacing, one depth language. This file is the ceiling. A design is
good when someone can describe its idea in one sentence, it shows the user's real situation, and it
still looks like the concept after it is built in APEX. A colour swap of stock Universal Theme has no
idea; a beautiful concept built on numbers the database does not have is a lie; a concept that
breaks when real text arrives was never finished.

Creativity here means **ideas about composition, emphasis, and character**, expressed through native
APEX structure plus the concept's own `brand-*` components. It never means copying the reference
site, inventing data, or decorating every surface.

## 1. The loop and its gates

```text
Data reality -> Brief -> Diverge (3) -> Render -> Critique -> Revise -> Board -> User picks
  -> Converge (kit + page map) -> Approval -> Build -> Deploy -> Live score + compare -> Fix
```

| Step | Output | Gate (the tool refuses to continue without it) |
| --- | --- | --- |
| Data reality | What the tables really hold | Board: `brief.md` has `## Data reality` |
| Brief | People, jobs, first-seen element per page, the reference's moves, forbidden words | Render: `brief.md` exists; board: `**Forbidden words:**` line |
| Diverge | Three concept folders | Render: `concept.md` has Big idea, Signature moves, Axes, APEX mapping |
| Render | Screenshots, axe, tells, text-spill check | `CONCEPT RENDERED` (zero blockers) |
| Critique and revise | Logged rounds in `concept.md` | Board: 2+ rounds, no placeholder, tells answered |
| Board | Side-by-side concepts | `BOARD RENDERED`: 3+ concepts that differ on 2+ axes |
| Converge | App kit, `application-design.md` page map | User approval (project rule) |
| Build and deploy | `.apx`, packages | `Validation successful`, `-WhatIf`, explicit target approval |
| Verify | Live screenshots and score | `DESIGN SCORE PASS` on the deployed pages, `DELIVERY GATE PASS` |

Commands: `node scripts/render-design-concept.mjs --concept <dir>` and `--board <concepts-dir>`.
Kit per concept: `node scripts/build-brand-kit.mjs --kit <concept>/brand-kit.json`.

## 2. Data reality first

The most expensive mistake is a concept that promises facts the database does not have ("due 14
Nov", "Op 20 at 104%" when orders have no due date and cells have no capacity). Before any concept:

1. Find what the pages read: the SQL in the existing `.apx` files (`grep -i "from\|join"`) and the
   live data dictionary, **read-only**. `working/database/*.sql` can be out of date; the live
   schema wins. If you cannot query the database, ask the user or the implementer and write the
   gap down as an assumption.
2. Write `## Data reality` in `concepts/brief.md`: the real tables and columns, what each page can
   honestly show, and **what it may not promise** (missing columns, missing limits, no history).
3. Prefer facts the data supports that still tell a story: a shortage ("−242 Picatinny") and hours
   of work queued are as dramatic as a due date, and they are true.
4. Every concept page declares its data in front matter: `"data": "sample"` (illustrative numbers;
   the render shows a "Sample data" ribbon) or `"data": "real"` with a `"dataSource"`. Before
   converging, render the chosen home page once with real numbers (`"data": "real"`); real data is
   longer, uglier, and more honest than mock data.

## 3. Write the brief

`concepts/brief.md`, once, shared by all concepts:

- **People and moments.** "The planner opens this at 07:30 to see which orders cannot be built from
  stock." Not "users manage orders".
- **Per page: the one job, the first thing seen, the main action.** No first-seen element means no
  hierarchy yet.
- **The reference's character** in one sentence, and 3-5 transferable moves. A move is a technique
  (full-bleed colour band, oversized numerals, white pills on colour), never an asset.
- **Must not transfer:** the reference's name, logo, images, copy, font files, and its domain. The
  app keeps its own name and vocabulary. If the reference sells cookies and the app plans rifle
  production, no page mentions cookies.
- `**Forbidden words:** brandname, product1, product2, ...` on one line: the reference's brand and
  product words. The renderer blocks them in every page.

## 4. Diverge: three concepts that are genuinely different

Each concept folder `concepts/<slug>/` holds `concept.md`, `shell.json`, `brand-kit.json`,
`components.css`, `fonts/`, and `pages/<page>.html` for 2-3 key pages. `concept.md` opens with:

```markdown
# Poster Floor
**Big idea:** One sentence a stranger could repeat.
**Signature moves:** 2-3 techniques that carry the idea.
**Borrowed from the reference:** ...
**Not borrowed:** name, product words, copy, images, logo, font files.
**Axes:** composition = poster bands; emphasis = one heroic number; colour = one colour field; type = oversized heavy display; density = airy; chrome = top navigation
```

The three must differ on **at least two axes** (the board checks the `**Axes:**` lines):

| Axis | Range |
| --- | --- |
| Composition | Command-centre board, editorial column, poster bands, split workbench, timeline-first |
| Emphasis | Numbers as heroes, the work queue as hero, the timeline as hero, the exception as hero |
| Colour | One confident colour field, neutral with a single accent, dark canvas with lit data, colour-coded categories |
| Type | Oversized condensed display, quiet grotesk with tabular numerals, editorial contrast of sizes |
| Density | Airy and calm, dense operator view |
| Chrome | Side nav, top nav, no title bar (the hero carries the title) |

A mix of two concepts (after the user's choice) declares `**Mix of:** a + c` and is exempt from the
divergence check.

### Signature moves (inspiration, not a menu)

- **The band.** A full-width colour field with the page's one fact and its main action.
- **Heroic numerals.** One number at 4-6x body size with a sentence saying why it matters.
- **Status as colour blocks.** The one problem is a solid block; everything else stays neutral.
- **The production strip.** Stages as connected blocks; the bottleneck filled.
- **Exception first, as tickets.** Each decision is a card with the suggested fix and one action.
- **Editorial split.** A narrow column with a sentence that explains the situation; work on the right.
- **Dark canvas, lit data.** Ink ground; each category owns one bright flat colour.
- **Hairline grid.** No cards; a visible 1px grid like a technical drawing.

Colour has meaning or it is noise: decide what each colour means ("red = problem, cobalt = action")
and keep it on every page.

### Things that are not ideas

Outlining every card in the brand colour. A grid of identical tiles. A gradient nobody asked for. An
icon on every heading. Hover lift on every card. ALL-CAPS everywhere. The renderer detects some of
these as tells; the critique must answer each one.

## 5. Composing pages

`pages/<slug>.html` is the body of the page only:

```html
<!-- page: {"title": "Home", "data": "sample", "chrome": {"titleBar": false}} -->
<section class="brand-band" aria-labelledby="hero">
  <p class="brand-eyebrow">Latest plan · saved 12 Oct</p>
  <h1 class="brand-display" id="hero">14 of 32 orders can't be built</h1>
  <a class="t-Button t-Button--hot brand-pill brand-pill--light" href="#"><span class="t-Button-label">Re-plan</span></a>
</section>
<div class="row"><div class="col col-8">...</div><div class="col col-4">...</div></div>
```

- `shell.json`: app name (the app's own), user, nav (`{ "label", "icon", "page" }`), chrome.
- **Allowed:** Universal Theme classes (`t-`, `a-`, `u-`, `fa-`, `row`, `col-*`), `brand-*` classes,
  semantic HTML (including `blockquote`, `meter`, `dl`), simple inline SVG.
- **Blocked by the renderer:** inline `style`, `<style>`, `<script>`, handlers, colour literals in
  markup, remote images, forbidden words, unnamed buttons, missing data declaration, horizontal
  overflow at 390px, **text spilling out of its box**, serious axe violations.
- Align every section to the same grid: wrap full-width sections in `row` / `col-12` when others use
  columns, or their left edges will differ by the column gutter.

### Stress the content before you critique

Mock text is short and friendly; real text is not. On at least the home page, use the **longest
real** values: the longest product or report name, raw codes (`SAKO-S20-PREC-308`), a five-digit
quantity, the lowercase customer name the data really contains. Button labels in fixed-width boxes
(ticket stubs, cards) stay at two short words ("Fix shortage", not "Fix in capacity check").
Design the empty state ("No plan yet") and the all-clear state ("All 32 orders can be built") as
deliberately as the problem state.

### Components: `components.css`

- Colours only through tokens (`var(--brand-*)`, `var(--brand-accent-*)` from `colors.accents` in
  the kit, `color-mix(in srgb, var(--brand-primary) 12%, transparent)`). Literal colours are rejected.
- Name by role: `brand-band`, `brand-stage--hot`, `brand-ticket__stub`. BEM elements (`__`) and
  modifiers (`--`) are fine; the base class needs an APEX mapping row.
- Links styled as buttons (`a.t-Button`) need `display: inline-flex; align-items: center` or their
  label sits high; style the `a.brand-pill.t-Button` case explicitly.
- Native `meter` needs token colours on `::-webkit-meter-*-value`, and `low`/`high`/`optimum` set so
  the bar colour agrees with the status chip next to it.
- Scroll containers (`overflow: auto`) get `role="region"`, an `aria-label(ledby)`, and `tabindex="0"`.
- A poster concept that paints a large brand-colour field declares `"expression": {"colourField": true}`
  in its kit, so the numeric score judges the field as intended.
- Every `brand-*` class needs a row in `## APEX mapping` saying where it attaches.

## 6. Critique (in `concept.md`, after opening every screenshot)

1. **One sentence** from the screenshot alone. Does it match the big idea?
2. **Five-second test.** What does the eye land on first, on each page? Is that the page's job?
3. **Template test.** Cover the logo: could this be any APEX app with a colour swap?
4. **Restraint test.** Name one thing you removed.
5. **Truth test.** Is every number backed by the data reality? Sample numbers are labelled.
6. **Reference test.** Beside the reference screenshot: the closest move and the biggest miss.
7. **Tells.** Answer every tell in `report.md`: fixed, or why it is right here (write the word "tell").
8. **Mobile.** Does the hero still lead at 390px?
9. **Senior designer.** What would they change next? Change it, re-render, log the round.

```markdown
## Critique
### Round 1
- First seen: ... / Template test: ... / Removed: ... / Tells: ...
- Changed: ...
### Round 2
- ...
```

Two rounds minimum. The board refuses concepts without them.

## 7. Present, then converge

Render the board and show it with, per concept: name, big idea, strongest screen, the honest
trade-off, and a recommendation. Mark sample data as sample. The user picks one or a mix; a mix is a
new concept folder (`**Mix of:**`) that is rendered and critiqued like the others.

Converge:

1. Copy the chosen `brand-kit.json` and `components.css` to `page-design/design/brand/`, rebuild,
   and render the chosen home page with real data.
2. Write `application-design.md`: the page map, the component map from the APEX mapping table, the
   data sources, and open questions. **Stop for approval.**

## 8. Translating to APEX: the traps that broke real builds

| Trap | Do this |
| --- | --- |
| Theme style Iris or Redwood loads after `brand.css` | `currentThemeStyle: @/Vita` (the gate checks) |
| Band placed in the Breadcrumb Bar slot | The title bar is sticky and JS-positioned; put the band in the **Body** slot as the first region |
| Band on a modal dialog page | Dialogs have no `body` slot and no room for a poster; no band |
| Numbers typed into the page | A Dynamic Content region calling a PL/SQL package; every value through `apex_escape.html`; links through `apex_page.get_url` |
| A page item drives the band but defaults to null | Give the item a default (for example the latest plan) so band and reports agree; add the band to the item's refresh action |
| Installing the package with SQLcl | `set define off` first (an `&` in a string swallows the next input line); pipe the script in as `deploy-apex-app.ps1` does |
| Top navigation | `navigationMenu { listTemplate: @/top-navigation-menu, listPosition: top }`; the real menu bar markup differs from the concept shell, so check its spacing live |
| Existing reports scroll on mobile | Make the scrolling container focusable (page JS adding `tabindex="0"` after load and after refresh) |
| Old `brand-*` classes on other pages | Map them into `components.css` or replace them; the gate fails on undefined classes |

## 9. Verify the live app against the concept

After deployment (with approval):

1. Score the deployed pages, logged in:
   `node scripts/score-design.mjs --url <app-url>/<page> --kit page-design/design/brand/brand-kit.json --user <user> --out working/design-preview/deployed/<page>`.
2. Open the live desktop and mobile screenshots beside the concept screenshots and list every
   difference. Fix, redeploy, rescore. The prototype score never stands in for the live one.
3. Tell the user to hard-refresh (Ctrl+F5): `brand.css` is cached by its version label.
