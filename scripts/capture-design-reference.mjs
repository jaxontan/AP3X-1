#!/usr/bin/env node
// Capture the visual "style DNA" of a reference website so the designer can match its look.
// Output is evidence for direction: screenshots, measured computed styles, and a draft brand
// token block. It never copies the site's markup, text, images, logos, or font files.
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const VIEWPORTS = [
    { name: 'desktop', width: 1440, height: 900 },
    { name: 'mobile', width: 390, height: 844 }
];

const DEFAULT_OUT = 'working/page-design/design/reference';
const CONSENT_LABELS = /^(accept( all)?( cookies)?|agree|i agree|allow( all)?|ok(ay)?|got it|continue|close)$/i;

function usage() {
    return `Usage:
  node scripts/capture-design-reference.mjs --url <https-url> [options]

Options:
  -u, --url <url>       Reference website whose look the app should follow
  -o, --out <path>      Output directory (default: ${DEFAULT_OUT})
      --channel <name>  Playwright browser channel, for example chrome or msedge
      --no-consent      Do not try to dismiss cookie or consent banners
  -h, --help            Show this help

Writes desktop/mobile screenshots, reference.json (measured styles), style-dna.md
(summary for the designer), and brand-tokens.draft.css (a starting --brand-* token block).

Example:
  node scripts/capture-design-reference.mjs --url https://www.example.com
`;
}

function parseArgs(argv) {
    const args = { url: null, out: DEFAULT_OUT, channel: process.env.PLAYWRIGHT_CHANNEL || null, consent: true };
    const nextValue = (index, flag) => {
        const value = argv[index + 1];
        if (!value || value.startsWith('-')) throw new Error(`Missing value for ${flag}.`);
        return value;
    };
    for (let index = 0; index < argv.length; index += 1) {
        const value = argv[index];
        if (value === '-u' || value === '--url') {
            args.url = nextValue(index, value);
            index += 1;
        } else if (value === '-o' || value === '--out') {
            args.out = nextValue(index, value);
            index += 1;
        } else if (value === '--channel') {
            args.channel = nextValue(index, value);
            index += 1;
        } else if (value === '--no-consent') {
            args.consent = false;
        } else if (value === '-h' || value === '--help') {
            process.stdout.write(usage());
            process.exit(0);
        } else {
            throw new Error(`Unknown argument: ${value}`);
        }
    }
    if (!args.url) throw new Error('Missing --url.');
    let parsed;
    try {
        parsed = new URL(args.url);
    } catch {
        throw new Error(`Not a valid URL: ${args.url}`);
    }
    if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') {
        throw new Error('Only http and https reference URLs are supported.');
    }
    args.url = parsed.href;
    return args;
}

function firstLine(error) {
    return String(error?.message || error).split(/\r?\n/)[0];
}

async function launchBrowser(chromium, requestedChannel) {
    const rootLinux = process.platform === 'linux' && typeof process.getuid === 'function' && process.getuid() === 0;
    const baseOptions = rootLinux ? { args: ['--no-sandbox', '--disable-dev-shm-usage'] } : {};
    const candidates = [];
    if (requestedChannel) candidates.push({ label: requestedChannel, options: { channel: requestedChannel } });
    candidates.push({ label: 'bundled Chromium', options: {} });
    candidates.push({ label: 'Google Chrome', options: { channel: 'chrome' } });
    candidates.push({ label: 'Microsoft Edge', options: { channel: 'msedge' } });

    const failures = [];
    for (const candidate of candidates) {
        try {
            const browser = await chromium.launch({ headless: true, ...baseOptions, ...candidate.options });
            return { browser, label: candidate.label };
        } catch (error) {
            failures.push(`${candidate.label}: ${firstLine(error)}`);
        }
    }
    throw new Error(`Could not launch a browser. Run "npm install" and "npx playwright install chromium".\n${failures.join('\n')}`);
}

