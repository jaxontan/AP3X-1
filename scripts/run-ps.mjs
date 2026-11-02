#!/usr/bin/env node
// Cross-platform launcher for the harness PowerShell scripts.
//
// Aider's `test-cmd` is a shell string, so it cannot branch on the host.
// macOS/Linux always have `pwsh`; Windows may only have `powershell.exe`.
// This wrapper tries `pwsh` first and falls back only when the binary is
// missing, so a failing script is never silently retried with another shell.
//
//   node scripts/run-ps.mjs -NoProfile -File scripts/validate-apex-app.ps1 -AppDirectory working/app
import { spawnSync } from 'node:child_process';

const args = process.argv.slice(2);

if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
    console.log('Usage: node scripts/run-ps.mjs -NoProfile -File <script.ps1> [arguments]');
    process.exit(args.length === 0 ? 2 : 0);
}

const candidates = process.platform === 'win32'
    ? ['pwsh', 'powershell', 'powershell.exe']
    : ['pwsh', 'powershell'];

for (const command of candidates) {
    const result = spawnSync(command, args, { stdio: 'inherit' });
    if (result.error && result.error.code === 'ENOENT') continue;
    if (result.error) {
        console.error(`Could not start ${command}: ${result.error.message}`);
        process.exit(1);
    }
    process.exit(result.status ?? 1);
}

console.error('No PowerShell found. Install PowerShell 7 (pwsh) or add Windows PowerShell to PATH.');
process.exit(127);
