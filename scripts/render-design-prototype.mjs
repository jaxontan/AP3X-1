#!/usr/bin/env node
// Render a design prototype from a JSON content spec, using real Universal Theme markup, the real
// APEX theme CSS from Oracle's CDN, and the brand kit's brand.css. The model writes content
// (app name, nav, KPIs, cards, report rows, form fields), never HTML or CSS.
//
//   node scripts/render-design-prototype.mjs --brand working/page-design/design/brand \
//        --spec working/page-design/design/prototype-spec.json --out working/design-preview/<name>
//
// The output is throwaway evidence. Never copy it into .apx, a Static Content region, or a
// Template Component.
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const CDN = { '26.1': { cdn: '26.1.2', theme: '26.1' }, '26.2': { cdn: '26.2.0', theme: '26.2' } };
const STATUSES = new Set(['success', 'warning', 'danger', 'info', 'neutral']);

const EXAMPLE_SPEC = {
    app: { name: 'Operations Portal' },
    user: 'A. Tan',
    nav: [
        { label: 'Home', icon: 'fa-home', current: true },
        { label: 'Orders', icon: 'fa-shopping-cart' },
        { label: 'Stores', icon: 'fa-map-marker' },
        { label: 'Reports', icon: 'fa-bar-chart' },
        { label: 'Administration', icon: 'fa-gear' }
    ],
    page: { title: 'Dashboard', breadcrumb: ['Home'], primaryAction: 'New order', secondaryAction: 'Export' },
    kpis: [
        { label: 'Orders today', value: '1,284', note: '+8% vs last week', status: 'success' },
        { label: 'Average ticket', value: '$12.40', note: '-2% vs last week', status: 'warning' },
        { label: 'Open issues', value: '7', note: '2 overdue', status: 'danger' },
        { label: 'Stores online', value: '142 / 145', note: '3 offline', status: 'info' }
    ],
    report: {
        title: 'Recent orders',
        columns: ['Order', 'Store', 'Placed', 'Amount', 'Status'],
        numeric: [3],
        rows: [
            ['#10482', 'Orchard Central', '09:42', '$24.50', { badge: 'Paid', status: 'success' }],
            ['#10481', 'Jurong Point', '09:40', '$8.20', { badge: 'Preparing', status: 'info' }],
            ['#10480', 'Tampines Mall', '09:37', '$41.00', { badge: 'Delayed', status: 'warning' }],
            ['#10479', 'VivoCity', '09:31', '$15.75', { badge: 'Refunded', status: 'danger' }],
            ['#10478', 'Bugis Junction', '09:30', '$9.90', { badge: 'Paid', status: 'success' }]
        ]
    },
    form: {
        title: 'Quick order',
        fields: [
            { label: 'Store', type: 'select', options: ['Orchard Central', 'Jurong Point', 'VivoCity'], required: true },
            { label: 'Customer name', type: 'text', required: true },
            { label: 'Notes', type: 'textarea' }
        ],
        submit: 'Create order',
        cancel: 'Cancel'
    },
    empty: { title: 'No escalations', text: 'Escalated orders will appear here.', action: 'View all orders' }
};

function usage() {
    return `Usage:
  node scripts/render-design-prototype.mjs --brand <brand-kit-dir> --out <preview-dir> [--spec <spec.json>]

Options:
  -b, --brand <dir>     Brand kit directory (contains brand-kit.json, css/brand.css, fonts/)
  -s, --spec <file>     Content spec JSON (default: a generic operations example; write your own)
  -o, --out <dir>       Preview directory, normally working/design-preview/<name>
      --name <file>     Output file name (default: index.html; use after.html for a redesign)
      --stock           Render without brand.css (the stock Vita baseline, e.g. as before.html)
      --print-example   Print an example spec and exit
  -h, --help            Show this help
`;
}