// ---------- colour maths (Node side) ----------

function hexToRgb(hex) {
    const value = hex.replace('#', '');
    return [0, 2, 4].map((offset) => parseInt(value.slice(offset, offset + 2), 16));
}

function rgbToHex(r, g, b) {
    return `#${[r, g, b].map((channel) => Math.round(channel).toString(16).padStart(2, '0')).join('').toUpperCase()}`;
}

function luminance(hex) {
    const [r, g, b] = hexToRgb(hex).map((channel) => {
        const c = channel / 255;
        return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
    });
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrast(a, b) {
    const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
    return Math.round(((hi + 0.05) / (lo + 0.05)) * 100) / 100;
}

function saturation(hex) {
    const [r, g, b] = hexToRgb(hex).map((channel) => channel / 255);
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    if (max === min) return 0;
    const light = (max + min) / 2;
    return light > 0.5 ? (max - min) / (2 - max - min) : (max - min) / (max + min);
}

function hue(hex) {
    const [r, g, b] = hexToRgb(hex).map((channel) => channel / 255);
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    if (max === min) return 0;
    const d = max - min;
    let h;
    if (max === r) h = ((g - b) / d) % 6;
    else if (max === g) h = (b - r) / d + 2;
    else h = (r - g) / d + 4;
    return (h * 60 + 360) % 360;
}

function shade(hex, factor) {
    const [r, g, b] = hexToRgb(hex);
    return rgbToHex(r * factor, g * factor, b * factor);
}

function isChromatic(hex) {
    const l = luminance(hex);
    return saturation(hex) >= 0.35 && l > 0.02 && l < 0.9;
}

function sameHueFamily(a, b) {
    const d = Math.abs(hue(a) - hue(b));
    return Math.min(d, 360 - d) < 25;
}

function textSafe(hex, ground) {
    let candidate = hex;
    for (let step = 0; step < 20 && contrast(candidate, ground) < 4.5; step += 1) candidate = shade(candidate, 0.9);
    return candidate;
}

// ---------- page measurement (browser side) ----------

function measurePage() {
    const toHex = (value) => {
        const match = /rgba?\(([^)]+)\)/.exec(value || '');
        if (!match) return null;
        const parts = match[1].split(/[ ,/]+/).filter(Boolean).map(Number);
        if (parts.length >= 4 && parts[3] < 0.5) return null;
        return `#${parts.slice(0, 3).map((n) => Math.round(n).toString(16).padStart(2, '0')).join('').toUpperCase()}`;
    };
    const bump = (map, key, weight) => {
        if (key === null || key === undefined || key === '') return;
        map[key] = (map[key] || 0) + weight;
    };
    const top = (map, limit) => Object.entries(map).sort((a, b) => b[1] - a[1]).slice(0, limit).map(([value, weight]) => ({ value, weight: Math.round(weight) }));
    const px = (value) => Math.round(parseFloat(value) || 0);
    const firstFamily = (family) => (family || '').split(',')[0].replace(/["']/g, '').trim();

    const viewportArea = window.innerWidth * window.innerHeight;
    const docHeight = Math.max(document.documentElement.scrollHeight, window.innerHeight);
    const background = {};
    const text = {};
    const border = {};
    const families = {};
    const sizes = {};
    const weights = {};
    const radii = {};
    const shadows = {};
    const spacing = {};
    const widths = {};

    const elements = Array.from(document.querySelectorAll('body *')).slice(0, 6000);
    for (const el of elements) {
        const rect = el.getBoundingClientRect();
        if (rect.width < 2 || rect.height < 2) continue;
        const style = getComputedStyle(el);
        if (style.visibility === 'hidden' || style.display === 'none' || Number(style.opacity) === 0) continue;
        const area = Math.min(rect.width * rect.height, viewportArea * 4);

        bump(background, toHex(style.backgroundColor), area);
        const ownText = Array.from(el.childNodes).filter((node) => node.nodeType === 3).map((node) => node.textContent.trim()).join('');
        if (ownText.length > 0) {
            bump(text, toHex(style.color), ownText.length);
            bump(families, firstFamily(style.fontFamily), ownText.length);
            bump(sizes, px(style.fontSize), ownText.length);
            bump(weights, style.fontWeight, ownText.length);
        }
        if (parseFloat(style.borderTopWidth) >= 1 && style.borderTopStyle !== 'none') bump(border, toHex(style.borderTopColor), rect.width);
        const radius = px(style.borderTopLeftRadius);
        if (radius > 0 && area > 400) bump(radii, radius >= 999 || radius >= Math.min(rect.width, rect.height) / 2 ? 'pill' : radius, 1);
        if (style.boxShadow && style.boxShadow !== 'none') bump(shadows, style.boxShadow, 1);
        for (const prop of ['paddingTop', 'paddingLeft', 'marginBottom', 'rowGap', 'columnGap']) {
            const value = px(style[prop]);
            if (value >= 4 && value <= 160) bump(spacing, value, 1);
        }
        const centred = Math.abs(rect.left - (window.innerWidth - rect.right)) < 4;
        if (centred && rect.width < window.innerWidth - 40 && rect.width >= 600 && rect.height > 100) bump(widths, Math.round(rect.width), 1);
    }

    const sample = (selector, limit) => Array.from(document.querySelectorAll(selector))
        .filter((el) => {
            const rect = el.getBoundingClientRect();
            return rect.width > 8 && rect.height > 8 && getComputedStyle(el).visibility !== 'hidden';
        })
        .slice(0, limit)
        .map((el) => {
            const style = getComputedStyle(el);
            const rect = el.getBoundingClientRect();
            return {
                tag: el.tagName.toLowerCase(),
                fontFamily: firstFamily(style.fontFamily),
                fontSize: px(style.fontSize),
                fontWeight: style.fontWeight,
                lineHeight: style.lineHeight,
                letterSpacing: style.letterSpacing,
                textTransform: style.textTransform,
                color: toHex(style.color),
                background: toHex(style.backgroundColor),
                borderRadius: style.borderTopLeftRadius,
                border: parseFloat(style.borderTopWidth) >= 1 ? `${style.borderTopWidth} ${toHex(style.borderTopColor)}` : 'none',
                padding: `${style.paddingTop} ${style.paddingRight} ${style.paddingBottom} ${style.paddingLeft}`,
                height: Math.round(rect.height),
                boxShadow: style.boxShadow === 'none' ? 'none' : style.boxShadow,
                inHeader: Boolean(el.closest('header, [role="banner"], nav'))
            };
        });

    const unique = (rows) => {
        const seen = new Set();
        return rows.filter((row) => {
            const key = JSON.stringify({ ...row, tag: '', height: 0 });
            if (seen.has(key)) return false;
            seen.add(key);
            return true;
        });
    };

    const bodyStyle = getComputedStyle(document.body);
    const header = document.querySelector('header, [role="banner"]');
    const headerStyle = header ? getComputedStyle(header) : null;
    const loadedFonts = document.fonts ? Array.from(document.fonts).filter((face) => face.status === 'loaded').map((face) => `${face.family.replace(/["']/g, '')} ${face.weight}`) : [];

    return {
        title: document.title,
        viewport: { width: window.innerWidth, height: window.innerHeight, documentHeight: docHeight },
        body: {
            background: toHex(bodyStyle.backgroundColor) || toHex(getComputedStyle(document.documentElement).backgroundColor) || '#FFFFFF',
            color: toHex(bodyStyle.color),
            fontFamily: bodyStyle.fontFamily,
            fontSize: px(bodyStyle.fontSize),
            lineHeight: bodyStyle.lineHeight
        },
        header: headerStyle ? {
            background: toHex(headerStyle.backgroundColor),
            color: toHex(headerStyle.color),
            height: Math.round(header.getBoundingClientRect().height),
            boxShadow: headerStyle.boxShadow,
            borderBottom: parseFloat(headerStyle.borderBottomWidth) >= 1 ? `${headerStyle.borderBottomWidth} ${toHex(headerStyle.borderBottomColor)}` : 'none'
        } : null,
        colors: { background: top(background, 12), text: top(text, 10), border: top(border, 8) },
        typography: { families: top(families, 6), sizes: top(sizes, 12), weights: top(weights, 6) },
        headings: unique(sample('h1, h2, h3', 24)).slice(0, 8),
        buttons: unique(sample('button, [role="button"], a[class*="btn" i], a[class*="button" i], input[type="submit"]', 60)).slice(0, 8),
        links: unique(sample('main a, a', 40)).slice(0, 4),
        inputs: unique(sample('input[type="text"], input[type="search"], input[type="email"], select, textarea', 10)).slice(0, 3),
        shape: { radii: top(radii, 8), shadows: top(shadows, 6) },
        spacing: top(spacing, 12),
        contentWidths: top(widths, 5),
        loadedFonts: Array.from(new Set(loadedFonts)).slice(0, 20)
    };
}

// ---------- capture ----------

async function dismissConsent(page) {
    const buttons = page.locator('button, [role="button"], a');
    const count = Math.min(await buttons.count().catch(() => 0), 200);
    for (let index = 0; index < count; index += 1) {
        const button = buttons.nth(index);
        const label = ((await button.innerText({ timeout: 500 }).catch(() => '')) || '').trim();
        if (label.length <= 24 && CONSENT_LABELS.test(label) && await button.isVisible().catch(() => false)) {
            await button.click({ timeout: 2000 }).catch(() => {});
            await page.waitForTimeout(600);
            return label;
        }
    }
    return null;
}

async function captureViewport(browser, args, viewport, outDir) {
    const context = await browser.newContext({
        viewport: { width: viewport.width, height: viewport.height },
        deviceScaleFactor: 1,
        reducedMotion: 'reduce',
        locale: 'en-US'
    });
    const page = await context.newPage();
    try {
        const response = await page.goto(args.url, { waitUntil: 'domcontentloaded', timeout: 45000 });
        await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});
        const consent = args.consent ? await dismissConsent(page) : null;
        // Trigger lazy-loaded sections, then return to the top.
        await page.evaluate(async () => {
            const step = Math.max(400, Math.floor(window.innerHeight * 0.8));
            const limit = Math.min(document.documentElement.scrollHeight, 12000);
            for (let y = 0; y < limit; y += step) {
                window.scrollTo(0, y);
                await new Promise((resolve) => setTimeout(resolve, 120));
            }
            window.scrollTo(0, 0);
            if (document.fonts && document.fonts.ready) await document.fonts.ready;
        });
        await page.waitForTimeout(800);

        const fold = path.join(outDir, `reference-${viewport.name}.png`);
        const full = path.join(outDir, `reference-${viewport.name}-full.png`);
        await page.screenshot({ path: fold });
        const height = await page.evaluate(() => document.documentElement.scrollHeight);
        await page.screenshot({ path: full, clip: { x: 0, y: 0, width: viewport.width, height: Math.min(height, 6000) } }).catch(async () => {
            await page.screenshot({ path: full, fullPage: true });
        });

        const measured = await page.evaluate(measurePage);
        return {
            viewport,
            status: response ? response.status() : null,
            finalUrl: page.url(),
            consentDismissed: consent,
            screenshots: { fold: path.basename(fold), full: path.basename(full) },
            measured
        };
    } finally {
        await context.close();
    }
}

