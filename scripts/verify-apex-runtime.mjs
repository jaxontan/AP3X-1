#!/usr/bin/env node
// Runtime gate for a deployed Oracle APEX application.
// Logs in as each test user, opens each page at desktop and mobile widths, and fails on:
// page errors, JavaScript errors, blank Font APEX icons, mobile horizontal overflow,
// serious/critical axe violations, a missing brand stylesheet, or an allowed page that a
// user should be denied (authorization leak).
// Passwords are read from an environment variable, never from the command line.
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const VIEWPORTS = [
    { name: 'desktop', width: 1440, height: 900 },
    { name: 'mobile', width: 390, height: 844 }
];
const AXE_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22a', 'wcag22aa'];
const DENIED_TEXT = /insufficient privileges|not authorized|access denied|you are not authorized/i;

function usage() {
    return `Usage:
  node scripts/verify-apex-runtime.mjs --url <app-url> --users <U1,U2> --pages <alias,...> [options]

Required:
  --url <url>            Application base URL, e.g. https://localhost:8443/ords/r/<workspace>/<app-alias>
  --users <list>         Comma-separated APEX test users to log in as
  --pages <list>         Comma-separated page aliases to open, e.g. home,orders

Options:
  --password-env <name>  Environment variable holding the test password (default APEX_TEST_PASSWORD)
  --deny <user:alias>    Page the user must NOT reach (repeatable), e.g. --deny EMP1:category-admin
  --brand                Require the brand layer at runtime (--brand-primary CSS token must resolve)
  --out <dir>            Report directory (default working/runtime-verification/<timestamp>)
  --insecure             Accept self-signed HTTPS certificates (local disposable databases)
  --strict               Fail on every axe violation, not only serious/critical
  --channel <name>       Playwright browser channel, e.g. chrome or msedge
  -h, --help             Show this help

Example:
  $env:APEX_TEST_PASSWORD = '<from credentials.md>'
  node scripts/verify-apex-runtime.mjs --url https://localhost:8443/ords/r/<workspace>/<app-alias> \\
    --users EMP1,MGR1,FIN1 --pages home,orders --deny EMP1:category-admin --brand --insecure
`;
}

function parseArgs(argv) {
    const args = { url: null, users: [], pages: [], passwordEnv: 'APEX_TEST_PASSWORD', deny: [], brand: false, out: null, insecure: false, strict: false, channel: process.env.PLAYWRIGHT_CHANNEL || null };
    const value = (i, flag) => {
        const v = argv[i + 1];
        if (!v || v.startsWith('--')) throw new Error(`Missing value for ${flag}.`);
        return v;
    };
    const list = (v) => v.split(',').map((s) => s.trim()).filter(Boolean);
    for (let i = 0; i < argv.length; i += 1) {
        const a = argv[i];
        if (a === '--url') { args.url = value(i, a); i += 1; }
        else if (a === '--users') { args.users = list(value(i, a)); i += 1; }
        else if (a === '--pages') { args.pages = list(value(i, a)); i += 1; }
        else if (a === '--password-env') { args.passwordEnv = value(i, a); i += 1; }
        else if (a === '--deny') {
            const v = value(i, a); i += 1;
            const [user, alias] = v.split(':');
            if (!user || !alias) throw new Error(`--deny expects user:alias, got "${v}".`);
            args.deny.push({ user: user.toUpperCase(), alias });
        }
        else if (a === '--brand') args.brand = true;
        else if (a === '--out') { args.out = value(i, a); i += 1; }
        else if (a === '--insecure') args.insecure = true;
        else if (a === '--strict') args.strict = true;
        else if (a === '--channel') { args.channel = value(i, a); i += 1; }
        else if (a === '-h' || a === '--help') { process.stdout.write(usage()); process.exit(0); }
        else throw new Error(`Unknown argument: ${a}`);
    }
    if (!args.url || args.users.length === 0 || args.pages.length === 0) {
        throw new Error('--url, --users, and --pages are required.');
    }
    return args;
}

async function launchBrowser(chromium, requestedChannel) {
    const candidates = [];
    if (requestedChannel) candidates.push({ channel: requestedChannel });
    candidates.push({}, { channel: 'chrome' }, { channel: 'msedge' });
    const failures = [];
    for (const options of candidates) {
        try {
            return await chromium.launch({ headless: true, ...options });
        } catch (error) {
            failures.push(`${options.channel || 'bundled Chromium'}: ${String(error.message).split('\n')[0]}`);
        }
    }
    throw new Error(`Could not launch a browser. Run "npm install" and "npx playwright install chromium".\n${failures.join('\n')}`);
}

