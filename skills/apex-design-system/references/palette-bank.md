# Direction Palette Bank

Optional role-based starting points for a prototype or a custom Theme Roller exploration. These are **not** Oracle Universal Theme tokens, not APEX inventory values, and not approved deployable colours.

Use one palette, map every role, and verify contrast with the design verifier before translating to a supported style or Theme Roller variables. Prefer Universal Theme tokens once the direction is chosen.

## Palette recipes

### 1. Operations blue

For support desks, service operations, and queue-heavy workspaces.

| Role | Value | Use |
| --- | --- | --- |
| Ground | `#F6F8FB` | Page background |
| Surface | `#FFFFFF` | Cards, regions, forms |
| Ink | `#172033` | Primary text |
| Muted | `#5B6475` | Secondary text and metadata |
| Accent | `#245BDB` | Primary action and active navigation |
| Border | `#D8DFEA` | Dividers and input borders |
| Status | `#1F7A4D` success / `#A15C00` warning / `#B42318` danger | Text plus icon or label |

Style cue: calm density, clear queue states, restrained accent.

### 2. Public trust navy

For government, regulatory, and internal administration.

| Role | Value | Use |
| --- | --- | --- |
| Ground | `#F7F8FA` | Page background |
| Surface | `#FFFFFF` | Content surfaces |
| Ink | `#1B2433` | Primary text |
| Muted | `#586274` | Helper text |
| Accent | `#0B5CAD` | Links and primary action |
| Border | `#D5DCE6` | Structure |
| Status | `#146C43` success / `#8A5A00` warning / `#A61B1B` danger | Text plus icon |

Style cue: institutional, legible, low decoration, strong table hierarchy.

### 3. Healthcare teal

For clinical operations, patient services, and appointment workflows.

| Role | Value | Use |
| --- | --- | --- |
| Ground | `#F3F9F8` | Page background |
| Surface | `#FFFFFF` | Content surfaces |
| Ink | `#15302F` | Primary text |
| Muted | `#526B69` | Secondary text |
| Accent | `#087E72` | Primary action |
| Border | `#CFE3DF` | Dividers and borders |
| Status | `#1F7A4D` success / `#9A5B00` warning / `#B42318` danger | Text plus icon |

Style cue: quiet, clean, reassuring; avoid decorative clinical iconography.

### 4. Finance graphite

For finance, procurement, and audit-oriented applications.

| Role | Value | Use |
| --- | --- | --- |
| Ground | `#F5F6F7` | Page background |
| Surface | `#FFFFFF` | Content surfaces |
| Ink | `#20242A` | Primary text |
| Muted | `#5D6570` | Secondary text |
| Accent | `#9A6700` | Primary action and highlights |
| Border | `#D7DBE0` | Structure |
| Status | `#1F7A4D` success / `#8A5A00` warning / `#B42318` danger | Text plus icon |

Style cue: precise, numeric, understated; use tabular figures and strong alignment.

### 5. Logistics slate

For dispatch, inventory, and fulfillment dashboards.

| Role | Value | Use |
| --- | --- | --- |
| Ground | `#F4F6F8` | Page background |
| Surface | `#FFFFFF` | Content surfaces |
| Ink | `#1D2836` | Primary text |
| Muted | `#566577` | Secondary text |
| Accent | `#C25117` | Primary action and alerts |
| Border | `#D4DCE5` | Structure |
| Status | `#1F7A4D` success / `#9A5B00` warning / `#B42318` danger | Text plus icon |

Style cue: operational, high-scan, status-forward; keep the accent for decisions, not decoration.

### 6. Education indigo

For learning, onboarding, and internal knowledge tools.

| Role | Value | Use |
| --- | --- | --- |
| Ground | `#F7F7FC` | Page background |
| Surface | `#FFFFFF` | Content surfaces |
| Ink | `#24233A` | Primary text |
| Muted | `#626079` | Secondary text |
| Accent | `#4D4AC7` | Primary action |
| Border | `#DDDCEA` | Structure |
| Status | `#1F7A4D` success / `#9A5B00` warning / `#B42318` danger | Text plus icon |

Style cue: structured, friendly, not playful; avoid oversized illustration blocks.

### 7. Editorial neutral

For knowledge bases, policy pages, and content-heavy admin tools.

| Role | Value | Use |
| --- | --- | --- |
| Ground | `#FAF9F7` | Page background |
| Surface | `#FFFFFF` | Content surfaces |
| Ink | `#211F1C` | Primary text |
| Muted | `#625E58` | Secondary text |
| Accent | `#9B2C2C` | Primary action and editorial emphasis |
| Border | `#DED9D2` | Structure |
| Status | `#1F7A4D` success / `#8A5A00` warning / `#B42318` danger | Text plus icon |

Style cue: generous measure, strong typographic hierarchy, minimal chrome.

### 8. Dark control room

For monitoring, incident response, and dense operational views where dark mode is required.

| Role | Value | Use |
| --- | --- | --- |
| Ground | `#101419` | Page background |
| Surface | `#171D24` | Content surfaces |
| Ink | `#F2F5F8` | Primary text |
| Muted | `#A7B2C0` | Secondary text |
| Accent | `#5EA7FF` | Primary action and focus |
| Border | `#303A46` | Structure |
| Status | `#63D18B` success / `#F0B35A` warning / `#FF7A7A` danger | Text plus icon |

Style cue: low glare, high signal, restrained glow; verify dark-mode contrast separately.

## Rules

- Pick one palette per application or clearly scoped workspace.
- Do not mix recipes or combine accents from several palettes.
- Keep status colours semantic and pair them with text or iconography.
- Use the local palette as a brief, then map to a supported Universal Theme style or an approved custom style. Do not paste these hex values into `.apx`.
- The verifier checks contrast and accessibility; it does not approve the palette or APEX implementation.
