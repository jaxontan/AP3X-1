#!/usr/bin/env node
// Build a complete, contrast-safe APEX brand.css from a small set of design decisions.
//
//   node scripts/build-brand-kit.mjs --reference working/page-design/design/reference/reference.json
//       Creates brand-kit.json (decisions) from a captured reference, then builds the kit.
//   node scripts/build-brand-kit.mjs --kit working/page-design/design/brand/brand-kit.json
//       Rebuilds after you edit the decisions. Never hand-edit the generated brand.css.
//
// Output (mirrors app/shared-components/static-files/):
//   <out>/brand-kit.json   decisions: colours, font, shape, depth, header/nav style
//   <out>/css/brand.css    tokens + Universal Theme mapping + primary-action rules
//   <out>/fonts/           open-licence font files (fetch with scripts/fetch-open-font.mjs)
//   <out>/kit-report.md    derived colours, contrast results, and every lever set
//
// Every --ut-*/--a-* variable written is checked against the variables the real Universal
// Theme CSS reads (skills/apex-design-system/assets/ut-css/<version>/consumed-vars.txt).
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const DEFAULT_OUT = 'working/page-design/design/brand';
const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1')), '..');
const SYSTEM_STACK = 'system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif';

// Open-licence families available from Fontsource (SIL OFL / Apache). A reference that already
// uses one of these keeps it; anything else is substituted below.
const OPEN_FONTS = [
    'Inter', 'Roboto', 'Open Sans', 'Lato', 'Montserrat', 'Poppins', 'Nunito', 'Nunito Sans', 'DM Sans', 'Source Sans 3',
    'Work Sans', 'Rubik', 'Manrope', 'Plus Jakarta Sans', 'IBM Plex Sans', 'Noto Sans', 'Raleway', 'Outfit', 'Figtree',
    'Lexend', 'Mulish', 'Karla', 'Barlow', 'Fira Sans', 'PT Sans', 'Oswald', 'Playfair Display', 'Merriweather', 'Lora',
    'Source Serif 4', 'Libre Franklin', 'Public Sans', 'Red Hat Display', 'Red Hat Text', 'Space Grotesk', 'Sora', 'Urbanist',
    'Jost', 'Archivo', 'Heebo', 'Assistant', 'Cabin', 'Quicksand', 'Josefin Sans', 'Hind', 'Titillium Web', 'Overpass',
    'Be Vietnam Pro', 'Onest', 'Hanken Grotesk', 'Schibsted Grotesk', 'Albert Sans', 'Instrument Sans'
];

// Proprietary or system faces -> closest open-licence character match.
const SUBSTITUTES = [
    [/speedee/i, 'Nunito Sans'], [/helvetica|arial|neue haas|aktiv/i, 'Inter'], [/sf pro|san francisco|-apple-system|system-ui/i, 'Inter'],
    [/segoe/i, 'Open Sans'], [/gotham|proxima/i, 'Montserrat'], [/avenir|museo sans|cereal/i, 'Nunito Sans'], [/futura/i, 'Jost'],
    [/circular|walsheim|apercu/i, 'DM Sans'], [/graphik|s[oö]hne|ember|netflix|uber move|oracle sans/i, 'Inter'],
    [/gilroy/i, 'Plus Jakarta Sans'], [/product sans|google sans/i, 'Outfit'], [/brandon/i, 'Josefin Sans'], [/\bdin\b/i, 'Barlow'],
    [/frutiger|myriad/i, 'Source Sans 3'], [/salesforce/i, 'Open Sans'], [/georgia|times|garamond/i, 'Source Serif 4']
];

const STATUS_DEFAULTS = { success: '#1F7A4D', warning: '#B25E09', danger: '#C62828', info: '#1D5FB4' };

function usage() {
    return `Usage:
  node scripts/build-brand-kit.mjs --reference <reference.json> [options]
  node scripts/build-brand-kit.mjs --kit <brand-kit.json> [options]
  node scripts/build-brand-kit.mjs --init --set colors.primary=#RRGGBB [--set ...]   (no reference site)

Options:
  -r, --reference <file>   Captured reference (scripts/capture-design-reference.mjs); writes a new brand-kit.json
  -k, --kit <file>         Existing brand-kit.json to rebuild from
      --init               Start a new kit from safe defaults (no reference); set colours with --set
  -o, --out <dir>          Output directory (default: ${DEFAULT_OUT}, or the kit's directory)
      --set <path=value>   Override a decision, e.g. --set colors.primary=#DB0007 --set font.family="DM Sans"
      --version <26.1|26.2> APEX version (default: kit value, else 26.2)
  -h, --help               Show this help
`;
}

