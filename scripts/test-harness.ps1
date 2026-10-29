[CmdletBinding()]
param(
    [string]$Root
)

$ErrorActionPreference = 'Stop'

if (-not $Root) {
    $Root = Split-Path -Parent $PSScriptRoot
}

$powerShellExe = Join-Path $PSHOME 'powershell.exe'
if (-not (Test-Path -LiteralPath $powerShellExe)) {
    $powerShellExe = 'powershell.exe'
}

$scripts = Join-Path $Root 'scripts'
$example = Join-Path $Root 'skills\apex\apexlang\26.2\apexlang-example-applications\assets\example-0'
if (-not (Test-Path -LiteralPath $example -PathType Container)) {
    Write-Error "Test fixture not found: $example"
    exit 2
}

$passed = 0
$failed = 0
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('apex-harness-test-' + [guid]::NewGuid().ToString('N'))

function Write-TestScript {
    param([string]$Path, [string]$Body)
    [System.IO.File]::WriteAllText($Path, $Body, (New-Object System.Text.UTF8Encoding($false)))
}

function Invoke-HarnessScript {
    param(
        [string]$Script,
        [string[]]$Arguments,
        [hashtable]$Environment = @{}
    )

    $saved = @{}
    $savedErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    try {
        foreach ($key in $Environment.Keys) {
            $saved[$key] = [System.Environment]::GetEnvironmentVariable($key, 'Process')
            [System.Environment]::SetEnvironmentVariable($key, $Environment[$key], 'Process')
        }

        $output = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $Script @Arguments 2>&1 | Out-String
        $code = $LASTEXITCODE
    }
    finally {
        foreach ($key in $Environment.Keys) {
            [System.Environment]::SetEnvironmentVariable($key, $saved[$key], 'Process')
        }
        $ErrorActionPreference = $savedErrorAction
    }

    return [pscustomobject]@{
        ExitCode = $code
        Output   = $output
    }
}

function Invoke-HarnessCommand {
    param(
        [string]$Command,
        [hashtable]$Environment = @{}
    )

    $saved = @{}
    $savedErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    try {
        foreach ($key in $Environment.Keys) {
            $saved[$key] = [System.Environment]::GetEnvironmentVariable($key, 'Process')
            [System.Environment]::SetEnvironmentVariable($key, $Environment[$key], 'Process')
        }

        $wrappedCommand = "$Command; exit `$LASTEXITCODE"
        $output = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -Command $wrappedCommand 2>&1 | Out-String
        $code = $LASTEXITCODE
    }
    finally {
        foreach ($key in $Environment.Keys) {
            [System.Environment]::SetEnvironmentVariable($key, $saved[$key], 'Process')
        }
        $ErrorActionPreference = $savedErrorAction
    }

    return [pscustomobject]@{
        ExitCode = $code
        Output   = $output
    }
}

function ConvertTo-SingleQuoted {
    param([string]$Value)
    return "'" + ($Value -replace "'", "''") + "'"
}

function Add-Result {
    param([string]$Name, [bool]$Ok, [string]$Detail = '')

    if ($Ok) {
        $script:passed++
        Write-Host "PASS     $Name" -ForegroundColor Green
    }
    else {
        $script:failed++
        Write-Host "FAIL     $Name" -ForegroundColor Red
        if ($Detail) {
            $Detail.TrimEnd() -split "`r?`n" | Select-Object -First 8 | ForEach-Object {
                Write-Host "         $_" -ForegroundColor DarkGray
            }
        }
    }
}

