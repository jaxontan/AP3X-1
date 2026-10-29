[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$isWindowsHost = $env:OS -eq 'Windows_NT'
$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root 'tools'
$sqlcl = Join-Path $tools 'sqlcl'
$sqlExe = if ($isWindowsHost) { 'sql.exe' } else { 'sql' }
$zip = Join-Path ([System.IO.Path]::GetTempPath()) 'sqlcl-latest.zip'
$url = 'https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip'

if ((Test-Path (Join-Path (Join-Path $sqlcl 'bin') $sqlExe)) -and -not $Force) {
    Write-Host "SQLcl already installed at $sqlcl. Use -Force to reinstall." -ForegroundColor Green
}
else {
    $curl = if (Get-Command curl.exe -ErrorAction SilentlyContinue) { 'curl.exe' } else { 'curl' }
    Write-Host "Downloading SQLcl from $url" -ForegroundColor Cyan
    & $curl -L --fail --retry 3 --output $zip $url
    if ($LASTEXITCODE -ne 0) {
        throw 'SQLcl download failed.'
    }

    New-Item -ItemType Directory -Force -Path $tools | Out-Null
    if (Test-Path $sqlcl) { Remove-Item -Recurse -Force $sqlcl }

    if ($isWindowsHost) {
        Expand-Archive -Path $zip -DestinationPath $tools -Force
    }
    else {
        & unzip -q -o $zip -d $tools
        if ($LASTEXITCODE -ne 0) {
            throw 'SQLcl extraction failed. Install unzip and retry.'
        }
        & chmod +x (Join-Path (Join-Path $sqlcl 'bin') 'sql')
        if ($LASTEXITCODE -ne 0) {
            throw 'Could not make the SQLcl launcher executable.'
        }
    }
    Write-Host "SQLcl extracted to $sqlcl" -ForegroundColor Green
}

$hasJava = [bool](Get-Command java -ErrorAction SilentlyContinue)
$hasJavaHome = $env:JAVA_HOME -and (Test-Path (Join-Path (Join-Path $env:JAVA_HOME 'bin') ($(if ($isWindowsHost) { 'java.exe' } else { 'java' }))))
if (-not $hasJava -and -not $hasJavaHome) {
    Write-Host 'Java not found. Installing JDK 21...' -ForegroundColor Yellow
    if ($isWindowsHost) {
        winget install --id Microsoft.OpenJDK.21 --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    }
    elseif ((& uname -s) -eq 'Darwin') {
        brew install --cask temurin@21
    }
    elseif (Get-Command apt-get -ErrorAction SilentlyContinue) {
        sudo apt-get update
        sudo apt-get install -y openjdk-21-jdk
    }
    elseif (Get-Command dnf -ErrorAction SilentlyContinue) {
        sudo dnf install -y java-21-openjdk-devel
    }
    elseif (Get-Command pacman -ErrorAction SilentlyContinue) {
        sudo pacman -S --needed --noconfirm jdk21-openjdk
    }
    elseif (Get-Command zypper -ErrorAction SilentlyContinue) {
        sudo zypper install -y java-21-openjdk-devel
    }
    else {
        throw 'Install JDK 21 manually and set JAVA_HOME.'
    }
    if ($LASTEXITCODE -ne 0) {
        throw 'JDK installation failed. Install JDK 21 manually and set JAVA_HOME.'
    }
}

. (Join-Path $PSScriptRoot 'set-env.ps1')
if (-not $env:SQLCL_BIN) {
    throw "SQLcl was extracted to $sqlcl, but its launcher was not found. Set SQLCL_BIN manually."
}

& $env:SQLCL_BIN -V
if ($LASTEXITCODE -ne 0) {
    throw 'SQLcl installation could not be verified.'
}

Write-Host 'SQLcl is ready. Run . ./scripts/set-env.ps1 (Windows: . .\scripts\set-env.ps1) in new shells.' -ForegroundColor Green
