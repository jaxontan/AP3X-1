#!/usr/bin/env node
// Deterministic design score (0-100) for an APEX prototype or a live APEX page.
// Measures the rendered page: reference fidelity against brand-kit.json, craft rules, the
// "still looks like stock APEX" tells, and axe accessibility. Every failed check names its fix.
// A design passes at 85+ with no failed blocker. Weaker and stronger models are held to the same bar.
//
//   node scripts/score-design.mjs --preview working/design-preview/<name> --kit working/page-design/design/brand/brand-kit.json
//   node scripts/score-design.mjs --url https://host/ords/r/ws/app/home --kit .../brand-kit.json
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { pathToFileURL } from 'node:url';

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1')), '..');
const VIEWPORTS = [{ name: 'desktop', width: 1440, height: 900 }, { name: 'mobile', width: 390, height: 844 }];
const AXE_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22a', 'wcag22aa'];
const PASS_SCORE = 85;

function usage() {
    return `Usage:
  node scripts/score-design.mjs --preview <dir-or-html> --kit <brand-kit.json> [options]
  node scripts/score-design.mjs --url <page-url> --kit <brand-kit.json> [options]

Options:
  -p, --preview <path>  Prototype directory (scores after.html, else index.html) or an HTML file
  -u, --url <url>       Live page to score instead of a prototype
  -k, --kit <file>      brand-kit.json: the design targets (required)
  -o, --out <dir>       Output directory (default: <preview>/score)
      --user <name>     Log in to the APEX app first (password from APEX_TEST_PASSWORD, never the command line)
      --password-env <n> Environment variable holding the password (default APEX_TEST_PASSWORD)
      --insecure        Accept self-signed HTTPS certificates (local disposable instances)
      --channel <name>  Playwright browser channel
  -h, --help            Show this help

Writes score.json, score.md, screenshots, and compare-desktop.png (reference beside the design)
when the kit's reference capture exists. Prints DESIGN SCORE PASS or DESIGN SCORE FAIL.
`;
}

function parseArgs(argv) {
    const args = { preview: null, url: null, kit: null, out: null, user: null, passwordEnv: 'APEX_TEST_PASSWORD', insecure: false, channel: process.env.PLAYWRIGHT_CHANNEL || null };
    const next = (i, flag) => {
        const v = argv[i + 1];
        if (!v || v.startsWith('--')) throw new Error(`Missing value for ${flag}.`);
        return v;
    };
    for (let i = 0; i < argv.length; i += 1) {
        const a = argv[i];
        if (a === '-p' || a === '--preview') { args.preview = next(i, a); i += 1; }
        else if (a === '-u' || a === '--url') { args.url = next(i, a); i += 1; }
        else if (a === '-k' || a === '--kit') { args.kit = next(i, a); i += 1; }
        else if (a === '-o' || a === '--out') { args.out = next(i, a); i += 1; }
        else if (a === '--channel') { args.channel = next(i, a); i += 1; }
        else if (a === '--user') { args.user = next(i, a); i += 1; }
        else if (a === '--password-env') { args.passwordEnv = next(i, a); i += 1; }
        else if (a === '--insecure') args.insecure = true;
        else if (a === '-h' || a === '--help') { process.stdout.write(usage()); process.exit(0); }
        else throw new Error(`Unknown argument: ${a}`);
    }
    if (!args.preview && !args.url) throw new Error('Pass --preview or --url.');
    if (!args.kit) throw new Error('Pass --kit <brand-kit.json>; the score measures the design against it.');
    if (args.user && !args.url) throw new Error('--user only applies with --url.');
    if (args.user && !process.env[args.passwordEnv]) throw new Error(`Set the ${args.passwordEnv} environment variable; the password is never passed on the command line.`);
    return args;
}