function parseArgs(argv) {
    const args = { brand: null, spec: null, out: null, name: 'index.html', stock: false };
    const next = (i, flag) => {
        const v = argv[i + 1];
        if (!v || v.startsWith('--')) throw new Error(`Missing value for ${flag}.`);
        return v;
    };
    for (let i = 0; i < argv.length; i += 1) {
        const a = argv[i];
        if (a === '-b' || a === '--brand') { args.brand = next(i, a); i += 1; }
        else if (a === '-s' || a === '--spec') { args.spec = next(i, a); i += 1; }
        else if (a === '-o' || a === '--out') { args.out = next(i, a); i += 1; }
        else if (a === '--name') { args.name = next(i, a); i += 1; }
        else if (a === '--stock') args.stock = true;
        else if (a === '--print-example') { process.stdout.write(`${JSON.stringify(EXAMPLE_SPEC, null, 2)}\n`); process.exit(0); }
        else if (a === '-h' || a === '--help') { process.stdout.write(usage()); process.exit(0); }
        else throw new Error(`Unknown argument: ${a}`);
    }
    if (!args.out) throw new Error('Missing --out.');
    if (!args.brand && !args.stock) throw new Error('Pass --brand <dir>, or --stock for the unbranded baseline.');
    if (!/^[a-z0-9-]+\.html$/.test(args.name)) throw new Error('--name must look like index.html, before.html, or after.html.');
    return args;
}

const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const icon = (v) => (/^fa-[a-z0-9-]+$/.test(String(v || '')) ? v : 'fa-circle-o');
const status = (v) => (STATUSES.has(v) ? v : 'neutral');

function badge(label, st) {
    const s = status(st);
    const cls = s === 'neutral' ? 't-Badge t-Badge--subtle' : `t-Badge t-Badge--${s} t-Badge--subtle`;
    const glyph = { success: 'fa-check-circle', warning: 'fa-warning', danger: 'fa-times-circle', info: 'fa-info-circle', neutral: 'fa-circle-o' }[s];
    return `<span class="${cls}"><span class="t-Badge-icon fa ${glyph}" aria-hidden="true"></span><span class="t-Badge-value">${esc(label)}</span></span>`;
}

function button(label, kind = '', iconName = null) {
    if (!label) return '';
    const cls = ['t-Button', kind === 'hot' ? 't-Button--hot' : '', kind === 'simple' ? 't-Button--simple' : '', iconName ? 't-Button--iconLeft' : ''].filter(Boolean).join(' ');
    const ic = iconName ? `<span class="t-Icon t-Icon--left fa ${icon(iconName)}" aria-hidden="true"></span>` : '';
    return `<button class="${cls}" type="button">${ic}<span class="t-Button-label">${esc(label)}</span></button>`;
}

function region(id, title, body, { buttons = '', noUI = false, scrollable = false } = {}) {
    if (noUI) return `<div class="t-Region t-Region--noUI" id="${id}" role="region" aria-label="${esc(title)}"><div class="t-Region-bodyWrap"><div class="t-Region-body">${body}</div></div></div>`;
    return `<div class="t-Region t-Region--scrollBody" id="${id}" role="region" aria-labelledby="${id}_heading">
  <div class="t-Region-header">
    <div class="t-Region-headerItems t-Region-headerItems--title"><h2 class="t-Region-title" id="${id}_heading">${esc(title)}</h2></div>
    <div class="t-Region-headerItems t-Region-headerItems--buttons">${buttons}</div>
  </div>
  <div class="t-Region-bodyWrap"><div class="t-Region-body"${scrollable ? ` tabindex="0" aria-label="${esc(title)}"` : ''}>${body}</div></div>
</div>`;
}

function kpiCards(kpis) {
    const items = kpis.map((k) => `<li class="a-CardView-item"><div class="a-CardView">
  <div class="a-CardView-header"><div class="a-CardView-headerBody">
    <h3 class="a-CardView-subTitle">${esc(k.label)}</h3>
    <p class="a-CardView-title brand-preview-kpi">${esc(k.value)}</p>
  </div></div>
  <div class="a-CardView-body"><div class="a-CardView-mainContent">${k.note ? badge(k.note, k.status) : ''}</div></div>
</div></li>`).join('\n');
    const cols = Math.min(4, Math.max(2, kpis.length));
    return `<div class="a-CardView-items a-CardView-items--grid${cols}col" role="list">${items}</div>`;
}

function cards(list) {
    const items = list.map((c) => `<li class="a-CardView-item"><div class="a-CardView">
  <div class="a-CardView-header">
    ${c.icon ? `<div class="a-CardView-iconWrap"><span class="a-CardView-icon u-color fa ${icon(c.icon)}" aria-hidden="true"></span></div>` : ''}
    <div class="a-CardView-headerBody"><h3 class="a-CardView-title">${esc(c.title)}</h3>${c.subtitle ? `<h4 class="a-CardView-subTitle">${esc(c.subtitle)}</h4>` : ''}</div>
    ${c.badge ? `<div class="a-CardView-badge">${badge(c.badge.label, c.badge.status)}</div>` : ''}
  </div>
  ${c.body ? `<div class="a-CardView-body"><div class="a-CardView-mainContent">${esc(c.body)}</div></div>` : ''}
</div></li>`).join('\n');
    return `<div class="a-CardView-items a-CardView-items--grid3col" role="list">${items}</div>`;
}

