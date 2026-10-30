<#
.SYNOPSIS
    Downloads and extracts the APEX 26.2 distribution for the local Docker sandbox.

.DESCRIPTION
    The database image does not contain APEX. The ORDS container in
    local-dev/docker-compose.yml installs APEX from the folder mounted at
    /opt/oracle/apex on first start, so that folder must contain an extracted
    APEX distribution.

    This script downloads the official APEX 26.2 zip, checks the download size,
    and extracts it to local-dev/apex. It is safe to re-run: if the distribution
    is already present it exits without downloading again.

    No credentials are read, written, or printed.

.PARAMETER Destination
    Folder that will contain apexins.sql and images/. Defaults to local-dev/apex
    under the repository root.

.PARAMETER Force
    Re-download and re-extract even when the distribution is already present.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts/get-apex-26.2.ps1
#>
[CmdletBinding()]
param(
    [string]$Destination,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$apexUrl = 'https://download.oracle.com/otn_software/apex/apex_26.2.zip'
$minimumBytes = 300MB

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $Destination) {
    $Destination = Join-Path (Join-Path $repoRoot 'local-dev') 'apex'
}
$Destination = [System.IO.Path]::GetFullPath($Destination)
$extractRoot = Split-Path -Parent $Destination
$zipPath = Join-Path (Join-Path $repoRoot 'local-dev') 'apex-26.2.zip'
$apexIns = Join-Path $Destination 'apexins.sql'
$versionFile = Join-Path (Join-Path $Destination 'images') 'apex_version.txt'

Write-Host 'Oracle APEX 26.2 download for the local Docker sandbox' -ForegroundColor Cyan
Write-Host "Source:      $apexUrl"
Write-Host "Destination: $Destination"
Write-Host ''

if ((Test-Path -LiteralPath $apexIns) -and -not $Force) {
    $installed = 'unknown'
    if (Test-Path -LiteralPath $versionFile) {
        $installed = (Get-Content -LiteralPath $versionFile -TotalCount 1).Trim()
    }
    if ($installed -match '^26\.2') {
        Write-Host "APEX $installed is already present. Nothing to do." -ForegroundColor Green
        Write-Host 'Use -Force to download again.'
        exit 0
    }
    Write-Host "Found APEX $installed in the destination. Replacing it with 26.2."
    $Force = $true
}

if (-not (Test-Path -LiteralPath $extractRoot)) {
    New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null
}

if ((Test-Path -LiteralPath $zipPath) -and -not $Force) {
    $existing = (Get-Item -LiteralPath $zipPath).Length
    if ($existing -ge $minimumBytes) {
        Write-Host "Using existing download: $zipPath ($([math]::Round($existing / 1MB)) MB)"
    }
    else {
        Write-Host "Existing download is incomplete ($([math]::Round($existing / 1MB)) MB). Downloading again."
        Remove-Item -LiteralPath $zipPath -Force
    }
}

if (-not (Test-Path -LiteralPath $zipPath)) {
    Write-Host 'Downloading APEX 26.2 (about 337 MB). This can take several minutes.'
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    try {
        if ($curl) {
            & $curl.Source --fail --location --output $zipPath $apexUrl
            if ($LASTEXITCODE -ne 0) {
                throw "curl.exe exited with code $LASTEXITCODE."
            }
        }
        else {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $apexUrl -OutFile $zipPath -UseBasicParsing
        }
    }
    catch {
        if (Test-Path -LiteralPath $zipPath) {
            Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue
        }
        throw "APEX download failed: $($_.Exception.Message). Check your network or proxy, then re-run this script."
    }
}

$size = (Get-Item -LiteralPath $zipPath).Length
if ($size -lt $minimumBytes) {
    Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue
    throw "Downloaded file is only $([math]::Round($size / 1MB)) MB, which is too small to be the APEX 26.2 zip. Delete it and re-run."
}
Write-Host "Download complete: $([math]::Round($size / 1MB)) MB"

Write-Host 'Extracting. This takes a few minutes.'
if ($Force -and (Test-Path -LiteralPath $Destination)) {
    Remove-Item -LiteralPath $Destination -Recurse -Force
}
$tar = Get-Command tar -ErrorAction SilentlyContinue
if ($tar) {
    & $tar.Source -xf $zipPath -C $extractRoot
    if ($LASTEXITCODE -ne 0) {
        throw "tar failed with exit code $LASTEXITCODE."
    }
}
else {
    # Expand-Archive expects a .zip extension, which $zipPath already has.
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractRoot -Force
}

if (-not (Test-Path -LiteralPath $apexIns)) {
    throw "Extraction finished but $apexIns was not found. The zip layout was not what this script expects; extract it manually into $extractRoot."
}

$version = 'unknown'
if (Test-Path -LiteralPath $versionFile) {
    $version = (Get-Content -LiteralPath $versionFile -TotalCount 1).Trim()
}

Write-Host ''
Write-Host "APEX $version is ready in $Destination" -ForegroundColor Green
Write-Host 'Next: cd local-dev; docker compose up -d'
Write-Host 'APEX will be installed by the ORDS container on first start (10-20 minutes).'
