[CmdletBinding()]
param(
    [switch]$Yes,
    [switch]$WithDocker,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'This bootstrap is for Windows. On macOS or Linux run: bash scripts/bootstrap.sh'
}

$root = Split-Path -Parent $PSScriptRoot

. (Join-Path $PSScriptRoot 'set-env.ps1')
. (Join-Path $PSScriptRoot 'windows-installers.ps1')

function Write-Head {
    param([string]$Text)
    Write-Host ''
    Write-Host $Text -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Text)
    Write-Host "  OK    $Text" -ForegroundColor Green
}

function Write-Missing {
    param([string]$Text)
    Write-Host "  MISS  $Text" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Text)
    Write-Host "  $Text" -ForegroundColor DarkGray
}

function Write-Warn {
    param([string]$Text)
    Write-Host "  WARN  $Text" -ForegroundColor Yellow
}

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-Python {
    if (-not (Test-Command 'python')) { return $false }
    try {
        $version = (& python --version 2>&1 | Out-String)
        return ($LASTEXITCODE -eq 0 -and $version -match 'Python 3\.')
    }
    catch {
        return $false
    }
}

function Test-Java21 {
    if (-not (Test-Command 'java')) { return $false }
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $version = (& java -version 2>&1 | Out-String)
        return ($LASTEXITCODE -eq 0 -and $version -match 'version "21')
    }
    catch {
        return $false
    }
    finally {
        $ErrorActionPreference = $previous
    }
}

function Test-Node20 {
    if (-not (Test-Command 'node')) { return $false }
    try {
        $major = [int]((& node -p "process.versions.node.split('.')[0]" 2>$null).Trim())
        return ($LASTEXITCODE -eq 0 -and $major -ge 20)
    }
    catch {
        return $false
    }
}

function Invoke-Native {
    param(
        [string]$File,
        [string[]]$Arguments
    )

    if ($DryRun) {
        Write-Host ("  DRY RUN: {0} {1}" -f $File, ($Arguments -join ' ')) -ForegroundColor DarkGray
        return
    }

    & $File @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw ("Command failed ({0}): {1} {2}" -f $LASTEXITCODE, $File, ($Arguments -join ' '))
    }
}

function Install-WingetPackage {
    param(
        [string]$Id,
        [string]$Label
    )

    if ($DryRun) {
        if (Test-Command 'winget') {
            Write-Host ("  DRY RUN: winget install --id {0} --exact --silent" -f $Id) -ForegroundColor DarkGray
        }
        else {
            Write-Host ("  DRY RUN: download the official {0} installer (winget is not available)" -f $Label) -ForegroundColor DarkGray
        }
        return
    }

    Write-Host "  Installing $Label..." -ForegroundColor Yellow
    if (-not (Test-Command 'winget')) {
        Install-WithoutWinget -Id $Id
        return
    }

    Invoke-Native -File 'winget' -Arguments @(
        'install', '--id', $Id, '--exact', '--silent',
        '--accept-package-agreements', '--accept-source-agreements',
        '--disable-interactivity'
    )
}

function Add-KnownPath {
    param([string]$Path)

    if ($Path -and (Test-Path -LiteralPath $Path) -and ($env:Path -notlike "*$Path*")) {
        $env:Path = "$Path;$env:Path"
    }
}

$missing = New-Object System.Collections.Generic.List[string]

if (-not (Test-Command 'git')) { $missing.Add('Git') }
if (-not (Test-Node20)) { $missing.Add('Node.js LTS') }
if (-not (Test-Python)) { $missing.Add('Python 3.12') }
if (-not (Test-Command 'uv')) { $missing.Add('uv') }
if (-not (Test-Java21)) { $missing.Add('Microsoft OpenJDK 21') }
if (-not (Test-Path (Join-Path $root 'tools\sqlcl\bin\sql.exe'))) { $missing.Add('SQLcl') }
if ($WithDocker -and -not (Test-Command 'docker')) { $missing.Add('Docker Desktop (optional)') }