function report(r) {
    const numeric = new Set(r.numeric || []);
    const head = r.columns.map((c, i) => `<th class="t-Report-colHead${numeric.has(i) ? ' u-tR' : ''}" id="c${i}" scope="col">${esc(c)}</th>`).join('');
    const rows = r.rows.map((row) => `<tr>${row.map((cell, i) => {
        const content = cell && typeof cell === 'object' ? badge(cell.badge, cell.status) : esc(cell);
        return `<td class="t-Report-cell${numeric.has(i) ? ' u-tR brand-preview-num' : ''}" headers="c${i}">${content}</td>`;
    }).join('')}</tr>`).join('\n');
    return `<div class="t-Report t-Report--altRowsDefault t-Report--rowHighlight t-Report--stretch"><div class="t-Report-wrap"><table class="t-Report-pagination" role="presentation"></table><div class="t-Report-tableWrap"><table class="t-Report-report"><thead><tr>${head}</tr></thead><tbody>${rows}</tbody></table></div></div></div>`;
}

function form(f) {
    const fields = f.fields.map((fld, i) => {
        const id = `P1_F${i}`;
        let input;
        let wrapper;
        if (fld.type === 'select') {
            input = `<select id="${id}" class="selectlist apex-item-select" ${fld.required ? 'required' : ''}><option value="">- Select -</option>${(fld.options || []).map((o) => `<option>${esc(o)}</option>`).join('')}</select>`;
            wrapper = 'apex-item-wrapper--select-list js-show-label';
        } else if (fld.type === 'textarea') {
            input = `<textarea id="${id}" class="textarea apex-item-textarea" rows="3"></textarea>`;
            wrapper = 'apex-item-wrapper--textarea';
        } else {
            input = `<input type="text" id="${id}" class="text_field apex-item-text" ${fld.required ? 'required' : ''}>`;
            wrapper = 'apex-item-wrapper--text-field';
        }
        return `<div class="t-Form-fieldContainer t-Form-fieldContainer--floatingLabel t-Form-fieldContainer--stretchInputs ${fld.required ? 'is-required' : ''} apex-item-wrapper ${wrapper}">
  <div class="t-Form-labelContainer"><label for="${id}" class="t-Form-label">${esc(fld.label)}${fld.required ? ' <span class="u-VisuallyHidden">(required)</span>' : ''}</label></div>
  <div class="t-Form-inputContainer"><div class="t-Form-itemWrapper">${input}</div></div>
</div>`;
    }).join('\n');
    const buttons = `<div class="t-ButtonRegion-buttons brand-preview-buttons">${button(f.cancel, 'simple')}${button(f.submit, 'hot')}</div>`;
    return `${fields}${buttons}`;
}

function empty(e) {
    return `<div class="brand-preview-empty"><span class="fa fa-inbox fa-2x" aria-hidden="true"></span><h3>${esc(e.title)}</h3><p>${esc(e.text)}</p>${button(e.action, 'simple')}</div>`;
}

