#!/usr/bin/env node
// Cross-platform launcher for the Oracle SQLcl MCP server.
// MCP hosts start this file with Node; it locates Java and SQLcl, then
// hands stdio directly to `sql -R 1 -mcp`.

import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
const isWindows = process.platform === 'win32';
const javaExe = isWindows ? 'java.exe' : 'java';

function exists(candidate) {
  try {
    return fs.existsSync(candidate);
  } catch {
    return false;
  }
}

function isJavaHome(candidate) {
  return Boolean(candidate) && exists(path.join(candidate, 'bin', javaExe));
}

function listDirectories(directory) {
  try {
    return fs
      .readdirSync(directory, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => path.join(directory, entry.name));
  } catch {
    return [];
  }
}

function findJavaHome() {
  if (isJavaHome(process.env.JAVA_HOME)) {
    return process.env.JAVA_HOME;
  }

  const candidates = [];
  if (isWindows) {
    for (const base of [
      'C:\\Program Files\\Microsoft',
      'C:\\Program Files\\Java',
      'C:\\Program Files\\Eclipse Adoptium'
    ]) {
      for (const entry of listDirectories(base)) {
        if (/jdk-?21/i.test(path.basename(entry))) {
          candidates.push(entry);
        }
      }
    }
  } else {
    for (const entry of listDirectories('/Library/Java/JavaVirtualMachines')) {
      candidates.push(path.join(entry, 'Contents', 'Home'));
    }
    for (const entry of listDirectories('/usr/lib/jvm')) {
      if (entry.includes('21')) {
        candidates.push(entry);
      }
    }
    candidates.push(
      '/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home',
      '/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home'
    );
  }

  candidates.sort().reverse();
  return candidates.find(isJavaHome);
}

function findSqlcl() {
  const configured = process.env.SQLCL_BIN;
  if (configured && exists(path.resolve(configured))) {
    return path.resolve(configured);
  }

  const local = path.join(
    root,
    'tools',
    'sqlcl',
    'bin',
    isWindows ? 'sql.exe' : 'sql'
  );
  return exists(local) ? local : null;
}

const javaHome = findJavaHome();
const sqlcl = findSqlcl();

if (!sqlcl) {
  console.error(
    'SQLcl not found. Run scripts/bootstrap.ps1 (Windows) or scripts/bootstrap.sh (macOS/Linux), or set SQLCL_BIN.'
  );
  process.exit(2);
}

const env = { ...process.env };
if (javaHome) {
  env.JAVA_HOME = javaHome;
  const pathKey = Object.keys(env).find((key) => key.toUpperCase() === 'PATH') || 'PATH';
  env[pathKey] = `${path.join(javaHome, 'bin')}${path.delimiter}${env[pathKey] || ''}`;
}
if (!env.JAVA_TOOL_OPTIONS) {
  env.JAVA_TOOL_OPTIONS = '-Djava.awt.headless=true -Dfile.encoding=UTF-8';
}

const child = spawn(sqlcl, ['-R', '1', '-mcp'], {
  cwd: root,
  env,
  stdio: 'inherit',
  windowsHide: true
});

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => {
    try {
      child.kill(signal);
    } catch {
      // The child may already be gone.
    }
  });
}

child.on('error', (error) => {
  console.error(`Unable to start SQLcl (${sqlcl}): ${error.message}`);
  process.exit(2);
});

child.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }
  process.exit(code ?? 1);
});
