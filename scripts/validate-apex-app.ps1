[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$AppDirectory
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'set-env.ps1')

if (-not $env:SQLCL_BIN) {
    Write-Error 'SQLCL_BIN is not set. Run scripts\install-sqlcl.ps1 or set SQLCL_BIN to the SQLcl executable.'
    exit 2
}

if (-not (Test-Path $env:SQLCL_BIN)) {
    Write-Error "SQLCL_BIN is not a file: $env:SQLCL_BIN"
    exit 2
}

if (-not (Test-Path $AppDirectory -PathType Container)) {
    Write-Error "Application directory does not exist: $AppDirectory"
    exit 2
}

$resolved = (Resolve-Path $AppDirectory).Path
if ($resolved -match '["\r\n]') {
    Write-Error 'Application directory contains unsupported SQLcl command characters (quote or newline).'
    exit 2
}

# SQLcl's APEXLang parser rejects CRLF with confusing token errors. Detect the
# line-ending problem before running SQLcl and point at the fix.
$crlfFiles = @()
foreach ($file in Get-ChildItem $resolved -Recurse -File -Filter '*.apx') {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    if ($bytes -contains 13) {
        $crlfFiles += $file.FullName
    }
}

if ($crlfFiles.Count -gt 0) {
    Write-Host 'APEXLang sources must use LF line endings. CRLF was found in:' -ForegroundColor Red
    $crlfFiles | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
    if ($crlfFiles.Count -gt 10) {
        Write-Host ("  ... and {0} more" -f ($crlfFiles.Count - 10))
    }
    Write-Host ''
    Write-Host 'Fix and re-run validation:' -ForegroundColor Yellow
    Write-Host ("  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\normalize-apx-tree.ps1 -AppDirectory `"$resolved`"")
    exit 2
}

$commands = @"
apex validate -input "$resolved"
exit
"@

Write-Host "Validating APEX application: $resolved"
Write-Host "SQLcl: $env:SQLCL_BIN"

$output = $commands | & $env:SQLCL_BIN /nolog 2>&1
$status = $LASTEXITCODE
$text = $output | Out-String
$text.TrimEnd() | Write-Host

if ($status -ne 0) {
    Write-Error "APEX validation failed with exit code $status."
    exit 1
}

if ($text -notmatch 'Validation successful') {
    Write-Error 'APEX validation did not report "Validation successful". Treating the result as a failure.'
    exit 1
}

Write-Host 'APEX validation PASSED.' -ForegroundColor Green
exit 0