function page(spec, version, withBrand, title) {
    const v = CDN[version] || CDN['26.2'];
    const base = `https://static.oracle.com/cdn/apex/${v.cdn}`;
    const nav = spec.nav.map((n) => `<li class="a-TreeView-node a-TreeView-node--topLevel${n.current ? ' is-current--top' : ''}" role="none">
  <div class="a-TreeView-row${n.current ? ' is-current--top is-selected' : ''}"></div>
  <div class="a-TreeView-content${n.current ? ' is-current--top' : ''}" role="treeitem" aria-selected="${n.current ? 'true' : 'false'}">
    <span class="fa ${icon(n.icon)}" aria-hidden="true"></span><a href="#" class="a-TreeView-label" tabindex="${n.current ? 0 : -1}">${esc(n.label)}</a>
  </div></li>`).join('\n');
    const crumbs = [...(spec.page.breadcrumb || [])].map((c) => `<li class="t-Breadcrumb-item"><a href="#" class="t-Breadcrumb-label">${esc(c)}</a></li>`).join('');

    const rows = [];
    const grid = (cols) => `<div class="row">${cols.map(([span, html]) => `<div class="col col-${span}">${html}</div>`).join('')}</div>`;
    if (spec.kpis?.length) rows.push(grid([[12, region('kpis', 'Key figures', kpiCards(spec.kpis), { noUI: true })]]));
    if (spec.cards?.length) rows.push(grid([[12, region('cards', spec.cardsTitle || 'Overview', cards(spec.cards))]]));
    const left = spec.report ? region('report', spec.report.title, report(spec.report), { buttons: button('Filter', 'simple', 'fa-filter'), scrollable: true }) : '';
    const right = [spec.form ? region('form', spec.form.title, form(spec.form)) : '', spec.empty ? region('empty', spec.empty.regionTitle || 'Escalations', empty(spec.empty)) : ''].join('');
    if (left && right) rows.push(grid([[8, left], [4, right]]));
    else if (left || right) rows.push(grid([[12, left || right]]));

    return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}</title>
