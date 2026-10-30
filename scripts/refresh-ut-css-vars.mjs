#!/usr/bin/env node
// Index the real Universal Theme CSS that Oracle publishes on its CDN, per APEX version.
// Writes variable NAMES, selectors, and a few stock values only (no Oracle CSS is vendored):
//   skills/apex-design-system/assets/ut-css/<version>/consumed-vars.txt  variables the runtime CSS reads
//   skills/apex-design-system/assets/ut-css/<version>/stock.json          stock Vita values for key variables
//   skills/apex-design-system/assets/ut-css/<version>/scoped-rules.json   Vita rules that hard-code colours on
//       hot buttons and the side navigation, which a :root override cannot reach
// brand.css overrides of anything not in consumed-vars.txt have no effect in that version.
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const VERSIONS = {
    '26.1': { cdn: '26.1.2', theme: '26.1' },
    '26.2': { cdn: '26.2.0', theme: '26.2' }
};

const STOCK_KEYS = [
    '--ut-palette-primary', '--ut-palette-primary-contrast', '--ut-header-background-color', '--ut-header-text-color',
    '--ut-body-background-color', '--ut-body-text-color', '--ut-body-nav-background-color', '--ut-region-background-color',
    '--ut-component-border-radius', '--ut-region-box-shadow', '--ut-header-height', '--a-base-font-family', '--ut-link-text-color'
];

const STOCK_PRIMARY = /#056ac8|#0784f9|#045daf|#4275a4|#e8f1fb/i;
const COLOUR_LITERAL = /#[0-9a-f]{3,8}\b|rgba?\(/i;

// Which family a hard-coded Vita rule belongs to, or null when the brand kit does not theme it.
function family(selector, body) {
    if (/t-TreeNav/.test(selector) && COLOUR_LITERAL.test(body)) return 'treenav';
    if (/--hot\b|button-group input:checked/.test(selector) && STOCK_PRIMARY.test(body)) return 'hot-button';
    return null;
}

function cdnFiles(version) {
    const v = VERSIONS[version];
    const base = `https://static.oracle.com/cdn/apex/${v.cdn}`;
    return {
        base,
        appUi: `${base}/app_ui/css/Core.min.css`,
        themeCore: `${base}/themes/theme_42/${v.theme}/css/Core.min.css`,
        vita: `${base}/themes/theme_42/${v.theme}/css/Vita.min.css`
    };
}

async function get(url) {
    const response = await fetch(url);
    if (!response.ok) throw new Error(`${response.status} ${url}`);
    return response.text();
}

function stripComments(css) {
    return css.replace(/\/\*[\s\S]*?\*\//g, '');
}

async function indexVersion(root, version) {
    const files = cdnFiles(version);
    const [appUi, themeCore, vita] = await Promise.all([get(files.appUi), get(files.themeCore), get(files.vita)]);
    const all = [appUi, themeCore, vita].map(stripComments).join('\n');

    const consumed = new Set([...all.matchAll(/var\((--[a-z0-9-]+)/g)].map((m) => m[1]));
    const stock = {};
    const vitaClean = stripComments(vita);
    const coreClean = stripComments(appUi) + stripComments(themeCore);
    for (const key of STOCK_KEYS) {
        const re = new RegExp(`(?:^|[;{])${key.replace(/-/g, '\\-')}:([^;}]+)`);
        const match = re.exec(vitaClean) || re.exec(coreClean);
        if (match) stock[key] = match[1].trim();
    }
    const scoped = [];
    for (const rule of vitaClean.match(/[^{}]+\{[^{}]*\}/g) || []) {
        const [selector, body] = rule.split('{');
        if (/^\s*:root\s*$/.test(selector) || selector.includes('@')) continue;
        const kind = family(selector, body);
        if (!kind) continue;
        const declarations = body.replace('}', '').split(';').filter((p) => COLOUR_LITERAL.test(p));
        scoped.push({
            family: kind,
            selector: selector.trim(),
            properties: declarations.map((p) => p.split(':')[0].trim()),
            important: declarations.some((p) => /!important/.test(p))
        });
    }

    const dir = path.join(root, 'skills', 'apex-design-system', 'assets', 'ut-css', version);
    await fs.mkdir(dir, { recursive: true });
    await fs.writeFile(path.join(dir, 'consumed-vars.txt'), `${[...consumed].sort().join('\n')}\n`, 'utf8');
    await fs.writeFile(path.join(dir, 'stock.json'), `${JSON.stringify({ source: files, stock }, null, 2)}\n`, 'utf8');
    await fs.rm(path.join(dir, 'scoped-primary.json'), { force: true });
    await fs.writeFile(path.join(dir, 'scoped-rules.json'), `${JSON.stringify(scoped, null, 2)}\n`, 'utf8');
    return { version, consumed: consumed.size, scoped: scoped.length, stock: Object.keys(stock).length };
}

async function main() {
    if (process.argv.includes('-h') || process.argv.includes('--help')) {
        process.stdout.write('Usage: node scripts/refresh-ut-css-vars.mjs [26.1|26.2 ...]\nIndexes Oracle CDN Universal Theme CSS into skills/apex-design-system/assets/ut-css/<version>/.\n');
        return;
    }
    const root = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1')), '..');
    const requested = process.argv.slice(2).filter((a) => !a.startsWith('-'));
    const versions = requested.length ? requested : Object.keys(VERSIONS);
    for (const version of versions) {
        if (!VERSIONS[version]) throw new Error(`Unknown version ${version}; known: ${Object.keys(VERSIONS).join(', ')}`);
        const result = await indexVersion(root, version);
        process.stdout.write(`${result.version}: ${result.consumed} consumed variables, ${result.stock} stock values, ${result.scoped} scoped colour rules\n`);
    }
}

main().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exit(1);
});
