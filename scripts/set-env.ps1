# Dot-source this file to configure the APEX harness environment:
#   Windows:  . .\scripts\set-env.ps1
#   macOS/Linux (PowerShell 7): . ./scripts/set-env.ps1
#
# It locates a JDK, uv/Spec Kit, the project-local SQLcl, and a local OpenCode
# binary, prepends them to PATH, and sets SQLCL_BIN when it is not already set.
# It does not set or print SQLCL_CONNECTION_STRING.

$HarnessRoot = Split-Path -Parent $PSScriptRoot
$IsWindowsHost = $env:OS -eq 'Windows_NT'
$PathSeparator = [string][System.IO.Path]::PathSeparator
$SqlclHome = Join-Path $HarnessRoot 'tools/sqlcl'

function Add-HarnessPath {
    param([string]$Directory)

    if (-not $Directory -or -not (Test-Path -LiteralPath $Directory)) {
        return
    }

    $entries = @($env:Path -split [regex]::Escape($PathSeparator))
    if ($entries -notcontains $Directory) {
        $env:Path = "$Directory$PathSeparator$env:Path"
    }
}

$javaExe = if ($IsWindowsHost) { 'java.exe' } else { 'java' }
$javaHomeExe = Join-Path 'bin' $javaExe

function Test-JavaHome {
    param([string]$HomePath)

    if (-not $HomePath) { return $false }
    return (Test-Path -LiteralPath (Join-Path $HomePath $javaHomeExe))
}

if (-not (Test-JavaHome $env:JAVA_HOME)) {
    $candidates = New-Object System.Collections.Generic.List[string]

    if ($IsWindowsHost) {
        foreach ($pattern in @(
            'C:\Program Files\Microsoft\jdk-*',
            'C:\Program Files\Java\jdk-21*',
            'C:\Program Files\Eclipse Adoptium\jdk-21*'
        )) {
            Get-ChildItem -Path $pattern -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { $candidates.Add($_.FullName) }
        }
    }
    else {
        foreach ($pattern in @(
            '/Library/Java/JavaVirtualMachines/*/Contents/Home',
            '/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home',
            '/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home',
            '/usr/lib/jvm/*21*',
            '/usr/lib/jvm/*-21-*'
        )) {
            Get-ChildItem -Path $pattern -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { $candidates.Add($_.FullName) }
        }
    }

    $jdk = $candidates |
        Sort-Object -Descending |
        Where-Object { Test-JavaHome $_ } |
        Select-Object -First 1

    if ($jdk) {
        $env:JAVA_HOME = $jdk
    }
}

if (Test-JavaHome $env:JAVA_HOME) {
    Add-HarnessPath (Join-Path $env:JAVA_HOME 'bin')
}

$uvBin = if ($IsWindowsHost) {
    Join-Path $env:USERPROFILE '.local/bin'
} else {
    Join-Path $HOME '.local/bin'
}
Add-HarnessPath $uvBin

$sqlclExe = if ($IsWindowsHost) {
    Join-Path (Join-Path $SqlclHome 'bin') 'sql.exe'
} else {
    Join-Path (Join-Path $SqlclHome 'bin') 'sql'
}
if (Test-Path -LiteralPath $sqlclExe) {
    Add-HarnessPath (Split-Path -Parent $sqlclExe)
    if (-not $env:SQLCL_BIN) {
        $env:SQLCL_BIN = $sqlclExe
    }
}

$openCodeCandidates = @(
    (Join-Path $HarnessRoot 'tools/opencode-v2'),
    (Join-Path $HOME '.opencode/bin')
)
foreach ($openCodeHome in $openCodeCandidates) {
    $openCodeExe = if ($IsWindowsHost) {
        Join-Path $openCodeHome 'opencode.exe'
    } else {
        Join-Path $openCodeHome 'opencode'
    }
    if (Test-Path -LiteralPath $openCodeExe) {
        Add-HarnessPath $openCodeHome
    }
}

# Ensure pipeline encoding to native processes (like SQLcl) is UTF-8 without BOM
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# SQLCL_CONNECTION_STRING is intentionally left alone. Validation works without
# it; deploy-apex-app.ps1 reports a clear error when a deployment needs it.
