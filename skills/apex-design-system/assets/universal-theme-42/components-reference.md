# Universal Theme 42 — Component Markup Reference

Real Oracle APEX class names + minimal markup patterns. Style everything with the CSS
custom properties from `tokens/*.css` — never literal colors.

## Page shell
```html
<body class="t-Body t-Body--noBoxBody">
  <header class="t-Header" style="background:var(--ut-header-background-color); color:var(--ut-header-text-color);">
    <div class="t-Header-logo">My App</div>
    <nav class="t-Header-nav">...</nav>
  </header>
  <nav class="t-Body-nav" style="background:var(--ut-body-nav-background-color); color:var(--ut-body-nav-text-color); width:var(--ut-nav-width);">
    <ul class="a-TreeView">...</ul>
  </nav>
  <main class="t-Body-content" style="background:var(--ut-body-background-color); color:var(--ut-body-text-color);">
    <div class="t-Body-title" style="background:var(--ut-body-title-background-color);">
      <nav class="t-Breadcrumb">...</nav>
      <h1>Page Title</h1>
    </div>
    <!-- regions go here -->
  </main>
</body>
```

## Region / Card container
```html
<div class="t-Region t-Region--card"
     style="background:var(--ut-region-background-color);
            border:var(--ut-region-border-width) solid var(--ut-region-border-color);
            border-radius:var(--ut-region-border-radius);
            box-shadow:var(--ut-region-box-shadow);">
  <div class="t-Region-header"
       style="background:var(--ut-region-header-background-color);
              border-bottom:1px solid var(--ut-region-header-border-color);
              padding:var(--ut-region-body-padding-y) var(--ut-region-body-padding-x);">
    <h3 class="t-Region-title">Region Title</h3>
    <div class="t-Region-headerItems"><!-- toolbar buttons --></div>
  </div>
  <div class="t-Region-body" style="padding:var(--ut-region-body-padding-y) var(--ut-region-body-padding-x);">
    ...content...
  </div>
  <div class="t-Region-buttons" style="padding:var(--ut-region-buttons-padding-y) var(--ut-region-buttons-padding-x);">
    <button class="t-Button t-Button--hot">Save</button>
  </div>
</div>
```

## Buttons
```html
<button class="t-Button">Default</button>
<button class="t-Button t-Button--hot">Hot (accent)</button>
<button class="t-Button t-Button--primary">Primary (alt)</button>
<button class="t-Button t-Button--success">Success</button>
<button class="t-Button t-Button--warning">Warning</button>
<button class="t-Button t-Button--danger">Danger</button>
<button class="t-Button t-Button--simple">Simple (outline)</button>
<button class="t-Button t-Button--link">Link style</button>
<button class="t-Button t-Button--noUI">No-UI</button>
```
All driven by `--a-button-*` tokens; state variants swap `--a-button-background-color`
/ `--a-button-text-color` to the relevant `--ut-palette-*` pair.

## Alerts
```html
<div class="t-Alert t-Alert--success" role="alert">
  <span class="t-Alert-icon"></span>
  <div class="t-Alert-wrap">
    <h3 class="t-Alert-title">Success</h3>
    <div class="t-Alert-body">Record saved.</div>
  </div>
</div>
<!-- variants: t-Alert--info / t-Alert--warning / t-Alert--danger -->
```

## Badges
```html
<span class="t-Badge" style="background:var(--ut-component-badge-background-color);
      color:var(--ut-component-badge-text-color); border-radius:var(--ut-component-badge-border-radius);">
  New
</span>
```

## Form field
```html
<div class="t-Form-fieldContainer">
  <label class="t-Form-label" for="P1_NAME">Name</label>
  <div class="t-Form-inputContainer">
    <input type="text" id="P1_NAME" class="apex-item-text"
           style="background:var(--a-field-input-background-color);
                  border:var(--a-field-input-border-width) solid var(--a-field-input-border-color);
                  border-radius:var(--a-field-input-border-radius);">
  </div>
</div>
```

## Card view (a-CardView)
```html
<div class="a-CardView" style="display:grid; gap:var(--a-cv-grid-gap); grid-template-columns:repeat(auto-fill,minmax(var(--a-cv-item-width),1fr));">
  <div class="a-CardView-card" style="background:var(--ut-region-background-color); border-radius:var(--a-cv-border-radius); box-shadow:var(--a-cv-shadow);">
    <div class="a-CardView-header" style="padding:var(--a-cv-header-padding-y) var(--a-cv-header-padding-x);">
      <div class="a-CardView-icon" style="width:var(--a-cv-icon-container-size); height:var(--a-cv-icon-container-size); background:var(--ut-component-icon-background-color); color:var(--ut-component-icon-color); border-radius:100%;"></div>
      <div class="a-CardView-title" style="font-size:var(--a-cv-title-font-size); line-height:var(--a-cv-title-line-height);">Card Title</div>
      <div class="a-CardView-subtitle" style="font-size:var(--a-cv-subtitle-font-size); color:var(--ut-component-text-muted-color);">Subtitle</div>
    </div>
    <div class="a-CardView-body" style="padding:var(--a-cv-body-padding-y) var(--a-cv-body-padding-x); font-size:var(--a-cv-maincontent-font-size);">
      Card content goes here.
    </div>
  </div>
</div>
```

## Interactive Report style table
```html
<table class="a-IRR-table" style="border-color:var(--a-gv-border-color); font-size:var(--a-gv-font-size);">
  <thead>
    <tr style="background:var(--ut-report-header-background-color); height:var(--a-gv-header-cell-height);">
      <th style="padding:var(--a-gv-header-cell-padding-y) var(--a-gv-header-cell-padding-x);">Column</th>
    </tr>
  </thead>
  <tbody>
    <tr style="height:var(--a-gv-cell-height);">
      <td style="padding:var(--a-gv-cell-padding-y) var(--a-gv-cell-padding-x); border-bottom:1px solid var(--ut-report-cell-border-color);">Value</td>
    </tr>
  </tbody>
</table>
```

## Tabs
```html
<div class="t-Tabs">
  <ul class="t-Tabs-list">
    <li class="t-Tabs-item is-active"><a class="t-Tabs-link" style="color:var(--ut-tabs-item-active-text-color); font-weight:var(--ut-tabs-item-active-font-weight);">Tab 1</a></li>
    <li class="t-Tabs-item"><a class="t-Tabs-link" style="color:var(--ut-tabs-item-text-color);">Tab 2</a></li>
  </ul>
</div>
```

## Icons
Universal Theme uses an icon font (`a-Icon`, classes like `icon-edit`, `icon-add`, or
Font Awesome `fa-*` if that library is loaded). For prototyping outside APEX, swap in
any icon set (Lucide, Font Awesome) and just size/color it with `--a-icon-size` and
`currentColor`.

## Notes for AI-generated output
- Always wire `background`, `color`, `border`, `border-radius`, `box-shadow`, `padding`
  to the matching CSS custom property rather than literal values.
- Prefer real class names above so markup is portable back into an actual APEX app
  (Custom PL/SQL region, static HTML, or a plugin template) with minimal changes.
- Status semantics: success = green, info = accent-blue (unless a style ties info to its
  own accent), warning = amber, danger = red — always via `--ut-palette-*` tokens, never
  hardcoded.
