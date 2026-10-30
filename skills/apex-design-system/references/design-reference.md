# Design Reference: Designing From a Website the User Likes

When the user gives a reference website ("make it feel like https://…"), that site is the strongest
design input you have. Adjectives such as "modern" or "playful" are guesses; a reference site is
evidence. This reference turns a URL into an APEX look the user will recognise, through tools that
produce the same result whichever model runs them.

Use it whenever `requirement.md` has a **Design reference** URL, or the user names one in the request.
It applies to new apps and redesigns.

## 1. Authority

The reference sits second in the brand-layer authority order (`brand-layer.md` §1):

1. Explicit user values (hex, fonts, radii) in `requirement.md` or the request.
2. **The design reference**: its measured colours, type character, shape, depth, density, and rhythm.
3. Accessibility (WCAG 2.2 AA): keep the reference colour, adjust its *usage*. The kit does this.
4. The target version's inventory for every APEX name.
5. Universal Theme defaults, for everything the reference does not show.

The rule "do not copy hex values from external research or screenshots" exists to stop the agent
from inventing a palette from a blog post. It does **not** apply to a reference the user chose:
the reference's colours are the point. Picking the "closest stock style" instead of the reference
palette is a requirement miss.

## 2. The pipeline

The look is generated, not hand-written. Every step prints a pass word; do not continue without it.

```bash
# 1. Capture: screenshots + measured style DNA
node scripts/capture-design-reference.mjs --url <reference-url>
#    -> working/page-design/design/reference/   REFERENCE CAPTURED

# 2. Generate the brand kit: decisions (brand-kit.json) + complete brand.css
node scripts/build-brand-kit.mjs --reference working/page-design/design/reference/reference.json
#    -> working/page-design/design/brand/       BRAND KIT PASS

# 3. Ship an open-licence font (weights as the kit asks), then rebuild
node scripts/fetch-open-font.mjs --family "<font.family>" --weights 400,500,600,700 --out working/page-design/design/brand/fonts
node scripts/build-brand-kit.mjs --kit working/page-design/design/brand/brand-kit.json

# 4. Render this app's screens from a content spec (no HTML by hand)
node scripts/render-design-prototype.mjs --print-example > working/page-design/design/prototype-spec.json   # then edit the content
node scripts/render-design-prototype.mjs --brand working/page-design/design/brand --spec working/page-design/design/prototype-spec.json --out working/design-preview/<name>

# 5. Score: 85+ and no blocker, with a fix for every failed check
node scripts/score-design.mjs --preview working/design-preview/<name> --kit working/page-design/design/brand/brand-kit.json
#    -> working/design-preview/<name>/score/    DESIGN SCORE PASS
```

Iterate by changing `brand-kit.json` (or the spec) and re-running steps 2 (with `--kit`), 4, and 5.
Never edit the generated `brand.css`; the delivery gate rejects an app `brand.css` that differs from
the kit.

If the capture fails (bot protection, login wall, consent wall), say so, ask the user for a
screenshot, and do not guess the look from the domain name.

## 3. What each tool decides, and what you decide

| Decision | Made by | You check |
| --- | --- | --- |
| Colour roles (brand vs action vs neutrals) | `build-brand-kit.mjs` from the capture: the brand colour from header/nav/area, the action colour from the largest repeated **content** buttons (header utilities are discounted) | `colors.primary` and `colors.action` against the screenshot. Swap them in `brand-kit.json` if the reference uses them the other way round. |
| Contrast-safe variants (text shades, button labels, status tints) | The kit, automatically; `kit-report.md` lists every pair | Nothing; a failing pair exits non-zero. |
| Every Universal Theme variable and the hard-coded Vita rules (hot buttons, nav state) | The kit, checked against the real APEX theme CSS index | Nothing. |
| Font | The kit: keeps an open-licence reference font, otherwise substitutes the closest open match (table in the script) | Character match. Change `font.family` if a closer OFL font exists, then fetch it. |
| Heading weight, radius, button shape, depth, header and nav style | The kit, from measurements | Compare with the screenshot; adjust `font.headingWeight`, `shape`, `depth`, `header.style`, `nav.style`. |
| Page content in the prototype | You, in `prototype-spec.json` from `requirement.md` | Real labels and plausible data, not lorem ipsum. |
| Pass or fail | `score-design.mjs` | Open `compare-desktop.png` and `design-mobile.png` before reporting. |

## 4. Read the reference like a designer

Fill in the bottom of `style-dna.md` and the **Design reference** section of `application-design.md`:

- **Character in one sentence.** For example: "Warm, confident, food-retail: white ground, one hot
  brand red for wayfinding, a sunny yellow for the main call to action, chunky bold headings, soft
  rounded cards with a gentle drop shadow."
- **Signature element.** The one thing that makes it recognisable (a bold coloured header bar, an
  oversized heading, a yellow pill CTA). Make sure the kit carries it.
- **Borrowed / not copied** (see §5) and the **font substitution**.

## 5. What to borrow and what never to copy

| Borrow (the look) | Never copy (the property) |
| --- | --- |
| Colour values and their roles | Logos, wordmarks, mascots, trademarked symbols |
| Type character, scale, weights, case | Proprietary font files (the kit substitutes an open-licence font) |
| Radius, shadow, border language | Photography, illustrations, icons from the site |
| Spacing rhythm, density, content width | Marketing copy, product names, slogans |
| Button and badge shape | HTML, CSS, JavaScript, class names |
| Header/nav treatment | Layouts that make the app pass as the reference company's own product |

The app must look *inspired by* the reference, never like it is the reference company's product.
Use the user's own app name and logo (or none).

## 6. Translate to APEX

An APEX app is a data application: header, navigation, regions, reports, forms, buttons. A marketing
site has heroes and promo tiles. Translate the *language*, not the layout. The kit already maps the
language onto Universal Theme; the page design still has to use it:

- The main action on each page is a **hot** button; everything else is default or simple.
- Status uses badges with text and an icon, never colour alone.
- KPI strips are one grouped cards/metric region; reports are Interactive or Classic Reports.
- A hero region only where the requirement asks for one; never stock photography.

## 7. Failure modes the tools catch, and the ones they do not

Caught by `score-design.mjs` or the delivery gate: stock Vita header, blue hot buttons, charcoal nav,
system font, missing brand.css, contrast failures, brand colour overuse, overflow on mobile,
variables APEX never reads, a hand-edited brand.css.

Not caught (look at the screenshots): copying the reference's homepage layout into a data app,
placeholder content, a prototype that shows different screens from the requirement, a signature
element that got lost.