<!-- Real Universal Theme CSS for APEX ${version} from Oracle's CDN, loaded in APEX order: core, theme, style, application. -->
<link rel="stylesheet" href="${base}/libraries/font-apex/2.5/css/font-apex.min.css">
<link rel="stylesheet" href="${base}/app_ui/css/Core.min.css">
<link rel="stylesheet" href="${base}/themes/theme_42/${v.theme}/css/Core.min.css">
<link rel="stylesheet" href="${base}/themes/theme_42/${v.theme}/css/Vita.min.css">
${withBrand ? '<link rel="stylesheet" href="css/brand.css">' : '<!-- stock baseline: no brand.css -->'}
<style>
/* Preview-only shim: APEX positions the title bar and nav with JavaScript at runtime. Not part of the brand. */
.t-Body-title{position:static!important;inset:auto!important;inline-size:auto!important}
.t-Body-content{padding-block-start:0!important}
.brand-preview-kpi{font-size:1.75rem;line-height:2.25rem;margin:.25rem 0 0;font-variant-numeric:tabular-nums}
.brand-preview-num{font-variant-numeric:tabular-nums}
.brand-preview-buttons{display:flex;gap:.5rem;justify-content:flex-end;padding:.5rem .75rem .75rem}
.brand-preview-empty{text-align:center;padding:1.5rem 1rem;color:var(--ut-component-text-muted-color,#555)}
.brand-preview-empty h3{margin:.5rem 0 .25rem;color:var(--ut-component-text-title-color,#000);font-size:1rem}
.brand-preview-empty p{margin:0 0 1rem}
@media (max-width:640px){.t-Body-nav{display:none!important}.t-Body-main{margin-inline-start:0!important}.row>.col{flex:0 0 100%;max-width:100%}}
</style>
</head>
<body class="t-PageBody t-PageBody--hideLeft t-PageBody--hideActions t-PageTemplate--standard apex-side-nav apex-icons-fontapex apex-theme-vita js-navExpanded">
<a href="#main" class="u-VisuallyHidden" id="t_Body_skipToContent">Skip to main content</a>
<header class="t-Header" id="t_Header" role="banner">
  <div class="t-Header-branding">
    <div class="t-Header-controls"><button class="t-Button t-Button--icon t-Button--header t-Button--headerTree" type="button" aria-label="Main navigation" title="Main navigation"><span class="t-Header-controlsIcon" aria-hidden="true"></span></button></div>
    <div class="t-Header-logo"><a href="#" class="t-Header-logo-link"><span class="apex-logo-text">${esc(spec.app.name)}</span></a></div>
    <div class="t-Header-navBar"><div class="t-Header-navBar--end"><ul class="t-NavigationBar"><li class="t-NavigationBar-item has-username"><button class="t-Button t-Button--icon t-Button--header t-Button--navBar" type="button" aria-label="${esc(spec.user || 'User')}"><span class="t-Icon fa fa-user" aria-hidden="true"></span><span class="t-Button-label">${esc(spec.user || 'User')}</span></button></li></ul></div></div>
  </div>
  <div class="t-Header-nav"></div>
</header>
<div class="t-Body">
  <div class="t-Body-nav" id="t_Body_nav" role="navigation" aria-label="Main navigation">
    <div class="t-TreeNav t-TreeNav--styleA" id="t_TreeNav"><div class="a-TreeView"><ul role="tree" aria-label="Main navigation">${nav}</ul></div></div>
  </div>
  <div class="t-Body-main">
    <div class="t-Body-title" id="t_Body_title">
      <div class="t-BreadcrumbRegion t-BreadcrumbRegion--showBreadcrumb t-BreadcrumbRegion--useBreadcrumbTitle">
        <div class="t-BreadcrumbRegion-body">
          <div class="t-BreadcrumbRegion-breadcrumb"><ul class="t-Breadcrumb">${crumbs}<li class="t-Breadcrumb-item is-active" aria-current="page"><span class="t-Breadcrumb-label">${esc(spec.page.title)}</span></li></ul></div>
          <div class="t-BreadcrumbRegion-title"><h1 class="t-BreadcrumbRegion-titleText">${esc(spec.page.title)}</h1></div>
        </div>
        <div class="t-BreadcrumbRegion-buttons">${button(spec.page.secondaryAction, 'simple', 'fa-download')}${button(spec.page.primaryAction, 'hot', 'fa-plus')}</div>
      </div>
    </div>
    <div class="t-Body-content" id="t_Body_content">
      <main id="main" class="t-Body-mainContent">
        <div class="t-Body-contentInner"><div class="container">
${rows.join('\n')}
        </div></div>
      </main>
    </div>
  </div>
</div>
</body>
</html>
`;
}

function validateSpec(spec) {
    const problems = [];
    if (!spec.app?.name) problems.push('app.name is required');
    if (!Array.isArray(spec.nav) || !spec.nav.length) problems.push('nav must be a non-empty array of { label, icon, current }');
    if (!spec.page?.title) problems.push('page.title is required');
    if (spec.report && (!Array.isArray(spec.report.columns) || !Array.isArray(spec.report.rows))) problems.push('report needs columns and rows arrays');
    if (spec.form && !Array.isArray(spec.form.fields)) problems.push('form.fields must be an array');
    return problems;
}

async function copyDir(from, to) {
    try {
        await fs.mkdir(to, { recursive: true });
        for (const f of await fs.readdir(from)) await fs.copyFile(path.join(from, f), path.join(to, f));
    } catch { /* optional */ }
}

async function main() {
    let args;
    try {
        args = parseArgs(process.argv.slice(2));
    } catch (error) {
        process.stderr.write(`${error.message}\n\n${usage()}`);
        process.exit(2);
    }
    const spec = args.spec ? JSON.parse((await fs.readFile(path.resolve(args.spec), 'utf8')).replace(/^﻿/, '')) : EXAMPLE_SPEC;
    const problems = validateSpec(spec);
    if (problems.length) {
        process.stderr.write(`Invalid spec:\n- ${problems.join('\n- ')}\nSee --print-example.\n`);
        process.exit(2);
    }

    const outDir = path.resolve(args.out);
    await fs.mkdir(outDir, { recursive: true });
    let version = '26.2';
    if (args.brand) {
        const brandDir = path.resolve(args.brand);
        const kit = JSON.parse(await fs.readFile(path.join(brandDir, 'brand-kit.json'), 'utf8'));
        version = kit.version || version;
        await copyDir(path.join(brandDir, 'css'), path.join(outDir, 'css'));
        await copyDir(path.join(brandDir, 'fonts'), path.join(outDir, 'fonts'));
    }
    const withBrand = !args.stock;
    const html = page(spec, version, withBrand, `${spec.app.name} - ${spec.page.title}${withBrand ? '' : ' (stock)'}`);
    await fs.writeFile(path.join(outDir, args.name), html, 'utf8');
    await fs.writeFile(path.join(outDir, 'spec.json'), `${JSON.stringify(spec, null, 2)}\n`, 'utf8');
    process.stdout.write(`Rendered ${path.relative(process.cwd(), path.join(outDir, args.name))} (APEX ${version} theme CSS${withBrand ? ' + brand.css' : ', stock'}).\n`);
    process.stdout.write(`Next: node scripts/score-design.mjs --preview ${path.relative(process.cwd(), outDir)}${args.brand ? ` --kit ${path.relative(process.cwd(), path.join(path.resolve(args.brand), 'brand-kit.json'))}` : ''}\nPROTOTYPE RENDERED\n`);
}

main().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exit(1);
});
