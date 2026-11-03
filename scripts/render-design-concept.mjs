#!/usr/bin/env node
// Render a creative design concept: page compositions the designer writes freely, wrapped in the
// real Universal Theme shell (Oracle CDN theme CSS + the concept's generated brand.css), linted
// against the guardrails, screenshotted, checked with axe, and scanned for generic-AI tells.
//
//   node scripts/render-design-concept.mjs --concept working/page-design/design/concepts/<slug>
//   node scripts/render-design-concept.mjs --board working/page-design/design/concepts
//
// A concept folder holds:
//   concept.md       name, big idea, signature moves, APEX mapping for every brand-* class, critique log
//   shell.json       { "app": "...", "user": "...", "nav": [{ "label", "icon", "page" }], "chrome": {...} }
//   brand-kit.json   decisions; components.css: the concept's own brand-* components (tokens only)
//   pages/*.html     the body of each page: Universal Theme markup + brand-* classes, nothing else
// Build the kit first: node scripts/build-brand-kit.mjs --kit <concept>/brand-kit.json
//
// The rendered HTML is evidence for choosing a direction. It is never copied into .apx.
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { pathToFileURL } from 'node:url';

const CDN = { '26.1': { cdn: '26.1.2', theme: '26.1' }, '26.2': { cdn: '26.2.0', theme: '26.2' } };
const VIEWPORTS = [{ name: 'desktop', width: 1440, height: 900 }, { name: 'mobile', width: 390, height: 844 }];
const AXE_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22a', 'wcag22aa'];
const ALLOWED_TAGS = new Set(['div', 'span', 'section', 'header', 'footer', 'article', 'aside', 'nav', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'ul', 'ol', 'li', 'dl', 'dt', 'dd',
    'a', 'button', 'strong', 'em', 'small', 'b', 'i', 'table', 'thead', 'tbody', 'tfoot', 'tr', 'th', 'td', 'caption', 'label', 'input', 'select', 'option', 'textarea',
    'form', 'fieldset', 'legend', 'time', 'abbr', 'br', 'hr', 'figure', 'figcaption', 'meter', 'progress', 'mark', 'sup', 'sub', 'blockquote', 'q', 'cite']);
const CLASS_OK = /^(t-|a-|u-|fa$|fa-|col$|col-|row$|container$|brand-|is-|has-|apex-)/;

function usage() {
    return `Usage:
  node scripts/render-design-concept.mjs --concept <concept-dir> [--out <dir>] [--no-shots]
  node scripts/render-design-concept.mjs --board <concepts-dir> [--out <dir>]

Renders every pages/*.html of a concept inside the real Universal Theme shell, lints it, takes
desktop and mobile screenshots, runs axe, and lists generic-AI tells. --board puts every rendered
concept side by side (board.html + board.png) for the user to choose from.
Default output: working/design-preview/concepts/<slug>/
Pass word: CONCEPT RENDERED (or BOARD RENDERED).
`;
}

function parseArgs(argv) {
    const args = { concept: null, board: null, out: null, shots: true };
    for (let i = 0; i < argv.length; i += 1) {
        const a = argv[i];
        const v = () => { const x = argv[i + 1]; if (!x || x.startsWith('--')) throw new Error(`Missing value for ${a}.`); i += 1; return x; };
        if (a === '--concept' || a === '-c') args.concept = v();
        else if (a === '--board') args.board = v();
        else if (a === '--out' || a === '-o') args.out = v();
        else if (a === '--no-shots') args.shots = false;
        else if (a === '-h' || a === '--help') { process.stdout.write(usage()); process.exit(0); }
        else throw new Error(`Unknown argument: ${a}`);
    }
    if (!args.concept && !args.board) throw new Error('Pass --concept <dir> or --board <dir>.');
    return args;
}

const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const readJson = async (f) => JSON.parse((await fs.readFile(f, 'utf8')).replace(/^﻿/, ''));
const exists = async (f) => fs.access(f).then(() => true, () => false);

// ---------- lint ----------

