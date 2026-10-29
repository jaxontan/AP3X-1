[CmdletBinding()]
param(
    [switch]$StrictNoKeys
)

$ErrorActionPreference = 'Continue'

. (Join-Path $PSScriptRoot 'set-env.ps1') | Out-Null

$root = Split-Path -Parent $PSScriptRoot
$isWindowsHost = $env:OS -eq 'Windows_NT'
$failures = New-Object System.Collections.Generic.List[string]

function Get-ToolPath {
    param([string]$Name, [string]$Fallback)

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    if ($Fallback -and (Test-Path $Fallback)) { return $Fallback }
    return $null
}

$sqlclPath = if ($env:SQLCL_BIN -and (Test-Path $env:SQLCL_BIN)) { $env:SQLCL_BIN } else { $null }
$uvPath = Get-ToolPath 'uv'
$pythonPath = Get-ToolPath 'python'
if (-not $pythonPath) { $pythonPath = Get-ToolPath 'python3' }

$checks = @(
    [pscustomobject]@{ Name = 'Node.js';    Path = (Get-ToolPath 'node');                     Required = $true;  Version = $(if (Get-Command node -ErrorAction SilentlyContinue) { node --version } else { '' }) }
    [pscustomobject]@{ Name = 'Python';     Path = $pythonPath;                               Required = $true;  Version = $(if ($pythonPath) { (& $pythonPath --version 2>&1) } else { '' }) }
    [pscustomobject]@{ Name = 'uv';         Path = $uvPath;                                 Required = $true;  Version = $(if ($uvPath) { (& $uvPath --version) 2>&1 } else { '' }) }
    [pscustomobject]@{ Name = 'OpenCode';   Path = (Get-ToolPath 'opencode');                 Required = $true;  Version = $(if (Get-Command opencode -ErrorAction SilentlyContinue) { opencode --version } else { '' }) }
    [pscustomobject]@{ Name = 'Java';       Path = (Get-ToolPath 'java');                     Required = $true;  Version = $(if (Get-Command java -ErrorAction SilentlyContinue) { (java -version 2>&1 | Select-Object -First 1) } else { '' }) }
    [pscustomobject]@{ Name = 'SQLcl';      Path = $sqlclPath;                                Required = $true;  Version = $(if ($sqlclPath) { (& $sqlclPath -V 2>&1 | Select-Object -First 1) } else { '' }) }
)

Write-Host ''
Write-Host 'Oracle APEX Agent Harness - doctor' -ForegroundColor Cyan
Write-Host '==================================='

foreach ($check in $checks) {
    $ok = [bool]$check.Path
    if (-not $ok -and $check.Required) { $failures.Add($check.Name) }
    $status = if ($ok) { 'OK' } else { 'MISSING' }
    $color = if ($ok) { 'Green' } else { 'Red' }
    Write-Host ('{0,-10} {1,-8} {2}' -f $check.Name, $status, $check.Version) -ForegroundColor $color
    if ($ok) { Write-Host ('           {0}' -f $check.Path) -ForegroundColor DarkGray }
}

Write-Host ''
Write-Host 'Harness files' -ForegroundColor Cyan
$requiredFiles = @(
    'opencode.jsonc',
    'AGENTS.md',
    '.gitattributes',
    'bootstrap.cmd',
    'skills/apex/SKILL.md',
    'skills/db/SKILL.md',
    'skills/apex-delivery/SKILL.md',
    'skills/apex-domains/SKILL.md',
    'skills/apex-design-system/SKILL.md',
    'skills/apex-ui-redesign/SKILL.md',
    'CLAUDE.md',
    '.claude/skills/oracle-apex/SKILL.md',
    '.agents/skills/oracle-apex.md',
    '.agents/rules/oracle-apex.md',
    '.agents/skills.json',
    '.agents/mcp_config.json',
    '.opencode/agents/apex.md',
    '.opencode/agents/apex-designer.md',
    '.opencode/commands/apex.plsql.md',
    '.opencode/commands/apex.apexlang.md',
    '.opencode/commands/apex.design.md',
    '.opencode/commands/apex.prototype.md',
    '.opencode/commands/apex.ui-redesign.md',
    '.claude/settings.json',
    '.mcp.json',
    'skills/harness/error-triage/SKILL.md',
    'scripts/bootstrap.ps1',
    'scripts/bootstrap.sh',
    'scripts/sqlcl-mcp.mjs',
    'scripts/normalize-apx-tree.ps1',
    'scripts/validate-apex-app.ps1',
    'scripts/verify-apex-change.ps1',
    'scripts/deploy-apex-app.ps1',
    'scripts/export-apex-app.ps1',
    'scripts/test-harness.ps1',
    'scripts/install-opencode-v2.ps1',
    'docs/PROVENANCE.md',
    'docs/getting-started.md',
    'docs/harnesses/README.md'
)