function New-TestApp {
    param([string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Copy-Item -Path (Join-Path $example '*') -Destination $Path -Recurse -Force
}

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

    $fakeSuccess = Join-Path $tempRoot 'fake-success.ps1'
    $fakeCompileError = Join-Path $tempRoot 'fake-compile-error.ps1'
    $fakeNoResult = Join-Path $tempRoot 'fake-no-result.ps1'
    $fakeOra = Join-Path $tempRoot 'fake-ora.ps1'
    $fakeExport = Join-Path $tempRoot 'fake-export.ps1'

    Write-TestScript -Path $fakeSuccess -Body @'
$null = $input | Out-String
Write-Output 'Validation successful'
Write-Output 'Import successful'
exit 0
'@

    Write-TestScript -Path $fakeCompileError -Body @'
$null = $input | Out-String
Write-Output 'APEXlang Compile Errors'
Write-Output 'Type: COMPONENT'
exit 0
'@

    Write-TestScript -Path $fakeNoResult -Body @'
$null = $input | Out-String
Write-Output 'Nothing to report'
exit 0
'@

    Write-TestScript -Path $fakeOra -Body @'
$null = $input | Out-String
Write-Output 'ORA-00942: table or view does not exist'
exit 0
'@

    Write-TestScript -Path $fakeExport -Body @'
$commands = $input | Out-String
if ($commands -match '-dir\s+"([^"]+)"') {
    $destination = $Matches[1]
}
else {
    Write-Error 'fake export could not find -dir'
    exit 2
}
if (-not (Test-Path -LiteralPath $destination)) {
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
}
Copy-Item -Path (Join-Path $env:FAKE_EXPORT_SOURCE '*') -Destination $destination -Recurse -Force
if ($env:FAKE_EXPORT_ORA) {
    Write-Output 'ORA-00942: table or view does not exist'
    exit 0
}
Write-Output 'Export successful'
exit 0
'@

    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'bootstrap.ps1') -Arguments @('-DryRun')
    Add-Result -Name 'bootstrap dry-run makes no changes' -Ok ($result.ExitCode -eq 0 -and $result.Output -match 'Dry run complete') -Detail $result.Output

    $app = Join-Path $tempRoot 'app'
    New-TestApp -Path $app

    $normalizeApp = Join-Path $tempRoot 'normalize'
    New-TestApp -Path $normalizeApp
    $normalizeFile = Get-ChildItem -LiteralPath $normalizeApp -Recurse -File -Filter '*.apx' | Select-Object -First 1
    $crlfText = [System.IO.File]::ReadAllText($normalizeFile.FullName)
    $crlfText = $crlfText -replace "`r?`n", "`r`n"
    [System.IO.File]::WriteAllText($normalizeFile.FullName, $crlfText, (New-Object System.Text.UTF8Encoding($true)))
    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'normalize-apx-tree.ps1') -Arguments @('-AppDirectory', $normalizeApp)
    $bytes = [System.IO.File]::ReadAllBytes($normalizeFile.FullName)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $hasCr = ($bytes -contains 13)
    Add-Result -Name 'normalize removes CRLF and UTF-8 BOM' -Ok ($result.ExitCode -eq 0 -and -not $hasBom -and -not $hasCr) -Detail $result.Output

    $utf16App = Join-Path $tempRoot 'utf16'
    New-Item -ItemType Directory -Path $utf16App -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $utf16App 'app.apx'), 'app test', [System.Text.Encoding]::Unicode)
    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'normalize-apx-tree.ps1') -Arguments @('-AppDirectory', $utf16App)
    Add-Result -Name 'normalize rejects UTF-16' -Ok ($result.ExitCode -eq 2) -Detail $result.Output

    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'validate-apex-app.ps1') -Arguments @('-AppDirectory', $app) -Environment @{ SQLCL_BIN = $fakeSuccess }
    Add-Result -Name 'validate accepts clean tree' -Ok ($result.ExitCode -eq 0 -and $result.Output -match 'Validation successful') -Detail $result.Output

    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'validate-apex-app.ps1') -Arguments @('-AppDirectory', $app) -Environment @{ SQLCL_BIN = $fakeCompileError }
    Add-Result -Name 'validate rejects compile diagnostics on exit 0' -Ok ($result.ExitCode -eq 1) -Detail $result.Output

    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'validate-apex-app.ps1') -Arguments @('-AppDirectory', $app) -Environment @{ SQLCL_BIN = $fakeOra }
    Add-Result -Name 'validate rejects ORA- errors on exit 0' -Ok ($result.ExitCode -eq 1) -Detail $result.Output

    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'validate-apex-app.ps1') -Arguments @('-AppDirectory', $app) -Environment @{ SQLCL_BIN = $fakeNoResult }
    Add-Result -Name 'validate requires the success marker' -Ok ($result.ExitCode -eq 1) -Detail $result.Output

    $bomApp = Join-Path $tempRoot 'bom'
    New-TestApp -Path $bomApp
    $bomFile = Get-ChildItem -LiteralPath $bomApp -Recurse -File -Filter '*.apx' | Select-Object -First 1
    [System.IO.File]::WriteAllText($bomFile.FullName, [System.IO.File]::ReadAllText($bomFile.FullName), (New-Object System.Text.UTF8Encoding($true)))
    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'validate-apex-app.ps1') -Arguments @('-AppDirectory', $bomApp) -Environment @{ SQLCL_BIN = $fakeSuccess }
    Add-Result -Name 'validate rejects a UTF-8 BOM before SQLcl' -Ok ($result.ExitCode -eq 2) -Detail $result.Output

    $crlfApp = Join-Path $tempRoot 'crlf'
    New-TestApp -Path $crlfApp
    $crlfFile = Get-ChildItem -LiteralPath $crlfApp -Recurse -File -Filter '*.apx' | Select-Object -First 1
    $crlfText = [System.IO.File]::ReadAllText($crlfFile.FullName)
    [System.IO.File]::WriteAllText($crlfFile.FullName, ($crlfText -replace "`r?`n", "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'validate-apex-app.ps1') -Arguments @('-AppDirectory', $crlfApp) -Environment @{ SQLCL_BIN = $fakeSuccess }
    Add-Result -Name 'validate rejects CRLF before SQLcl' -Ok ($result.ExitCode -eq 2) -Detail $result.Output

    $exportMatch = Join-Path $tempRoot 'export-match'
    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'export-apex-app.ps1') -Arguments @('-ApplicationId', '100', '-OutputDirectory', $exportMatch, '-ConnectionString', 'fake', '-CompareDirectory', $app) -Environment @{ SQLCL_BIN = $fakeExport; SQLCL_CONNECTION_STRING = 'fake'; FAKE_EXPORT_SOURCE = $app }
    Add-Result -Name 'export reports no drift for a matching tree' -Ok ($result.ExitCode -eq 0 -and $result.Output -match 'No drift') -Detail $result.Output

    $compareDrift = Join-Path $tempRoot 'compare-drift'
    New-TestApp -Path $compareDrift
    $driftFile = Get-ChildItem -LiteralPath $compareDrift -Recurse -File -Filter '*.apx' | Select-Object -First 1
    Add-Content -LiteralPath $driftFile.FullName -Value 'drift'
    $exportDrift = Join-Path $tempRoot 'export-drift'
    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'export-apex-app.ps1') -Arguments @('-ApplicationId', '100', '-OutputDirectory', $exportDrift, '-ConnectionString', 'fake', '-CompareDirectory', $compareDrift) -Environment @{ SQLCL_BIN = $fakeExport; SQLCL_CONNECTION_STRING = 'fake'; FAKE_EXPORT_SOURCE = $app }
    Add-Result -Name 'export reports drift with a non-zero exit' -Ok ($result.ExitCode -eq 1 -and $result.Output -match 'Drift detected') -Detail $result.Output

    $exportOra = Join-Path $tempRoot 'export-ora'
    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'export-apex-app.ps1') -Arguments @('-ApplicationId', '100', '-OutputDirectory', $exportOra, '-ConnectionString', 'fake') -Environment @{ SQLCL_BIN = $fakeExport; SQLCL_CONNECTION_STRING = 'fake'; FAKE_EXPORT_SOURCE = $app; FAKE_EXPORT_ORA = '1' }
    Add-Result -Name 'export rejects ORA- errors on exit 0' -Ok ($result.ExitCode -eq 1) -Detail $result.Output

    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'deploy-apex-app.ps1') -Arguments @('-AppDirectory', $app, '-WhatIf') -Environment @{ SQLCL_BIN = $fakeSuccess }
    Add-Result -Name 'deploy WhatIf does not call SQLcl' -Ok ($result.ExitCode -eq 0 -and $result.Output -match 'WhatIf') -Detail $result.Output

    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'deploy-apex-app.ps1') -Arguments @('-AppDirectory', $app) -Environment @{ SQLCL_BIN = $fakeSuccess; SQLCL_CONNECTION_STRING = $null }
    Add-Result -Name 'deploy requires a connection' -Ok ($result.ExitCode -eq 2) -Detail $result.Output

    $result = Invoke-HarnessScript -Script (Join-Path $scripts 'export-apex-app.ps1') -Arguments @('-ApplicationId', '100', '-OutputDirectory', (Join-Path $tempRoot 'export-no-connection')) -Environment @{ SQLCL_BIN = $fakeExport; SQLCL_CONNECTION_STRING = $null }
    Add-Result -Name 'export requires a connection' -Ok ($result.ExitCode -eq 2) -Detail $result.Output

    $deployScript = Join-Path $scripts 'deploy-apex-app.ps1'
    $deployCommand = "`$ConfirmPreference = 'None'; & $(ConvertTo-SingleQuoted $deployScript) -AppDirectory $(ConvertTo-SingleQuoted $app) -ConnectionString 'fake'"
    $result = Invoke-HarnessCommand -Command $deployCommand -Environment @{ SQLCL_BIN = $fakeSuccess }
    Add-Result -Name 'deploy accepts a clean fake import' -Ok ($result.ExitCode -eq 0) -Detail $result.Output

    $result = Invoke-HarnessCommand -Command $deployCommand -Environment @{ SQLCL_BIN = $fakeOra }
    Add-Result -Name 'deploy rejects ORA- errors on exit 0' -Ok ($result.ExitCode -eq 1) -Detail $result.Output

    $bomDeployCommand = "`$ConfirmPreference = 'None'; & $(ConvertTo-SingleQuoted $deployScript) -AppDirectory $(ConvertTo-SingleQuoted $bomApp) -ConnectionString 'fake'"
    $result = Invoke-HarnessCommand -Command $bomDeployCommand -Environment @{ SQLCL_BIN = $fakeSuccess }
    Add-Result -Name 'deploy rejects a UTF-8 BOM before SQLcl' -Ok ($result.ExitCode -eq 2) -Detail $result.Output

    $crlfDeployCommand = "`$ConfirmPreference = 'None'; & $(ConvertTo-SingleQuoted $deployScript) -AppDirectory $(ConvertTo-SingleQuoted $crlfApp) -ConnectionString 'fake'"
    $result = Invoke-HarnessCommand -Command $crlfDeployCommand -Environment @{ SQLCL_BIN = $fakeSuccess }
    Add-Result -Name 'deploy rejects CRLF before SQLcl' -Ok ($result.ExitCode -eq 2) -Detail $result.Output
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host ("Harness self-test: {0} passed, {1} failed." -f $passed, $failed) -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
if ($failed -gt 0) {
    exit 1
}
exit 0
