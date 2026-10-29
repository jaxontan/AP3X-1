# Design Quality Scorecard

Use this scorecard before and after a redesign. It makes "better" measurable without replacing the requirement, APEX inventory, or runtime verification. Score the same content at the same viewports both times.

## 1. Scoring scale

Score each dimension from 0 to 5.

| Score | Meaning |
| --- | --- |
| 0 | Missing or actively harmful. The design cannot ship. |
| 1 | Major gaps; the problem is visible without close inspection. |
| 2 | Some intent, but inconsistent or unreliable in common states. |
| 3 | Acceptable baseline; noticeable gaps remain. |
| 4 | Strong, consistent, and evidenced; only minor polish remains. |
| 5 | Exceptional and defensible; the choice is clearly right for this product and survives mobile, keyboard, and error states. |

Every score of 3 or below needs a concrete finding and a fix. "Looks better" is not evidence.

## 2. Dimensions and quality bars

| Dimension | Quality bar | Evidence |
| --- | --- | --- |
| Hierarchy | One clear page job and primary action; no more than three visual levels; a new user can find the next action in five seconds. | Screenshot at desktop and mobile; annotated primary action. |
| Spacing | Use the Universal Theme spacing scale or a 4/8 px base. Section gaps target 32 px desktop and 24 px mobile; card or panel padding 16-24 px; page gutters 24-32 px desktop and 16-20 px mobile. Avoid arbitrary 13/17/23 px gaps. | Screenshot; spacing table for the main regions. |
| Typography | At most two families. Use five or six sizes from a restrained scale, for example 12/14/16/20/24/32. Body text is 16 px desktop and 15-16 px mobile; line height 1.45-1.6; measure 45-75 characters; numbers align in tables. | Computed font sizes and line heights; screenshot. |
| Colour and contrast | Four to six named roles: ground, ink, accent, surface, border, status. Normal text meets WCAG 2.2 AA 4.5:1; large text and non-text UI/focus indicators meet 3:1. Status is never conveyed by colour alone. Dark mode is checked when offered. | Axe color-contrast results plus manual contrast check for custom pairs. |
| Density and responsive fit | Data-table rows target 36-44 px; form controls target 40-48 px; pointer targets are at least 24x24 px, with 44x44 px preferred. No horizontal overflow at 390 px. Content width stays within 1200-1440 px on large screens unless the page needs a full-width workspace. | Desktop and mobile screenshots; overflow result from the verifier. |
| States | Hover, focus, active, disabled, loading, empty, error, and success are all designed. Focus is visible without relying on colour alone. Reduced motion is respected. | State inventory; keyboard walkthrough; verifier axe results. |
| Accessibility | No serious or critical axe violations; labels are programmatic; keyboard order follows visual order; dialogs have a title and cancel path; page remains usable at 200% zoom. | `verify-design-preview.mjs` report plus manual keyboard and zoom check. |

Targets are design review ranges, not APEX syntax. If the target instance or a native template has a documented value, that value wins. Do not invent a token or hardcode a colour in `.apx`; brand colours live only in the `brand.css` token block (`skills/apex-design-system/references/brand-layer.md`).

## 3. Before/after protocol

1. Freeze the prototype content and the two evidence viewports: desktop 1440x900 and mobile 390x844.
2. Score the **before** state before editing. Record the seven dimension scores and the evidence path.
3. Build the direction and prototype.
4. Run the visual verifier on the same content:
   `node scripts/verify-design-preview.mjs --preview working/design-preview/<name>`
5. Re-score the **after** state with the same reviewer and the same viewports. Do not change the rubric mid-review.
6. Compare dimension by dimension. A higher total does not excuse a regression in accessibility, focus, or mobile overflow.
7. If browser evidence is unavailable, mark the relevant dimensions `NOT VERIFIED`; do not claim a numeric improvement.

## 4. Ship gate

A visual direction is ready for implementation only when:

- Accessibility is at least 4/5 and has no serious or critical axe violations.
- No dimension is below 3/5.
- The total is at least 24/35.
- Mobile has no horizontal overflow and the primary action remains reachable.
- The after state is no worse than the before state on any dimension without an explicit, accepted trade-off.
- The requirement, authorization, and APEX inventory checks still pass. This scorecard does not approve deployable markup.

If the gate fails, fix the named dimension or report `PARTIAL` with the exact evidence gap.

## 5. Report template

| Dimension | Before | After | Evidence | Delta |
| --- | ---: | ---: | --- | ---: |
| Hierarchy |  |  |  |  |
| Spacing |  |  |  |  |
| Typography |  |  |  |  |
| Colour and contrast |  |  |  |  |
| Density and responsive fit |  |  |  |  |
| States |  |  |  |  |
| Accessibility |  |  |  |  |
| **Total** | **/35** | **/35** |  |  |

Add the verifier report path, the browser used, and the two screenshot paths. Call out every `NOT VERIFIED` item explicitly.

## 6. Direction-only external banks

UI UX Pro Max and similar banks may suggest a style, palette mood, typography mood, or anti-pattern. They are direction inputs only. Read `skills/apex-design-system/references/ui-ux-pro-max.md` before using one. Never copy their HTML, CSS, Tailwind, React, animation, or font-import output into APEX. The deployable result must still use the target version's theme style, templates, and tokens.