foreach ($relative in $requiredFiles) {
    $path = Join-Path $root $relative
    if (Test-Path $path) {
        Write-Host ('OK       {0}' -f $relative) -ForegroundColor Green
    }
    else {
        Write-Host ('MISSING  {0}' -f $relative) -ForegroundColor Red
        $failures.Add($relative)
    }
}

$skillCount = (Get-ChildItem (Join-Path $root 'skills') -Recurse -File -Filter 'SKILL.md' -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Host ('SKILL.md files: {0}' -f $skillCount)

Write-Host ''
Write-Host 'Configuration JSON' -ForegroundColor Cyan
foreach ($relative in @('.claude/settings.json', '.mcp.json', '.agents/skills.json', '.agents/mcp_config.json')) {
    $path = Join-Path $root $relative
    if (-not (Test-Path $path)) {
        continue
    }
    try {
        Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null
        Write-Host ('OK       {0}' -f $relative) -ForegroundColor Green
    }
    catch {
        Write-Host ('FAIL     {0}' -f $relative) -ForegroundColor Red
        $failures.Add($relative)
    }
}

Write-Host ''
Write-Host 'Harness adapters' -ForegroundColor Cyan
$adapterChecks = @(
    [pscustomobject]@{ Host = 'Codex CLI';    File = 'AGENTS.md';                          Patterns = @('skills/apex-design-system/SKILL.md', 'skills/apex-ui-redesign/SKILL.md') }
    [pscustomobject]@{ Host = 'Claude Code';  File = 'CLAUDE.md';                          Patterns = @('skills/apex-design-system/SKILL.md', 'skills/apex-ui-redesign/SKILL.md') }
    [pscustomobject]@{ Host = 'Claude skill'; File = '.claude/skills/oracle-apex/SKILL.md'; Patterns = @('skills/apex-design-system/SKILL.md', 'skills/apex-ui-redesign/SKILL.md') }
    [pscustomobject]@{ Host = 'DSH rules';    File = '.agents/rules/oracle-apex.md';         Patterns = @('skills/apex-design-system/SKILL.md', 'skills/apex-ui-redesign/SKILL.md') }
    [pscustomobject]@{ Host = 'DSH skill';    File = '.agents/skills/oracle-apex.md';        Patterns = @('skills/apex-design-system/SKILL.md', 'skills/apex-ui-redesign/SKILL.md') }
)

foreach ($check in $adapterChecks) {
    $path = Join-Path $root $check.File
    $missing = @()
    if (Test-Path -LiteralPath $path) {
        $missing = @($check.Patterns | Where-Object { -not (Select-String -LiteralPath $path -Pattern $_ -SimpleMatch -Quiet) })
    }
    else {
        $missing = $check.Patterns
    }

    if ($missing.Count -eq 0) {
        Write-Host ('OK       {0} ({1})' -f $check.Host, $check.File) -ForegroundColor Green
    }
    else {
        Write-Host ('FAIL     {0} ({1}) missing: {2}' -f $check.Host, $check.File, ($missing -join ', ')) -ForegroundColor Red
        $failures.Add("$($check.Host) adapter")
    }
}

$antigravityMcp = Join-Path $root '.agents/mcp_config.json'
if ((Test-Path -LiteralPath $antigravityMcp) -and (Select-String -LiteralPath $antigravityMcp -Pattern 'oracle-sqlcl' -SimpleMatch -Quiet)) {
    Write-Host 'OK       Antigravity (.agents/mcp_config.json)' -ForegroundColor Green
}
else {
    Write-Host 'FAIL     Antigravity (.agents/mcp_config.json)' -ForegroundColor Red
    $failures.Add('Antigravity adapter')
}

Write-Host ''
Write-Host 'OpenCode config' -ForegroundColor Cyan
$opencodeCurrent = Get-ToolPath 'opencode'
$opencodeV2 = if ($isWindowsHost) {
    Join-Path $root 'tools/opencode-v2/opencode.exe'
} else {
    Join-Path $root 'tools/opencode-v2/opencode'
}
if ($opencodeCurrent -and (Test-Path -LiteralPath $opencodeV2)) {
    $currentFull = [System.IO.Path]::GetFullPath($opencodeCurrent)
    $v2Full = [System.IO.Path]::GetFullPath($opencodeV2)
    if ($currentFull.Equals($v2Full, [System.StringComparison]::OrdinalIgnoreCase)) {
        $opencodeCurrent = $null
    }
}
$opencodeRuntimes = @(
    [pscustomobject]@{ Name = 'PATH'; Path = $opencodeCurrent; Required = $false }
    [pscustomobject]@{ Name = 'V2'; Path = $(if (Test-Path -LiteralPath $opencodeV2) { $opencodeV2 } else { $null }); Required = $false }
)

foreach ($runtime in $opencodeRuntimes) {
    if (-not $runtime.Path) {
        $status = if ($runtime.Required) { 'MISSING' } else { 'SKIP' }
        $color = if ($runtime.Required) { 'Red' } else { 'Yellow' }
        Write-Host ('{0,-8} {1}' -f $runtime.Name, $status) -ForegroundColor $color
        if ($runtime.Required) { $failures.Add("OpenCode $($runtime.Name)") }
        continue
    }

    $version = (& $runtime.Path --version 2>&1 | Select-Object -First 1)
    $configResult = & $runtime.Path debug config 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        $agentArgs = if ($version -match '(^|[ v])2\.') { @('debug', 'agents') } else { @('agent', 'list') }
        $agentResult = & $runtime.Path @agentArgs 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Host ('OK       {0} {1} accepts opencode.jsonc and agents' -f $runtime.Name, $version) -ForegroundColor Green
        }
        else {
            Write-Host ('FAIL     {0} {1} rejected an agent definition' -f $runtime.Name, $version) -ForegroundColor Red
            $detail = ($agentResult -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 5) -join [Environment]::NewLine
            Write-Host $detail -ForegroundColor DarkGray
            $failures.Add("OpenCode $($runtime.Name) agents")
        }
    }
    else {
        Write-Host ('FAIL     {0} {1} rejected opencode.jsonc' -f $runtime.Name, $version) -ForegroundColor Red
        $detail = ($configResult -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 5) -join [Environment]::NewLine
        Write-Host $detail -ForegroundColor DarkGray
        $failures.Add("OpenCode $($runtime.Name) config")
    }
}

