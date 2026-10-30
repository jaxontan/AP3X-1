#!/usr/bin/env node
// Generates Claude Code and Codex/Antigravity/DSH skill bridges from the
// OpenCode commands in .opencode/commands/apex.*.md, so every host offers the
// same workflows from one source.
//
//   node scripts/sync-agent-commands.mjs          write the bridges
//   node scripts/sync-agent-commands.mjs --check  exit 1 if any bridge is stale
//
// .opencode/commands/apex.plsql.md  ->  .claude/skills/apex-plsql/SKILL.md  (/apex-plsql in Claude Code)
//                                   ->  .agents/skills/apex-plsql/SKILL.md  (Codex, Antigravity, DSH)
import { readFileSync, writeFileSync, readdirSync, mkdirSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const sourceDir = join(root, '.opencode', 'commands');
const check = process.argv.includes('--check');

// Commands whose side effects must only run when the user types the command.
const userInvokedOnly = new Set(['apex-deploy']);

function parse(text) {
  const match = text.replace(/\r\n/g, '\n').match(/^---\n([\s\S]*?)\n---\n+([\s\S]*)$/);
  if (!match) throw new Error('missing frontmatter');
  const meta = {};
  for (const line of match[1].split('\n')) {
    const kv = line.match(/^(\w[\w-]*):\s*(.*)$/);
    if (kv) meta[kv[1]] = kv[2].trim();
  }
  return { meta, body: match[2].trimEnd() + '\n' };
}

function render(name, meta, body, host) {
  // OpenCode names commands apex.plsql; skill hosts require apex-plsql.
  let text = body.replace(/\/apex\.([a-z-]+)/g, '/apex-$1');
  if (host === 'agents') {
    text = text.replace(/\$ARGUMENTS/g, "the user's request (the text after the skill name)");
  }
  const lines = ['---', `name: ${name}`, `description: ${meta.description}`];
  if (host === 'claude') {
    lines.push('argument-hint: "[target or request]"');
    if (userInvokedOnly.has(name)) lines.push('disable-model-invocation: true');
  }
  lines.push('---', '');
  lines.push(`<!-- Generated from .opencode/commands/${name.replace('apex-', 'apex.')}.md by scripts/sync-agent-commands.mjs. Edit the source, then re-run the script. -->`, '');
  lines.push('Canonical instructions: `AGENTS.md`. The delivery contract and gates there apply to this workflow.', '');
  if (meta.agent) {
    lines.push(`Work within the role and limits in \`.opencode/agents/${meta.agent}.md\` (ignore its OpenCode-only frontmatter).`, '');
  }
  return lines.join('\n') + '\n' + text;
}

const sources = readdirSync(sourceDir).filter((f) => /^apex\.[a-z-]+\.md$/.test(f)).sort();
const stale = [];
for (const file of sources) {
  const name = file.replace(/^apex\.([a-z-]+)\.md$/, 'apex-$1');
  const { meta, body } = parse(readFileSync(join(sourceDir, file), 'utf8'));
  if (!meta.description) throw new Error(`${file}: missing description`);
  for (const [host, dir] of [['claude', '.claude/skills'], ['agents', '.agents/skills']]) {
    const target = join(root, dir, name, 'SKILL.md');
    const content = render(name, meta, body, host);
    const current = existsSync(target) ? readFileSync(target, 'utf8') : null;
    if (current === content) continue;
    const rel = `${dir}/${name}/SKILL.md`;
    if (check) { stale.push(rel); continue; }
    mkdirSync(dirname(target), { recursive: true });
    writeFileSync(target, content, { encoding: 'utf8' });
    console.log(`wrote ${rel}`);
  }
}

if (check) {
  if (stale.length) {
    console.error(`Stale or missing command bridges:\n  ${stale.join('\n  ')}\nRun: node scripts/sync-agent-commands.mjs`);
    process.exit(1);
  }
  console.log(`Command bridges in sync (${sources.length} commands).`);
}