function pageUrl(base, alias, session) {
    const url = new URL(`${base.replace(/\/+$/, '')}/${alias}`);
    if (session) url.searchParams.set('session', session);
    return url.toString();
}

async function login(page, args, user, password) {
    await page.goto(args.url, { waitUntil: 'domcontentloaded' });
    const username = page.locator('input[id$="_USERNAME"], input[name$="_USERNAME"]').first();
    const pwd = page.locator('input[id$="_PASSWORD"], input[type="password"]').first();
    await username.fill(user);
    await pwd.fill(password);
    const before = page.url();
    await pwd.press('Enter');
    await page.waitForURL((url) => url.toString() !== before, { timeout: 30000 }).catch(() => {});
    await page.waitForLoadState('networkidle').catch(() => {});
    const session = new URL(page.url()).searchParams.get('session');
    if (await page.locator('input[type="password"]').count() > 0) {
        throw new Error(`Login failed for ${user}: still on the login page.`);
    }
    return session;
}

async function inspect(page, args) {
    return page.evaluate((wantBrand) => {
        // A visible icon slot with no glyph, no image and no content renders as an empty box
        // (e.g. a hero region whose icon was never set). Unknown fa-* names do not render blank;
        // Font APEX falls back to a generic glyph, so scripts/verify-delivery.ps1 checks names statically.
        const blankIcons = [];
        for (const el of document.querySelectorAll('.fa, .t-Icon')) {
            const rect = el.getBoundingClientRect();
            if (rect.width < 4 || rect.height < 4) continue;
            const style = getComputedStyle(el);
            if (style.visibility === 'hidden' || style.display === 'none') continue;
            const content = getComputedStyle(el, '::before').content;
            const noGlyph = !content || content === 'none' || content === 'normal' || content === '""';
            if (noGlyph && style.backgroundImage === 'none' && !el.textContent.trim() && el.children.length === 0) {
                const cls = el.className.toString().trim().replace(/\s+/g, '.');
                const owner = el.closest('[id]');
                blankIcons.push(`${cls || 'icon'}${owner ? ` in #${owner.id}` : ''} (${Math.round(rect.width)}x${Math.round(rect.height)})`);
            }
        }
        const widths = [document.documentElement.scrollWidth, document.body ? document.body.scrollWidth : 0];
        const brandPrimary = getComputedStyle(document.documentElement).getPropertyValue('--brand-primary').trim();
        const errorRegion = document.querySelector('.t-Alert--danger.t-Alert--page, #t_Alert_Notification .t-Alert--danger, .a-ErrorPage');
        return {
            title: document.title,
            blankIcons: [...new Set(blankIcons)],
            overflowPixels: Math.max(...widths) - window.innerWidth,
            brandPrimary,
            missingBrand: wantBrand && !brandPrimary,
            apexError: errorRegion ? errorRegion.textContent.replace(/\s+/g, ' ').trim().slice(0, 200) : null,
            deniedText: /insufficient privileges|not authorized|access denied/i.test(document.body ? document.body.innerText : '')
        };
    }, args.brand);
}

async function main() {
    const args = parseArgs(process.argv.slice(2));
    const password = process.env[args.passwordEnv];
    if (!password) throw new Error(`Set the test password in the ${args.passwordEnv} environment variable.`);

    const { chromium } = await import('playwright');
    const AxeBuilder = (await import('@axe-core/playwright')).default;
    const stamp = new Date().toISOString().replace(/[:.]/g, '-');
    const outDir = path.resolve(args.out || path.join('working', 'runtime-verification', stamp));
    await fs.mkdir(outDir, { recursive: true });

    const browser = await launchBrowser(chromium, args.channel);
    const results = [];
    const failures = [];
    try {
        for (const user of args.users.map((u) => u.toUpperCase())) {
            const context = await browser.newContext({ ignoreHTTPSErrors: args.insecure });
            const page = await context.newPage();
            const jsErrors = [];
            page.on('pageerror', (e) => jsErrors.push(String(e.message).split('\n')[0]));
            page.on('console', (m) => { if (m.type() === 'error') jsErrors.push(m.text().slice(0, 200)); });

            let session;
            try {
                session = await login(page, args, user, password);
            } catch (error) {
                failures.push(`${user}: ${error.message}`);
                await context.close();
                continue;
            }

            const denied = args.deny.filter((d) => d.user === user).map((d) => d.alias);
            for (const alias of [...args.pages, ...denied.filter((a) => !args.pages.includes(a))]) {
                const mustDeny = denied.includes(alias);
                for (const viewport of mustDeny ? [VIEWPORTS[0]] : VIEWPORTS) {
                    await page.setViewportSize({ width: viewport.width, height: viewport.height });
                    jsErrors.length = 0;
                    const response = await page.goto(pageUrl(args.url, alias, session), { waitUntil: 'networkidle' }).catch((e) => ({ status: () => 0, error: e }));
                    const status = response?.status?.() ?? 0;
                    const info = await inspect(page, args);
                    const reached = status > 0 && status < 400 && !info.deniedText && !(await page.locator('input[type="password"]').count());
                    const shot = path.join(outDir, `${user}-${alias}-${viewport.name}.png`);
                    await page.screenshot({ path: shot, fullPage: true }).catch(() => {});
                    const label = `${user} ${alias} ${viewport.name}`;
                    const entry = { user, alias, viewport: viewport.name, status, mustDeny, reached, ...info, jsErrors: [...jsErrors], screenshot: shot, axe: [] };

                    if (mustDeny) {
                        if (reached) failures.push(`${label}: authorization leak, page should be denied but rendered.`);
                        results.push(entry);
                        continue;
                    }
                    if (!reached) failures.push(`${label}: page not reachable (HTTP ${status}${info.deniedText ? ', access denied' : ''}).`);
                    if (info.apexError) failures.push(`${label}: APEX error shown: ${info.apexError}`);
                    if (jsErrors.length) failures.push(`${label}: JavaScript errors: ${jsErrors.slice(0, 3).join(' | ')}`);
                    if (info.blankIcons.length) failures.push(`${label}: blank icons: ${info.blankIcons.join(', ')}`);
                    if (viewport.name === 'mobile' && info.overflowPixels > 1) failures.push(`${label}: horizontal overflow of ${info.overflowPixels}px.`);
                    if (info.missingBrand) failures.push(`${label}: --brand-primary is not defined; brand.css did not load.`);

                    if (reached) {
                        const axe = await new AxeBuilder({ page }).withTags(AXE_TAGS).analyze();
                        const gated = axe.violations.filter((v) => args.strict || v.impact === 'serious' || v.impact === 'critical');
                        entry.axe = axe.violations.map((v) => ({ id: v.id, impact: v.impact, nodes: v.nodes.length }));
                        if (gated.length) failures.push(`${label}: axe ${gated.map((v) => `${v.id}(${v.impact})`).join(', ')}`);
                    }
                    results.push(entry);
                }
            }
            await context.close();
        }
    } finally {
        await browser.close();
    }

    const report = { url: args.url, users: args.users, pages: args.pages, deny: args.deny, passed: failures.length === 0, failures, results };
    await fs.writeFile(path.join(outDir, 'report.json'), JSON.stringify(report, null, 2));
    const md = [
        '# APEX runtime verification', '',
        `- URL: ${args.url}`, `- Users: ${args.users.join(', ')}`, `- Pages: ${args.pages.join(', ')}`,
        `- Result: ${report.passed ? 'PASS' : 'FAIL'}`, '',
        '| User | Page | Viewport | HTTP | Expected | Blank icons | JS errors | Axe | Screenshot |',
        '| --- | --- | --- | ---: | --- | ---: | ---: | ---: | --- |',
        ...results.map((r) => `| ${r.user} | ${r.alias} | ${r.viewport} | ${r.status} | ${r.mustDeny ? 'denied' : 'allowed'} | ${r.blankIcons.length} | ${r.jsErrors.length} | ${r.axe.length} | \`${path.basename(r.screenshot)}\` |`),
        '', '## Failures', '', ...(failures.length ? failures.map((f) => `- ${f}`) : ['None.'])
    ].join('\n');
    await fs.writeFile(path.join(outDir, 'report.md'), md + '\n');

    process.stdout.write(`Report: ${path.join(outDir, 'report.md')}\n`);
    if (failures.length) {
        process.stdout.write(`RUNTIME GATE FAIL (${failures.length})\n${failures.map((f) => `  - ${f}`).join('\n')}\n`);
        process.exit(1);
    }
    process.stdout.write('RUNTIME GATE PASS\n');
}

main().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exit(2);
});
