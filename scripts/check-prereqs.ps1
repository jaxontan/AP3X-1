[CmdletBinding()]
param(
    [switch]$Yes,
    [switch]$CheckOnly,
    [switch]$SkipDocker
)

# Checks every tool the harness and the local Docker sandbox need, then offers
# to install or start whatever is missing, one step at a time. AI agents
# (Claude Code, Codex, OpenCode, Antigravity) are intentionally not checked.

$ErrorActionPreference = 'Continue'

if ($env:OS -ne 'Windows_NT') {
    throw 'This check is for Windows. On macOS or Linux run: bash scripts/check-prereqs.sh'
}

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'set-env.ps1') | Out-Null

$script:RestartWindows = $false
$script:RestartTerminal = $false

function Write-Head {
    param([string]$Text)
    Write-Host ''
    Write-Host $Text -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Text)
    Write-Host "  OK    $Text" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Text)
    Write-Host "  WARN  $Text" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Text)
    Write-Host "  $Text" -ForegroundColor DarkGray
}

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function New-Result {
    param([bool]$Ok, [string]$Detail)
    return [pscustomobject]@{ Ok = $Ok; Detail = $Detail }
}

# First non-empty output line of a native command, or $null when it is missing or fails.
function Get-FirstLine {
    param([string]$File, [string[]]$Arguments)

    try {
        $output = $null | & $File @Arguments 2>&1 | ForEach-Object { "$_" }
        if ($LASTEXITCODE -ne 0) { return $null }
        return ($output | Where-Object { $_.Trim() } | Select-Object -First 1)
    }
    catch {
        return $null
    }
}

# Picks up PATH entries that installers wrote to the registry during this run.
function Update-SessionPath {
    $entries = @($env:Path -split ';')
    foreach ($scope in @('Machine', 'User')) {
        $value = [Environment]::GetEnvironmentVariable('Path', $scope)
        if (-not $value) { continue }
        foreach ($entry in ($value -split ';')) {
            $expanded = [Environment]::ExpandEnvironmentVariables($entry)
            if ($expanded -and ($entries -notcontains $expanded)) {
                $env:Path = "$env:Path;$expanded"
                $entries += $expanded
            }
        }
    }
    foreach ($extra in @(
        (Join-Path $env:ProgramFiles 'Docker\Docker\resources\bin'),
        (Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\resources\bin'),
        (Join-Path $env:ProgramFiles 'nodejs'),
        (Join-Path $env:USERPROFILE '.local\bin')
    )) {
        if ((Test-Path -LiteralPath $extra) -and ($entries -notcontains $extra)) {
            $env:Path = "$extra;$env:Path"
        }
    }
    . (Join-Path $PSScriptRoot 'set-env.ps1') | Out-Null
}

function Invoke-Winget {
    param([string]$Id)

    if (-not (Test-Command 'winget')) {
        throw "winget is not available. Install 'App Installer' from the Microsoft Store, then run this check again."
    }

    $verb = 'install'
    $listed = & winget list --id $Id --exact --accept-source-agreements 2>$null | Out-String
    if ($LASTEXITCODE -eq 0 -and $listed -match [regex]::Escape($Id)) { $verb = 'upgrade' }

    Write-Info "winget $verb --id $Id"
    & winget $verb --id $Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        throw "winget $verb $Id failed with exit code $LASTEXITCODE."
    }
    $script:RestartTerminal = $true
}

function Invoke-InRepository {
    param([string]$File, [string[]]$Arguments)

    Push-Location $root
    try {
        & $File @Arguments
        if ($LASTEXITCODE -ne 0) { throw "$File $($Arguments -join ' ') failed with exit code $LASTEXITCODE." }
    }
    finally {
        Pop-Location
    }
}

