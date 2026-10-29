#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { pathToFileURL } from 'node:url';

const nodeVersion = process.versions.node.split('.').map(Number);
if (nodeVersion[0] < 22 || (nodeVersion[0] === 22 && nodeVersion[1] < 12)) {
    process.stderr.write(`Node.js 22.12 or newer is required for @axe-core/playwright; found ${process.versions.node}.\n`);
    process.exit(2);
}

const VIEWPORTS = [
    { name: 'desktop', width: 1440, height: 900 },
    { name: 'mobile', width: 390, height: 844 }
];

const AXE_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22a', 'wcag22aa'];

function usage() {
    return `Usage:
  node scripts/verify-design-preview.mjs --preview <file-or-directory> [options]

Options:
  -p, --preview <path>  Prototype HTML file or directory containing before/after/index.html
  -o, --out <path>      Output directory (default: <preview>/verification)
      --strict          Fail on every axe violation, not only serious/critical
      --channel <name>  Playwright browser channel, for example chrome or msedge
  -h, --help            Show this help

Examples:
  node scripts/verify-design-preview.mjs --preview working/design-preview/ticket-redesign
  node scripts/verify-design-preview.mjs -p working/design-preview/ticket-redesign/after.html --strict
`;
}

function parseArgs(argv) {
    const args = { preview: null, out: null, strict: false, channel: process.env.PLAYWRIGHT_CHANNEL || null };
    const nextValue = (index, flag) => {
        const value = argv[index + 1];
        if (!value || value.startsWith('-')) throw new Error(`Missing value for ${flag}.`);
        return value;
    };
    for (let index = 0; index < argv.length; index += 1) {
        const value = argv[index];
        if (value === '-p' || value === '--preview') {
            args.preview = nextValue(index, value);
            index += 1;
        } else if (value === '-o' || value === '--out') {
            args.out = nextValue(index, value);
            index += 1;
        } else if (value === '--strict') {
            args.strict = true;
        } else if (value === '--channel') {
            args.channel = nextValue(index, value);
            index += 1;
        } else if (value === '-h' || value === '--help') {
            process.stdout.write(usage());
            process.exit(0);
        } else {
            throw new Error(`Unknown argument: ${value}`);
        }
    }
    if (!args.preview) {
        throw new Error('Missing --preview. Pass an HTML file or a prototype directory.');
    }
    return args;
}

async function exists(file) {
    try {
        await fs.access(file);
        return true;
    } catch {
        return false;
    }
}

