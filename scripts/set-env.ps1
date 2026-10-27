# Dot-source this file to configure the APEX harness environment:
#   . .\scripts\set-env.ps1
#
# It locates the installed JDK and the project-local SQLcl, prepends them to
# PATH, and sets SQLCL_BIN when it is not already set. It does not set or print
# SQLCL_CONNECTION_STRING.

$HarnessRoot = Split-Path -Parent $PSScriptRoot
$SqlclHome = Join-Path $HarnessRoot 'tools\sqlcl'

if (-not $env:JAVA_HOME -or -not (Test-Path (Join-Path $env:JAVA_HOME 'bin\java.exe'))) {
    $jdk = Get-ChildItem 'C:\Program Files\Microsoft\jdk-*' -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 1
    if ($jdk) {
        $env:JAVA_HOME = $jdk.FullName
    }
}

if ($env:JAVA_HOME) {
    $javaBin = Join-Path $env:JAVA_HOME 'bin'
    if ($env:Path -notlike "*$javaBin*") {
        $env:Path = "$javaBin;$env:Path"
    }
}

$sqlclExe = Join-Path $SqlclHome 'bin\sql.exe'
if (Test-Path $sqlclExe) {
    $sqlclBin = Join-Path $SqlclHome 'bin'
    if ($env:Path -notlike "*$sqlclBin*") {
        $env:Path = "$sqlclBin;$env:Path"
    }
    if (-not $env:SQLCL_BIN) {
        $env:SQLCL_BIN = $sqlclExe
    }
}

# SQLCL_CONNECTION_STRING is intentionally left alone. Validation works without
# it; deploy-apex-app.ps1 reports a clear error when a deployment needs it.