Write-Head 'Oracle APEX Harness bootstrap (Windows)'
Write-Host "Repository: $root"
Write-Host 'This installs free developer tools only. It does not request or store API keys.'

if ($missing.Count -eq 0) {
    Write-Ok 'All requested prerequisites are already installed.'
}
else {
    Write-Host ''
    Write-Host 'Missing prerequisites:' -ForegroundColor Yellow
    foreach ($item in $missing) { Write-Missing $item }

    if (-not $Yes -and -not $DryRun) {
        $answer = Read-Host 'Install these now? [Y/n]'
        if ($answer -match '^(n|no)$') {
            Write-Host 'Cancelled. Nothing was changed.'
            exit 0
        }
    }
}

if ($missing.Contains('Git')) {
    Install-WingetPackage -Id 'Git.Git' -Label 'Git'
}

if ($missing.Contains('Node.js LTS')) {
    Install-WingetPackage -Id 'OpenJS.NodeJS.LTS' -Label 'Node.js LTS'
}

if ($missing.Contains('Python 3.12')) {
    Install-WingetPackage -Id 'Python.Python.3.12' -Label 'Python 3.12'
}

if ($missing.Contains('uv')) {
    Install-WingetPackage -Id 'astral-sh.uv' -Label 'uv'
}

if ($missing.Contains('Microsoft OpenJDK 21')) {
    Install-WingetPackage -Id 'Microsoft.OpenJDK.21' -Label 'Microsoft OpenJDK 21'
}

Add-KnownPath (Join-Path $env:ProgramFiles 'Git\cmd')
Add-KnownPath (Join-Path $env:ProgramFiles 'nodejs')
Add-KnownPath (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312')
Add-KnownPath (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\Scripts')
Add-KnownPath (Join-Path $env:USERPROFILE '.local\bin')

if (-not $DryRun) {
    . (Join-Path $PSScriptRoot 'set-env.ps1')
}

if ($missing.Contains('SQLcl')) {
    Write-Host '  Installing SQLcl into tools\sqlcl...' -ForegroundColor Yellow
    if ($DryRun) {
        Write-Host '  DRY RUN: install-sqlcl.ps1' -ForegroundColor DarkGray
    }
    else {
        & (Join-Path $PSScriptRoot 'install-sqlcl.ps1')
        if ($LASTEXITCODE -ne 0) { throw 'SQLcl installation failed.' }
    }
}

if ($missing.Contains('Docker Desktop (optional)')) {
    try {
        Install-WingetPackage -Id 'Docker.DockerDesktop' -Label 'Docker Desktop'
        Write-Warn 'Start Docker Desktop once after installation, then re-run the doctor.'
    }
    catch {
        Write-Warn "Docker Desktop was not installed: $($_.Exception.Message)"
        Write-Warn 'The local Oracle sandbox is optional; install Docker later if you need it.'
    }
}

if ($DryRun) {
    Write-Host ''
    Write-Host 'Dry run complete. No software was installed and no files were changed.' -ForegroundColor Green
    exit 0
}

Add-KnownPath (Join-Path $env:ProgramFiles 'Git\cmd')
Add-KnownPath (Join-Path $env:ProgramFiles 'nodejs')
Add-KnownPath (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312')
Add-KnownPath (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\Scripts')
Add-KnownPath (Join-Path $env:USERPROFILE '.local\bin')
. (Join-Path $PSScriptRoot 'set-env.ps1')

Write-Head 'Verifying the harness'
$powerShellExe = Join-Path $PSHOME 'powershell.exe'
if (-not (Test-Path -LiteralPath $powerShellExe)) { $powerShellExe = 'powershell.exe' }

& $powerShellExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'harness-doctor.ps1')
$code = $LASTEXITCODE

Write-Host ''
if ($code -eq 0) {
    Write-Host 'Bootstrap complete. Open this repository in your coding agent' -ForegroundColor Green
    Write-Host 'and ask it to design or build your APEX app.' -ForegroundColor Green
}
else {
    Write-Warn 'Bootstrap finished, but the doctor reported problems above. Fix them and re-run: .\doctor.cmd'
}

exit $code
