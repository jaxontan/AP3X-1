[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$AppDirectory,

    [string]$ConnectionString = $env:SQLCL_CONNECTION_STRING
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
    Write-Host 'Fix and re-run deployment:' -ForegroundColor Yellow
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
    Write-Host 'Fix and re-run deployment:' -ForegroundColor Yellow
    Write-Host ("  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\normalize-apx-tree.ps1 -AppDirectory `"$resolved`"")
    exit 2
}

$commands = @"
begin
  apex_application_install.set_auto_install_sup_obj(
    p_auto_install_sup_obj => true
  );
end;
/
apex import -input "$resolved"
exit
"@

Write-Host "Application directory: $resolved"
Write-Host "SQLcl: $env:SQLCL_BIN"
Write-Host ("Target connection: {0}" -f $(if ($ConnectionString) { '(set; hidden)' } else { '(not set)' }))

if ($WhatIfPreference) {
    Write-Host ''
    Write-Host 'WhatIf: SQLcl would run the following commands:' -ForegroundColor Yellow
    Write-Host $commands
    exit 0
}

if (-not $ConnectionString) {
    Write-Error 'SQLCL_CONNECTION_STRING is not set. Set it, or pass -ConnectionString, before deploying.' -ErrorAction Continue
    exit 2
}

if (-not $PSCmdlet.ShouldProcess($resolved, 'Import the APEX application into the target database')) {
    exit 0
}

$output = $commands | & $env:SQLCL_BIN $ConnectionString 2>&1
$status = $LASTEXITCODE
$text = $output | Out-String
$text.TrimEnd() | Write-Host

if ($status -ne 0) {
    Write-Error "APEX import failed with exit code $status."
    exit 1
}

if ($text -match 'ORA-\d{3,5}') {
    Write-Error 'APEX import produced ORA- errors. Treating the deployment as failed even though the process exited 0.'
    exit 1
}

if ($text -match '\bFILE_IGNORED\b' -or $text -match 'APEXlang Compile Errors' -or $text -match '(?m)^\s*Error:') {
    Write-Error 'APEX import reported skipped files or compile diagnostics. Treating the deployment as failed.'
    exit 1
}

Write-Host 'APEX import completed without ORA- errors.' -ForegroundColor Green
exit 0