// Log in through the APEX login page, then return to the target page in the same session.
async function apexLogin(page, url, user, password) {
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 45000 });
    const pwd = page.locator('input[id$="_PASSWORD"], input[type="password"]').first();
    if (await pwd.count() === 0) return;
    await page.locator('input[id$="_USERNAME"], input[name$="_USERNAME"]').first().fill(user);
    await pwd.fill(password);
    const before = page.url();
    await pwd.press('Enter');
    await page.waitForURL((u) => u.toString() !== before, { timeout: 30000 }).catch(() => {});
    await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});
    if (await page.locator('input[type="password"]').count() > 0) throw new Error(`Login failed for ${user}: still on the login page.`);
}

// ---------- colour ----------

function parseColor(value) {
    const m = /rgba?\(([^)]+)\)/.exec(value || '');
    if (m) {
        const p = m[1].split(/[ ,/]+/).filter(Boolean).map(Number);
        return { rgb: p.slice(0, 3), alpha: p.length > 3 ? p[3] : 1 };
    }
    const h = /^#([0-9a-f]{6})$/i.exec(String(value || '').trim());
    if (h) return { rgb: [0, 2, 4].map((i) => parseInt(h[1].slice(i, i + 2), 16)), alpha: 1 };
    return null;
}

function lab([r, g, b]) {
    const lin = (c) => {
        const s = c / 255;
        return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
    };
    const [R, G, B] = [lin(r), lin(g), lin(b)];
    const f = (t) => (t > 0.008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116);
    const x = f((R * 0.4124 + G * 0.3576 + B * 0.1805) / 0.95047);
    const y = f(R * 0.2126 + G * 0.7152 + B * 0.0722);
    const z = f((R * 0.0193 + G * 0.1192 + B * 0.9505) / 1.08883);
    return [116 * y - 16, 500 * (x - y), 200 * (y - z)];
}

function deltaE(a, b) {
    const ca = parseColor(a);
    const cb = parseColor(b);
    if (!ca || !cb) return 999;
    const [l1, a1, b1] = lab(ca.rgb);
    const [l2, a2, b2] = lab(cb.rgb);
    return Math.round(Math.sqrt((l1 - l2) ** 2 + (a1 - a2) ** 2 + (b1 - b2) ** 2) * 10) / 10;
}

function hex(value) {
    const c = parseColor(value);
    return c ? `#${c.rgb.map((n) => Math.round(n).toString(16).padStart(2, '0')).join('').toUpperCase()}` : String(value);
}

// ---------- measurement (browser side) ----------