async function collectTargets(previewPath) {
    const resolved = path.resolve(process.cwd(), previewPath);
    const stat = await fs.stat(resolved);
    if (stat.isFile()) {
        return {
            input: resolved,
            isDirectory: false,
            targets: [{ label: path.basename(resolved, path.extname(resolved)), file: resolved, gate: true }]
        };
    }
    if (!stat.isDirectory()) {
        throw new Error(`Preview is neither a file nor a directory: ${resolved}`);
    }

    const before = path.join(resolved, 'before.html');
    const after = path.join(resolved, 'after.html');
    const index = path.join(resolved, 'index.html');
    const targets = [];
    if (await exists(before)) targets.push({ label: 'before', file: before, gate: false });
    if (await exists(after)) targets.push({ label: 'after', file: after, gate: true });
    if (targets.length === 0 && await exists(index)) targets.push({ label: 'preview', file: index, gate: true });
    if (targets.length === 0) {
        throw new Error('No before.html, after.html, or index.html found in the preview directory.');
    }
    if (!targets.some((target) => target.gate) && targets[0]) {
        targets[0].gate = true;
    }
    return { input: resolved, isDirectory: true, targets };
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

function shortText(value, limit = 300) {
    const text = String(value || '').replace(/\s+/g, ' ').trim();
    return text.length > limit ? `${text.slice(0, limit)}...` : text;
}

function axeSummary(violations) {
    const counts = { critical: 0, serious: 0, moderate: 0, minor: 0 };
    for (const violation of violations) {
        if (Object.prototype.hasOwnProperty.call(counts, violation.impact)) counts[violation.impact] += 1;
    }
    return counts;
}

function relativePath(file) {
    const relative = path.relative(process.cwd(), file);
    return relative || file;
}

async function verifyTarget(browser, target, viewport, outDir) {
    const context = await browser.newContext({
        viewport: { width: viewport.width, height: viewport.height },
        reducedMotion: 'reduce'
    });
    const page = await context.newPage();
    const screenshot = path.join(outDir, `${target.label}-${viewport.name}.png`);
    try {
        await page.goto(pathToFileURL(target.file).href, { waitUntil: 'load', timeout: 30000 });
        await page.evaluate(async () => {
            if (document.fonts && document.fonts.ready) await document.fonts.ready;
        });
        await page.addStyleTag({
            content: '*,*::before,*::after{animation-duration:0s!important;animation-delay:0s!important;transition-duration:0s!important;transition-delay:0s!important;caret-color:transparent!important;}'
        });
        await page.waitForTimeout(100);
        await page.screenshot({ path: screenshot, fullPage: true });

        const overflow = await page.evaluate(() => {
            const documentElement = document.documentElement;
            const body = document.body;
            const widths = [documentElement.scrollWidth, body ? body.scrollWidth : 0];
            return {
                viewportWidth: window.innerWidth,
                documentWidth: documentElement.scrollWidth,
                bodyWidth: body ? body.scrollWidth : 0,
                overflowPixels: Math.max(...widths) - window.innerWidth
            };
        });

        const AxeBuilder = (await import('@axe-core/playwright')).default;
        const axe = await new AxeBuilder({ page })
            .withTags(AXE_TAGS)
            .analyze();

        const violations = axe.violations.map((violation) => ({
            id: violation.id,
            impact: violation.impact,
            help: violation.help,
            helpUrl: violation.helpUrl,
            nodes: violation.nodes.map((node) => ({
                target: node.target,
                html: shortText(node.html),
                failureSummary: shortText(node.failureSummary, 600)
            }))
        }));

        return {
            label: target.label,
            file: relativePath(target.file),
            gate: target.gate,
            viewport,
            screenshot: relativePath(screenshot),
            overflow,
            hasHorizontalOverflow: overflow.overflowPixels > 1,
            axe: {
                violations,
                counts: axeSummary(violations),
                passes: axe.passes.length,
                incomplete: axe.incomplete.length
            }
        };
    } finally {
        await context.close();
    }
}

function buildMarkdown(report) {
    const lines = [
        '# Design Preview Verification',
        '',
        `- Target: \`${report.preview}\``,
        `- Browser: ${report.browser}`,
        `- Generated: ${report.generatedAt}`,
        `- Result: **${report.summary.result}**`,
        `- Blocking findings in the gated preview: ${report.summary.blocking}`,
        `- Gated serious/critical axe violations: ${report.summary.seriousOrCritical}`,
        `- Gated color-contrast violations: ${report.summary.colorContrast}`,
        `- Gated horizontal overflow: ${report.summary.overflow}`,
        `- Baseline serious/critical axe violations: ${report.summary.baselineSeriousOrCritical}`,
        `- Baseline color-contrast violations: ${report.summary.baselineColorContrast}`,
        `- Baseline horizontal overflow: ${report.summary.baselineOverflow}`,
        '',
        '## Viewports',
        '',
        '| Preview | Viewport | Gate | Screenshot | Axe violations | Color contrast | Overflow |',
        '| --- | --- | --- | --- | ---: | ---: | --- |'
    ];

    for (const result of report.results) {
        const violations = result.axe.counts.critical + result.axe.counts.serious + result.axe.counts.moderate + result.axe.counts.minor;
        const contrast = result.axe.violations.filter((violation) => violation.id === 'color-contrast').length;
        lines.push(`| ${result.label} | ${result.viewport.name} ${result.viewport.width}x${result.viewport.height} | ${result.gate ? 'yes' : 'baseline'} | \`${result.screenshot}\` | ${violations} | ${contrast} | ${result.hasHorizontalOverflow ? 'FAIL' : 'none'} |`);
    }

    lines.push('', '## Findings', '');
    let findingCount = 0;
    for (const result of report.results) {
        for (const violation of result.axe.violations) {
            findingCount += 1;
            lines.push(`### [${result.gate ? 'gate' : 'baseline'}] ${result.label} / ${result.viewport.name}: ${violation.id} (${violation.impact})`);
            lines.push(`- ${violation.help}`);
            lines.push(`- Rule: ${violation.helpUrl}`);
            for (const node of violation.nodes.slice(0, 5)) {
                lines.push(`- Target: \`${node.target.join(' ')}\``);
                if (node.failureSummary) lines.push(`  ${node.failureSummary}`);
            }
            lines.push('');
        }
        if (result.hasHorizontalOverflow) {
            findingCount += 1;
            lines.push(`### [${result.gate ? 'gate' : 'baseline'}] ${result.label} / ${result.viewport.name}: horizontal overflow`);
            lines.push(`- Content is ${result.overflow.overflowPixels}px wider than the ${result.viewport.width}px viewport.`);
            lines.push('');
        }
    }
    if (findingCount === 0) {
        lines.push('No axe violations or horizontal overflow found.');
    } else if (report.summary.blocking === 0) {
        lines.push('The gated preview passed; the findings above are baseline-only.');
    }

    lines.push('', '## Limits', '', 'This gate checks rendered layout overflow and automated axe rules. It does not replace manual keyboard, 200% zoom, state, or target-instance APEX verification.', '');
    return `${lines.join('\n')}\n`;
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
        await import('@axe-core/playwright');
    } catch (error) {
        process.stderr.write('Playwright dependencies are not installed. Run "npm install" and "npx playwright install chromium".\n');
        process.stderr.write(`${error.message}\n`);
        process.exit(2);
    }

    let collection;
    try {
        collection = await collectTargets(args.preview);
    } catch (error) {
        process.stderr.write(`${error.message}\n`);
        process.exit(2);
    }

    const defaultOut = collection.isDirectory
        ? path.join(collection.input, 'verification')
        : path.join(path.dirname(collection.input), 'verification');
    const outDir = path.resolve(process.cwd(), args.out || defaultOut);
    await fs.mkdir(outDir, { recursive: true });

    const launched = await launchBrowser(chromium, args.channel);
    const results = [];
    try {
        for (const target of collection.targets) {
            for (const viewport of VIEWPORTS) {
                results.push(await verifyTarget(launched.browser, target, viewport, outDir));
            }
        }
    } finally {
        await launched.browser.close();
    }

    const gateResults = results.filter((result) => result.gate);
    const strictViolations = gateResults.reduce((total, result) => total + result.axe.violations.length, 0);
    const seriousOrCritical = gateResults.reduce((total, result) => total + result.axe.counts.critical + result.axe.counts.serious, 0);
    const colorContrast = gateResults.reduce((total, result) => total + result.axe.violations.filter((violation) => violation.id === 'color-contrast').length, 0);
    const overflow = gateResults.filter((result) => result.hasHorizontalOverflow).length;
    const baselineResults = results.filter((result) => !result.gate);
    const baselineSeriousOrCritical = baselineResults.reduce((total, result) => total + result.axe.counts.critical + result.axe.counts.serious, 0);
    const baselineColorContrast = baselineResults.reduce((total, result) => total + result.axe.violations.filter((violation) => violation.id === 'color-contrast').length, 0);
    const baselineOverflow = baselineResults.filter((result) => result.hasHorizontalOverflow).length;
    const blocking = overflow + (args.strict ? strictViolations : seriousOrCritical);

    const report = {
        preview: relativePath(collection.input),
        browser: launched.label,
        generatedAt: new Date().toISOString(),
        strict: args.strict,
        viewports: VIEWPORTS,
        results,
        summary: {
            result: blocking === 0 ? 'PASS' : 'FAIL',
            blocking,
            seriousOrCritical,
            colorContrast,
            overflow,
            strictViolations,
            baselineSeriousOrCritical,
            baselineColorContrast,
            baselineOverflow
        }
    };

    await fs.writeFile(path.join(outDir, 'report.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
    await fs.writeFile(path.join(outDir, 'axe.json'), `${JSON.stringify(results.map((result) => ({ label: result.label, viewport: result.viewport.name, axe: result.axe })), null, 2)}\n`, 'utf8');
    await fs.writeFile(path.join(outDir, 'report.md'), buildMarkdown(report), 'utf8');

    process.stdout.write(`Design verification: ${report.summary.result}\n`);
    process.stdout.write(`Report: ${relativePath(path.join(outDir, 'report.md'))}\n`);
    process.stdout.write(`Blocking findings: ${blocking}; color contrast: ${colorContrast}; overflow: ${overflow}\n`);
    process.exitCode = blocking === 0 ? 0 : 1;
}

main().catch((error) => {
    process.stderr.write(`${error.stack || error.message}\n`);
    process.exit(2);
});
