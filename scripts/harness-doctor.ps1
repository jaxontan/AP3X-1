[CmdletBinding()]
param(
    [switch]$StrictNoKeys
)

$ErrorActionPreference = 'Continue'

. (Join-Path $PSScriptRoot 'set-env.ps1') | Out-Null

$root = Split-Path -Parent $PSScriptRoot
$failures = New-Object System.Collections.Generic.List[string]

function Get-ToolPath {
    param([string]$Name, [string]$Fallback)

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    if ($Fallback -and (Test-Path $Fallback)) { return $Fallback }
    return $null
}

$sqlclPath = if ($env:SQLCL_BIN -and (Test-Path $env:SQLCL_BIN)) { $env:SQLCL_BIN } else { $null }
$specifyPath = Get-ToolPath 'specify' (Join-Path $env:USERPROFILE '.local\bin\specify.exe')
$uvPath = Get-ToolPath 'uv' (Join-Path $env:USERPROFILE '.local\bin\uv.exe')

$checks = @(
    [pscustomobject]@{ Name = 'Node.js';    Path = (Get-ToolPath 'node');                     Required = $true;  Version = $(if (Get-Command node -ErrorAction SilentlyContinue) { node --version } else { '' }) }
    [pscustomobject]@{ Name = 'Python';     Path = (Get-ToolPath 'python');                   Required = $true;  Version = $(if (Get-Command python -ErrorAction SilentlyContinue) { python --version 2>&1 } else { '' }) }
    [pscustomobject]@{ Name = 'uv';         Path = $uvPath;                                 Required = $true;  Version = $(if ($uvPath) { (& $uvPath --version) 2>&1 } else { '' }) }
    [pscustomobject]@{ Name = 'Spec Kit';   Path = $specifyPath;                              Required = $true;  Version = $(if ($specifyPath) { (& $specifyPath --version) 2>&1 } else { '' }) }
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
    'skills\apex\SKILL.md',
    'skills\db\SKILL.md',
    'skills\apex-delivery\SKILL.md',
    'skills\apex-domains\SKILL.md',
    'CLAUDE.md',
    '.claude\skills\oracle-apex\SKILL.md',
    '.agents\skills\oracle-apex.md',
    '.agents\rules\oracle-apex.md',
    '.opencode\agents\apex.md',
    '.opencode\commands\apex.design.md',
    '.opencode\commands\apex.plsql.md',
    '.opencode\commands\apex.apexlang.md',
    '.specify\memory\constitution.md',
    'scripts\normalize-apx-tree.ps1',
    'scripts\install-opencode-v2.ps1',
    'docs\PROVENANCE.md',
    'docs\harnesses\README.md'
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
Write-Host 'OpenCode v2 config' -ForegroundColor Cyan
if (Get-Command opencode -ErrorAction SilentlyContinue) {
    $configResult = & opencode debug config 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'OK       v2 permissions accepted' -ForegroundColor Green
    }
    else {
        Write-Host 'FAIL     opencode rejected opencode.jsonc' -ForegroundColor Red
        $detail = ($configResult -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 5) -join [Environment]::NewLine
        Write-Host $detail -ForegroundColor DarkGray
        $failures.Add('OpenCode v2 config')
    }
}
else {
    Write-Host 'SKIP     opencode not on PATH' -ForegroundColor Yellow
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
    [pscustomobject]@{
        Name    = 'Antigravity'
        Path    = (Get-ToolPath 'antigravity')
        Version = $(if (Get-Command antigravity -ErrorAction SilentlyContinue) { antigravity --version } else { '' })
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
