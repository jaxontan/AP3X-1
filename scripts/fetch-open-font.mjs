#!/usr/bin/env node
// Download open-licence web fonts (SIL OFL or Apache 2.0) from Fontsource for self-hosting in an
// APEX app. Remote font imports break CSP; ship the .woff2 files as static application files.
// Refuses any font whose package licence is not OFL or Apache.
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const ALLOWED_LICENSES = /^(OFL-1\.1|Apache-2\.0)$/i;

function usage() {
    return `Usage:
  node scripts/fetch-open-font.mjs --family "<Font Name>" --out <fonts-dir> [--weights 400,500,600,700]

Writes <slug>-latin-<weight>-normal.woff2 files plus FONT-SOURCE.md (package, pinned version, licence).
Default weights: 400,500,600,700 (APEX uses normal, medium, semibold, and bold).

Example:
  node scripts/fetch-open-font.mjs --family "Nunito Sans" --out working/page-design/design/brand/fonts
`;
}

function parseArgs(argv) {
    const args = { family: null, out: null, weights: [400, 500, 600, 700] };
    const next = (i, flag) => {
        const v = argv[i + 1];
        if (!v || v.startsWith('--')) throw new Error(`Missing value for ${flag}.`);
        return v;
    };
    for (let i = 0; i < argv.length; i += 1) {
        const a = argv[i];
        if (a === '--family') { args.family = next(i, a); i += 1; }
        else if (a === '--out') { args.out = next(i, a); i += 1; }
        else if (a === '--weights') { args.weights = next(i, a).split(',').map(Number).filter((n) => n >= 100 && n <= 900); i += 1; }
        else if (a === '-h' || a === '--help') { process.stdout.write(usage()); process.exit(0); }
        else throw new Error(`Unknown argument: ${a}`);
    }
    if (!args.family || !args.out) throw new Error('Pass --family and --out.');
    if (!/^[A-Za-z0-9 ]+$/.test(args.family)) throw new Error('Font family may contain only letters, digits, and spaces.');
    return args;
}

async function fetchOk(url, kind = 'text') {
    const response = await fetch(url);
    if (!response.ok) throw new Error(`${response.status} ${url}`);
    return kind === 'bytes' ? Buffer.from(await response.arrayBuffer()) : kind === 'json' ? response.json() : response.text();
}

async function main() {
    let args;
    try {
        args = parseArgs(process.argv.slice(2));
    } catch (error) {
        process.stderr.write(`${error.message}\n\n${usage()}`);
        process.exit(2);
    }
    const slug = args.family.toLowerCase().replace(/\s+/g, '-');
    const pkg = `@fontsource/${slug}`;

    let version;
    try {
        ({ version } = await fetchOk(`https://data.jsdelivr.com/v1/packages/npm/${pkg}/resolved`, 'json'));
    } catch (error) {
        process.stderr.write(`Font "${args.family}" is not on Fontsource (${pkg}): ${error.message}\nPick an open-licence family from skills/apex-design-system/references/design-reference.md.\n`);
        process.exit(1);
    }
    const base = `https://cdn.jsdelivr.net/npm/${pkg}@${version}`;
    const meta = await fetchOk(`${base}/package.json`, 'json');
    if (!ALLOWED_LICENSES.test(String(meta.license || ''))) {
        process.stderr.write(`Refusing ${pkg}@${version}: licence "${meta.license}" is not OFL-1.1 or Apache-2.0.\n`);
        process.exit(1);
    }

    const outDir = path.resolve(args.out);
    await fs.mkdir(outDir, { recursive: true });
    const written = [];
    for (const weight of args.weights) {
        const file = `${slug}-latin-${weight}-normal.woff2`;
        try {
            const bytes = await fetchOk(`${base}/files/${file}`, 'bytes');
            if (bytes.length < 1000 || bytes.subarray(0, 4).toString('latin1') !== 'wOF2') throw new Error('not a woff2 file');
            await fs.writeFile(path.join(outDir, file), bytes);
            written.push({ weight, file, bytes: bytes.length });
        } catch (error) {
            process.stderr.write(`Weight ${weight} unavailable: ${error.message}\n`);
        }
    }
    if (!written.length) {
        process.stderr.write('No font files downloaded.\n');
        process.exit(1);
    }
    const licence = await fetchOk(`${base}/LICENSE`).catch(() => '');
    if (licence) await fs.writeFile(path.join(outDir, `${slug}-LICENSE.txt`), licence, 'utf8');
    const source = [
        `# ${args.family}`,
        '',
        `- Package: ${pkg}@${version} (${base})`,
        `- Licence: ${meta.license}${licence ? ` (copied to ${slug}-LICENSE.txt)` : ''}`,
        `- Files: ${written.map((w) => `${w.file} (${Math.round(w.bytes / 1024)} KB)`).join(', ')}`,
        '- Register each .woff2 in static-files.apx with mimeType font/woff2; brand.css references ../fonts/<file>.',
        ''
    ].join('\n');
    await fs.writeFile(path.join(outDir, 'FONT-SOURCE.md'), source, 'utf8');
    process.stdout.write(`${args.family}: ${pkg}@${version}, ${meta.license}, weights ${written.map((w) => w.weight).join(', ')} -> ${path.relative(process.cwd(), outDir)}\nFONT FETCHED\n`);
}

main().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exit(1);
});
