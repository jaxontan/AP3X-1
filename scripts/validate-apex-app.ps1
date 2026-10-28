[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$AppDirectory
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'set-env.ps1')

if (-not $env:SQLCL_BIN) {
    Write-Error 'SQLCL_BIN is not set. Run scripts\install-sqlcl.ps1 or set SQLCL_BIN to the SQLcl executable.' -ErrorAction Continue
    exit 2
}

if (-not (Test-Path $env:SQLCL_BIN)) {
    Write-Error "SQLCL_BIN is not a file: $env:SQLCL_BIN" -ErrorAction Continue
    exit 2
}

if (-not (Test-Path $AppDirectory -PathType Container)) {
    Write-Error "Application directory does not exist: $AppDirectory" -ErrorAction Continue
    exit 2
}

$resolved = (Resolve-Path $AppDirectory).Path
if ($resolved -match '["\r\n]') {
    Write-Error 'Application directory contains unsupported SQLcl command characters (quote or newline).' -ErrorAction Continue
    exit 2
}

# SQLcl's APEXLang parser rejects CRLF with confusing token errors and treats a
# UTF-8 BOM as source text. Detect both before running SQLcl and point at the fix.
$crlfFiles = @()
$bomFiles = @()
foreach ($file in Get-ChildItem $resolved -Recurse -File -Filter '*.apx') {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    if ($bytes -contains 13) {
        $crlfFiles += $file.FullName
    }
    $hasUtf8Bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $hasUtf16Bom = ($bytes.Length -ge 2 -and (($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) -or ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF)))
    if ($hasUtf8Bom -or $hasUtf16Bom) {
        $bomFiles += $file.FullName
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

if ($bomFiles.Count -gt 0) {
    Write-Host 'APEXLang sources must be UTF-8 without a byte-order mark. A BOM was found in:' -ForegroundColor Red
    $bomFiles | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
    if ($bomFiles.Count -gt 10) {
        Write-Host ("  ... and {0} more" -f ($bomFiles.Count - 10))
    }
    Write-Host ''
    Write-Host 'Remove the BOM (save as UTF-8 without BOM) and re-run validation.' -ForegroundColor Yellow
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

$failureChecks = @(
    @{ Name = 'compile errors'; Pattern = 'APEXlang Compile Errors' },
    @{ Name = 'compile diagnostics'; Pattern = '(?m)^\s*Type:\s*[A-Z_]+' },
    @{ Name = 'error diagnostics'; Pattern = '(?m)^\s*Error:' },
    @{ Name = 'ignored source files'; Pattern = '\bFILE_IGNORED\b' },
    @{ Name = 'database errors'; Pattern = '\bORA-\d{3,5}\b' },
    @{ Name = 'failed validation'; Pattern = '\bValidation failed\b' }
)

foreach ($check in $failureChecks) {
    if ($text -match $check.Pattern) {
        Write-Error ("APEX validation reported {0}. Treating the result as a failure." -f $check.Name)
        exit 1
    }
}

if ($text -notmatch 'Validation successful') {
    Write-Error 'APEX validation did not report "Validation successful". Treating the result as a failure.'
    exit 1
}

Write-Host 'APEX validation PASSED.' -ForegroundColor Green
exit 0