function measure(fontFamily) {
    const visible = (el) => {
        if (!el) return false;
        const r = el.getBoundingClientRect();
        const s = getComputedStyle(el);
        return r.width > 0 && r.height > 0 && s.visibility !== 'hidden' && s.display !== 'none';
    };
    const first = (selectors) => {
        for (const sel of selectors) {
            const found = Array.from(document.querySelectorAll(sel)).find(visible);
            if (found) return found;
        }
        return null;
    };
    const style = (el) => (el ? getComputedStyle(el) : null);
    const px = (v) => parseFloat(v) || 0;

    const header = first(['.t-Header']);
    const hot = Array.from(document.querySelectorAll('.t-Button--hot:not(.t-Button--simple):not(.t-Button--link):not(.t-Button--noUI)')).filter(visible);
    const nav = first(['.t-Body-nav']);
    const navSelected = first(['.t-TreeNav .a-TreeView-row.is-current--top', '.t-TreeNav .a-TreeView-row.is-selected']);
    const navSelectedLabel = first(['.t-TreeNav .a-TreeView-content.is-current--top .a-TreeView-label']);
    const logo = first(['.t-Header-logo-link', '.t-Header-logo']);
    const region = first(['.t-Region:not(.t-Region--noUI)']);
    const card = first(['.a-CardView']);
    const pageTitle = first(['.t-BreadcrumbRegion-titleText', '.t-BreadcrumbRegion--useBreadcrumbTitle .t-Breadcrumb-item:last-child .t-Breadcrumb-label', '.t-Breadcrumb-item:last-child', 'h1']);
    const regionTitles = Array.from(document.querySelectorAll('.t-Region-title')).filter(visible);
    const content = first(['.t-Body-content', '.t-Body-main', 'body']);
    const bodyStyle = getComputedStyle(document.body);

    // Text sizes and spacing across visible elements.
    const sizes = new Map();
    const spacing = [];
    const targets = [];
    const all = Array.from(document.querySelectorAll('body *')).slice(0, 4000);
    for (const el of all) {
        if (!visible(el)) continue;
        const s = getComputedStyle(el);
        const ownText = Array.from(el.childNodes).filter((n) => n.nodeType === 3 && n.textContent.trim()).length > 0;
        if (ownText) sizes.set(Math.round(px(s.fontSize)), (sizes.get(Math.round(px(s.fontSize))) || 0) + 1);
        for (const p of ['paddingTop', 'paddingLeft', 'marginBottom', 'rowGap', 'columnGap']) {
            const v = px(s[p]);
            if (v >= 2 && v <= 96) spacing.push(v);
        }
        // WCAG 2.5.8 target size: controls, measured on the clickable box (a nav label's row, not its text).
        // Inline links in text and visually hidden skip links are exempt.
        if (el.matches('button, input:not([type="hidden"]), select, textarea, [role="button"], a.t-Button, .a-TreeView-label')) {
            const box = el.closest('.a-TreeView-content') || el;
            const r = box.getBoundingClientRect();
            if (r.width > 1 && r.height > 1 && r.top < window.innerHeight * 2) targets.push({ w: Math.round(r.width), h: Math.round(r.height), text: (el.innerText || el.getAttribute('aria-label') || el.tagName).trim().slice(0, 30) });
        }
    }

    // Body line height: median ratio over text elements that declare a numeric line height.
    const ratios = [];
    for (const el of all) {
        if (ratios.length > 200 || !visible(el)) continue;
        const s = getComputedStyle(el);
        const hasText = Array.from(el.childNodes).some((n) => n.nodeType === 3 && n.textContent.trim().length > 3);
        if (hasText && px(s.lineHeight) > 0 && px(s.fontSize) >= 12 && px(s.fontSize) <= 18) ratios.push(px(s.lineHeight) / px(s.fontSize));
    }
    ratios.sort((a, b) => a - b);
    const lineHeight = ratios.length ? ratios[Math.floor(ratios.length / 2)] : 1.2;

    // Points whose rendered pixel colour gives the effective background (children often paint it).
    const rectPoint = (el, fx, fy) => {
        if (!el) return null;
        const r = el.getBoundingClientRect();
        return { x: Math.round(r.left + r.width * fx), y: Math.round(r.top + Math.min(r.height - 2, Math.max(2, r.height * fy))) };
    };
    const samples = {
        header: header ? { x: Math.round(window.innerWidth * 0.55), y: Math.round(header.getBoundingClientRect().top + 3) } : null,
        nav: nav ? rectPoint(nav, 0.5, 0.97) : null,
        navSelected: navSelected ? rectPoint(navSelected, 0.9, 0.5) : null
    };

    const fontLoaded = fontFamily && document.fonts ? document.fonts.check(`16px "${fontFamily}"`) : false;
    return {
        brandPrimary: getComputedStyle(document.documentElement).getPropertyValue('--brand-primary').trim(),
        header: header ? { bg: style(header).backgroundColor, color: style(header).color } : null,
        hot: hot.map((b) => ({ bg: style(b).backgroundColor, color: style(b).color, radius: style(b).borderTopLeftRadius, h: Math.round(b.getBoundingClientRect().height) })),
        nav: nav ? { bg: style(nav).backgroundColor, color: style(nav).color } : null,
        navSelected: navSelected ? { bg: style(navSelected).backgroundColor, color: style(navSelectedLabel || navSelected).color } : null,
        logo: logo ? { color: style(logo).color } : null,
        ground: style(content).backgroundColor,
        bodyBg: bodyStyle.backgroundColor,
        region: region ? { bg: style(region).backgroundColor, radius: px(style(region).borderTopLeftRadius), shadow: style(region).boxShadow, border: style(region).borderTopWidth } : null,
        card: card ? { radius: px(style(card).borderTopLeftRadius), shadow: style(card).boxShadow } : null,
        fonts: {
            body: bodyStyle.fontFamily,
            pageTitle: pageTitle ? style(pageTitle).fontFamily : null,
            loaded: fontLoaded
        },
        type: {
            bodySize: px(bodyStyle.fontSize),
            bodyLineHeight: lineHeight,
            pageTitleSize: pageTitle ? px(style(pageTitle).fontSize) : 0,
            pageTitleWeight: pageTitle ? Number(style(pageTitle).fontWeight) : 0,
            regionTitleWeights: regionTitles.map((t) => Number(style(t).fontWeight)),
            sizes: Array.from(sizes.entries()).sort((a, b) => b[1] - a[1])
        },
        spacing,
        targets,
        samples,
        overflow: Math.max(document.documentElement.scrollWidth, document.body.scrollWidth) - window.innerWidth
    };
}