// ---------- synthesis ----------

function deriveRoles(desktop) {
    const m = desktop.measured;
    const ground = m.body.background || '#FFFFFF';
    const bgs = m.colors.background.map((c) => c.value);
    const surface = bgs.find((value) => value !== ground && !isChromatic(value) && luminance(value) > 0.8) || '#FFFFFF';
    const ink = m.colors.text.map((c) => c.value).find((value) => contrast(value, ground) >= 7) || m.body.color || '#1A1A1A';
    const muted = m.colors.text.map((c) => c.value).find((value) => value !== ink && !isChromatic(value) && contrast(value, ground) >= 4.5 && contrast(value, ground) < 12) || null;
    const border = m.colors.border.map((c) => c.value).find((value) => !isChromatic(value)) || null;

    // Brand colours: chromatic, weighted toward buttons and the header, then by painted area.
    const score = {};
    const add = (value, weight) => { if (value && isChromatic(value)) score[value] = (score[value] || 0) + weight; };
    m.colors.background.forEach((c, index) => add(c.value, 12 - index));
    m.colors.text.forEach((c, index) => add(c.value, (10 - index) / 2));
    m.buttons.forEach((b) => { add(b.background, 6); add(b.color, 2); });
    if (m.header) add(m.header.background, 8);
    const chromatic = Object.entries(score).sort((a, b) => b[1] - a[1]).map(([value]) => value);
    const primary = chromatic[0] || null;
    const accent = chromatic.find((value) => primary && !sameHueFamily(value, primary)) || null;

    const roles = { ground, surface, ink, muted, border, primary, accent };
    if (primary) {
        roles.onPrimary = contrast(primary, '#FFFFFF') >= contrast(primary, ink) ? '#FFFFFF' : ink;
        roles.primaryStrong = textSafe(primary, ground);
    }
    if (accent) roles.onAccent = contrast(accent, '#FFFFFF') >= contrast(accent, ink) ? '#FFFFFF' : ink;
    return roles;
}