function Test-DockerEngine {
    $null | & docker info --format '{{.ServerVersion}}' 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

# Docker Desktop installs machine-wide (Program Files) or per user (LocalAppData).
function Find-DockerDesktop {
    $candidates = New-Object System.Collections.Generic.List[string]
    $docker = Get-Command 'docker' -ErrorAction SilentlyContinue
    if ($docker) {
        # <install>\resources\bin\docker.exe
        $candidates.Add((Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $docker.Source))) 'Docker Desktop.exe'))
    }
    Get-ItemProperty -Path @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    ) -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -eq 'Docker Desktop' -and $_.InstallLocation } |
        ForEach-Object { $candidates.Add((Join-Path $_.InstallLocation 'Docker Desktop.exe')) }
    $candidates.Add((Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'))
    $candidates.Add((Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\Docker Desktop.exe'))

    return ($candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1)
}

function Start-DockerDesktop {
    $exe = Find-DockerDesktop
    if (-not $exe) {
        throw 'Docker Desktop.exe was not found.'
    }

    Start-Process -FilePath $exe
    Write-Host '  Waiting for the Docker engine (up to 3 minutes; accept the Docker terms if a window asks)' -NoNewline
    $deadline = (Get-Date).AddMinutes(3)
    while ((Get-Date) -lt $deadline) {
        if (Test-DockerEngine) {
            Write-Host ' ready.'
            return
        }
        Write-Host '.' -NoNewline
        Start-Sleep -Seconds 5
    }
    Write-Host ''
    throw 'The Docker engine did not start within 3 minutes.'
}

$checks = @(
    @{
        Key = 'winget'; Name = 'winget (App Installer)'; Required = $false
        Test = {
            $v = Get-FirstLine 'winget' @('--version')
            if ($v) { New-Result $true $v } else { New-Result $false 'not found; automatic installs are unavailable' }
        }
        Help = @('Install "App Installer" from the Microsoft Store:', 'https://apps.microsoft.com/detail/9NBLGGH4NNS1')
    }
    @{
        Key = 'git'; Name = 'Git'; Required = $true
        Test = {
            $v = Get-FirstLine 'git' @('--version')
            if ($v) { New-Result $true $v } else { New-Result $false 'not found' }
        }
        Action = 'Install Git with winget'; Fix = { Invoke-Winget 'Git.Git' }
        Help = @('Download and run the installer from https://git-scm.com/download/win')
    }
    @{
        Key = 'node'; Name = 'Node.js 22.12+'; Required = $true
        Test = {
            $v = Get-FirstLine 'node' @('--version')
            if (-not $v) { return New-Result $false 'not found' }
            try { $ok = [version]($v.TrimStart('v')) -ge [version]'22.12.0' } catch { $ok = $false }
            if ($ok) { New-Result $true $v } else { New-Result $false "$v is too old (need 22.12 or newer)" }
        }
        Action = 'Install Node.js LTS with winget'; Fix = { Invoke-Winget 'OpenJS.NodeJS.LTS' }
        Help = @('Install the LTS release from https://nodejs.org/')
    }
    @{
        Key = 'npm'; Name = 'npm'; Required = $true; DependsOn = @('node')
        Test = {
            $v = Get-FirstLine 'npm.cmd' @('--version')
            if ($v) { New-Result $true $v } else { New-Result $false 'not found' }
        }
        Action = 'Reinstall Node.js LTS (includes npm) with winget'; Fix = { Invoke-Winget 'OpenJS.NodeJS.LTS' }
        Help = @('npm ships with Node.js; reinstall Node.js from https://nodejs.org/')
    }
    @{
        Key = 'python'; Name = 'Python 3'; Required = $true
        Test = {
            foreach ($exe in @('python', 'python3')) {
                $v = Get-FirstLine $exe @('--version')
                if ($v -match '^Python 3\.') { return New-Result $true $v }
            }
            New-Result $false 'not found (the Microsoft Store "python" alias does not count)'
        }
        Action = 'Install Python 3.12 with winget'; Fix = { Invoke-Winget 'Python.Python.3.12' }
        Help = @('Install from https://www.python.org/downloads/ and tick "Add python.exe to PATH".')
    }
    @{
        Key = 'uv'; Name = 'uv'; Required = $true
        Test = {
            $v = Get-FirstLine 'uv' @('--version')
            if ($v) { New-Result $true $v } else { New-Result $false 'not found' }
        }
        Action = 'Install uv with winget'; Fix = { Invoke-Winget 'astral-sh.uv' }
        Help = @('See https://docs.astral.sh/uv/getting-started/installation/')
    }
    @{
        Key = 'java'; Name = 'Java (JDK 21+)'; Required = $true
        Test = {
            $v = Get-FirstLine 'java' @('-version')
            if (-not $v) { return New-Result $false 'not found' }
            if ($v -match 'version "(\d+)' -and [int]$Matches[1] -ge 21) { New-Result $true $v }
            else { New-Result $false "$v is too old (need 21 or newer)" }
        }
        Action = 'Install Microsoft OpenJDK 21 with winget'; Fix = { Invoke-Winget 'Microsoft.OpenJDK.21' }
        Help = @('Install a JDK 21 from https://learn.microsoft.com/java/openjdk/download')
    }
    @{
        Key = 'sqlcl'; Name = 'SQLcl (tools\sqlcl)'; Required = $true; DependsOn = @('java')
        Test = {
            $exe = Join-Path $root 'tools\sqlcl\bin\sql.exe'
            if (Test-Path -LiteralPath $exe) { New-Result $true $exe } else { New-Result $false 'not found in tools\sqlcl' }
        }
        Action = 'Download SQLcl into tools\sqlcl'
        Fix = {
            & (Join-Path $PSScriptRoot 'install-sqlcl.ps1')
            if ($LASTEXITCODE -ne 0) { throw 'SQLcl installation failed.' }
        }
        Help = @('Run: powershell -ExecutionPolicy Bypass -File scripts\install-sqlcl.ps1',
                 'or unzip https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip into tools\')
    }
)

if (-not $SkipDocker) {
    $checks += @(
        @{
            Key = 'wsl'; Name = 'WSL 2 (for Docker)'; Required = $true
            Test = {
                $null | & wsl.exe --status 2>$null | Out-Null
                if ($LASTEXITCODE -eq 0) { New-Result $true 'installed' } else { New-Result $false 'not installed' }
            }
            Action = 'Install WSL 2 (opens an administrator prompt; Windows restart required)'
            Fix = {
                $process = Start-Process -FilePath 'wsl.exe' -ArgumentList '--install', '--no-distribution' -Verb RunAs -Wait -PassThru
                if ($process.ExitCode -ne 0) { throw "wsl --install failed with exit code $($process.ExitCode)." }
                $script:RestartWindows = $true
            }
            Help = @('In an administrator PowerShell run: wsl --install --no-distribution',
                     'then restart Windows. See https://learn.microsoft.com/windows/wsl/install')
        }
        @{
            Key = 'docker'; Name = 'Docker'; Required = $true
            Test = {
                $v = Get-FirstLine 'docker' @('--version')
                if ($v) { New-Result $true $v } else { New-Result $false 'not found' }
            }
            Action = 'Install Docker Desktop with winget (asks for administrator rights)'
            Fix = {
                Invoke-Winget 'Docker.DockerDesktop'
                Write-Warn 'If Docker Desktop asks you to sign out to join the docker-users group, do that after this check.'
            }
            Help = @('Install Docker Desktop from https://www.docker.com/products/docker-desktop/')
        }
        @{
            Key = 'compose'; Name = 'Docker Compose v2'; Required = $true; DependsOn = @('docker')
            Test = {
                $v = Get-FirstLine 'docker' @('compose', 'version')
                if ($v) { New-Result $true $v } else { New-Result $false 'not found' }
            }
            Action = 'Update Docker Desktop (includes Compose) with winget'; Fix = { Invoke-Winget 'Docker.DockerDesktop' }
            Help = @('Compose ships with Docker Desktop; update Docker Desktop to the latest version.')
        }
        @{
            Key = 'engine'; Name = 'Docker engine running'; Required = $true; DependsOn = @('docker', 'wsl')
            Test = {
                $v = Get-FirstLine 'docker' @('info', '--format', '{{.ServerVersion}}')
                if ($v) { New-Result $true "server $v" } else { New-Result $false 'not running' }
            }
            Action = 'Start Docker Desktop and wait for the engine'; Fix = { Start-DockerDesktop }
            Help = @('Start Docker Desktop from the Start menu and wait until it says "Engine running".')
        }
    )
}

$checks += @(
    @{
        Key = 'npmdeps'; Name = 'npm packages (Playwright)'; Required = $false; DependsOn = @('npm')
        Test = {
            $manifest = Join-Path $root 'node_modules\playwright\package.json'
            $axe = Join-Path $root 'node_modules\@axe-core\playwright\package.json'
            if ((Test-Path -LiteralPath $manifest) -and (Test-Path -LiteralPath $axe)) {
                $version = (Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json).version
                New-Result $true "playwright $version"
            }
            else {
                New-Result $false 'not installed (needed only for design verification)'
            }
        }
        Action = 'Run npm ci in the repository'; Fix = { Invoke-InRepository 'npm.cmd' @('ci') }
        Help = @('In the repository folder run: npm.cmd ci')
    }
    @{
        Key = 'chromium'; Name = 'Playwright Chromium'; Required = $false; DependsOn = @('npmdeps')
        Test = {
            Push-Location $root
            try {
                $null | & node -e "const fs=require('fs');const {chromium}=require('playwright');process.exit(fs.existsSync(chromium.executablePath())?0:1)" 2>$null | Out-Null
                $code = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }
            if ($code -eq 0) { New-Result $true 'installed' } else { New-Result $false 'not installed (about 300 MB download)' }
        }
        Action = 'Download Chromium for Playwright'; Fix = { Invoke-InRepository 'npx.cmd' @('playwright', 'install', 'chromium') }
        Help = @('In the repository folder run: npx.cmd playwright install chromium')
    }
)

function Invoke-Check {
    param([hashtable]$Check)

    try {
        $result = & $Check.Test
    }
    catch {
        $result = New-Result $false $_.Exception.Message
    }
    $Check.Result = $result
    return $result
}

function Write-Table {
    foreach ($check in $checks) {
        $result = $check.Result
        if ($result.Ok) { $status = 'OK'; $color = 'Green' }
        elseif ($check.Required) { $status = 'FAIL'; $color = 'Red' }
        else { $status = 'WARN'; $color = 'Yellow' }
        Write-Host ('  {0,-5} {1,-27} {2}' -f $status, $check.Name, $result.Detail) -ForegroundColor $color
    }
}

function Write-Help {
    param([hashtable]$Check)

    Write-Host '  To fix it yourself:' -ForegroundColor Yellow
    foreach ($line in $Check.Help) { Write-Host "    $line" }
}

function Confirm-Step {
    param([string]$Question)

    if ($Yes) { return $true }
    $answer = Read-Host "  $Question? [Y/n]"
    return ($answer -notmatch '^(n|no)$')
}

function Get-RequiredFailures {
    return @($checks | Where-Object { $_.Required -and -not $_.Result.Ok })
}

function Complete-Check {
    $failures = @(Get-RequiredFailures)
    Write-Host ''
    if ($script:RestartWindows) {
        Write-Warn 'Restart Windows to finish installing WSL 2, then run check.cmd again.'
    }
    elseif ($script:RestartTerminal) {
        Write-Info 'Open a new terminal so it picks up the updated PATH.'
    }
    if ($failures.Count -eq 0) {
        Write-Host 'Prerequisite check finished: everything required is ready.' -ForegroundColor Green
        exit 0
    }
    Write-Host ('Prerequisite check finished: {0} required item(s) still need attention: {1}' -f $failures.Count, (($failures | ForEach-Object { $_.Name }) -join ', ')) -ForegroundColor Red
    exit 1
}

Write-Head 'AP3X-1 prerequisite check (Windows)'
Write-Host "Repository: $root"
Write-Info 'Checks developer tools and Docker only. AI agents are not checked or installed.'
Write-Host ''

foreach ($check in $checks) { Invoke-Check $check | Out-Null }
Write-Table

$failing = @($checks | Where-Object { -not $_.Result.Ok })
if ($failing.Count -eq 0) { Complete-Check }

if ($CheckOnly) {
    foreach ($check in $failing) {
        Write-Host ''
        Write-Host "$($check.Name): $($check.Result.Detail)" -ForegroundColor Yellow
        Write-Help $check
    }
    Complete-Check
}

Write-Head 'Fixing what is missing'
Write-Info 'Each step asks first. Answer n to skip it and see how to do it yourself.'

foreach ($check in $checks) {
    if ((Invoke-Check $check).Ok) { continue }

    Write-Host ''
    Write-Host "$($check.Name): $($check.Result.Detail)" -ForegroundColor Yellow

    $blocked = @($checks | Where-Object { $check.DependsOn -contains $_.Key -and -not $_.Result.Ok })
    if ($blocked.Count -gt 0) {
        Write-Info ('Skipped: fix {0} first.' -f (($blocked | ForEach-Object { $_.Name }) -join ', '))
        continue
    }

    if (-not $check.Fix) {
        Write-Help $check
        continue
    }

    if (-not (Confirm-Step $check.Action)) {
        Write-Help $check
        continue
    }

    try {
        & $check.Fix
    }
    catch {
        Write-Warn $_.Exception.Message
    }
    Update-SessionPath

    if ((Invoke-Check $check).Ok) {
        Write-Ok "$($check.Name): $($check.Result.Detail)"
    }
    else {
        Write-Warn "$($check.Name) is still not ready: $($check.Result.Detail)"
        Write-Help $check
    }
}

Write-Head 'Result'
Write-Table
Complete-Check
