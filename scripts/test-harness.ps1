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

    # Delivery gate: a minimal project that satisfies requirement -> design -> app, then one mutation per rule.
    $deliveryGate = Join-Path $scripts 'verify-delivery.ps1'
    function New-DeliveryFixture {
        param([string]$Name, [hashtable]$Override = @{})
        $root = Join-Path $tempRoot $Name
        $files = [ordered]@{
            'page-design\requirement.md'                       = "# Req`n`n- **Brand colours**: primary #7C3AED`n- Pill-shaped status badges`n- Page 1 lists claims`n"
            'page-design\application-design.md'                = "| Field | Value |`n| --- | --- |`n| Status | IMPLEMENTED |`n`n## 8. Requirement trace`n`n| # | Requirement | Status | Implemented at | Notes |`n| --- | --- | --- | --- | --- |`n| 1 | Brand colours | DONE | app/shared-components/static-files/css/brand.css:1 | |`n| 2 | Pill badges | DONE | app/pages/p00001-home.apx:3 | |`n| 3 | Page 1 | DONE | app/pages/p00001-home.apx:1 | |`n"
            'app\application.apx'                              = "app T (`n    css {`n        fileUrls: #APP_FILES#css/brand.css?v=#APP_VERSION#`n    }`n)`n"
            'app\shared-components\static-files.apx'           = "file `"css/brand.css`" (`n    mimeType: text/css`n)`n"
            'app\shared-components\static-files\css\brand.css' = ":root {`n  --brand-primary: #7C3AED;`n}`n.brand-pill { border-radius: 999px; }`n"
            'app\pages\p00001-home.apx'                        = "page 1 (`n    name: Claims`n    region r (`n        cssClasses: brand-pill t-Badge`n        icon: fa-home`n    )`n)`n"
            'database\packages\demo_api.pks'                   = "create or replace package demo_api as`n  function is_ok return boolean;`nend demo_api;`n"
            'database\tests\test_demo_api.sql'                 = "begin null; end;`n"
        }
        foreach ($key in $Override.Keys) { $files[$key] = $Override[$key] }
        foreach ($key in $files.Keys) {
            $path = Join-Path $root $key
            New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
            Write-TestScript -Path $path -Body $files[$key]
        }
        # Wire the package function into the page so the fixture passes the PL/SQL check.
        Add-Content -LiteralPath (Join-Path $root 'app\pages\p00001-home.apx') -Value '-- uses demo_api.is_ok' -Encoding UTF8
        return $root
    }

    $result = Invoke-HarnessScript -Script $deliveryGate -Arguments @('-ProjectDirectory', (New-DeliveryFixture 'gate-pass'))
    Add-Result -Name 'delivery gate passes a traced, branded project' -Ok ($result.ExitCode -eq 0 -and $result.Output -match 'DELIVERY GATE PASS') -Detail $result.Output

    $gateCases = @(
        @{ Name = 'delivery gate rejects a missing design'; Override = @{ 'page-design\application-design.md' = '' }; Expect = 'Status is' },
        @{ Name = 'delivery gate rejects an unapproved design'; Override = @{ 'page-design\application-design.md' = "| Status | DRAFT |`n" }; Expect = "Status is 'DRAFT'" },
        @{ Name = 'delivery gate rejects PLANNED trace rows'; Override = @{ 'page-design\application-design.md' = "| Status | IMPLEMENTED |`n`n## Requirement trace`n`n| # | Requirement | Status | Implemented at |`n| 1 | a | PLANNED | |`n| 2 | b | PLANNED | |`n| 3 | c | PLANNED | |`n" }; Expect = "status 'PLANNED'" },
        @{ Name = 'delivery gate rejects a dropped brand colour'; Override = @{ 'app\shared-components\static-files\css\brand.css' = ":root {`n  --brand-primary: #2563EB;`n}`n.brand-pill { border-radius: 999px; }`n" }; Expect = '#7C3AED is not defined' },
        @{ Name = 'delivery gate rejects an unknown icon'; Override = @{ 'app\pages\p00001-home.apx' = "page 1 (`n    region r (`n        cssClasses: brand-pill t-Badge`n        icon: fa-shield-check`n    )`n)`n" }; Expect = 'Unknown Font APEX icon' },
        @{ Name = 'delivery gate rejects inline style in .apx'; Override = @{ 'app\pages\p00001-home.apx' = "page 1 (`n    region r (`n        cssClasses: brand-pill t-Badge`n        html: <div style=`"color:red`">x</div>`n    )`n)`n" }; Expect = 'Inline style=' },
        @{ Name = 'delivery gate rejects an undefined brand class'; Override = @{ 'app\pages\p00001-home.apx' = "page 1 (`n    region r (`n        cssClasses: brand-pill brand-ghost t-Badge`n    )`n)`n" }; Expect = "brand-ghost' is used" },
        @{ Name = 'delivery gate rejects a hero with an empty icon box'; Override = @{ 'app\pages\p00001-home.apx' = "page 1 (`n    region hero (`n        cssClasses: brand-pill t-Badge`n        appearance {`n            template: @/hero`n        }`n    )`n)`n" }; Expect = 'renders an empty icon box' },
        @{ Name = 'delivery gate rejects an icon on a text-only button'; Override = @{ 'app\pages\p00001-home.apx' = "page 1 (`n    region r (`n        cssClasses: brand-pill t-Badge`n    )`n    button b (`n        appearance {`n            buttonTemplate: @/text`n            icon: fa-home`n        }`n    )`n)`n" }; Expect = 'does not render icons' },
        @{ Name = 'delivery gate rejects an uncalled package API'; Override = @{ 'database\packages\demo_api.pks' = "create or replace package demo_api as`n  function is_ok return boolean;`n  function can_edit return boolean;`nend demo_api;`n" }; Expect = 'can_edit is public but never called' },
        @{ Name = 'delivery gate rejects a function called as a statement'; Override = @{ 'app\pages\p00001-home.apx' = "page 1 (`n    name: Claims`n    region r (`n        cssClasses: brand-pill t-Badge`n        plsqlCode: begin demo_api.is_ok; end;`n    )`n)`n" }; Expect = 'PLS-00221' },
        @{ Name = 'delivery gate rejects an unknown named parameter'; Override = @{ 'database\packages\demo_api.pks' = "create or replace package demo_api as`n  function is_ok return boolean;`n  procedure save(p_id in number);`nend demo_api;`n"; 'app\pages\p00001-home.apx' = "page 1 (`n    name: Claims`n    region r (`n        cssClasses: brand-pill t-Badge`n        plsqlCode: demo_api.save(p_ident => 1);`n    )`n)`n" }; Expect = 'has no parameter p_ident' },
        @{ Name = 'delivery gate rejects a trace row citing a structural line'; Override = @{ 'page-design\application-design.md' = "| Status | IMPLEMENTED |`n`n## Requirement trace`n`n| # | Requirement | Status | Implemented at |`n| 1 | Brand colours | DONE | app/shared-components/static-files/css/brand.css:1 |`n| 2 | Pill badges | DONE | app/pages/p00001-home.apx:3 |`n| 3 | Page 1 lists claims | DONE | app/pages/p00001-home.apx:6 |`n" }; Expect = 'a structural line' },
        @{ Name = 'delivery gate rejects a trace row citing unrelated code'; Override = @{ 'page-design\application-design.md' = "| Status | IMPLEMENTED |`n`n## Requirement trace`n`n| # | Requirement | Status | Implemented at |`n| 1 | Brand colours | DONE | app/shared-components/static-files/css/brand.css:1 |`n| 2 | Pill badges | DONE | app/pages/p00001-home.apx:3 |`n| 3 | Page 1 lists claims | DONE | app/shared-components/static-files/css/brand.css:2 |`n" }; Expect = 'nothing within 15 lines mentions' },
        @{ Name = 'delivery gate rejects a requested chart that was not built'; Override = @{ 'page-design\requirement.md' = "# Req`n`n- **Brand colours**: primary #7C3AED`n- Pill-shaped status badges`n- Page 1 lists claims with a chart by month`n" }; Expect = "asks for 'chart'" },
        @{ Name = 'delivery gate rejects a hard-coded statistic'; Override = @{ 'app\pages\p00001-home.apx' = "page 1 (`n    name: Claims`n    region r (`n        cssClasses: brand-pill t-Badge`n        plsqlCode: :P1_STAT_AVG_IN := '09:02';`n    )`n)`n" }; Expect = 'hard-coded value' }
    )
    $caseIndex = 0
    foreach ($case in $gateCases) {
        $caseIndex++
        $result = Invoke-HarnessScript -Script $deliveryGate -Arguments @('-ProjectDirectory', (New-DeliveryFixture "gate-fail-$caseIndex" $case.Override))
        Add-Result -Name $case.Name -Ok ($result.ExitCode -eq 1 -and $result.Output -match [regex]::Escape($case.Expect)) -Detail $result.Output
    }

    # Adapter drift: every agent entry point must carry the delivery contract, and every file it cites must exist.
    $contractAnchors = @(
        'working/page-design/requirement.md',
        'working/page-design/application-design.md',
        'docs/templates/application-design.template.md',
        'skills/apex-design-system/references/brand-layer.md',
        'scripts/validate-apex-app.ps1',
        'scripts/verify-delivery.ps1'
    )
    $adapters = @(
        'AGENTS.md', 'CLAUDE.md',
        '.claude/skills/oracle-apex/SKILL.md',
        '.agents/skills/oracle-apex.md', '.agents/rules/oracle-apex.md',
        '.opencode/agents/apex.md', '.opencode/agents/apex-reviewer.md',
        '.opencode/agents/apex-planner.md', '.opencode/agents/apex-designer.md'
    )
    $drift = @()
    foreach ($adapter in $adapters) {
        $adapterPath = Join-Path $Root $adapter
        if (-not (Test-Path -LiteralPath $adapterPath)) { $drift += "$adapter is missing"; continue }
        $adapterText = [System.IO.File]::ReadAllText($adapterPath)
        foreach ($anchor in $contractAnchors) {
            if ($adapterText.IndexOf($anchor) -lt 0) { $drift += "$adapter does not cite $anchor" }
        }
    }
    foreach ($anchor in $contractAnchors | Where-Object { $_ -notlike 'working/*' }) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $anchor))) { $drift += "contract cites $anchor, which does not exist" }
    }
    foreach ($template in 'requirement.template.md', 'application-design.template.md') {
        if (-not (Test-Path -LiteralPath (Join-Path $Root "docs\templates\$template"))) { $drift += "docs/templates/$template is missing" }
    }
    Add-Result -Name 'agent adapters carry the delivery contract' -Ok ($drift.Count -eq 0) -Detail ($drift -join "`n")

    # Command bridges: Claude Code and .agents skills are generated from .opencode/commands.
    $bridgeOutput = & node (Join-Path $scripts 'sync-agent-commands.mjs') --check 2>&1 | Out-String
    Add-Result -Name 'command bridges match .opencode/commands' -Ok ($LASTEXITCODE -eq 0) -Detail $bridgeOutput

    $runtimeVerifier = Join-Path $scripts 'verify-apex-runtime.mjs'
    $runtimeOutput = & node --check $runtimeVerifier 2>&1 | Out-String
    Add-Result -Name 'runtime verifier parses' -Ok ($LASTEXITCODE -eq 0) -Detail $runtimeOutput
    $runtimeOutput = & node $runtimeVerifier --help 2>&1 | Out-String
    Add-Result -Name 'runtime verifier prints usage' -Ok ($LASTEXITCODE -eq 0 -and $runtimeOutput -match '--deny') -Detail $runtimeOutput
    $savedPassword = $env:APEX_TEST_PASSWORD
    $env:APEX_TEST_PASSWORD = $null
    $savedErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $runtimeOutput = & node $runtimeVerifier --url https://localhost/ords/r/x/y --users U1 --pages home 2>&1 | Out-String
    $runtimeExit = $LASTEXITCODE
    $ErrorActionPreference = $savedErrorAction
    $env:APEX_TEST_PASSWORD = $savedPassword
    Add-Result -Name 'runtime verifier refuses to run without a password env var' -Ok ($runtimeExit -eq 2 -and $runtimeOutput -match 'APEX_TEST_PASSWORD') -Detail $runtimeOutput

    $designVerifier = Join-Path $scripts 'verify-design-preview.mjs'
    $designOutput = & node --check $designVerifier 2>&1 | Out-String
    $designExit = $LASTEXITCODE
    Add-Result -Name 'design verifier parses' -Ok ($designExit -eq 0) -Detail $designOutput

    $designOutput = & node $designVerifier --help 2>&1 | Out-String
    $designExit = $LASTEXITCODE
    Add-Result -Name 'design verifier prints usage' -Ok ($designExit -eq 0 -and $designOutput -match '--preview') -Detail $designOutput
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