// Rendered pixel colours at named points, read from a viewport screenshot.
async function pixels(page, points) {
    const entries = Object.entries(points).filter(([, p]) => p && p.x >= 0 && p.y >= 0);
    if (!entries.length) return {};
    return page.evaluate(async ({ shot, entries: list }) => {
        const img = new Image();
        img.src = shot;
        await img.decode();
        const canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0);
        const out = {};
        for (const [name, p] of list) {
            const d = ctx.getImageData(Math.min(p.x, img.width - 1), Math.min(p.y, img.height - 1), 1, 1).data;
            out[name] = `rgb(${d[0]}, ${d[1]}, ${d[2]})`;
        }
        return out;
    }, { shot: `data:image/png;base64,${(await page.screenshot()).toString('base64')}`, entries });
}

// Fraction of the first viewport painted in a colour (sampled from the screenshot).
async function coverage(page, colors) {
    return page.evaluate(async ({ shot, colors: targets }) => {
        const img = new Image();
        img.src = shot;
        await img.decode();
        const canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0);
        const data = ctx.getImageData(0, 0, img.width, img.height).data;
        const rgbs = targets.map((h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16)));
        const hits = rgbs.map(() => 0);
        let n = 0;
        for (let i = 0; i < data.length; i += 4 * 7) {
            n += 1;
            rgbs.forEach((c, k) => {
                if (Math.abs(data[i] - c[0]) + Math.abs(data[i + 1] - c[1]) + Math.abs(data[i + 2] - c[2]) < 40) hits[k] += 1;
            });
        }
        return hits.map((h) => h / n);
    }, { shot: `data:image/png;base64,${(await page.screenshot()).toString('base64')}`, colors });
}

// ---------- scoring ----------

function check(id, title, weight, pass, measured, expected, fix, blocker = false) {
    return { id, title, weight, pass: Boolean(pass), earned: pass ? weight : 0, measured, expected, fix, blocker };
}