function numericRadius(m) {
    const values = m.shape.radii.filter((r) => r.value !== 'pill').map((r) => Number(r.value));
    return values.length ? values[0] : 0;
}

function buttonShape(m) {
    const first = m.buttons.find((b) => b.background && b.background !== m.body.background);
    if (!first) return 'not detected';
    const radius = parseFloat(first.borderRadius) || 0;
    return radius >= first.height / 2 - 1 ? 'pill' : radius === 0 ? 'square' : `${Math.round(radius)}px rounded`;
}

function cssTokens(url, roles, desktop) {
    const m = desktop.measured;
    const radius = numericRadius(m);
    const family = m.typography.families[0]?.value || 'system-ui';
    const shadow = m.shape.shadows[0]?.value || 'none';
    const line = (name, value, note) => (value ? `  ${name}: ${value};${note ? ` /* ${note} */` : ''}` : `  /* ${name}: not detected */`);
    return [
        `/* DRAFT brand tokens measured from ${url}`,
        '   Starting point only. Confirm every value against the screenshots, then copy the',
        '   approved values into app/shared-components/static-files/css/brand.css.',
        '   Font: never ship the reference site\'s font files; pick an open-licence match. */',
        ':root {',
        line('--brand-primary', roles.primary, roles.primary ? `contrast on ground ${contrast(roles.primary, roles.ground)}:1` : ''),
        line('--brand-primary-strong', roles.primaryStrong, 'text-safe shade, >= 4.5:1 on ground'),
        line('--brand-on-primary', roles.onPrimary, roles.primary && roles.onPrimary ? `${contrast(roles.primary, roles.onPrimary)}:1` : ''),
        line('--brand-accent', roles.accent, roles.accent ? `contrast on ground ${contrast(roles.accent, roles.ground)}:1` : ''),
        line('--brand-on-accent', roles.onAccent, roles.accent && roles.onAccent ? `${contrast(roles.accent, roles.onAccent)}:1` : ''),
        line('--brand-ground', roles.ground, 'page background'),
        line('--brand-surface', roles.surface, 'cards and regions'),
        line('--brand-ink', roles.ink, `${contrast(roles.ink, roles.ground)}:1 on ground`),
        line('--brand-muted', roles.muted, roles.muted ? `${contrast(roles.muted, roles.ground)}:1 on ground` : ''),
        line('--brand-border', roles.border, ''),
        line('--brand-radius', `${radius}px`, 'most common non-pill radius'),
        line('--brand-shadow', shadow === 'none' ? null : shadow, 'most common shadow'),
        `  /* reference UI font: ${family} -> choose an open-licence equivalent for --brand-font-ui */`,
        '}',
        ''
    ].join('\n');
}