function parseArgs(argv) {
    const args = { reference: null, kit: null, init: false, out: null, sets: [], version: null };
    const next = (i, flag) => {
        const v = argv[i + 1];
        if (v === undefined || v.startsWith('--')) throw new Error(`Missing value for ${flag}.`);
        return v;
    };
    for (let i = 0; i < argv.length; i += 1) {
        const a = argv[i];
        if (a === '-r' || a === '--reference') { args.reference = next(i, a); i += 1; }
        else if (a === '-k' || a === '--kit') { args.kit = next(i, a); i += 1; }
        else if (a === '-o' || a === '--out') { args.out = next(i, a); i += 1; }
        else if (a === '--set') { args.sets.push(next(i, a)); i += 1; }
        else if (a === '--version') { args.version = next(i, a); i += 1; }
        else if (a === '--init') args.init = true;
        else if (a === '-h' || a === '--help') { process.stdout.write(usage()); process.exit(0); }
        else throw new Error(`Unknown argument: ${a}`);
    }
    if ([args.reference, args.kit, args.init].filter(Boolean).length !== 1) throw new Error('Pass exactly one of --reference <reference.json>, --kit <brand-kit.json>, or --init.');
    return args;
}

// ---------- colour maths ----------

const HEX = /^#[0-9A-F]{6}$/;

