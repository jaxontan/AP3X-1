[CmdletBinding()]
param(
    [string]$InstallDirectory = (Join-Path $env:LOCALAPPDATA 'OracleApexHarness\uc-local-apex-dev'),

    [ValidateSet('26-1', '26-2')]
    [string]$Branch = '26-2',

    [switch]$Execute
)

$ErrorActionPreference = 'Stop'

$repoUrl = 'https://github.com/United-Codes/uc-local-apex-dev.git'
$failures = @()
$warnings = @()

function Add-Failure {
    param([string]$Message)
    $script:failures += $Message
}

function Add-Warning {
    param([string]$Message)
    $script:warnings += $Message
}

$setEnv = Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\set-env.ps1'
if (Test-Path -LiteralPath $setEnv) {
    . $setEnv
}

Write-Host 'Local Oracle APEX sandbox preflight' -ForegroundColor Cyan
Write-Host "Upstream:  $repoUrl"
Write-Host "Branch:    $Branch"
Write-Host "Directory: $InstallDirectory"
Write-Host ''

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Add-Failure 'git is not on PATH.'
}

$bashPath = $null
$bash = Get-Command bash -ErrorAction SilentlyContinue
if ($bash) {
    $bashPath = $bash.Source
}
if (-not $bashPath) {
    $gitBash = 'C:\Program Files\Git\bin\bash.exe'
    if (Test-Path -LiteralPath $gitBash) {
        $bashPath = $gitBash
    }
}
if (-not $bashPath) {
    Add-Failure 'bash is not on PATH. Install Git for Windows so the upstream install.sh can run.'
}

$docker = Get-Command docker -ErrorAction SilentlyContinue
$podman = Get-Command podman -ErrorAction SilentlyContinue
if (-not $docker -and -not $podman) {
    Add-Failure 'Docker or Podman is required. Install Docker Desktop or Podman with Compose.'
}
elseif ($docker) {
    $dockerInfo = & docker info --format '{{.ServerVersion}}' 2>&1
    if ($LASTEXITCODE -ne 0) {
        Add-Failure 'Docker is installed but the daemon is not reachable. Start Docker Desktop.'
    }
    else {
        Write-Host "Docker:    $($dockerInfo | Select-Object -First 1)" -ForegroundColor DarkGray
        $compose = & docker compose version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Add-Failure 'Docker Compose is not available. Enable the Compose plugin.'
        }
    }
}
elseif ($podman) {
    $podmanInfo = & podman info --format '{{.Version.Version}}' 2>&1
    if ($LASTEXITCODE -ne 0) {
        Add-Failure 'Podman is installed but is not reachable. Start the Podman machine or service.'
    }
    else {
        Write-Host "Podman:    $($podmanInfo | Select-Object -First 1)" -ForegroundColor DarkGray
        $compose = & podman compose version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Add-Failure 'Podman Compose is not available. Install a Compose provider.'
        }
    }
}

$sql = Get-Command sql -ErrorAction SilentlyContinue
if (-not $sql) {
    Add-Failure 'SQLcl (sql) is not on PATH. Run scripts/install-sqlcl.ps1 or source scripts/set-env.ps1.'
}

$curl = Get-Command curl.exe -ErrorAction SilentlyContinue
$wget = Get-Command wget.exe -ErrorAction SilentlyContinue
if (-not $curl -and -not $wget) {
    Add-Failure 'curl or wget is required by the upstream installer.'
}

$unzip = Get-Command unzip -ErrorAction SilentlyContinue
if (-not $unzip) {
    Add-Warning 'unzip is not on PATH. The upstream installer may need it.'
}

$drive = (Get-Item -LiteralPath $env:LOCALAPPDATA).PSDrive
if ($drive -and $drive.Free -lt 35GB) {
    Add-Warning "Only $([math]::Round($drive.Free / 1GB, 1)) GB free on $($drive.Name):. The sandbox needs about 35 GB."
}

Write-Host 'Requirements: 4 GB RAM, 3 CPUs, 35 GB free disk, Docker/Podman Compose, Git Bash, SQLcl.' -ForegroundColor DarkGray
Write-Host ''

if ($warnings.Count -gt 0) {
    Write-Host 'Warnings' -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
    Write-Host ''
}

if ($failures.Count -gt 0) {
    Write-Host 'Preflight failed' -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host "  - $failure" -ForegroundColor Red
    }
    Write-Host ''
    if (-not $Execute) {
        Write-Host 'Preview only. Resolve the failures before running with -Execute.' -ForegroundColor Yellow
        exit 0
    }
    exit 2
}

if (-not $Execute) {
    Write-Host 'Preflight passed. This was a preview; nothing was cloned or installed.' -ForegroundColor Green
    Write-Host 'Re-run with -Execute to clone the pinned branch and start the upstream installer.' -ForegroundColor Green
    exit 0
}

if (Test-Path -LiteralPath $InstallDirectory) {
    $gitDirectory = Join-Path $InstallDirectory '.git'
    if (-not (Test-Path -LiteralPath $gitDirectory)) {
        $entries = @(Get-ChildItem -LiteralPath $InstallDirectory -Force)
        if ($entries.Count -gt 0) {
            Write-Error "Install directory exists, is not a Git checkout, and is not empty: $InstallDirectory"
            exit 2
        }
    }
    else {
        $remote = (& git -C $InstallDirectory remote get-url origin 2>$null).Trim()
        if ($LASTEXITCODE -ne 0 -or $remote -ne $repoUrl) {
            Write-Error "Existing checkout does not point at $repoUrl : $InstallDirectory"
            exit 2
        }
        Write-Host "Updating existing checkout at $InstallDirectory" -ForegroundColor Cyan
        & git -C $InstallDirectory fetch --depth 1 origin $Branch
        if ($LASTEXITCODE -ne 0) {
            Write-Error 'git fetch failed.'
            exit 1
        }
        & git -C $InstallDirectory checkout $Branch
        if ($LASTEXITCODE -ne 0) {
            Write-Error "git checkout $Branch failed."
            exit 1
        }
        & git -C $InstallDirectory pull --ff-only origin $Branch
        if ($LASTEXITCODE -ne 0) {
            Write-Error "git pull --ff-only origin $Branch failed."
            exit 1
        }
    }
}
else {
    Write-Host "Cloning $repoUrl ($Branch) into $InstallDirectory" -ForegroundColor Cyan
    & git clone --branch $Branch --depth 1 $repoUrl $InstallDirectory
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'git clone failed.'
        exit 1
    }
}

$installer = Join-Path $InstallDirectory 'install.sh'
if (-not (Test-Path -LiteralPath $installer)) {
    Write-Error "Upstream installer not found: $installer"
    exit 1
}

Write-Host ''
Write-Host 'Starting the upstream installer. This normally takes 20-40 minutes.' -ForegroundColor Cyan
Write-Host 'The installer may prompt for ORACLE_PASSWORD; do not paste a password into this chat.' -ForegroundColor Yellow
Write-Host ''

Push-Location $InstallDirectory
try {
    & $bashPath './install.sh'
    $status = $LASTEXITCODE
}
finally {
    Pop-Location
}

if ($status -ne 0) {
    Write-Error "Upstream installer failed with exit code $status. Review its output and $InstallDirectory."
    exit $status
}

Write-Host ''
Write-Host 'Sandbox install finished.' -ForegroundColor Green
Write-Host 'APEX: http://localhost:8181/ords/apex (workspace INTERNAL, user ADMIN).' -ForegroundColor Green
Write-Host 'Save a named connection before using the SQLcl MCP server.' -ForegroundColor Green