Write-Host ''
Write-Host 'Optional harnesses' -ForegroundColor Cyan

$optionalHarnesses = @(
    [pscustomobject]@{
        Name    = 'Codex CLI'
        Path    = (Get-ToolPath 'codex')
        Version = $(if (Get-Command codex -ErrorAction SilentlyContinue) { codex --version } else { '' })
        Adapter = 'AGENTS.md'
    }
    [pscustomobject]@{
        Name    = 'Claude Code'
        Path    = (Get-ToolPath 'claude')
        Version = $(if (Get-Command claude -ErrorAction SilentlyContinue) { claude --version } else { '' })
        Adapter = 'CLAUDE.md + .claude/skills'
    }
    $agyFallback = if ($isWindowsHost) {
        Join-Path $env:LOCALAPPDATA 'agy/bin/agy.exe'
    } else {
        Join-Path $HOME '.local/bin/agy'
    }
    $agyPath = Get-ToolPath 'agy' $agyFallback
    $antigravityPath = if ($agyPath) { $agyPath } else { Get-ToolPath 'antigravity' }
    $antigravityVersion = if ($antigravityPath) {
        $raw = (& $antigravityPath --version 2>&1 | Select-Object -First 1)
        if ($agyPath -and -not (Get-Command antigravity -ErrorAction SilentlyContinue)) { "agy $raw" } else { $raw }
    } else { '' }

    [pscustomobject]@{
        Name    = 'Antigravity'
        Path    = $antigravityPath
        Version = $antigravityVersion
        Adapter = 'AGENTS.md + .agents'
    }
    [pscustomobject]@{
        Name    = 'DSH'
        Path    = (Get-ToolPath 'dsh')
        Version = $(if (Get-Command dsh -ErrorAction SilentlyContinue) { dsh --version } else { '' })
        Adapter = 'AGENTS.md + .agents/skills'
    }
    [pscustomobject]@{
        Name    = 'Ollama'
        Path    = (Get-ToolPath 'ollama')
        Version = $(if (Get-Command ollama -ErrorAction SilentlyContinue) { (ollama --version 2>&1 | Select-Object -First 1) } else { '' })
        Adapter = 'local models for Codex/DSH'
    }
)