function table(rows, columns) {
    if (!rows.length) return '_none detected_\n';
    const header = `| ${columns.map((c) => c.label).join(' | ')} |\n| ${columns.map(() => '---').join(' | ')} |\n`;
    return header + rows.map((row) => `| ${columns.map((c) => String(c.get(row) ?? '').replace(/\|/g, '\\|')).join(' | ')} |`).join('\n') + '\n';
}

// Many sites ship bold as a separate face ("Brand-Bold") with font-weight 400.
function effectiveWeight(row) {
    const family = row.fontFamily || '';
    const named = /black|heavy/i.test(family) ? 900 : /extra-?bold/i.test(family) ? 800 : /semi-?bold|demi/i.test(family) ? 600 : /bold/i.test(family) ? 700 : /medium/i.test(family) ? 500 : null;
    return named && Number(row.fontWeight) < named ? `${named} (from face name)` : row.fontWeight;
}

function swatch(value) {
    return value ? `\`${value}\`` : '_n/a_';
}

function styleDna(url, captured, roles, captures) {
    const desktop = captures.find((c) => c.viewport.name === 'desktop');
    const mobile = captures.find((c) => c.viewport.name === 'mobile');
    const m = desktop.measured;
    const sizes = m.typography.sizes.map((s) => Number(s.value)).sort((a, b) => a - b);
    const lines = [
        '# Design Reference: Style DNA',
        '',
        `- Reference: ${url}`,
        `- Captured: ${captured}`,
        `- Final URL: ${desktop.finalUrl} (HTTP ${desktop.status ?? 'n/a'})`,
        `- Consent banner dismissed: ${desktop.consentDismissed ? `yes ("${desktop.consentDismissed}")` : 'no'}`,
        '',
        'Measured from computed styles. Numbers are evidence, not taste: look at the screenshots before deciding.',
        'Borrow the look (colour roles, type character, shape, depth, density, rhythm). Never copy the site\'s',
        'logo, wordmark, images, copy, font files, or markup. See skills/apex-design-system/references/design-reference.md.',
        '',
        '## Screenshots',
        '',
        ...captures.map((c) => `- ${c.viewport.name} ${c.viewport.width}x${c.viewport.height}: \`${c.screenshots.fold}\` (fold), \`${c.screenshots.full}\` (long)`),
        '',
        '## Suggested colour roles',
        '',
        table([
            ['Ground', roles.ground], ['Surface', roles.surface], ['Ink', roles.ink], ['Muted', roles.muted],
            ['Border', roles.border], ['Primary (brand)', roles.primary], ['Primary text-safe', roles.primaryStrong],
            ['On primary', roles.onPrimary], ['Accent', roles.accent], ['On accent', roles.onAccent]
        ], [
            { label: 'Role', get: (r) => r[0] },
            { label: 'Value', get: (r) => swatch(r[1]) },
            { label: 'Contrast', get: (r) => {
                if (!r[1] || r[0] === 'Ground') return '';
                if (r[0] === 'On primary' && roles.primary) return `${contrast(r[1], roles.primary)}:1 on primary`;
                if (r[0] === 'On accent' && roles.accent) return `${contrast(r[1], roles.accent)}:1 on accent`;
                return `${contrast(r[1], roles.ground)}:1 on ground`;
            } }
        ]),
        roles.primary && roles.onPrimary ? `Primary with its on-colour: ${contrast(roles.primary, roles.onPrimary)}:1. ${contrast(roles.primary, roles.onPrimary) < 4.5 ? 'Below 4.5:1: use large/bold text on primary fills, or darken the fill for small text.' : 'Passes 4.5:1 for normal text.'}` : '',
        roles.accent && roles.onAccent ? `Accent with its on-colour: ${contrast(roles.accent, roles.onAccent)}:1. ${contrast(roles.accent, roles.onAccent) < 4.5 ? 'Below 4.5:1: keep accent for fills with ink text, borders, or large text.' : 'Passes 4.5:1.'}` : '',
        '',
        '### Raw colour weights',
        '',
        table(m.colors.background.slice(0, 8), [{ label: 'Background', get: (r) => swatch(r.value) }, { label: 'Painted area weight', get: (r) => r.weight }]),
        table(m.colors.text.slice(0, 6), [{ label: 'Text colour', get: (r) => swatch(r.value) }, { label: 'Characters', get: (r) => r.weight }]),
        '## Typography',
        '',
        `- Body: ${m.body.fontFamily} at ${m.body.fontSize}px, line-height ${m.body.lineHeight}`,
        `- Families by text volume: ${m.typography.families.map((f) => `${f.value} (${f.weight})`).join(', ') || 'n/a'}`,
        `- Size scale in use (px): ${sizes.join(' / ') || 'n/a'}`,
        `- Weights by text volume: ${m.typography.weights.map((w) => `${w.value} (${w.weight})`).join(', ') || 'n/a'}`,
        `- Web fonts loaded: ${m.loadedFonts.join(', ') || 'none detected'}`,
        '',
        table(m.headings, [
            { label: 'Heading', get: (r) => r.tag }, { label: 'Family', get: (r) => r.fontFamily }, { label: 'Size', get: (r) => `${r.fontSize}px` },
            { label: 'Weight', get: (r) => effectiveWeight(r) }, { label: 'Line height', get: (r) => r.lineHeight }, { label: 'Tracking', get: (r) => r.letterSpacing },
            { label: 'Case', get: (r) => r.textTransform }, { label: 'Colour', get: (r) => swatch(r.color) }
        ]),
        '## Buttons and controls',
        '',
        `- Dominant button shape: ${buttonShape(m)}`,
        '',
        table(m.buttons, [
            { label: 'Tag', get: (r) => r.tag }, { label: 'Where', get: (r) => (r.inHeader ? 'header/nav' : 'content') },
            { label: 'Background', get: (r) => swatch(r.background) }, { label: 'Text', get: (r) => swatch(r.color) },
            { label: 'Radius', get: (r) => r.borderRadius }, { label: 'Height', get: (r) => `${r.height}px` }, { label: 'Padding', get: (r) => r.padding },
            { label: 'Font', get: (r) => `${r.fontSize}px/${effectiveWeight(r)} ${r.textTransform !== 'none' ? r.textTransform : ''}` }, { label: 'Border', get: (r) => r.border }
        ]),
        table(m.inputs, [
            { label: 'Input', get: (r) => r.tag }, { label: 'Background', get: (r) => swatch(r.background) }, { label: 'Border', get: (r) => r.border },
            { label: 'Radius', get: (r) => r.borderRadius }, { label: 'Height', get: (r) => `${r.height}px` }
        ]),
        '## Shape, depth, and rhythm',
        '',
        `- Corner radii (by frequency): ${m.shape.radii.map((r) => (r.value === 'pill' ? 'pill' : `${r.value}px`) + ` (${r.weight})`).join(', ') || 'square corners'}`,
        `- Shadows (by frequency): ${m.shape.shadows.length ? '' : 'none, flat surfaces'}`,
        ...m.shape.shadows.slice(0, 4).map((s) => `  - \`${s.value}\` (${s.weight})`),
        `- Spacing values (px, by frequency): ${m.spacing.map((s) => `${s.value} (${s.weight})`).join(', ') || 'n/a'}`,
        `- Centred content widths (px): ${m.contentWidths.map((w) => w.value).join(', ') || 'full width'}`,
        m.header ? `- Header: background ${m.header.background ? swatch(m.header.background) : `transparent (shows ground ${swatch(m.body.background)})`}, text ${swatch(m.header.color)}, height ${m.header.height}px, border ${m.header.borderBottom}, shadow ${m.header.boxShadow === 'none' ? 'none' : `\`${m.header.boxShadow}\``}` : '- Header: no <header> landmark detected',
        '',
        '## Mobile',
        '',
        mobile ? `- Body ${mobile.measured.body.fontSize}px; size scale ${mobile.measured.typography.sizes.map((s) => s.value).sort((a, b) => a - b).join(' / ')}; dominant button shape ${buttonShape(mobile.measured)}` : '- not captured',
        '',
        '## Designer to fill in after looking at the screenshots',
        '',
        '- One-sentence character of the reference (what makes it feel like itself):',
        '- Signature element worth translating into APEX:',
        '- What NOT to take (trademarks, imagery, layouts that do not suit a data app):',
        '- Font substitution (reference font -> open-licence font, and why):',
        ''
    ];
    return lines.filter((line) => line !== null).join('\n');
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
    try {
        ({ chromium } = await import('playwright'));
    } catch (error) {
        process.stderr.write('Playwright is not installed. Run "npm install" and "npx playwright install chromium".\n');
        process.stderr.write(`${error.message}\n`);
        process.exit(2);
    }

    const outDir = path.resolve(process.cwd(), args.out);
    await fs.mkdir(outDir, { recursive: true });

    const launched = await launchBrowser(chromium, args.channel);
    const captures = [];
    try {
        for (const viewport of VIEWPORTS) {
            try {
                captures.push(await captureViewport(launched.browser, args, viewport, outDir));
            } catch (error) {
                process.stderr.write(`Capture failed at ${viewport.name}: ${firstLine(error)}\n`);
            }
        }
    } finally {
        await launched.browser.close();
    }

    const desktop = captures.find((c) => c.viewport.name === 'desktop');
    if (!desktop) {
        process.stderr.write('No desktop capture; the reference site could not be loaded. Check the URL, network, or bot protection.\n');
        process.exit(1);
    }
    if (desktop.measured.colors.text.length === 0) {
        process.stderr.write('The page rendered no visible text; it may be blocked by bot protection or require JavaScript consent. Inspect the screenshot.\n');
    }

    const captured = new Date().toISOString();
    const roles = deriveRoles(desktop);
    const report = { url: args.url, captured, browser: launched.label, roles, captures };
    await fs.writeFile(path.join(outDir, 'reference.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
    await fs.writeFile(path.join(outDir, 'style-dna.md'), styleDna(args.url, captured, roles, captures), 'utf8');
    await fs.writeFile(path.join(outDir, 'brand-tokens.draft.css'), cssTokens(args.url, roles, desktop), 'utf8');

    process.stdout.write(`Captured ${args.url} with ${launched.label}.\n`);
    process.stdout.write(`Output: ${outDir}\n`);
    for (const c of captures) process.stdout.write(`- ${c.viewport.name}: ${c.screenshots.fold}, ${c.screenshots.full}\n`);
    process.stdout.write('- reference.json, style-dna.md, brand-tokens.draft.css\n');
    process.stdout.write(`Suggested roles: primary ${roles.primary ?? 'n/a'}, accent ${roles.accent ?? 'n/a'}, ground ${roles.ground}, ink ${roles.ink}.\n`);
    process.stdout.write('Look at the screenshots before using these values. REFERENCE CAPTURED\n');
}

main().catch((error) => {
    process.stderr.write(`${error.stack || error.message}\n`);
    process.exit(1);
});