function score(kit, stock, m, mobile, axe, cover) {
    const t = kit.derived;
    const checks = [];
    const stockHeader = stock['--ut-header-background-color'];
    const stockPrimary = stock['--ut-palette-primary'];
    const stockNav = stock['--ut-body-nav-background-color'];
    const firstHot = m.hot[0];

    // Blockers
    const seriousAxe = axe.filter((v) => v.impact === 'serious' || v.impact === 'critical');
    checks.push(check('B1', 'No serious or critical accessibility violations (desktop + mobile)', 15, seriousAxe.length === 0,
        seriousAxe.map((v) => `${v.viewport}: ${v.id} x${v.nodes}`).join('; ') || 'none', '0',
        'Fix each axe finding. Contrast: change the colour in brand-kit.json and rebuild; markup: fix the prototype spec or region.', true));
    checks.push(check('B2', 'No horizontal overflow at 390px', 5, mobile.overflow <= 1, `${mobile.overflow}px`, '0px',
        'Make wide content scroll inside its region (reports) or stack columns on mobile.', true));
    const stockTells = [];
    if (m.header && deltaE(m.header.bg, stockHeader) < 5) stockTells.push('header is stock Vita blue');
    if (firstHot && deltaE(firstHot.bg, stockPrimary) < 5) stockTells.push('primary button is stock Vita blue');
    if (m.nav && deltaE(m.nav.bg, stockNav) < 5 && kit.nav?.style !== 'dark') stockTells.push('side nav is stock Vita charcoal');
    if (/^system-ui|^-apple-system/.test(m.fonts.body.replace(/["']/g, '').trim()) && kit.font?.family) stockTells.push('body font is the stock system stack');
    checks.push(check('B3', 'Does not look like stock APEX', 10, stockTells.length === 0, stockTells.join('; ') || 'no stock tells', 'none of: stock header, stock blue button, stock nav, system font',
        'Load the generated brand.css app-wide and keep its section 3 (hot button) and 4 (nav) rules; set font.family and fetch the font.', true));
    checks.push(check('B4', 'brand.css is loaded', 5, Boolean(m.brandPrimary), m.brandPrimary || 'missing', '--brand-primary defined',
        'Link css/brand.css (prototype) or set application css.fileUrls to #APP_FILES#css/brand.css?v=#APP_VERSION#.', true));

    // Fidelity to the brand kit (which carries the reference)
    checks.push(check('F1', 'Primary action uses the kit action colour', 8, firstHot && deltaE(firstHot.bg, t.action) < 5,
        firstHot ? hex(firstHot.bg) : 'no hot button rendered', t.action, 'Use a hot button for the main action; keep brand.css section 3. Change colors.action in brand-kit.json if the target is wrong.'));
    checks.push(check('F2', 'Header matches the kit header style', 5, m.header && deltaE(m.header.bg, t.headerBg) < 5,
        m.header ? hex(m.header.bg) : 'no header', `${t.headerBg} (${kit.header?.style})`, 'Set header.style in brand-kit.json (light | brand | dark) and rebuild.'));
    checks.push(check('F3', 'Page ground matches the kit', 4, deltaE(m.ground, t.ground) < 5 || deltaE(m.bodyBg, t.ground) < 5,
        hex(m.ground), t.ground, 'Set colors.ground in brand-kit.json and rebuild.'));
    const usesFont = kit.font?.family && m.fonts.body.includes(kit.font.family) && m.fonts.loaded;
    checks.push(check('F4', 'Brand font is loaded and used', 8, !kit.font?.family || usesFont,
        `${m.fonts.body.split(',')[0]}${m.fonts.loaded ? ' (loaded)' : ' (NOT loaded)'}`, kit.font?.family || 'system',
        `Run node scripts/fetch-open-font.mjs --family "${kit.font?.family}" --out <brand>/fonts, rebuild the kit, and re-render.`));
    const targetRadius = Number(kit.shape?.radius ?? 6);
    const measuredRadius = m.region?.radius ?? m.card?.radius ?? 0;
    checks.push(check('F5', 'Corner radius matches the kit', 4, Math.abs(measuredRadius - targetRadius) <= 2,
        `${measuredRadius}px`, `${targetRadius}px`, 'Set shape.radius in brand-kit.json and rebuild.'));
    const hasShadow = (m.region?.shadow && m.region.shadow !== 'none') || (m.card?.shadow && m.card.shadow !== 'none');
    const wantShadow = (kit.depth?.shadow || 'soft') === 'soft';
    checks.push(check('F6', 'Depth language matches the kit', 3, hasShadow === wantShadow,
        hasShadow ? 'shadowed surfaces' : 'flat surfaces', wantShadow ? 'soft shadows' : 'flat', 'Set depth.shadow (soft | flat) in brand-kit.json and rebuild.'));
    const hw = Number(kit.font?.headingWeight || 700);
    const weights = [m.type.pageTitleWeight, ...m.type.regionTitleWeights].filter(Boolean);
    checks.push(check('F7', 'Headings carry the reference weight', 6, weights.length > 0 && Math.min(...weights) >= hw - 100,
        `page title ${m.type.pageTitleWeight}, region titles ${[...new Set(m.type.regionTitleWeights)].join('/') || 'none'}`, `>= ${hw - 100}`,
        'Keep brand.css section 5 (heading weight) and the --ut-breadcrumb-title-font-weight mapping; fetch the bold font weights.'));
    const brandVisible = [m.logo?.color, m.navSelected?.bg, m.navSelected?.color, m.header?.bg].some((c) => c && deltaE(c, t.primary) < 8 || (c && deltaE(c, t.primaryText) < 8) || (c && deltaE(c, t.navSelected) < 4));
    checks.push(check('F8', 'Brand colour carries wayfinding (logo, header, or selected nav)', 4, brandVisible,
        `logo ${m.logo ? hex(m.logo.color) : '-'}, selected nav ${m.navSelected ? hex(m.navSelected.bg) : '-'}`, `${t.primary} family`,
        'Keep header.logo = primary or header.style = brand, and the nav rules in brand.css section 4.'));

    // Craft
    const distinct = m.type.sizes.filter(([, n]) => n >= 2).length;
    checks.push(check('C1', 'Restrained type scale', 4, distinct <= 8, `${distinct} sizes used 2+ times`, '<= 8',
        'Remove one-off font sizes; use template options and the brand heading rules instead of custom sizes.'));
    const onGrid = m.spacing.length ? m.spacing.filter((v) => Math.abs(v / 4 - Math.round(v / 4)) < 0.13 || Math.abs(v / 2 - Math.round(v / 2)) < 0.07 && v <= 8).length / m.spacing.length : 1;
    checks.push(check('C2', 'Spacing sits on a 4px grid', 4, onGrid >= 0.8, `${Math.round(onGrid * 100)}%`, '>= 80%',
        'Use Universal Theme spacing template options; avoid custom padding values that are not multiples of 4.'));
    const [primaryCover, actionCover] = cover;
    const brandCover = primaryCover + actionCover;
    checks.push(check('C3', 'Brand colour is present but not overused (first viewport)', 4, brandCover >= 0.003 && brandCover <= 0.25,
        `${(brandCover * 100).toFixed(1)}%`, '0.3% - 25%', brandCover > 0.25 ? 'Brand colour is painting large surfaces; keep it for header/nav, the main action, and status.' : 'Brand colour is missing; check brand.css loads and the primary action is a hot button.'));
    const hotColours = new Set(m.hot.map((b) => hex(b.bg)));
    checks.push(check('C4', 'One primary-action colour', 3, hotColours.size === 1, [...hotColours].join(', ') || 'none', '1',
        'Use the hot button only for the main action on each screen; all hot buttons share the action colour.'));
    const ratio = m.type.bodySize ? m.type.pageTitleSize / m.type.bodySize : 0;
    checks.push(check('C5', 'Clear title hierarchy', 3, ratio >= 1.6, `title/body ${ratio.toFixed(2)}`, '>= 1.6',
        'Use the Title Bar breadcrumb title (large) for the page title; do not shrink it with compact options.'));
    const small = m.targets.filter((x) => x.w < 24 || x.h < 24);
    checks.push(check('C6', 'Pointer targets at least 24x24', 3, small.length === 0, small.slice(0, 4).map((x) => `${x.text} ${x.w}x${x.h}`).join('; ') || 'all >= 24px', '>= 24x24',
        'Use standard button sizes; do not apply tiny/small button options to primary controls.'));
    checks.push(check('C7', 'Readable body text', 2, m.type.bodySize >= 13 && m.type.bodySize <= 18 && m.type.bodyLineHeight >= 1.3,
        `${m.type.bodySize}px / ${m.type.bodyLineHeight.toFixed(2)}`, '13-18px, line height >= 1.3', 'Do not override the base font size below 13px.'));

    const total = checks.reduce((s, c) => s + c.earned, 0);
    const blockersFailed = checks.filter((c) => c.blocker && !c.pass);
    return { total, pass: total >= PASS_SCORE && blockersFailed.length === 0, checks, blockersFailed };
}

async function compareImage(browser, reference, design, out) {
    const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });
    const img = async (p) => `data:image/png;base64,${(await fs.readFile(p)).toString('base64')}`;
    await page.setContent(`<html><body style="margin:0;font:600 18px system-ui;background:#eee;display:grid;grid-template-columns:1fr 1fr;gap:12px;padding:12px">
<div><div style="padding:6px 0">Reference</div><img style="width:100%;border:1px solid #ccc" src="${await img(reference)}"></div>
<div><div style="padding:6px 0">Design</div><img style="width:100%;border:1px solid #ccc" src="${await img(design)}"></div></body></html>`);
    await page.screenshot({ path: out, fullPage: true });
    await page.close();
}

async function main() {
    let args;
    try {
        args = parseArgs(process.argv.slice(2));
    } catch (error) {
        process.stderr.write(`${error.message}\n\n${usage()}`);
        process.exit(2);
    }
    let chromium;
    let AxeBuilder;
    try {
        ({ chromium } = await import('playwright'));
        ({ default: AxeBuilder } = await import('@axe-core/playwright'));
    } catch (error) {
        process.stderr.write(`Playwright dependencies are not installed. Run "npm install" and "npx playwright install chromium".\n${error.message}\n`);
        process.exit(2);
    }

    const kitPath = path.resolve(args.kit);
    const kit = JSON.parse((await fs.readFile(kitPath, 'utf8')).replace(/^﻿/, ''));
    const report = await fs.readFile(path.join(path.dirname(kitPath), 'kit-report.md'), 'utf8').catch(() => '');
    const derived = {};
    for (const line of (await fs.readFile(path.join(path.dirname(kitPath), 'css', 'brand.css'), 'utf8').catch(() => '')).split('\n')) {
        const mm = /^\s*--brand-([a-z-]+):\s*(#[0-9A-Fa-f]{6});/.exec(line);
        if (mm) derived[mm[1].replace(/-([a-z])/g, (_, c) => c.toUpperCase())] = mm[2].toUpperCase();
    }
    if (!derived.action) {
        process.stderr.write(`No generated brand.css next to ${args.kit}. Run node scripts/build-brand-kit.mjs --kit ${args.kit} first.\n`);
        process.exit(2);
    }
    kit.derived = { ...derived, headerBg: derived.headerBg, navSelected: derived.navSelected };
    const stock = JSON.parse(await fs.readFile(path.join(ROOT, 'skills', 'apex-design-system', 'assets', 'ut-css', kit.version || '26.2', 'stock.json'), 'utf8')).stock;

    let target;
    let outDir;
    if (args.url) {
        target = args.url;
        outDir = path.resolve(args.out || 'working/design-score');
    } else {
        const p = path.resolve(args.preview);
        const stat = await fs.stat(p);
        let file = p;
        if (stat.isDirectory()) {
            for (const name of ['after.html', 'index.html']) {
                try { await fs.access(path.join(p, name)); file = path.join(p, name); break; } catch { /* next */ }
            }
            if (file === p) throw new Error('No after.html or index.html in the preview directory.');
        }
        target = pathToFileURL(file).href;
        outDir = path.resolve(args.out || path.join(stat.isDirectory() ? p : path.dirname(p), 'score'));
    }
    await fs.mkdir(outDir, { recursive: true });

    const browser = await chromium.launch({ headless: true, ...(args.channel ? { channel: args.channel } : {}) });
    const results = {};
    const axe = [];
    let cover = [0, 0];
    try {
        for (const vp of VIEWPORTS) {
            const context = await browser.newContext({ viewport: { width: vp.width, height: vp.height }, reducedMotion: 'reduce', ignoreHTTPSErrors: args.insecure });
            const page = await context.newPage();
            if (args.user) await apexLogin(page, target, args.user, process.env[args.passwordEnv]);
            await page.goto(target, { waitUntil: 'load', timeout: 45000 });
            await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});
            await page.evaluate(async () => { if (document.fonts) await document.fonts.ready; });
            await page.screenshot({ path: path.join(outDir, `design-${vp.name}.png`), fullPage: true });
            await page.screenshot({ path: path.join(outDir, `design-${vp.name}-fold.png`) });
            results[vp.name] = await page.evaluate(measure, kit.font?.family || null);
            // Effective (painted) colours beat computed ones: transparent wrappers report black.
            const painted = await pixels(page, results[vp.name].samples);
            const r = results[vp.name];
            if (r.header && painted.header) r.header.bg = painted.header;
            if (r.nav && painted.nav) r.nav.bg = painted.nav;
            if (r.navSelected && painted.navSelected) r.navSelected.bg = painted.navSelected;
            if (vp.name === 'desktop') cover = await coverage(page, [derived.primary, derived.action]);
            const found = await new AxeBuilder({ page }).withTags(AXE_TAGS).analyze();
            for (const v of found.violations) axe.push({ viewport: vp.name, id: v.id, impact: v.impact, nodes: v.nodes.length, help: v.help });
            await context.close();
        }
        const refShot = kit.source?.capture ? path.join(path.dirname(path.resolve(kit.source.capture)), 'reference-desktop.png') : null;
        if (refShot) {
            try {
                await fs.access(refShot);
                await compareImage(browser, refShot, path.join(outDir, 'design-desktop-fold.png'), path.join(outDir, 'compare-desktop.png'));
            } catch { /* no reference capture available */ }
        }
    } finally {
        await browser.close();
    }

    const result = score(kit, stock, results.desktop, results.mobile, axe, cover);
    const rel = (p) => path.relative(process.cwd(), p).replace(/\\/g, '/');
    const md = [
        `# Design Score: ${result.total}/100 ${result.pass ? 'PASS' : 'FAIL'}`,
        '',
        `- Target: ${args.url || rel(target.replace('file:///', ''))}`,
        `- Kit: ${rel(kitPath)} (reference: ${kit.source?.reference || 'none'})`,
        `- Pass rule: score >= ${PASS_SCORE} and every blocker (B*) passes`,
        `- Screenshots: design-desktop.png, design-mobile.png${kit.source?.capture ? ', compare-desktop.png (open it: reference beside design)' : ''}`,
        '',
        '| Check | Result | Points | Measured | Expected |',
        '| --- | --- | ---: | --- | --- |',
        ...result.checks.map((c) => `| ${c.id}${c.blocker ? ' (blocker)' : ''} ${c.title} | ${c.pass ? 'PASS' : 'FAIL'} | ${c.earned}/${c.weight} | ${String(c.measured).replace(/\|/g, '/')} | ${c.expected} |`),
        '',
        '## Fixes, in order',
        '',
        ...(result.checks.filter((c) => !c.pass).sort((a, b) => Number(b.blocker) - Number(a.blocker) || b.weight - a.weight).map((c, i) => `${i + 1}. **${c.id} ${c.title}**: ${c.fix}`)),
        result.checks.every((c) => c.pass) ? 'None. Open compare-desktop.png and confirm the design reads as the reference family.' : '',
        '',
        '## Not measured',
        '',
        'Taste beyond these rules, keyboard order, 200% zoom, and states other than the default. Look at the screenshots.',
        report ? '' : '\nkit-report.md was not found next to the kit.',
        ''
    ].join('\n');
    await fs.writeFile(path.join(outDir, 'score.json'), `${JSON.stringify({ total: result.total, pass: result.pass, checks: result.checks, measured: results, axe }, null, 2)}\n`, 'utf8');
    await fs.writeFile(path.join(outDir, 'score.md'), md, 'utf8');

    process.stdout.write(`Design score: ${result.total}/100 (${rel(path.join(outDir, 'score.md'))})\n`);
    for (const c of result.checks.filter((x) => !x.pass)) process.stdout.write(`- FAIL ${c.id}${c.blocker ? ' (blocker)' : ''} ${c.title}: ${c.measured} (expected ${c.expected})\n`);
    process.stdout.write(result.pass ? 'DESIGN SCORE PASS\n' : 'DESIGN SCORE FAIL\n');
    process.exit(result.pass ? 0 : 1);
}

main().catch((error) => {
    process.stderr.write(`${error.stack || error.message}\n`);
    process.exit(2);
});
