[CmdletBinding()]
param(
    [string]$Destination,
    [string]$ZipPath,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
if (-not $Destination) {
    $Destination = Join-Path $root 'tools\opencode-v2'
}

$url = 'https://opencode.ai/update/api/latest/cli/opencode/opencode-windows-x64.zip'
$cachedZip = Join-Path $env:TEMP 'opencode-v2-win64.zip'

if ($ZipPath) {
    if (-not (Test-Path -LiteralPath $ZipPath)) {
        throw "Zip not found: $ZipPath"
    }
    $archive = (Resolve-Path -LiteralPath $ZipPath).Path
}
else {
    $archive = $cachedZip
    if (-not (Test-Path -LiteralPath $archive)) {
        $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($curl) {
            & $curl.Source -L --fail --max-time 600 -o $archive $url
            if ($LASTEXITCODE -ne 0) {
                Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue
                throw "Download failed with exit code $LASTEXITCODE"
            }
        }
        else {
            Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $archive
        }
    }
}

$archiveItem = Get-Item -LiteralPath $archive
if ($archiveItem.Length -lt 10MB) {
    throw "Archive looks incomplete: $($archiveItem.Length) bytes"
}

if ($Force -and (Test-Path -LiteralPath $Destination)) {
    Remove-Item -LiteralPath $Destination -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $Destination | Out-Null

$extract = Join-Path $env:TEMP ('opencode-v2-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $extract | Out-Null
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($archive, $extract)
    $binary = Get-ChildItem -LiteralPath $extract -Filter 'opencode.exe' -Recurse | Select-Object -First 1
    if (-not $binary) {
        throw 'opencode.exe not found in archive'
    }
    $target = Join-Path $Destination 'opencode.exe'
    Copy-Item -LiteralPath $binary.FullName -Destination $target -Force
}
finally {
    Remove-Item -LiteralPath $extract -Recurse -Force -ErrorAction SilentlyContinue
}

$shim = Join-Path $Destination 'opencode2.cmd'
$shimContent = '@echo off' + "`r`n" + '"%~dp0opencode.exe" %*' + "`r`n" + 'exit /b %errorlevel%' + "`r`n"
Set-Content -LiteralPath $shim -Value $shimContent -Encoding ASCII -NoNewline

$versionOutput = (& $target --version 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0) {
    throw "Installed binary failed to run: $versionOutput"
}
if ($versionOutput -notmatch '^v?2\.') {
    throw "Installed OpenCode is not 2.x: $versionOutput. This harness requires the v2 permissions schema."
}

Write-Host "Installed $versionOutput at $target"
Write-Host 'Run ". .\scripts\set-env.ps1" to put OpenCode v2 first on PATH.'