foreach ($harness in $optionalHarnesses) {
    if ($harness.Path) {
        Write-Host ('{0,-12} {1,-8} {2}' -f $harness.Name, 'OK', $harness.Version) -ForegroundColor Green
        Write-Host ('             {0}' -f $harness.Adapter) -ForegroundColor DarkGray
    }
    else {
        Write-Host ('{0,-12} {1,-8} {2}' -f $harness.Name, 'OPTIONAL', 'not installed; adapter ready') -ForegroundColor DarkGray
        Write-Host ('             {0}' -f $harness.Adapter) -ForegroundColor DarkGray
    }
}

Write-Host ''
Write-Host 'Environment' -ForegroundColor Cyan
Write-Host ('JAVA_HOME:                 {0}' -f $(if ($env:JAVA_HOME) { $env:JAVA_HOME } else { '(not set)' }))
Write-Host ('SQLCL_BIN:                 {0}' -f $(if ($env:SQLCL_BIN) { $env:SQLCL_BIN } else { '(not set)' }))
Write-Host ('SQLCL_CONNECTION_STRING:   {0}' -f $(if ($env:SQLCL_CONNECTION_STRING) { '(set)' } else { '(not set; required only for deploy)' }))

Write-Host ''
Write-Host 'Paid API key check' -ForegroundColor Cyan
$paidKeyNames = @(
    'OPENAI_API_KEY',
    'ANTHROPIC_API_KEY',
    'ANTHROPIC_AUTH_TOKEN',
    'GEMINI_API_KEY',
    'GOOGLE_API_KEY',
    'DEEPSEEK_API_KEY',
    'OPENROUTER_API_KEY',
    'GROQ_API_KEY',
    'MISTRAL_API_KEY',
    'XAI_API_KEY'
)
$setKeys = @()
foreach ($name in $paidKeyNames) {
    if (Test-Path ("Env:" + $name)) {
        $setKeys += $name
    }
}

if ($setKeys.Count -eq 0) {
    Write-Host 'No paid API key environment variables detected.' -ForegroundColor Green
}
else {
    Write-Host ('Set (values hidden): {0}' -f ($setKeys -join ', ')) -ForegroundColor Yellow
    Write-Host 'The harness will not use these keys. Unset them for a strictly keyless session.' -ForegroundColor Yellow
    if ($StrictNoKeys) {
        $failures.Add('Paid API key environment variables are set')
    }
}

Write-Host ''
if ($failures.Count -gt 0) {
    Write-Host ('Doctor found {0} problem(s): {1}' -f $failures.Count, ($failures -join ', ')) -ForegroundColor Red
    exit 1
}

Write-Host 'Harness is ready.' -ForegroundColor Green
exit 0