// Returns a list of problems in a page fragment. The fragment is the designer's free composition, so
// the rules guard buildability and accessibility, not taste.
export function lintFragment(html, { definedClasses, mappedClasses, brandWords }) {
    const problems = [];
    const fm = /<!--\s*page:\s*(\{[\s\S]*?\})\s*-->/.exec(html);
    let spec = null;
    try { spec = fm ? JSON.parse(fm[1]) : null; } catch { problems.push('The page front matter is not valid JSON.'); }
    if (!fm) problems.push('Start the page with front matter: <!-- page: {"title": "...", "data": "real" | "sample"} -->.');
    if (spec && !['real', 'sample'].includes(spec.data)) problems.push('Front matter must say "data": "real" or "sample". Sample pages get a visible ribbon so nobody mistakes mock numbers for the app.');
    if (spec && spec.data === 'real' && !String(spec.dataSource || '').trim()) problems.push('A "data": "real" page must name its "dataSource" (the query, view, or plan the numbers came from).');
    const text = html.replace(/<!--[\s\S]*?-->/g, '');
    if (/<\s*(script|style|link|iframe|object|embed)\b/i.test(text)) problems.push('No <script>, <style>, <link>, <iframe>, <object>, or <embed>: styling lives in components.css, behaviour in APEX.');
    if (/\sstyle\s*=/i.test(text)) problems.push('No inline style= attributes: create a brand-* class in components.css.');
    if (/\son[a-z]+\s*=/i.test(text)) problems.push('No inline event handlers (onclick= ...).');
    if (/javascript:/i.test(text)) problems.push('No javascript: URLs.');
    for (const m of text.matchAll(/\s([a-z-]+)\s*=\s*"\s*(#[0-9a-f]{3,8}|(?:rgba?|hsla?)\([^"]*\))\s*"/gi)) {
        if (m[1].toLowerCase() !== 'href') problems.push(`No colour literals in markup (${m[1]}="${m[2]}"): colours come from tokens in components.css.`);
    }
    if (/<img\b[^>]*src\s*=\s*["']?https?:/i.test(text)) problems.push('No remote images: use Font APEX icons or ship an asset as a static file.');
    for (const m of text.matchAll(/<\s*([a-z][a-z0-9-]*)\b/gi)) {
        const tag = m[1].toLowerCase();
        if (!ALLOWED_TAGS.has(tag) && tag !== 'img' && tag !== 'svg' && tag !== 'path' && tag !== 'circle' && tag !== 'rect' && tag !== 'line' && tag !== 'polyline' && tag !== 'g' && tag !== 'title') {
            problems.push(`Tag <${tag}> is not part of the allowed vocabulary.`);
        }
    }
    const used = new Set();
    for (const m of text.matchAll(/\sclass\s*=\s*"([^"]*)"/gi)) for (const c of m[1].split(/\s+/).filter(Boolean)) used.add(c);
    for (const c of used) {
        if (!CLASS_OK.test(c)) problems.push(`Class "${c}" is neither Universal Theme (t-, a-, u-, fa-) nor a brand-* component.`);
        if (c.startsWith('brand-') && !definedClasses.has(c)) problems.push(`Class "${c}" is used but not defined in components.css.`);
        if (c.startsWith('brand-') && !mappedClasses.has(c) && !mappedClasses.has(c.replace(/(__|--).*$/, ''))) problems.push(`Class "${c}" has no row in the concept.md APEX mapping table; say where it attaches in APEX.`);
    }
    const visible = text.replace(/<[^>]+>/g, ' ').toLowerCase();
    for (const w of brandWords) if (w && new RegExp(`\\b${w}\\b`, 'i').test(visible)) problems.push(`Forbidden word "${w}" (the reference brand or its product words, from brief.md) appears in the page text. Borrow the look, never the brand or its vocabulary.`);
    for (const m of text.matchAll(/<button\b([^>]*)>([\s\S]*?)<\/button>/gi)) {
        const label = m[2].replace(/<[^>]+>/g, '').trim();
        if (!label && !/aria-label\s*=/.test(m[1])) problems.push('A <button> has no text and no aria-label.');
    }
    return problems;
}

function classesDefinedIn(css) {
    const set = new Set();
    for (const m of css.replace(/\/\*[\s\S]*?\*\//g, '').matchAll(/\.(brand-[a-z0-9_-]+)/gi)) set.add(m[1]);
    return set;
}

function classesMappedIn(md) {
    // Rows of a markdown table whose first cell names a brand-* class: | `brand-band` | region cssClasses ... |
    const set = new Set();
    for (const m of md.matchAll(/^\|\s*`?\.?(brand-[a-z0-9_-]+)`?\s*\|/gim)) set.add(m[1]);
    return set;
}

// brief.md (shared by all concepts): "**Forbidden words:** cookie, creme, dunk" lists the reference's
// product words that must never appear in the app, on top of the reference brand name.
export function forbiddenWordsFrom(briefMd) {
    const m = /^\*\*Forbidden words:?\*\*:?\s*(.+)$/im.exec(briefMd || '');
    return m ? m[1].split(/[,;]/).map((w) => w.trim().toLowerCase().replace(/[.`*]/g, '')).filter((w) => w.length >= 3) : [];
}

// concept.md must carry the idea, the moves, the axes, and the APEX mapping.
export function conceptStructureProblems(md) {
    const problems = [];
    if (!/^#\s+\S/m.test(md)) problems.push('concept.md needs a "# <Concept name>" heading.');
    if (!/^\*\*Big idea:?\*\*/im.test(md)) problems.push('concept.md needs a "**Big idea:**" line (one sentence).');
    if (!/^\*\*Signature moves:?\*\*/im.test(md)) problems.push('concept.md needs a "**Signature moves:**" line.');
    if (!/^\*\*Axes:?\*\*/im.test(md)) problems.push('concept.md needs an "**Axes:**" line (composition = ...; emphasis = ...; colour = ...; type = ...; density = ...; chrome = ...).');
    if (!/^##\s+APEX mapping/im.test(md)) problems.push('concept.md needs an "## APEX mapping" table.');
    return problems;
}

// "**Axes:** composition = poster bands; emphasis = one number; ..." -> { composition: 'poster bands', ... }
export function axesOf(md) {
    const m = /^\*\*Axes:?\*\*:?\s*(.+)$/im.exec(md || '');
    const axes = {};
    if (!m) return axes;
    for (const part of m[1].split(';')) {
        const kv = /^\s*([a-z]+)\s*[=:]\s*(.+?)\s*\.?\s*$/i.exec(part);
        if (kv) axes[kv[1].toLowerCase()] = kv[2].toLowerCase();
    }
    return axes;
}

// The critique: at least two logged rounds, no placeholder, and the last round answers tells when any exist.
export function critiqueProblems(md, tells = []) {
    const problems = [];
    const critique = (/^##\s+Critique\s*$([\s\S]*)/im.exec(md || '') || [, ''])[1];
    if (!critique.trim() || /_\(written after rendering\)_/.test(critique)) problems.push('the critique has not been written');
    const rounds = critique.match(/^###\s+Round\s+\d+/gim) || [];
    if (rounds.length < 2) problems.push(`the critique has ${rounds.length} round(s); at least 2 are required (render, critique, revise, re-render)`);
    if (tells.length) {
        const last = critique.split(/^###\s+Round\s+\d+/im).pop() || '';
        if (!/\btells?\b/i.test(last)) problems.push(`report.md lists ${tells.length} tell(s) but the last critique round does not answer them`);
    }
    return problems;
}

function brandWordsFrom(kit) {
    try {
        const host = new URL(kit.source?.reference || '').hostname.replace(/^www\./, '');
        const word = host.split('.')[0];
        return word && word.length >= 3 ? [word] : [];
    } catch {
        return [];
    }
}

// ---------- page shell ----------

function shell({ version, shellSpec, pageSpec, body, title }) {
    const v = CDN[version] || CDN['26.2'];
    const base = `https://static.oracle.com/cdn/apex/${v.cdn}`;
    const chrome = { nav: 'side', titleBar: true, ...(shellSpec.chrome || {}), ...(pageSpec.chrome || {}) };
    const navItems = (shellSpec.nav || []).map((n) => {
        const cur = n.page === pageSpec.slug || n.label === pageSpec.current;
        return { ...n, cur };
    });
    const sideNav = navItems.map((n) => `<li class="a-TreeView-node a-TreeView-node--topLevel${n.cur ? ' is-current--top' : ''}" role="none">
  <div class="a-TreeView-row${n.cur ? ' is-current--top is-selected' : ''}"></div>
  <div class="a-TreeView-content${n.cur ? ' is-current--top' : ''}" role="treeitem" aria-selected="${n.cur}">
    <span class="fa ${esc(n.icon || 'fa-circle-o')}" aria-hidden="true"></span><a href="${esc(n.page || '#')}.html" class="a-TreeView-label">${esc(n.label)}</a>
  </div></li>`).join('\n');
    const topNav = navItems.map((n) => `<li class="a-MenuBar-item${n.cur ? ' is-current' : ''}"><a class="a-MenuBar-label" href="${esc(n.page || '#')}.html"${n.cur ? ' aria-current="page"' : ''}>${esc(n.label)}</a></li>`).join('');
    const side = chrome.nav === 'side';
    const titleBar = chrome.titleBar ? `<div class="t-Body-title" id="t_Body_title">
      <div class="t-BreadcrumbRegion t-BreadcrumbRegion--showTitle">
        <div class="t-BreadcrumbRegion-body">
          <div class="t-BreadcrumbRegion-title"><h1 class="t-BreadcrumbRegion-titleText">${esc(pageSpec.title)}</h1></div>
        </div>
        <div class="t-BreadcrumbRegion-buttons">${pageSpec.primaryAction ? `<button class="t-Button t-Button--hot" type="button"><span class="t-Button-label">${esc(pageSpec.primaryAction)}</span></button>` : ''}</div>
      </div>
    </div>` : '';
    return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}</title>
<link rel="stylesheet" href="${base}/libraries/font-apex/2.5/css/font-apex.min.css">
<link rel="stylesheet" href="${base}/app_ui/css/Core.min.css">
<link rel="stylesheet" href="${base}/themes/theme_42/${v.theme}/css/Core.min.css">
<link rel="stylesheet" href="${base}/themes/theme_42/${v.theme}/css/Vita.min.css">
<link rel="stylesheet" href="css/brand.css">
<style>
/* Preview-only shim: APEX positions the title bar and nav with JavaScript at runtime. Not part of the design. */
.t-Body-title{position:static!important;inset:auto!important;inline-size:auto!important}
.t-Body-content{padding-block-start:0!important}
${side ? '' : '.t-Body-nav{display:none!important}.t-Body-main{margin-inline-start:0!important}'}
.t-Header-nav .a-MenuBar ul{display:flex;gap:1.5rem;list-style:none;margin:0;padding:0 1rem}
.concept-sample{position:fixed;inset-block-end:12px;inset-inline-end:12px;z-index:9999;margin:0;padding:6px 12px;border-radius:999px;background:#1b1b1f;color:#fff;font:600 12px/1.2 system-ui,sans-serif;letter-spacing:.04em}
@media (max-width:640px){.t-Body-nav{display:none!important}.t-Body-main{margin-inline-start:0!important}.row>.col{flex:0 0 100%;max-width:100%}.t-Header-nav{display:none}}
</style>
</head>
<body class="t-PageBody ${side ? 't-PageBody--hideLeft' : 't-PageBody--topNav'} t-PageBody--hideActions t-PageTemplate--standard apex-side-nav apex-icons-fontapex apex-theme-vita js-navExpanded ${esc(pageSpec.bodyClass || '')}">
<a href="#main" class="u-VisuallyHidden" id="t_Body_skipToContent">Skip to main content</a>
${pageSpec.data === 'sample' ? '<p class="concept-sample" role="note">Sample data: numbers are illustrative</p>' : ''}
<header class="t-Header" id="t_Header" role="banner">
  <div class="t-Header-branding">
    <div class="t-Header-controls"><button class="t-Button t-Button--icon t-Button--header t-Button--headerTree" type="button" aria-label="Main navigation"><span class="t-Header-controlsIcon" aria-hidden="true"></span></button></div>
    <div class="t-Header-logo"><a href="#" class="t-Header-logo-link"><span class="apex-logo-text">${esc(shellSpec.app)}</span></a></div>
    <div class="t-Header-navBar"><div class="t-Header-navBar--end"><ul class="t-NavigationBar"><li class="t-NavigationBar-item has-username"><button class="t-Button t-Button--icon t-Button--header t-Button--navBar" type="button" aria-label="${esc(shellSpec.user || 'User')}: user menu"><span class="t-Icon fa fa-user" aria-hidden="true"></span><span class="t-Button-label">${esc(shellSpec.user || 'User')}</span></button></li></ul></div></div>
  </div>
  <div class="t-Header-nav">${side ? '' : `<nav class="a-MenuBar" aria-label="Main navigation"><ul>${topNav}</ul></nav>`}</div>
</header>
<div class="t-Body">
  ${side ? `<div class="t-Body-nav" id="t_Body_nav" role="navigation" aria-label="Main navigation"><div class="t-TreeNav t-TreeNav--styleA"><div class="a-TreeView"><ul role="tree" aria-label="Main navigation">${sideNav}</ul></div></div></div>` : ''}
  <div class="t-Body-main">
    ${titleBar}
    <div class="t-Body-content" id="t_Body_content">
      <main id="main" class="t-Body-mainContent">
        <div class="t-Body-contentInner"><div class="container">
${body}
        </div></div>
      </main>
    </div>
  </div>
</div>
</body>
</html>
`;
}

// Page front matter: <!-- page: {"title": "...", "primaryAction": "...", "chrome": {...}} -->
function frontMatter(html, slug) {
    const m = /<!--\s*page:\s*(\{[\s\S]*?\})\s*-->/.exec(html);
    let spec = {};
    if (m) spec = JSON.parse(m[1]);
    return { slug, title: spec.title || slug, ...spec };
}

// ---------- generic-AI tells, measured in the browser ----------

function measureTells() {
    const vis = (el) => { const r = el.getBoundingClientRect(); return r.width > 40 && r.height > 24; };
    const main = document.querySelector('main') || document.body;
    const surfaces = [...main.querySelectorAll('.t-Region, .t-Card, .a-CardView, [class*="brand-"]')].filter(vis)
        .filter((el) => { const cs = getComputedStyle(el); return cs.backgroundColor !== 'rgba(0, 0, 0, 0)' || parseFloat(cs.borderTopWidth) > 0; });
    const primary = getComputedStyle(document.documentElement).getPropertyValue('--brand-primary').trim().toLowerCase();
    const hexToRgb = (h) => { const m = /^#?([0-9a-f]{6})$/i.exec(h); return m ? `rgb(${parseInt(m[1].slice(0, 2), 16)}, ${parseInt(m[1].slice(2, 4), 16)}, ${parseInt(m[1].slice(4, 6), 16)})` : ''; };
    const primaryRgb = hexToRgb(primary);
    const outlined = surfaces.filter((el) => { const cs = getComputedStyle(el); return parseFloat(cs.borderTopWidth) >= 1 && cs.borderTopColor === primaryRgb; });
    const sizes = new Map();
    for (const el of surfaces) { const r = el.getBoundingClientRect(); const k = `${Math.round(r.width / 10)}x${Math.round(r.height / 10)}`; sizes.set(k, (sizes.get(k) || 0) + 1); }
    const sameBox = Math.max(0, ...sizes.values());
    const fontSizes = [...main.querySelectorAll('h1,h2,h3,p,span,div,td,th,li,a')].filter((e) => e.childNodes.length && [...e.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim()))
        .map((e) => parseFloat(getComputedStyle(e).fontSize));
    const maxFont = Math.max(16, ...fontSizes);
    const bodyFont = 16;
    // Area painted in a non-neutral colour (any saturated background) in the first viewport.
    let colourArea = 0;
    for (const el of main.querySelectorAll('*')) {
        const cs = getComputedStyle(el);
        const m = /rgba?\((\d+), (\d+), (\d+)(?:, ([\d.]+))?\)/.exec(cs.backgroundColor);
        if (!m || (m[4] !== undefined && Number(m[4]) < 0.5)) continue;
        const [r, g, b] = [Number(m[1]), Number(m[2]), Number(m[3])];
        const sat = Math.max(r, g, b) - Math.min(r, g, b);
        if (sat < 40) continue;
        const rect = el.getBoundingClientRect();
        const w = Math.max(0, Math.min(rect.right, innerWidth) - Math.max(rect.left, 0));
        const h = Math.max(0, Math.min(rect.bottom, innerHeight) - Math.max(rect.top, 0));
        colourArea = Math.max(colourArea, (w * h) / (innerWidth * innerHeight));
    }
    return { surfaces: surfaces.length, outlined: outlined.length, sameBox, scaleContrast: +(maxFont / bodyFont).toFixed(2), boldestColourBlock: +colourArea.toFixed(3) };
}

// Text that runs out of its own box (a long label in a fixed-width button or stub). Real data is longer
// than mock data; this is the check that catches it before the build does.
function measureSpill() {
    const out = [];
    for (const el of document.querySelectorAll('main *')) {
        if (!el.childNodes.length || ![...el.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim())) continue;
        const cs = getComputedStyle(el);
        if (cs.overflowX !== 'visible' || cs.display === 'inline' || el.clientWidth === 0) continue;
        if (el.closest('.brand-scroll, .t-Report-tableWrap, [tabindex="0"]')) continue;
        if (el.scrollWidth > el.clientWidth + 2) {
            out.push(`${el.tagName.toLowerCase()}${el.classList.length ? '.' + [...el.classList].join('.') : ''} ("${el.textContent.trim().slice(0, 40)}")`);
        }
        if (out.length >= 5) break;
    }
    return out;
}

function tellsFrom(m) {
    const tells = [];
    if (m.surfaces >= 4 && m.outlined / m.surfaces > 0.5) tells.push(`Brand colour outlines ${m.outlined} of ${m.surfaces} surfaces: an outline is not a design idea. Use fills, bands, or type instead.`);
    if (m.surfaces >= 6 && m.sameBox / m.surfaces > 0.6) tells.push(`${m.sameBox} of ${m.surfaces} surfaces are the same box: a uniform card grid reads as a template. Vary scale to show what matters most.`);
    if (m.scaleContrast < 2) tells.push(`The largest text is only ${m.scaleContrast}x body size: there is no hero moment. Give the page one element at 2.5x or more.`);
    if (m.boldestColourBlock < 0.04) tells.push('No block of colour anywhere in the first screen: the brand appears only in lines and text. Commit to one confident colour moment.');
    return tells;
}

// ---------- render a concept ----------

async function renderConcept(args) {
    const dir = path.resolve(args.concept);
    const slug = path.basename(dir);
    const outDir = path.resolve(args.out || path.join('working', 'design-preview', 'concepts', slug));
    const need = ['concept.md', 'shell.json', 'brand-kit.json', 'css/brand.css', 'pages'];
    for (const f of need) if (!(await exists(path.join(dir, f)))) throw new Error(`${slug}: missing ${f}.${f === 'css/brand.css' ? ` Run: node scripts/build-brand-kit.mjs --kit ${path.relative(process.cwd(), path.join(dir, 'brand-kit.json'))}` : ''}`);
    const kit = await readJson(path.join(dir, 'brand-kit.json'));
    const shellSpec = await readJson(path.join(dir, 'shell.json'));
    const conceptMd = await fs.readFile(path.join(dir, 'concept.md'), 'utf8');
    const components = (await exists(path.join(dir, 'components.css'))) ? await fs.readFile(path.join(dir, 'components.css'), 'utf8') : '';
    const brandCss = await fs.readFile(path.join(dir, 'css', 'brand.css'), 'utf8');
    if (components && !brandCss.includes(components.replace(/\r/g, '').trim().slice(0, 200))) {
        throw new Error(`${slug}: css/brand.css is older than components.css. Rebuild: node scripts/build-brand-kit.mjs --kit ${path.relative(process.cwd(), path.join(dir, 'brand-kit.json'))}`);
    }
    const briefMd = await fs.readFile(path.join(path.dirname(dir), 'brief.md'), 'utf8').catch(() => '');
    if (!briefMd) throw new Error(`${slug}: ${path.relative(process.cwd(), path.join(path.dirname(dir), 'brief.md'))} is missing. Write the shared brief first (creative-direction.md section 2).`);
    const ctx = { definedClasses: classesDefinedIn(brandCss), mappedClasses: classesMappedIn(conceptMd), brandWords: [...new Set([...brandWordsFrom(kit), ...forbiddenWordsFrom(briefMd)])] };
    const structure = conceptStructureProblems(conceptMd);
    if (structure.length) throw new Error(`${slug}: ${structure.join(' ')}`);

    await fs.mkdir(path.join(outDir, 'shots'), { recursive: true });
    await fs.cp(path.join(dir, 'css'), path.join(outDir, 'css'), { recursive: true });
    if (await exists(path.join(dir, 'fonts'))) await fs.cp(path.join(dir, 'fonts'), path.join(outDir, 'fonts'), { recursive: true });

    const pageFiles = (await fs.readdir(path.join(dir, 'pages'))).filter((f) => f.endsWith('.html')).sort();
    if (!pageFiles.length) throw new Error(`${slug}: pages/ has no .html compositions.`);
    const results = [];
    let lintFailures = 0;
    for (const file of pageFiles) {
        const pslug = file.replace(/\.html$/, '');
        const fragment = await fs.readFile(path.join(dir, 'pages', file), 'utf8');
        const pageSpec = frontMatter(fragment, pslug);
        const problems = lintFragment(fragment, ctx);
        lintFailures += problems.length;
        await fs.writeFile(path.join(outDir, file), shell({ version: kit.version || '26.2', shellSpec, pageSpec, body: fragment, title: `${shellSpec.app} - ${pageSpec.title}` }), 'utf8');
        results.push({ page: pslug, title: pageSpec.title, problems, viewports: {} });
    }

    if (args.shots) {
        let chromium; let AxeBuilder;
        try {
            ({ chromium } = await import('playwright'));
            ({ default: AxeBuilder } = await import('@axe-core/playwright'));
        } catch (error) {
            throw new Error(`Playwright dependencies are not installed. Run "npm install" and "npx playwright install chromium". ${error.message}`);
        }
        const browser = await chromium.launch({ headless: true });
        try {
            for (const r of results) {
                for (const vp of VIEWPORTS) {
                    const context = await browser.newContext({ viewport: { width: vp.width, height: vp.height }, reducedMotion: 'reduce' });
                    const page = await context.newPage();
                    await page.goto(pathToFileURL(path.join(outDir, `${r.page}.html`)).href, { waitUntil: 'load', timeout: 45000 });
                    await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});
                    await page.evaluate(async () => { if (document.fonts) await document.fonts.ready; });
                    await page.screenshot({ path: path.join(outDir, 'shots', `${r.page}-${vp.name}.png`), fullPage: true });
                    await page.screenshot({ path: path.join(outDir, 'shots', `${r.page}-${vp.name}-fold.png`) });
                    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - innerWidth);
                    const found = await new AxeBuilder({ page }).withTags(AXE_TAGS).analyze();
                    const serious = found.violations.filter((v) => v.impact === 'serious' || v.impact === 'critical').map((v) => `${v.id} x${v.nodes.length}`);
                    const tells = vp.name === 'desktop' ? tellsFrom(await page.evaluate(measureTells)) : [];
                    const spill = await page.evaluate(measureSpill);
                    r.viewports[vp.name] = { overflow, axe: serious, tells, spill };
                    await context.close();
                }
            }
        } finally {
            await browser.close();
        }
    }

    const blockers = results.flatMap((r) => [...r.problems.map((p) => `${r.page}: ${p}`),
        ...Object.entries(r.viewports).flatMap(([vp, v]) => [...v.axe.map((a) => `${r.page} (${vp}): accessibility ${a}`), ...(v.overflow > 0 ? [`${r.page} (${vp}): ${v.overflow}px horizontal overflow`] : []),
            ...(v.spill || []).map((e) => `${r.page} (${vp}): text spills out of ${e}; shorten the copy, let it wrap, or widen the box`)])]);
    const tells = results.flatMap((r) => (r.viewports.desktop?.tells || []).map((t) => `${r.page}: ${t}`));
    const report = [
        `# Concept render: ${slug}`,
        '',
        `- Concept: ${path.relative(process.cwd(), dir)}`,
        `- Reference: ${kit.source?.reference || 'none'}`,
        `- Pages: ${results.map((r) => r.page).join(', ')}`,
        `- Screenshots: shots/<page>-desktop.png, shots/<page>-mobile.png (open every one before the critique)`,
        '',
        '## Blockers (guardrails: must be zero)',
        '',
        ...(blockers.length ? blockers.map((b) => `- ${b}`) : ['None.']),
        '',
        '## Generic-AI tells (the critique must answer each one: fix it, or say why it is right here)',
        '',
        ...(tells.length ? tells.map((t) => `- ${t}`) : ['None detected. Detection is narrow: still run the critique in creative-direction.md.']),
        ''
    ].join('\n');
    await fs.writeFile(path.join(outDir, 'report.md'), report, 'utf8');
    await fs.writeFile(path.join(outDir, 'report.json'), `${JSON.stringify({ concept: slug, blockers, tells, results }, null, 2)}\n`, 'utf8');
    process.stdout.write(`${report}\n`);
    if (blockers.length) {
        process.stdout.write(`CONCEPT BLOCKED (${blockers.length})\n`);
        process.exit(1);
    }
    process.stdout.write(`Rendered to ${path.relative(process.cwd(), outDir)}\nCONCEPT RENDERED\n`);
}

// ---------- board ----------

async function renderBoard(args) {
    const conceptsDir = path.resolve(args.board);
    const previewRoot = path.resolve(args.out || path.join('working', 'design-preview', 'concepts'));
    const slugs = (await fs.readdir(conceptsDir, { withFileTypes: true })).filter((d) => d.isDirectory()).map((d) => d.name).sort();

    // The brief comes first: data reality and forbidden words are decided before any concept.
    const briefMd = await fs.readFile(path.join(conceptsDir, 'brief.md'), 'utf8').catch(() => '');
    const briefProblems = [];
    if (!briefMd) briefProblems.push('brief.md is missing');
    if (briefMd && !/^##\s+Data reality/im.test(briefMd)) briefProblems.push('brief.md has no "## Data reality" section (which tables and columns really exist; what the pages may not promise)');
    if (briefMd && !forbiddenWordsFrom(briefMd).length) briefProblems.push('brief.md has no "**Forbidden words:**" line (the reference brand\'s product words)');
    if (briefProblems.length) {
        process.stdout.write(`${briefProblems.map((p) => `- ${p}`).join('\n')}\nBOARD BLOCKED\n`);
        process.exit(1);
    }

    const cards = [];
    const blocked = [];
    const candidates = [];
    for (const slug of slugs) {
        const md = await fs.readFile(path.join(conceptsDir, slug, 'concept.md'), 'utf8').catch(() => '');
        const name = (/^#\s+(.+)$/m.exec(md) || [, slug])[1].trim();
        const idea = (/^\*\*Big idea:?\*\*:?\s*(.+)$/im.exec(md) || /^>\s*(.+)$/m.exec(md) || [, ''])[1].trim();
        const shots = path.join(previewRoot, slug, 'shots');
        const files = (await fs.readdir(shots).catch(() => [])).filter((f) => /-desktop-fold\.png$/.test(f)).sort();
        const mobile = (await fs.readdir(shots).catch(() => [])).filter((f) => /-mobile-fold\.png$/.test(f)).sort();
        const report = await readJson(path.join(previewRoot, slug, 'report.json')).catch(() => null);
        const problems = [...conceptStructureProblems(md)];
        if (!files.length || !report) problems.push('not rendered (run --concept first)');
        if (report?.blockers?.length) problems.push(`${report.blockers.length} guardrail blocker(s) in report.md`);
        problems.push(...critiqueProblems(md, report?.tells || []));
        const isMix = /^\*\*Mix of:?\*\*/im.test(md) || /\(mix\b/i.test(name);
        candidates.push({ slug, name, axes: axesOf(md), isMix });
        if (problems.length) { blocked.push({ slug, problems }); continue; }
        cards.push({ slug, name, idea, files: files.map((f) => `${slug}/shots/${f}`), mobile: mobile[0] ? `${slug}/shots/${mobile[0]}` : null });
    }

    // Divergence: original concepts must differ on at least two axes, or they are one idea in two colours.
    const originals = candidates.filter((c) => !c.isMix);
    for (let i = 0; i < originals.length; i += 1) {
        for (let j = i + 1; j < originals.length; j += 1) {
            const a = originals[i].axes;
            const b = originals[j].axes;
            const keys = [...new Set([...Object.keys(a), ...Object.keys(b)])];
            const differ = keys.filter((k) => a[k] !== b[k]).length;
            if (keys.length && differ < 2) blocked.push({ slug: `${originals[i].slug} + ${originals[j].slug}`, problems: [`differ on only ${differ} axis; concepts must differ on at least two (creative-direction.md section 3)`] });
        }
    }
    if (blocked.length) process.stdout.write(`Not on the board:\n${blocked.map((b) => `- ${b.slug}: ${b.problems.join('; ')}`).join('\n')}\n`);
    if (cards.length < 3 || blocked.some((b) => b.slug.includes(' + '))) {
        process.stdout.write(`${cards.length} concept(s) ready; the board needs at least 3 genuinely different, critiqued concepts.\nBOARD BLOCKED\n`);
        process.exit(1);
    }
    const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Design concepts</title>
<style>body{margin:0;font:16px/1.5 system-ui,sans-serif;background:#f4f4f2;color:#111}main{padding:32px}h1{margin:0 0 24px;font-size:28px}
.c{background:#fff;border-radius:12px;padding:24px;margin:0 0 32px;box-shadow:0 1px 3px rgba(0,0,0,.08)}.c h2{margin:0;font-size:22px}.c p{margin:4px 0 16px;color:#444}
.g{display:grid;grid-template-columns:repeat(auto-fit,minmax(420px,1fr));gap:16px;align-items:start}.g img{width:100%;border:1px solid #ddd;border-radius:6px}.m{max-width:220px}</style></head>
<body><main><h1>Design concepts: pick one, or mix</h1>
${cards.map((c, i) => `<section class="c"><h2>${String.fromCharCode(65 + i)}. ${esc(c.name)}</h2><p>${esc(c.idea)}</p><div class="g">${c.files.map((f) => `<img src="${esc(f)}" alt="${esc(c.name)}: ${esc(path.basename(f))}">`).join('')}${c.mobile ? `<img class="m" src="${esc(c.mobile)}" alt="${esc(c.name)} on mobile">` : ''}</div></section>`).join('\n')}
</main></body></html>`;
    await fs.writeFile(path.join(previewRoot, 'board.html'), html, 'utf8');
    if (args.shots) {
        try {
            const { chromium } = await import('playwright');
            const browser = await chromium.launch({ headless: true });
            const page = await browser.newPage({ viewport: { width: 1600, height: 1000 } });
            await page.goto(pathToFileURL(path.join(previewRoot, 'board.html')).href, { waitUntil: 'load' });
            await page.screenshot({ path: path.join(previewRoot, 'board.png'), fullPage: true });
            await browser.close();
        } catch (error) {
            process.stderr.write(`Board screenshot skipped: ${error.message}\n`);
        }
    }
    process.stdout.write(`Board: ${path.relative(process.cwd(), path.join(previewRoot, 'board.html'))} (${cards.length} concepts)\nBOARD RENDERED\n`);
}

async function main() {
    let args;
    try {
        args = parseArgs(process.argv.slice(2));
    } catch (error) {
        process.stderr.write(`${error.message}\n\n${usage()}`);
        process.exit(2);
    }
    if (args.board) await renderBoard(args);
    else await renderConcept(args);
}

if (import.meta.url === pathToFileURL(process.argv[1] || '').href) {
    main().catch((error) => {
        process.stderr.write(`${error.message}\n`);
        process.exit(1);
    });
}