function normHex(value) {
    if (!value) return null;
    let v = String(value).trim().toUpperCase();
    if (/^#[0-9A-F]{3}$/.test(v)) v = `#${v[1]}${v[1]}${v[2]}${v[2]}${v[3]}${v[3]}`;
    return HEX.test(v) ? v : null;
}

function rgb(hex) {
    return [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
}

function toHex([r, g, b]) {
    return `#${[r, g, b].map((c) => Math.max(0, Math.min(255, Math.round(c))).toString(16).padStart(2, '0')).join('').toUpperCase()}`;
}

function mix(a, b, weightOfB) {
    const x = rgb(a);
    const y = rgb(b);
    return toHex(x.map((c, i) => c + (y[i] - c) * weightOfB));
}

function lum(hex) {
    const [r, g, b] = rgb(hex).map((c) => {
        const s = c / 255;
        return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
    });
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrast(a, b) {
    const [hi, lo] = [lum(a), lum(b)].sort((x, y) => y - x);
    return Math.round(((hi + 0.05) / (lo + 0.05)) * 100) / 100;
}

function sat(hex) {
    const [r, g, b] = rgb(hex).map((c) => c / 255);
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    if (max === min) return 0;
    const l = (max + min) / 2;
    return l > 0.5 ? (max - min) / (2 - max - min) : (max - min) / (max + min);
}

function chromatic(hex) {
    const l = lum(hex);
    return sat(hex) >= 0.35 && l > 0.02 && l < 0.9;
}

// Darken (or lighten) toward black/white until the pair reaches the target ratio.
function ensureContrast(color, against, target) {
    if (contrast(color, against) >= target) return color;
    const towards = lum(against) > 0.4 ? '#000000' : '#FFFFFF';
    for (let w = 0.04; w <= 1; w += 0.04) {
        const candidate = mix(color, towards, w);
        if (contrast(candidate, against) >= target) return candidate;
    }
    return towards;
}

function bestOn(fill, ink) {
    return contrast(fill, '#FFFFFF') >= contrast(fill, ink) ? '#FFFFFF' : ink;
}

function hoverOf(hex) {
    return lum(hex) > 0.35 ? mix(hex, '#000000', 0.08) : mix(hex, '#FFFFFF', 0.12);
}

function activeOf(hex) {
    return mix(hex, '#000000', lum(hex) > 0.35 ? 0.16 : 0.18);
}

// ---------- decisions ----------

function cleanFamily(family) {
    return String(family || '')
        .replace(/["']/g, '')
        .split(',')[0]
        .replace(/[-_ ]?(regular|bold|light|medium|semibold|black|heavy|book|roman|italic)$/i, '')
        .replace(/([a-z])([A-Z])/g, '$1 $2')
        .trim();
}

function chooseFont(referenceFamily) {
    const clean = cleanFamily(referenceFamily);
    const open = OPEN_FONTS.find((f) => f.toLowerCase() === clean.toLowerCase());
    if (open) return { family: open, reason: `reference uses ${open}, an open-licence font` };
    const sub = SUBSTITUTES.find(([re]) => re.test(clean));
    if (sub) return { family: sub[1], reason: `reference font "${clean}" is not open-licence; ${sub[1]} is the closest open match` };
    return { family: 'Inter', reason: `reference font "${clean || 'unknown'}" not recognised; Inter is a neutral default. Pick a closer open-licence match if one exists.` };
}

function headingWeight(m) {
    const weights = (m.headings || []).map((h) => {
        const named = /black|heavy/i.test(h.fontFamily) ? 900 : /extra-?bold/i.test(h.fontFamily) ? 800 : /semi-?bold|demi/i.test(h.fontFamily) ? 600 : /bold/i.test(h.fontFamily) ? 700 : 0;
        return Math.max(Number(h.fontWeight) || 400, named);
    });
    return weights.length ? Math.max(...weights) : 700;
}

function kitFromReference(reference, refPath) {
    const desktop = reference.captures.find((c) => c.viewport.name === 'desktop');
    const m = desktop.measured;
    const roles = reference.roles;
    const ink = normHex(roles.ink) || '#1F1F1F';
    const ground = normHex(roles.ground) || '#FFFFFF';

    // Action colour: the chromatic fill on the biggest, most repeated content buttons.
    // Header and nav buttons are utilities (locate, sign in), not the main call to action.
    const buttonScore = {};
    for (const b of m.buttons || []) {
        const bg = normHex(b.background);
        if (bg && chromatic(bg)) buttonScore[bg] = (buttonScore[bg] || 0) + (b.height || 30) * (b.inHeader ? 0.25 : 1);
    }
    const action = Object.entries(buttonScore).sort((a, b) => b[1] - a[1])[0]?.[0] || normHex(roles.accent) || normHex(roles.primary);
    const primary = normHex(roles.primary) || action || '#2F5BD3';

    const radii = (m.shape?.radii || []).filter((r) => r.value !== 'pill').map((r) => Number(r.value));
    const radius = radii.length ? Math.min(radii[0], 16) : 6;
    const firstButton = (m.buttons || []).find((b) => normHex(b.background));
    const pill = firstButton && parseFloat(firstButton.borderRadius) >= firstButton.height / 2 - 1;
    const shadow = m.shape?.shadows?.find((s) => !/inset/.test(s.value))?.value || null;
    const headerBg = normHex(m.header?.background);
    const headerStyle = headerBg && chromatic(headerBg) ? 'brand' : headerBg && lum(headerBg) < 0.1 ? 'dark' : 'light';
    const font = chooseFont(m.typography?.families?.[0]?.value || m.body.fontFamily);

    return {
        $schema: 'brand-kit/1',
        version: '26.2',
        source: { reference: reference.url, capture: refPath, captured: reference.captured },
        colors: {
            primary,
            action,
            ground,
            surface: normHex(roles.surface) || '#FFFFFF',
            ink,
            muted: normHex(roles.muted),
            border: normHex(roles.border),
            ...STATUS_DEFAULTS
        },
        font: { family: font.family, reason: font.reason, referenceFamily: cleanFamily(m.typography?.families?.[0]?.value), headingWeight: Math.min(800, Math.max(600, headingWeight(m))) },
        shape: { radius, button: pill ? 'pill' : radius === 0 ? 'square' : 'rounded' },
        depth: { shadow: shadow ? 'soft' : 'flat', referenceShadow: shadow },
        header: { style: headerStyle, logo: headerStyle === 'light' ? 'primary' : 'inherit', tall: (m.header?.height || 0) >= 64 },
        nav: { style: headerStyle === 'light' ? 'light' : 'dark' },
        notes: [
            'Edit values here, then rebuild with: node scripts/build-brand-kit.mjs --kit <this file>',
            'colors.primary = brand/wayfinding colour (logo, selected nav, links, focus). colors.action = the hot/primary button fill.',
            'header.style: light | brand | dark. nav.style: light | dark. shape.button: rounded | pill | square. depth.shadow: soft | flat.'
        ]
    };
}

// Safe defaults for an app with no reference site: calm neutrals, a light header, one accent.
function kitFromDefaults() {
    return {
        $schema: 'brand-kit/1',
        version: '26.2',
        source: { reference: null },
        colors: { primary: '#2E5AAC', action: '#2E5AAC', ground: '#F7F8FA', surface: '#FFFFFF', ink: '#1C2430', muted: null, border: null, ...STATUS_DEFAULTS },
        font: { family: 'Inter', reason: 'neutral, highly legible open-licence UI font', headingWeight: 700 },
        shape: { radius: 8, button: 'rounded' },
        depth: { shadow: 'soft' },
        header: { style: 'light', logo: 'primary', tall: false },
        nav: { style: 'light' },
        notes: [
            'Set colors.primary and colors.action from requirement.md, then rebuild with --kit.',
            'header.style: light | brand | dark. nav.style: light | dark. shape.button: rounded | pill | square. depth.shadow: soft | flat.'
        ]
    };
}

function applySets(kit, sets) {
    for (const s of sets) {
        const eq = s.indexOf('=');
        if (eq < 1) throw new Error(`--set expects path=value, got ${s}`);
        const keys = s.slice(0, eq).split('.');
        let value = s.slice(eq + 1).replace(/^"|"$/g, '');
        if (value === 'true' || value === 'false') value = value === 'true';
        else if (/^-?\d+(\.\d+)?$/.test(value)) value = Number(value);
        let node = kit;
        for (const k of keys.slice(0, -1)) node = node[k] ??= {};
        node[keys.at(-1)] = value;
    }
}

// ---------- derivation ----------

function derive(kit) {
    const c = kit.colors;
    const problems = [];
    for (const key of ['primary', 'action', 'ground', 'surface', 'ink']) {
        if (!normHex(c[key])) problems.push(`colors.${key} must be a #RRGGBB hex value (got ${c[key]})`);
    }
    if (problems.length) throw new Error(problems.join('\n'));

    const ground = normHex(c.ground);
    const surface = normHex(c.surface);
    const ink = ensureContrast(normHex(c.ink), surface, 7);
    const primary = normHex(c.primary);
    const action = normHex(c.action);
    const t = {
        ground, surface, ink,
        muted: ensureContrast(normHex(c.muted) || mix(ink, surface, 0.38), surface, 4.6),
        border: normHex(c.border) || mix(ink, surface, 0.86),
        primary,
        primaryHover: hoverOf(primary),
        primaryText: ensureContrast(primary, surface, 4.5),
        primaryTint: mix(primary, surface, 0.9),
        onPrimary: bestOn(primary, ink),
        action,
        actionHover: hoverOf(action),
        actionActive: activeOf(action),
        actionText: ensureContrast(action, surface, 4.5),
        onAction: bestOn(action, ink)
    };
    t.focus = ensureContrast(primary, ground, 3);
    t.navSelected = t.primaryTint;
    t.navSelectedText = ensureContrast(primary, t.primaryTint, 4.5);
    for (const s of ['success', 'warning', 'danger', 'info']) {
        const base = normHex(c[s]) || STATUS_DEFAULTS[s];
        t[s] = base;
        t[`on${s[0].toUpperCase()}${s.slice(1)}`] = bestOn(base, ink);
        // Subtle badges put status text on a pale tint of the status colour; contrast is checked there.
        t[`${s}Shade`] = mix(base, surface, 0.9);
        t[`${s}Text`] = ensureContrast(base, t[`${s}Shade`], 4.5);
    }

    const header = kit.header?.style || 'light';
    if (header === 'brand') { t.headerBg = primary; t.headerText = t.onPrimary; t.logo = t.onPrimary; }
    else if (header === 'dark') { t.headerBg = mix(ink, '#000000', 0.3); t.headerText = '#FFFFFF'; t.logo = '#FFFFFF'; }
    else { t.headerBg = surface; t.headerText = ink; t.logo = kit.header?.logo === 'primary' ? t.primaryText : ink; }

    const nav = kit.nav?.style || 'light';
    if (nav === 'dark') { t.navBg = mix(ink, '#000000', 0.2); t.navText = '#FFFFFF'; t.navSelected = mix(t.navBg, '#FFFFFF', 0.12); t.navSelectedText = '#FFFFFF'; t.navHover = mix(t.navBg, '#FFFFFF', 0.07); }
    else { t.navBg = surface; t.navText = ink; t.navHover = mix(surface, ink, 0.05); }

    const r = Math.max(0, Math.min(24, Number(kit.shape?.radius ?? 6)));
    const button = kit.shape?.button || 'rounded';
    const shadowSoft = '0 1px 2px rgb(0 0 0 / 0.06), 0 4px 14px rgb(0 0 0 / 0.08)';
    const soft = (kit.depth?.shadow || 'soft') === 'soft';
    const shape = {
        radius: `${r}px`,
        radiusSm: `${Math.max(0, Math.min(r, 8) - 2)}px`,
        button: button === 'pill' ? '999px' : button === 'square' ? '0px' : `${Math.max(0, Math.min(r, 12) - 2)}px`,
        shadow: soft ? shadowSoft : 'none',
        headerShadow: header === 'light' ? (soft ? '0 2px 8px rgb(0 0 0 / 0.08)' : `0 1px 0 ${t.border}`) : 'none',
        regionBorder: soft ? '0px' : '1px'
    };

    const report = [
        ['ink on surface', t.ink, t.surface, 7], ['muted on surface', t.muted, t.surface, 4.5],
        ['primary text on surface', t.primaryText, t.surface, 4.5], ['on-primary on primary', t.onPrimary, t.primary, 4.5],
        ['on-action on action (button label)', t.onAction, t.action, 4.5], ['action text on surface', t.actionText, t.surface, 4.5],
        ['header text on header', t.headerText, t.headerBg, 4.5], ['logo on header', t.logo, t.headerBg, 3],
        ['nav text on nav', t.navText, t.navBg, 4.5], ['selected nav text', t.navSelectedText, t.navSelected, 4.5],
        ['focus ring on ground', t.focus, t.ground, 3],
        ['nav text on hover', t.navText, t.navHover, 4.5],
        ...['success', 'warning', 'danger', 'info'].map((s) => [`${s} label on ${s}`, t[`on${s[0].toUpperCase()}${s.slice(1)}`], t[s], 4.5]),
        ...['success', 'warning', 'danger', 'info'].map((s) => [`${s} text on ${s} tint (subtle badge)`, t[`${s}Text`], t[`${s}Shade`], 4.5])
    ].map(([name, fg, bg, min]) => ({ name, fg, bg, ratio: contrast(fg, bg), min, pass: contrast(fg, bg) >= min }));

    return { t, shape, report };
}

// ---------- CSS ----------

function fontFaces(kit, fontFiles) {
    const family = kit.font?.family;
    if (!family || !fontFiles.length) return '';
    return fontFiles.map((f) => `@font-face {\n  font-family: "${family}";\n  font-style: normal;\n  font-weight: ${f.weight};\n  font-display: swap;\n  src: url("../fonts/${f.file}") format("woff2");\n}\n`).join('');
}

// Split a selector list on top-level commas only.
function selectorParts(selector) {
    const parts = [];
    let depth = 0;
    let current = '';
    for (const ch of selector) {
        if (ch === '(') depth += 1;
        if (ch === ')') depth -= 1;
        if (ch === ',' && depth === 0) { parts.push(current.trim()); current = ''; } else current += ch;
    }
    if (current.trim()) parts.push(current.trim());
    return parts;
}

// Vita hard-codes nav colours per state; re-declare each selector with the brand nav tokens.
function navRules(scoped) {
    const groups = { hover: [], selected: [], base: [] };
    for (const rule of scoped.filter((r) => r.family === 'treenav')) {
        const important = rule.important ? ' !important' : '';
        for (const part of selectorParts(rule.selector)) {
            const kind = /is-hover/.test(part) ? 'hover' : /is-current|is-selected/.test(part) ? 'selected' : 'base';
            const props = rule.properties.filter((p) => p === 'background-color' || p === 'color');
            groups[kind].push({ part, props, important });
        }
    }
    const values = {
        hover: { 'background-color': 'var(--brand-nav-hover)', color: 'var(--brand-nav-text)' },
        selected: { 'background-color': 'var(--brand-nav-selected)', color: 'var(--brand-nav-selected-text)' },
        base: { 'background-color': 'var(--brand-nav-bg)', color: 'var(--brand-nav-text)' }
    };
    const out = [];
    for (const [kind, rules] of Object.entries(groups)) {
        const byShape = new Map();
        for (const r of rules) {
            const key = `${r.props.join(',')}|${r.important}`;
            if (!byShape.has(key)) byShape.set(key, { props: r.props, important: r.important, parts: [] });
            byShape.get(key).parts.push(r.part);
        }
        for (const g of byShape.values()) {
            out.push(`${[...new Set(g.parts)].join(',\n')} {\n${g.props.map((p) => `  ${p}: ${values[kind][p]}${g.important};`).join('\n')}\n}`);
        }
    }
    return out.join('\n\n');
}

function primaryRules(scoped) {
    const out = [];
    for (const rule of scoped.filter((r) => r.family === 'hot-button')) {
        const sel = rule.selector.split(',').join(',\n');
        if (/\.fa:after/.test(rule.selector)) {
            out.push(`${sel} {\n  background-color: var(--brand-action);\n}`);
        } else if (/noUI/.test(rule.selector)) {
            out.push(`${sel} {\n  --a-button-text-color: var(--brand-action-text);\n  color: var(--brand-action-text);\n}`);
        } else if (/t-Button--link/.test(rule.selector)) {
            out.push(`${sel} {\n  --a-button-text-color: var(--brand-action-text);\n}`);
        } else if (/t-Button--simple/.test(rule.selector)) {
            out.push(`${sel} {\n  --a-button-border-color: var(--brand-action-text);\n  --a-button-text-color: var(--brand-action-text);\n  --a-button-hover-background-color: var(--brand-action);\n  --a-button-hover-text-color: var(--brand-on-action);\n}`);
        } else {
            out.push(`${sel} {\n  --a-button-background-color: var(--brand-action);\n  --a-button-text-color: var(--brand-on-action);\n  --a-button-hover-background-color: var(--brand-action-hover);\n  --a-button-active-background-color: var(--brand-action-active);\n  --a-button-border-color: var(--brand-action);\n}`);
        }
    }
    return out.join('\n\n');
}

function buildCss(kit, d, scoped, fontFiles) {
    const { t, shape } = d;
    const family = kit.font?.family ? `"${kit.font.family}", ${SYSTEM_STACK}` : SYSTEM_STACK;
    const hw = kit.font?.headingWeight || 700;
    const tall = kit.header?.tall ? '4rem' : null;
    const tokens = [
        ['--brand-primary', t.primary], ['--brand-primary-hover', t.primaryHover], ['--brand-primary-text', t.primaryText],
        ['--brand-primary-tint', t.primaryTint], ['--brand-on-primary', t.onPrimary],
        ['--brand-action', t.action], ['--brand-action-hover', t.actionHover], ['--brand-action-active', t.actionActive],
        ['--brand-action-text', t.actionText], ['--brand-on-action', t.onAction],
        ['--brand-ground', t.ground], ['--brand-surface', t.surface], ['--brand-ink', t.ink], ['--brand-muted', t.muted], ['--brand-border', t.border],
        ['--brand-header-bg', t.headerBg], ['--brand-header-text', t.headerText], ['--brand-logo', t.logo],
        ['--brand-nav-bg', t.navBg], ['--brand-nav-text', t.navText], ['--brand-nav-selected', t.navSelected], ['--brand-nav-selected-text', t.navSelectedText],
        ['--brand-nav-hover', t.navHover], ['--brand-focus', t.focus], ['--brand-row-alt', mix(t.surface, t.ink, 0.025)],
        ...['success', 'warning', 'danger', 'info'].flatMap((s) => [[`--brand-${s}`, t[s]], [`--brand-on-${s}`, t[`on${s[0].toUpperCase()}${s.slice(1)}`]], [`--brand-${s}-text`, t[`${s}Text`]], [`--brand-${s}-shade`, t[`${s}Shade`]]]),
        ['--brand-radius', shape.radius], ['--brand-radius-sm', shape.radiusSm], ['--brand-button-radius', shape.button],
        ['--brand-shadow', shape.shadow], ['--brand-header-shadow', shape.headerShadow],
        ['--brand-font-ui', family], ['--brand-heading-weight', String(hw)]
    ];
    const ut = [
        // Typography
        ['--a-base-font-family', 'var(--brand-font-ui)'], ['--ut-alternate-heading-font-family', 'var(--brand-font-ui)'],
        ['--ut-hero-region-title-font-family', 'var(--brand-font-ui)'], ['--ut-hero-region-title-font-weight', 'var(--brand-heading-weight)'],
        ['--ut-breadcrumb-item-active-font-weight', 'var(--brand-heading-weight)'], ['--ut-breadcrumb-title-font-weight', 'var(--brand-heading-weight)'],
        ['--ut-breadcrumb-title-font-family', 'var(--brand-font-ui)'], ['--a-cv-title-font-weight', 'var(--brand-heading-weight)'],
        ['--ut-cardlist-title-font-weight', 'var(--brand-heading-weight)'], ['--ut-logo-font-weight', 'var(--brand-heading-weight)'],
        // Global palette
        ['--ut-palette-primary', 'var(--brand-primary)'], ['--ut-palette-primary-contrast', 'var(--brand-on-primary)'],
        ['--ut-palette-primary-text', 'var(--brand-primary-text)'], ['--ut-palette-primary-shade', 'var(--brand-primary-tint)'],
        ['--ut-link-text-color', 'var(--brand-primary-text)'], ['--ut-focus-outline-color', 'var(--brand-focus)'],
        ...['success', 'warning', 'danger', 'info'].flatMap((s) => [
            [`--ut-palette-${s}`, `var(--brand-${s})`], [`--ut-palette-${s}-contrast`, `var(--brand-on-${s})`],
            [`--ut-palette-${s}-shade`, `var(--brand-${s}-shade)`], ...(s === 'info' ? [] : [[`--ut-palette-${s}-text`, `var(--brand-${s}-text)`]]),
            // Subtle badges colour their text with the base palette colour; give them the contrast-safe shade.
            [`--ut-badge-subtle-${s}-text-color`, `var(--brand-${s}-text)`], [`--ut-badge-subtle-${s}-background-color`, `var(--brand-${s}-shade)`]
        ]),
        // Header
        ['--ut-header-background-color', 'var(--brand-header-bg)'], ['--ut-header-text-color', 'var(--brand-header-text)'],
        ['--ut-header-box-shadow', 'var(--brand-header-shadow)'], ['--ut-header-border-width', '0px'], ['--ut-logo-text-color', 'var(--brand-logo)'],
        ...(tall ? [['--ut-header-height', tall]] : []),
        // Navigation
        ['--ut-body-nav-background-color', 'var(--brand-nav-bg)'], ['--ut-body-nav-text-color', 'var(--brand-nav-text)'],
        ['--ut-body-nav-border-color', 'var(--brand-border)'], ['--ut-body-nav-border-width', kit.nav?.style === 'dark' ? '0px' : '1px'],
        ['--a-treeview-node-selected-background-color', 'var(--brand-nav-selected)'], ['--a-treeview-node-selected-text-color', 'var(--brand-nav-selected-text)'],
        ['--a-treeview-node-selected-icon-color', 'var(--brand-nav-selected-text)'],
        // Ground, title bar, text
        ['--ut-body-background-color', 'var(--brand-ground)'], ['--ut-body-text-color', 'var(--brand-ink)'],
        ['--ut-body-title-background-color', 'var(--brand-ground)'], ['--ut-body-title-text-color', 'var(--brand-ink)'],
        ['--ut-body-title-box-shadow', 'none'], ['--ut-component-text-default-color', 'var(--brand-ink)'],
        ['--ut-component-text-title-color', 'var(--brand-ink)'], ['--ut-component-text-muted-color', 'var(--brand-muted)'],
        // Regions and cards
        ['--ut-component-border-radius', 'var(--brand-radius)'], ['--ut-region-border-radius', 'var(--brand-radius)'],
        ['--ut-region-background-color', 'var(--brand-surface)'], ['--ut-region-text-color', 'var(--brand-ink)'],
        ['--ut-region-border-color', 'var(--brand-border)'], ['--ut-region-border-width', shape.regionBorder],
        ['--ut-region-box-shadow', 'var(--brand-shadow)'], ['--ut-region-header-background-color', 'var(--brand-surface)'],
        ['--ut-region-header-text-color', 'var(--brand-ink)'], ['--ut-region-header-border-color', 'var(--brand-border)'],
        ['--a-cv-border-radius', 'var(--brand-radius)'], ['--a-cv-shadow', 'var(--brand-shadow)'], ['--a-cv-border-color', 'var(--brand-border)'],
        // Controls
        ['--a-button-border-radius', 'var(--brand-button-radius)'], ['--a-field-input-border-radius', 'var(--brand-radius-sm)'],
        ['--a-field-input-border-color', 'var(--brand-border)'], ['--a-field-input-focus-border-color', 'var(--brand-focus)'],
        // Reports and badges
        ['--ut-report-header-background-color', 'var(--brand-surface)'], ['--ut-report-header-text-color', 'var(--brand-muted)'],
        ['--ut-report-header-cell-font-weight', 'var(--brand-heading-weight)'], ['--ut-report-cell-border-color', 'var(--brand-border)'],
        // Quiet tables: barely-there zebra rows, a brand-tinted hover, hairline borders.
        ['--ut-report-cell-alt-background-color', 'var(--brand-row-alt)'], ['--ut-report-cell-hover-background-color', 'var(--brand-primary-tint)'],
        ['--ut-report-border-color', 'var(--brand-border)'], ['--ut-report-header-cell-border-color', 'var(--brand-border)'],
        ['--a-gv-header-background-color', 'var(--brand-surface)'],
        ['--ut-badge-border-radius', kit.shape?.button === 'square' ? 'var(--brand-radius-sm)' : '999px']
    ];

    const lines = (pairs) => pairs.map(([k, v]) => `  ${k}: ${v};`).join('\n');
    const css = `/* Generated by scripts/build-brand-kit.mjs from brand-kit.json (APEX ${kit.version}).
   Do not hand-edit: change brand-kit.json and rebuild. Load app-wide with
   application css.fileUrls: #APP_FILES#css/brand.css?v=#APP_VERSION#
   Reference: ${kit.source?.reference || 'none'} */

${fontFaces(kit, fontFiles)}
/* 1. Brand tokens: the only colour literals in the app. */
:root {
${lines(tokens)}
}

/* 2. Universal Theme mapping. Every variable below is read by the APEX ${kit.version} theme CSS. */
:root {
${lines(ut)}
}

/* 3. Primary action. Vita hard-codes its blue on these selectors, so :root is not enough. */
${primaryRules(scoped)}

/* 4. Side navigation. Vita hard-codes nav state colours on these selectors. */
${navRules(scoped)}

/* 5. Headings. Region titles inherit weight; give them the brand heading weight. */
.t-Region-title,
.t-BreadcrumbRegion-titleText {
  font-weight: var(--brand-heading-weight);
  letter-spacing: -0.01em;
}

/* 6. Motion respects the user. */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { transition-duration: 0s !important; animation-duration: 0s !important; }
}
`;
    return { css, utVars: ut.map(([k]) => k) };
}

async function readJson(file) {
    return JSON.parse((await fs.readFile(file, 'utf8')).replace(/^﻿/, ''));
}

async function fontFilesIn(dir, family) {
    const slug = String(family || '').toLowerCase().replace(/\s+/g, '-');
    try {
        const files = await fs.readdir(dir);
        return files
            .map((file) => ({ file, m: new RegExp(`^${slug}-latin-(\\d{3})-normal\\.woff2$`).exec(file) }))
            .filter((x) => x.m)
            .map((x) => ({ file: x.file, weight: Number(x.m[1]) }))
            .sort((a, b) => a.weight - b.weight);
    } catch {
        return [];
    }
}

async function main() {
    let args;
    try {
        args = parseArgs(process.argv.slice(2));
    } catch (error) {
        process.stderr.write(`${error.message}\n\n${usage()}`);
        process.exit(2);
    }

    let kit;
    let outDir;
    if (args.kit) {
        kit = await readJson(path.resolve(args.kit));
        outDir = path.resolve(args.out || path.dirname(path.resolve(args.kit)));
    } else if (args.init) {
        kit = kitFromDefaults();
        outDir = path.resolve(args.out || DEFAULT_OUT);
    } else {
        const refPath = path.resolve(args.reference);
        kit = kitFromReference(await readJson(refPath), path.relative(process.cwd(), refPath).replace(/\\/g, '/'));
        outDir = path.resolve(args.out || DEFAULT_OUT);
    }
    applySets(kit, args.sets);
    if (args.version) kit.version = args.version;
    kit.version ||= '26.2';

    const assetDir = path.join(ROOT, 'skills', 'apex-design-system', 'assets', 'ut-css', kit.version);
    let consumed;
    let scoped;
    try {
        consumed = new Set((await fs.readFile(path.join(assetDir, 'consumed-vars.txt'), 'utf8')).split(/\r?\n/).filter(Boolean));
        scoped = await readJson(path.join(assetDir, 'scoped-rules.json'));
    } catch {
        process.stderr.write(`No Universal Theme index for APEX ${kit.version}. Run: node scripts/refresh-ut-css-vars.mjs ${kit.version}\n`);
        process.exit(2);
    }

    const derived = derive(kit);
    await fs.mkdir(path.join(outDir, 'css'), { recursive: true });
    await fs.mkdir(path.join(outDir, 'fonts'), { recursive: true });
    const fontFiles = await fontFilesIn(path.join(outDir, 'fonts'), kit.font?.family);
    const { css, utVars } = buildCss(kit, derived, scoped, fontFiles);

    const unread = utVars.filter((v) => !consumed.has(v));
    if (unread.length) {
        process.stderr.write(`Internal error: these variables are not read by APEX ${kit.version} and would have no effect: ${unread.join(', ')}\n`);
        process.exit(1);
    }

    await fs.writeFile(path.join(outDir, 'brand-kit.json'), `${JSON.stringify(kit, null, 2)}\n`, 'utf8');
    await fs.writeFile(path.join(outDir, 'css', 'brand.css'), css, 'utf8');

    const failing = derived.report.filter((r) => !r.pass);
    const report = [
        '# Brand Kit Report',
        '',
        `- APEX version: ${kit.version}`,
        `- Reference: ${kit.source?.reference || 'none'}`,
        `- Font: ${kit.font?.family || 'system'} (${kit.font?.reason || 'set by hand'}); files: ${fontFiles.length ? fontFiles.map((f) => f.weight).join(', ') : 'NONE - run scripts/fetch-open-font.mjs'}`,
        `- Header: ${kit.header?.style}; nav: ${kit.nav?.style}; buttons: ${kit.shape?.button}; radius: ${derived.shape.radius}; depth: ${kit.depth?.shadow}`,
        `- Universal Theme variables set: ${utVars.length} (all verified against the APEX ${kit.version} theme CSS)`,
        `- Hard-coded Vita colour rules re-declared: ${scoped.length} (hot buttons and side navigation)`,
        '',
        '## Contrast',
        '',
        '| Pair | Foreground | Background | Ratio | Minimum | Result |',
        '| --- | --- | --- | ---: | ---: | --- |',
        ...derived.report.map((r) => `| ${r.name} | \`${r.fg}\` | \`${r.bg}\` | ${r.ratio}:1 | ${r.min}:1 | ${r.pass ? 'PASS' : 'FAIL'} |`),
        '',
        failing.length ? `**${failing.length} contrast pair(s) fail.** Change the colour in brand-kit.json and rebuild.` : 'All contrast pairs pass.',
        ''
    ].join('\n');
    await fs.writeFile(path.join(outDir, 'kit-report.md'), report, 'utf8');

    const rel = (p) => path.relative(process.cwd(), p);
    process.stdout.write(`Brand kit written to ${rel(outDir)}\n`);
    process.stdout.write(`- brand-kit.json, css/brand.css, kit-report.md\n`);
    process.stdout.write(`- primary ${derived.t.primary}, action ${derived.t.action} (label ${derived.t.onAction}), header ${kit.header?.style}, nav ${kit.nav?.style}, font ${kit.font?.family}\n`);
    const neededWeights = [...new Set([400, 500, 600, 700, Number(kit.font?.headingWeight || 700)])].sort();
    const missingWeights = neededWeights.filter((w) => !fontFiles.some((f) => f.weight === w));
    if (kit.font?.family && missingWeights.length) {
        process.stdout.write(`- Font weights missing: ${missingWeights.join(', ')}. Run: node scripts/fetch-open-font.mjs --family "${kit.font.family}" --weights ${neededWeights.join(',')} --out ${rel(path.join(outDir, 'fonts'))} then rebuild.\n`);
    }
    if (failing.length) {
        process.stdout.write(`BRAND KIT FAIL: ${failing.map((f) => f.name).join('; ')}\n`);
        process.exit(1);
    }
    process.stdout.write('BRAND KIT PASS\n');
}

main().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exit(1);
});
