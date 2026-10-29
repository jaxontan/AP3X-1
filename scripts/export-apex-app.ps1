[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ApplicationId,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$OutputDirectory,

    [string]$ConnectionString = $env:SQLCL_CONNECTION_STRING,

    [string]$CompareDirectory,

    [switch]$Force
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

if ($ApplicationId -notmatch '^\d+$' -or [int64]$ApplicationId -le 0) {
    Write-Error "ApplicationId must be a positive integer: $ApplicationId" -ErrorAction Continue
    exit 2
}

$outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)
if ($outputPath -match '["\r\n]') {
    Write-Error 'Output directory contains unsupported SQLcl command characters (quote or newline).' -ErrorAction Continue
    exit 2
}

if (Test-Path -LiteralPath $outputPath) {
    if (Test-Path -LiteralPath $outputPath -PathType Leaf) {
        Write-Error "Output path is a file, not a directory: $outputPath" -ErrorAction Continue
        exit 2
    }
    $existing = @(Get-ChildItem -LiteralPath $outputPath -Force)
    if ($existing.Count -gt 0 -and -not $Force) {
        Write-Error "Output directory is not empty: $outputPath. Pass -Force to replace its contents." -ErrorAction Continue
        exit 2
    }
}

if ($CompareDirectory) {
    if (-not (Test-Path -LiteralPath $CompareDirectory -PathType Container)) {
        Write-Error "Compare directory does not exist: $CompareDirectory" -ErrorAction Continue
        exit 2
    }
    $comparePath = (Resolve-Path -LiteralPath $CompareDirectory).Path
}

$commands = @"
apex export -applicationid $ApplicationId -exptype APEXLANG -split -dir "$outputPath"
exit
"@

Write-Host "Application ID: $ApplicationId"
Write-Host "Output directory: $outputPath"
Write-Host "SQLcl: $env:SQLCL_BIN"
Write-Host ("Target connection: {0}" -f $(if ($ConnectionString) { '(set; hidden)' } else { '(not set)' }))

if ($WhatIfPreference) {
    Write-Host ''
    Write-Host 'WhatIf: SQLcl would run the following commands:' -ForegroundColor Yellow
    Write-Host $commands
    exit 0
}

if (-not $ConnectionString) {
    Write-Error 'SQLCL_CONNECTION_STRING is not set. Set it, or pass -ConnectionString, before exporting.' -ErrorAction Continue
    exit 2
}

if (-not $PSCmdlet.ShouldProcess($outputPath, "Export APEX application $ApplicationId")) {
    exit 0
}

if ((Test-Path -LiteralPath $outputPath) -and $Force) {
    Get-ChildItem -LiteralPath $outputPath -Force | Remove-Item -Recurse -Force
}
else {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}

$output = $commands | & $env:SQLCL_BIN $ConnectionString 2>&1
$status = $LASTEXITCODE
$text = $output | Out-String
$text.TrimEnd() | Write-Host

if ($status -ne 0) {
    Write-Error "APEX export failed with exit code $status."
    exit 1
}

if ($text -match 'ORA-\d{3,5}') {
    Write-Error 'APEX export produced ORA- errors. Treating the export as failed even though the process exited 0.'
    exit 1
}

if ($text -match '\bFILE_IGNORED\b' -or $text -match '(?m)^\s*Error:') {
    Write-Error 'APEX export reported skipped files or errors. Treating the export as failed.'
    exit 1
}

$exported = @(Get-ChildItem -LiteralPath $outputPath -Recurse -File -Filter '*.apx')
if ($exported.Count -eq 0) {
    Write-Error "APEX export produced no .apx files under $outputPath."
    exit 1
}

$exportRoot = $outputPath
if (-not (Test-Path -LiteralPath (Join-Path $outputPath 'application.apx'))) {
    $subApp = Get-ChildItem -LiteralPath $outputPath -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'application.apx') } | Select-Object -First 1
    if ($subApp) {
        $exportRoot = $subApp.FullName
    }
}

& (Join-Path $PSScriptRoot 'normalize-apx-tree.ps1') -AppDirectory $exportRoot
if ($LASTEXITCODE -ne 0) {
    Write-Error 'Failed to normalize the exported APEXLang tree.'
    exit 1
}

if (-not $CompareDirectory) {
    Write-Host "APEX export completed: $($exported.Count) .apx file(s)." -ForegroundColor Green
    exit 0
}

$exportMap = @{}
foreach ($file in Get-ChildItem -LiteralPath $exportRoot -Recurse -File) {
    $relative = $file.FullName.Substring($exportRoot.Length).TrimStart('\', '/')
    $exportMap[$relative] = $file.FullName
}

$compareMap = @{}
foreach ($file in Get-ChildItem -LiteralPath $comparePath -Recurse -File) {
    $relative = $file.FullName.Substring($comparePath.Length).TrimStart('\', '/')
    $compareMap[$relative] = $file.FullName
}

$differences = @()
foreach ($relative in $exportMap.Keys) {
    if (-not $compareMap.ContainsKey($relative)) {
        $differences += "only in export: $relative"
        continue
    }
    $exportHash = (Get-FileHash -LiteralPath $exportMap[$relative] -Algorithm SHA256).Hash
    $compareHash = (Get-FileHash -LiteralPath $compareMap[$relative] -Algorithm SHA256).Hash
    if ($exportHash -ne $compareHash) {
        $differences += "different: $relative"
    }
}

foreach ($relative in $compareMap.Keys) {
    if (-not $exportMap.ContainsKey($relative)) {
        $differences += "only in working tree: $relative"
    }
}

if ($differences.Count -gt 0) {
    Write-Host ''
    Write-Host "Drift detected between the database export and $comparePath ($($differences.Count) file(s)):" -ForegroundColor Red
    $differences | Sort-Object | Select-Object -First 50 | ForEach-Object { Write-Host "  - $_" }
    if ($differences.Count -gt 50) {
        Write-Host ("  ... and {0} more" -f ($differences.Count - 50))
    }
    exit 1
}

Write-Host "No drift: the export matches $comparePath." -ForegroundColor Green
exit 0
