[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root 'tools'
$sqlcl = Join-Path $tools 'sqlcl'
$zip = Join-Path $env:TEMP 'sqlcl-latest.zip'
$url = 'https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip'

if ((Test-Path (Join-Path $sqlcl 'bin\sql.exe')) -and -not $Force) {
    Write-Host "SQLcl already installed at $sqlcl. Use -Force to reinstall." -ForegroundColor Green
}
else {
    Write-Host "Downloading SQLcl from $url" -ForegroundColor Cyan
    & curl.exe -L --fail --output $zip $url
    if ($LASTEXITCODE -ne 0) {
        throw 'SQLcl download failed.'
    }

    New-Item -ItemType Directory -Force -Path $tools | Out-Null
    if (Test-Path $sqlcl) { Remove-Item -Recurse -Force $sqlcl }
    Expand-Archive -Path $zip -DestinationPath $tools -Force
    Write-Host "SQLcl extracted to $sqlcl" -ForegroundColor Green
}

$jdk = Get-ChildItem 'C:\Program Files\Microsoft\jdk-*' -Directory -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending |
    Select-Object -First 1

if (-not (Get-Command java -ErrorAction SilentlyContinue) -and -not $jdk) {
    Write-Host 'Java not found. Installing Microsoft OpenJDK 21 with winget...' -ForegroundColor Yellow
    winget install --id Microsoft.OpenJDK.21 --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        throw 'JDK installation failed. Install JDK 21 manually and set JAVA_HOME.'
    }
}

. (Join-Path $PSScriptRoot 'set-env.ps1')
& $env:SQLCL_BIN -V
if ($LASTEXITCODE -ne 0) {
    throw 'SQLcl installation could not be verified.'
}

Write-Host 'SQLcl is ready. Run . .\scripts\set-env.ps1 in new shells.' -ForegroundColor Green
