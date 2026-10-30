<#
.SYNOPSIS
  Whole-project delivery gate: requirement -> application design -> app -> database.

.DESCRIPTION
  Fails delivery when the build silently drifts from the user's requirement. Checks:
    Trace    application-design.md exists, is IMPLEMENTED, and every requirement bullet has a
             trace row marked DONE (with a valid file:line) or NOT DONE: <reason>. A cited line
             must not be structural, and code near it must mention the requirement.
    Design   requirement hex colours live in brand.css and brand.css is loaded app-wide;
             requirement design keywords (pill, shadow, badge, chart, live clock, confirm, ...)
             have evidence in the build; statistic items are not hard-coded;
             no inline style/handlers/javascript: or hex in .apx; hex in brand.css only on
             --brand-* token lines; brand-* classes are defined and used; every Font APEX icon
             exists; every styling column a view exposes is used by a page.
    PL/SQL   every public package subprogram is called somewhere; every pkg.member(...) call
             matches the spec (function vs procedure, parameter names, required arguments);
             tests exist.

  Exit codes: 0 pass, 1 blocking findings, 2 usage error.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-delivery.ps1 -ProjectDirectory working
#>
[CmdletBinding()]
param(
    [string]$ProjectDirectory = 'working',
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'

$script:failures = New-Object System.Collections.Generic.List[string]
$script:warnings = New-Object System.Collections.Generic.List[string]

function Add-Failure { param([string]$Area, [string]$Message) $script:failures.Add("[$Area] $Message") }
function Add-Warning { param([string]$Area, [string]$Message) $script:warnings.Add("[$Area] $Message") }

function Read-Text {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path).Replace("`r`n", "`n")
}

function Get-RelativePath {
    param([string]$Path)
    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $full.Substring($repoRoot.Length).TrimStart('\', '/').Replace('\', '/')
    }
    return $full
}

# Returns "relative/path:line" for every line in $Files matching $Pattern.
function Find-Lines {
    param([System.IO.FileInfo[]]$Files, [string]$Pattern)
    $hits = @()
    foreach ($file in $Files) {
        $lines = (Read-Text $file.FullName).Split("`n")
        for ($i = 0; $i -lt $lines.Length; $i++) {
            if ([regex]::IsMatch($lines[$i], $Pattern)) {
                $hits += ('{0}:{1}' -f (Get-RelativePath $file.FullName), ($i + 1))
            }
        }
    }
    return $hits
}

function Format-Hits {
    param([string[]]$Hits, [int]$Max = 5)
    $shown = ($Hits | Select-Object -First $Max) -join ', '
    if ($Hits.Count -gt $Max) { $shown += " (+$($Hits.Count - $Max) more)" }
    return $shown
}

# Masks single-line string literals as '___' and blanks comments, keeping offsets and line numbers intact.
function Remove-PlsqlNoise {
    param([string]$Text)
    return [regex]::Replace($Text, "'[^'\n]*'|--[^\n]*|/\*[\s\S]*?\*/", {
            param($m)
            if ($m.Value[0] -eq "'") { return "'" + ('_' * ($m.Value.Length - 2)) + "'" }
            return [regex]::Replace($m.Value, '[^\n]', ' ')
        })
}

function Get-ClosingParen {
    param([string]$Text, [int]$Open)
    $depth = 0
    for ($i = $Open; $i -lt $Text.Length; $i++) {
        if ($Text[$i] -eq '(') { $depth++ }
        elseif ($Text[$i] -eq ')') { $depth--; if ($depth -eq 0) { return $i } }
    }
    return -1
}

# Splits an argument or parameter list on top-level commas.
function Split-TopLevel {
    param([string]$Text)
    if (-not $Text.Trim()) { return @() }
    $parts = @(); $depth = 0; $start = 0
    for ($i = 0; $i -lt $Text.Length; $i++) {
        if ($Text[$i] -eq '(') { $depth++ }
        elseif ($Text[$i] -eq ')') { $depth-- }
        elseif ($Text[$i] -eq ',' -and $depth -eq 0) { $parts += $Text.Substring($start, $i - $start); $start = $i + 1 }
    }
    $parts += $Text.Substring($start)
    # Keep blank parts: a blanked string literal is still an argument.
    return @($parts | ForEach-Object { $_.Trim() })
}

# Returns @{ member = @( @{ Kind; Params = @( @{ Name; Mode; Optional } ) } ) } for a package spec.
function Get-PackageContract {
    param([string]$SpecText)
    $clean = Remove-PlsqlNoise $SpecText
    $subs = @{}
    foreach ($m in [regex]::Matches($clean, '(?i)\b(FUNCTION|PROCEDURE)\s+(\w+)')) {
        $params = @()
        $pos = $m.Index + $m.Length
        while ($pos -lt $clean.Length -and [char]::IsWhiteSpace($clean[$pos])) { $pos++ }
        if ($pos -lt $clean.Length -and $clean[$pos] -eq '(') {
            $close = Get-ClosingParen $clean $pos
            if ($close -gt $pos) {
                foreach ($decl in (Split-TopLevel $clean.Substring($pos + 1, $close - $pos - 1))) {
                    $p = [regex]::Match($decl, '(?is)^(\w+)\s+(IN\s+OUT\b|OUT\b|IN\b)?')
                    if (-not $p.Success) { continue }
                    $mode = ($p.Groups[2].Value -replace '\s+', ' ').ToUpperInvariant()
                    if (-not $mode) { $mode = 'IN' }
                    $params += [pscustomobject]@{ Name = $p.Groups[1].Value.ToLowerInvariant(); Mode = $mode; Optional = ($decl -match '(?i)\bDEFAULT\b|:=') }
                }
            }
        }
        $name = $m.Groups[2].Value.ToLowerInvariant()
        if (-not $subs.ContainsKey($name)) { $subs[$name] = @() }
        $subs[$name] += , ([pscustomobject]@{ Kind = $m.Groups[1].Value.ToUpperInvariant(); Params = $params })
    }
    return @{ Subs = $subs; Clean = $clean }
}

# --- Resolve paths -----------------------------------------------------------
$repoRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot)).TrimEnd('\', '/')
if (-not [System.IO.Path]::IsPathRooted($ProjectDirectory)) {
    $ProjectDirectory = Join-Path $repoRoot $ProjectDirectory
}
if (-not (Test-Path -LiteralPath $ProjectDirectory -PathType Container)) {
    Write-Error "Project directory does not exist: $ProjectDirectory"
    exit 2
}
$project = [System.IO.Path]::GetFullPath($ProjectDirectory).TrimEnd('\', '/')
$requirementPath = Join-Path $project 'page-design\requirement.md'
$designPath = Join-Path $project 'page-design\application-design.md'
$appDir = Join-Path $project 'app'
$dbDir = Join-Path $project 'database'

$apxFiles = @()
if (Test-Path -LiteralPath $appDir) {
    $apxFiles = @(Get-ChildItem -LiteralPath $appDir -Recurse -File -Filter '*.apx')
}
$dbFiles = @()
if (Test-Path -LiteralPath $dbDir) {
    $dbFiles = @(Get-ChildItem -LiteralPath $dbDir -Recurse -File | Where-Object { $_.Extension -in '.sql', '.pks', '.pkb' })
}
$brandCssPath = Join-Path $appDir 'shared-components\static-files\css\brand.css'
$hasBrandCss = Test-Path -LiteralPath $brandCssPath
$brandCss = if ($hasBrandCss) { Read-Text $brandCssPath } else { '' }
$apxText = (($apxFiles | ForEach-Object { Read-Text $_.FullName }) -join "`n")

Write-Host 'APEX delivery gate' -ForegroundColor Cyan
Write-Host "Project:  $project"
Write-Host "App:      $($apxFiles.Count) .apx files"
Write-Host "Database: $($dbFiles.Count) SQL/package files"
Write-Host ''

# --- 1. Requirement trace ----------------------------------------------------
$requirement = ''
$requirementIsTemplate = $true
if (-not (Test-Path -LiteralPath $requirementPath)) {
    Add-Warning 'trace' 'No page-design/requirement.md; requirement trace and design-fidelity checks skipped.'
}
else {
    $requirement = [regex]::Replace((Read-Text $requirementPath), '(?s)<!--.*?-->', '')
    $requirementIsTemplate = $requirement.Contains('[e.g.')
    if ($requirementIsTemplate) {
        Add-Warning 'trace' 'requirement.md is still the blank template; requirement trace and design-fidelity checks skipped.'
    }
}

if (-not $requirementIsTemplate) {
    $bullets = @(
        $requirement.Split("`n") |
            Where-Object { $_ -match '^\s*[-*]\s+\S' } |
            ForEach-Object { ($_ -replace '^\s*[-*]\s+', '').Trim() } |
            Where-Object { $_ -and -not $_.EndsWith(':') }
    )

    if (-not (Test-Path -LiteralPath $designPath)) {
        Add-Failure 'trace' 'page-design/application-design.md is missing. Write it from docs/templates/application-design.template.md before building.'
    }
    else {
        $design = Read-Text $designPath
        $statusMatch = [regex]::Match($design, '(?im)^\|\s*Status\s*\|\s*([^|]*)\|')
        $status = if ($statusMatch.Success) { $statusMatch.Groups[1].Value.Trim() } else { '' }
        if ($status -notmatch '^(APPROVED|IMPLEMENTED)\b') {
            Add-Failure 'trace' "application-design.md Status is '$status'; the user must approve it (APPROVED) before building."
        }
        elseif ($status -notmatch '^IMPLEMENTED\b') {
            Add-Failure 'trace' "application-design.md Status is '$status'; set IMPLEMENTED after updating the trace."
        }

        $section = [regex]::Match($design, '(?ims)^##\s+(\d+\.\s*)?Requirement trace\s*$(.*?)(?=^##\s|\z)')
        if (-not $section.Success) {
            Add-Failure 'trace' "application-design.md has no '## Requirement trace' section."
        }
        else {
            $rows = @()
            foreach ($line in $section.Groups[2].Value.Split("`n")) {
                if ($line -notmatch '^\s*\|') { continue }
                $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
                if ($cells.Count -lt 4) { continue }
                if ($cells[0] -match '^-+$' -or $cells[0] -eq '#') { continue }
                if (-not $cells[1]) { continue }
                $rows += , $cells
            }

            if ($rows.Count -lt $bullets.Count) {
                Add-Failure 'trace' "Requirement trace has $($rows.Count) rows but requirement.md has $($bullets.Count) bullets. Every bullet needs a row."
            }

            $done = 0; $notDone = 0
            foreach ($row in $rows) {
                $label = "trace row $($row[0]) '$($row[1])'"
                $rowStatus = $row[2]
                if ($rowStatus -match '^DONE\b') {
                    $done++
                    $refs = [regex]::Matches($row[3], '([A-Za-z0-9_./\\-]+\.(apx|sql|pks|pkb|css|js|md)):(\d+)')
                    if ($refs.Count -eq 0) {
                        Add-Failure 'trace' "$label is DONE but has no file:line evidence."
                    }
                    foreach ($ref in $refs) {
                        $refPath = $ref.Groups[1].Value
                        $refLine = [int]$ref.Groups[3].Value
                        $candidates = @(
                            (Join-Path $project $refPath),
                            (Join-Path $repoRoot $refPath),
                            (Join-Path $appDir $refPath),
                            (Join-Path $dbDir $refPath)
                        )
                        $resolved = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
                        if (-not $resolved) {
                            Add-Failure 'trace' "$label cites $refPath, which does not exist."
                            continue
                        }
                        $refLines = (Read-Text $resolved).Split("`n")
                        $count = $refLines.Length
                        if ($refLine -lt 1 -or $refLine -gt $count) {
                            Add-Failure 'trace' "$label cites line $refLine of $refPath, which has $count lines."
                            continue
                        }
                        # The cited line must be the implementation, not a brace, fence, or layout key.
                        $cited = $refLines[$refLine - 1].Trim()
                        if ($cited -match '^([{}()\[\],;]*|```\w*|[\w-]+\s*[{(]|slot:\s*\S+|sequence:\s*\d+|(end|begin)\s*;?)$') {
                            Add-Failure 'trace' "$label cites ${refPath}:$refLine, which is '$cited', a structural line. Cite the line that implements the requirement."
                            continue
                        }
                        # Something near the cited line must mention what the requirement asks for.
                        $window = ($refLines[([Math]::Max(0, $refLine - 4))..([Math]::Min($count - 1, $refLine + 14))] -join "`n").ToLowerInvariant()
                        $strong = @([regex]::Matches($row[1], '`([^`]+)`|#[0-9A-Fa-f]{6}\b|\bP\d+_\w+|\bfa-[a-z0-9-]+|\b\w+_api\.\w+') |
                                ForEach-Object { if ($_.Groups[1].Success) { $_.Groups[1].Value } else { $_.Value } } |
                                ForEach-Object { $_.ToLowerInvariant(); ($_ -split '\.')[-1].ToLowerInvariant() } | Sort-Object -Unique)
                        $words = @([regex]::Matches($row[1].ToLowerInvariant(), '[a-z]{4,}') | ForEach-Object { $_.Value } |
                                Where-Object { $_ -notmatch '^(page|pages|type|normal|with|from|that|this|only|have|when|each|into|which|their|they|them|show|shows|plus|will|must|item|items|region|regions|button|buttons|action|actions|default|optional|required|done|than|also|does|uses|used)$' } |
                                ForEach-Object { if ($_.Length -gt 5) { $_.Substring(0, 5) } else { $_ } } | Sort-Object -Unique)
                        $relevant = if ($strong.Count -eq 0 -and $words.Count -eq 0) { $true } elseif ($strong.Count -gt 0) { @($strong | Where-Object { $window.Contains($_) }).Count -gt 0 } else { @($words | Where-Object { $window.Contains($_) }).Count -gt 0 }
                        if (-not $relevant) {
                            $expected = if ($strong.Count -gt 0) { $strong -join ', ' } else { $words -join ', ' }
                            Add-Failure 'trace' "$label cites ${refPath}:$refLine, but nothing within 15 lines mentions it (looked for: $expected). Cite the code that implements it, or mark it NOT DONE."
                        }
                    }
                }
                elseif ($rowStatus -match '^NOT DONE\s*:\s*\S') {
                    $notDone++
                    Add-Warning 'trace' "$label is $rowStatus"
                }
                else {
                    Add-Failure 'trace' "$label has status '$rowStatus'; use DONE (with file:line) or NOT DONE: <reason>."
                }
            }
            Write-Host "Trace:    $($rows.Count) rows for $($bullets.Count) requirement bullets ($done DONE, $notDone NOT DONE)"
        }
    }
}

# --- 2. Design fidelity ------------------------------------------------------
if ($apxFiles.Count -eq 0) {
    Add-Warning 'design' 'No .apx files; design checks skipped.'
}
else {
    # 2a. Requirement brand colours must reach brand.css and brand.css must load app-wide.
    if (-not $requirementIsTemplate) {
        $hexes = @([regex]::Matches($requirement, '#[0-9A-Fa-f]{6}\b') | ForEach-Object { $_.Value.ToUpperInvariant() } | Sort-Object -Unique)
        if ($hexes.Count -gt 0) {
            if (-not $hasBrandCss) {
                Add-Failure 'design' "requirement.md specifies colours ($($hexes -join ', ')) but app/shared-components/static-files/css/brand.css does not exist. See skills/apex-design-system/references/brand-layer.md."
            }
            else {
                foreach ($hex in $hexes) {
                    if ($brandCss.ToUpperInvariant().IndexOf($hex) -lt 0) {
                        Add-Failure 'design' "Requirement colour $hex is not defined in brand.css."
                    }
                }
            }
        }

        $keywords = @(
            @{ Word = 'pill'; Evidence = 'pill'; Hint = 't-Badge--pill or a brand pill class' },
            @{ Word = 'shadow'; Evidence = 'shadow'; Hint = 'a box-shadow token or shadow template option' },
            @{ Word = 'floating'; Evidence = 'floating'; Hint = '@/optional-floating / @/required-floating labels' },
            @{ Word = 'badge'; Evidence = 'badge'; Hint = 'Badge template component, badge column, or t-Badge' },
            @{ Word = 'gradient'; Evidence = 'gradient'; Hint = 'a gradient in brand.css' },
            @{ Word = 'rounded|radius'; Evidence = 'radius'; Hint = 'a border-radius token' },
            @{ Word = 'dark mode|dark-mode'; Evidence = 'prefers-color-scheme|vita-dark|data-theme'; Hint = 'dark-mode token overrides' },
            @{ Word = 'chart'; Evidence = 'type:\s*chart\b'; Hint = 'a chart region (type: chart)' },
            @{ Word = 'live\b[^.\n]{0,40}clock|ticking clock|clock that ticks'; Label = 'live clock'; Evidence = 'setInterval|setTimeout|requestAnimationFrame'; Hint = 'page JavaScript that updates the clock on a timer' },
            @{ Word = 'confirm'; Evidence = 'requiresConfirmation:\s*true|confirmation\s*\{|apex\.(message\.)?confirm'; Hint = 'requiresConfirmation: true with a confirmation { message } block' },
            @{ Word = 'spinner'; Evidence = 'spinner|showSpinner|is-processing|aria-busy'; Hint = 'a loading state (apex.util.showSpinner or a brand spinner class)' },
            @{ Word = 'legend'; Evidence = 'legend'; Hint = 'a visible legend region or list' }
        )
        $jsText = ''
        if (Test-Path -LiteralPath $appDir) {
            $jsText = ((Get-ChildItem -LiteralPath $appDir -Recurse -File -Filter '*.js' | ForEach-Object { Read-Text $_.FullName }) -join "`n")
        }
        $evidenceText = $apxText + "`n" + $brandCss + "`n" + $jsText
        foreach ($keyword in $keywords) {
            $asked = @($requirement.Split("`n") | Where-Object {
                    $_ -match "(?i)\b($($keyword.Word))" -and $_ -notmatch '(?i)not (required|needed|wanted)|\bnone\b|:\s*no\b'
                })
            if ($asked.Count -gt 0 -and -not [regex]::IsMatch($evidenceText, "(?i)$($keyword.Evidence)")) {
                $label = if ($keyword.Label) { $keyword.Label } else { $keyword.Word }
                Add-Failure 'design' "requirement.md asks for '$label' but the build has no evidence of it (expected $($keyword.Hint))."
            }
        }
    }

    if ($hasBrandCss) {
        $appApx = Join-Path $appDir 'application.apx'
        if (-not ((Test-Path -LiteralPath $appApx) -and (Read-Text $appApx) -match 'css/brand(\.min)?\.css')) {
            Add-Failure 'design' 'brand.css exists but application.apx does not load it (css { fileUrls: #APP_FILES#css/brand.css?v=#APP_VERSION# }).'
        }
        if ((Read-Text $appApx) -match 'css/brand#MIN#\.css' -and -not (Test-Path -LiteralPath (Join-Path $appDir 'shared-components\static-files\css\brand.min.css'))) {
            Add-Failure 'design' 'application.apx loads brand#MIN#.css but brand.min.css does not exist; the page would request a missing file.'
        }
        $staticApx = Join-Path $appDir 'shared-components\static-files.apx'
        if (-not ((Test-Path -LiteralPath $staticApx) -and (Read-Text $staticApx) -match 'file\s+"css/brand\.css"')) {
            Add-Failure 'design' 'brand.css is not registered in shared-components/static-files.apx.'
        }

        $cssLines = $brandCss.Split("`n")
        $inComment = $false
        for ($i = 0; $i -lt $cssLines.Length; $i++) {
            $line = $cssLines[$i]
            if ($line -match '/\*') { $inComment = $true }
            $code = if ($inComment) { '' } else { $line }
            if ($line -match '\*/') { $inComment = $false; $code = ($line -split '\*/', 2)[1] }
            if ($code -match '#[0-9A-Fa-f]{3,8}\b' -and $code -notmatch '^\s*--brand-[a-z0-9-]+\s*:') {
                Add-Failure 'design' "brand.css:$($i + 1) uses a hex colour outside a --brand-* token declaration."
            }
        }
    }

    # 2b. No inline styles, inline handlers, javascript: URLs, or hex colours in .apx.
    $inlineStyle = @(Find-Lines $apxFiles '(?i)\sstyle\s*=\s*["'']')
    if ($inlineStyle.Count) { Add-Failure 'design' "Inline style= in .apx; move it to brand.css and attach a class: $(Format-Hits $inlineStyle)" }
    $handlers = @(Find-Lines $apxFiles '(?i)\son(click|change|load|submit|mouse\w+|key\w+|focus|blur)\s*=\s*["'']')
    if ($handlers.Count) { Add-Failure 'design' "Inline event handler in .apx; use a Dynamic Action: $(Format-Hits $handlers)" }
    $jsUrls = @(Find-Lines $apxFiles '(?i)javascript:')
    if ($jsUrls.Count) { Add-Failure 'design' "javascript: URL in .apx: $(Format-Hits $jsUrls)" }
    $apxHex = @(Find-Lines $apxFiles '#[0-9A-Fa-f]{6}\b')
    if ($apxHex.Count) { Add-Failure 'design' "Hex colour in .apx; brand colours belong in the brand.css token block: $(Format-Hits $apxHex)" }
    $fakeStats = @(Find-Lines $apxFiles "(?i):P\d+_\w*(STAT|AVG|TOTAL|RATE|COUNT|KPI|SUM|PCT|MINS)\w*\s*:=\s*'?\d*[1-9][\d\s:.,%]*'?\s*;")
    if ($fakeStats.Count) { Add-Failure 'design' "Statistic item assigned a hard-coded value; compute it from data or remove the tile: $(Format-Hits $fakeStats)" }

    # 2b2. A hero region renders a large empty icon box unless it has an image or hides the icon.
    foreach ($file in $apxFiles) {
        $lines = (Read-Text $file.FullName).Split("`n")
        for ($i = 0; $i -lt $lines.Length; $i++) {
            if ($lines[$i] -notmatch '^\s*template:\s*@/hero\s*$') { continue }
            $start = $i
            while ($start -gt 0 -and $lines[$start] -notmatch '^(\s*)region\s+\S+\s*\(') { $start-- }
            $indent = ([regex]::Match($lines[$start], '^\s*')).Value
            $end = $i
            while ($end -lt $lines.Length - 1 -and $lines[$end] -ne "$indent)") { $end++ }
            $block = $lines[$start..$end] -join "`n"
            if ($block -notmatch '(?m)^\s*(fileUrl|iconClasses|icon):' -and $block -notmatch 't-HeroRegion--hideIcon') {
                Add-Failure 'design' "Hero region at $(Get-RelativePath $file.FullName):$($start + 1) has no image or icon and does not set t-HeroRegion--hideIcon; it renders an empty icon box."
            }
        }
    }

    # 2b3. The text-only button template ignores icon:; the icon silently disappears at runtime.
    $silentIcons = @()
    foreach ($file in $apxFiles) {
        $lines = (Read-Text $file.FullName).Split("`n")
        for ($i = 0; $i -lt $lines.Length; $i++) {
            if ($lines[$i] -notmatch '^(\s*)buttonTemplate:\s*@/text\s*$') { continue }
            $j = $i
            while ($j -gt 0 -and $lines[$j] -notmatch '^\s*appearance\s*\{') { $j-- }
            $indent = ([regex]::Match($lines[$j], '^\s*')).Value
            $k = $i
            while ($k -lt $lines.Length - 1 -and $lines[$k] -ne "$indent}") { $k++ }
            if (($lines[$j..$k] -join "`n") -match '(?m)^\s*icon:\s*\S') {
                $silentIcons += ('{0}:{1}' -f (Get-RelativePath $file.FullName), ($i + 1))
            }
        }
    }
    if ($silentIcons.Count) {
        Add-Failure 'design' "Button sets icon: with buttonTemplate @/text, which does not render icons; use @/text-with-icon (with t-Button--iconLeft/iconRight) or @/icon: $(Format-Hits $silentIcons)"
    }

    # 2c. brand-* classes: used => defined; defined => used.
    $used = @([regex]::Matches($apxText, '(?<![-\w])brand-[a-z0-9][a-z0-9-]*') | ForEach-Object { $_.Value } | Sort-Object -Unique)
    $defined = @([regex]::Matches($brandCss, '\.(brand-[a-z0-9][a-z0-9-]*)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    foreach ($class in $used) {
        if ($defined -notcontains $class) { Add-Failure 'design' "Class '$class' is used in .apx but not defined in brand.css." }
    }
    foreach ($class in $defined) {
        if ($used -notcontains $class) { Add-Warning 'design' "Class '$class' is defined in brand.css but never used." }
    }

    # 2d. Every Font APEX icon must exist in the version's icon index.
    $version = '26.1'
    $versionFile = Join-Path $appDir '.apex\apexlang.json'
    if (Test-Path -LiteralPath $versionFile) {
        $mmd = [string](Get-Content -LiteralPath $versionFile -Raw | ConvertFrom-Json).mmdVersion
        if ($mmd -match '^(\d+\.\d+)') { $version = $Matches[1] }
    }
    $indexPath = Join-Path $repoRoot "skills\apex\apexlang\$version\apexlang-generation\assets\indexes\font-apex-icon-index.json"
    if (-not (Test-Path -LiteralPath $indexPath)) {
        $indexPath = Join-Path $repoRoot 'skills\apex\apexlang\26.1\apexlang-generation\assets\indexes\font-apex-icon-index.json'
        Add-Warning 'design' "No Font APEX index for $version; checked icons against the 26.1 index."
    }
    $icons = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($icon in (Get-Content -LiteralPath $indexPath -Raw | ConvertFrom-Json).icons) { [void]$icons.Add([string]$icon) }
    $modifier = '^fa-(lg|[2-5]x|fw|spin|pulse|border|inverse|li|ul|stack(-[12]x)?|pull-(left|right)|rotate-\d+|flip-\w+|anim-[\w-]+|sm|xs|s?x?l)$'
    $badIcons = @()
    foreach ($file in @($apxFiles) + @($dbFiles)) {
        $lines = (Read-Text $file.FullName).Split("`n")
        for ($i = 0; $i -lt $lines.Length; $i++) {
            foreach ($m in [regex]::Matches($lines[$i], '(?<![\w-])fa-[a-z0-9]+(-[a-z0-9]+)*')) {
                if (-not $icons.Contains($m.Value) -and $m.Value -notmatch $modifier) {
                    $badIcons += ('{0} at {1}:{2}' -f $m.Value, (Get-RelativePath $file.FullName), ($i + 1))
                }
            }
        }
    }
    foreach ($bad in ($badIcons | Sort-Object -Unique)) {
        Add-Failure 'design' "Unknown Font APEX icon (renders blank): $bad"
    }

    # 2e. Styling columns exposed by views must be consumed by a page.
    foreach ($file in $dbFiles) {
        $text = Read-Text $file.FullName
        foreach ($view in [regex]::Matches($text, '(?is)CREATE\s+(OR\s+REPLACE\s+)?(FORCE\s+)?VIEW\s+(\w+)\s+AS(.*?)(;|\n/\s*\n)')) {
            $viewName = $view.Groups[3].Value
            $cols = @([regex]::Matches($view.Groups[4].Value, '(?i)\bAS\s+([a-z_][a-z0-9_]*)\s*(,|\n|$)') | ForEach-Object { $_.Groups[1].Value.ToLowerInvariant() }) +
                    @([regex]::Matches($view.Groups[4].Value, '(?i)\b\w+\.([a-z_][a-z0-9_]*)\s*(,|\n)') | ForEach-Object { $_.Groups[1].Value.ToLowerInvariant() })
            foreach ($col in ($cols | Where-Object { $_ -match '(css|class|icon|colou?r|badge)' } | Sort-Object -Unique)) {
                if (-not [regex]::IsMatch($apxText, "(?i)\b$col\b")) {
                    Add-Failure 'design' "View $viewName exposes styling column '$col' but no page uses it ($(Get-RelativePath $file.FullName))."
                }
            }
        }
    }
}

# --- 3. PL/SQL wiring --------------------------------------------------------
$specs = @($dbFiles | Where-Object { $_.Extension -eq '.pks' })
if ($specs.Count -gt 0) {
    $testsDir = Join-Path $dbDir 'tests'
    $testFiles = @()
    if (Test-Path -LiteralPath $testsDir) { $testFiles = @(Get-ChildItem -LiteralPath $testsDir -Recurse -File -Filter '*.sql') }
    if ($testFiles.Count -eq 0) {
        Add-Failure 'plsql' 'Packages exist but database/tests/ has no test scripts. Every business rule needs a test.'
    }

    $sources = @{}
    foreach ($file in @($apxFiles) + @($dbFiles)) { $sources[$file.FullName] = Read-Text $file.FullName }
    $contracts = @{}

    foreach ($spec in $specs) {
        $specText = $sources[$spec.FullName]
        $packageMatch = [regex]::Match($specText, '(?i)PACKAGE\s+(\w+)')
        $package = if ($packageMatch.Success) { $packageMatch.Groups[1].Value } else { $spec.BaseName }
        $contracts[$package.ToLowerInvariant()] = Get-PackageContract $specText
        $names = @([regex]::Matches($specText, '(?im)^\s*(FUNCTION|PROCEDURE)\s+(\w+)') | ForEach-Object { $_.Groups[2].Value.ToLowerInvariant() } | Sort-Object -Unique)
        foreach ($name in $names) {
            $appRefs = 0; $testRefs = 0
            foreach ($path in $sources.Keys) {
                if ($path -eq $spec.FullName) { continue }
                $text = $sources[$path]
                $count = [regex]::Matches($text, "(?i)\b$name\b").Count
                $count -= [regex]::Matches($text, "(?im)^\s*(FUNCTION|PROCEDURE)\s+$name\b").Count
                $count -= [regex]::Matches($text, "(?i)\bEND\s+$name\s*;").Count
                if ($count -le 0) { continue }
                if ($testFiles | Where-Object { $_.FullName -eq $path }) { $testRefs += $count } else { $appRefs += $count }
            }
            if ($appRefs -eq 0 -and $testRefs -eq 0) {
                Add-Failure 'plsql' "$package.$name is public but never called. Wire it into the app/APIs or remove it."
            }
            elseif ($appRefs -eq 0) {
                Add-Warning 'plsql' "$package.$name is only called by tests; confirm the app enforces what it checks."
            }
        }
    }

    # 3b. Call contract. apex validate does not compile embedded PL/SQL, so a call that does not
    #     match the spec (PLS-00221/00222/00302/00306/00363) otherwise surfaces only at runtime.
    $statementTail = '(?i)(;|```plsql|plsqlCode:|\b(begin|then|else|loop|exec|execute|call))$'
    foreach ($path in $sources.Keys) {
        if ($specs | Where-Object { $_.FullName -eq $path }) { continue }
        $clean = Remove-PlsqlNoise $sources[$path]
        foreach ($package in $contracts.Keys) {
            $contract = $contracts[$package]
            foreach ($m in [regex]::Matches($clean, '(?i)(?<![\w$#])' + $package + '\.(\w+)')) {
                $member = $m.Groups[1].Value.ToLowerInvariant()
                $where = '{0}:{1}' -f (Get-RelativePath $path), $clean.Substring(0, $m.Index).Split("`n").Length
                if (-not $contract.Subs.ContainsKey($member)) {
                    if (-not [regex]::IsMatch($contract.Clean, "(?i)\b$member\b")) {
                        Add-Failure 'plsql' "$where references $package.$member, which the $package spec does not declare (PLS-00302)."
                    }
                    continue
                }

                $pos = $m.Index + $m.Length
                while ($pos -lt $clean.Length -and [char]::IsWhiteSpace($clean[$pos])) { $pos++ }
                $callArgs = @()
                if ($pos -lt $clean.Length -and $clean[$pos] -eq '(') {
                    $close = Get-ClosingParen $clean $pos
                    if ($close -lt 0) { continue }
                    $callArgs = @(Split-TopLevel $clean.Substring($pos + 1, $close - $pos - 1))
                    $pos = $close + 1
                    while ($pos -lt $clean.Length -and [char]::IsWhiteSpace($clean[$pos])) { $pos++ }
                }
                elseif ($pos -ge $clean.Length -or $clean[$pos] -ne ';') { continue } # a name reference such as authFunctionName:, not a call

                $before = ($clean.Substring(0, $m.Index).TrimEnd() -replace '\w+\.$', '').TrimEnd()
                $tail = $before.Substring([Math]::Max(0, $before.Length - 20))
                $isStatement = ($pos -lt $clean.Length -and $clean[$pos] -eq ';') -and ($before.Length -eq 0 -or [regex]::IsMatch($tail, $statementTail))
                $overloads = @($contract.Subs[$member])
                $kinds = @($overloads | ForEach-Object { $_.Kind })
                if ($isStatement -and $kinds -notcontains 'PROCEDURE') {
                    Add-Failure 'plsql' "$where calls function $package.$member as a statement (PLS-00221). Use its return value, e.g. l_result := $package.$member(...);"
                    continue
                }
                if (-not $isStatement -and $kinds -notcontains 'FUNCTION') {
                    Add-Failure 'plsql' "$where uses procedure $package.$member as an expression (PLS-00222). Call it as a statement."
                    continue
                }

                $named = @(); $positional = 0; $argText = @{}
                foreach ($arg in $callArgs) {
                    $nm = [regex]::Match($arg, '^(\w+)\s*=>\s*([\s\S]*)$')
                    if ($nm.Success) { $key = $nm.Groups[1].Value.ToLowerInvariant(); $named += $key; $argText[$key] = $nm.Groups[2].Value.Trim() }
                    else { $positional++ }
                }
                $wanted = if ($isStatement) { 'PROCEDURE' } else { 'FUNCTION' }
                $fits = $false; $problem = ''
                foreach ($overload in ($overloads | Where-Object { $_.Kind -eq $wanted })) {
                    $names = @($overload.Params | ForEach-Object { $_.Name })
                    $unknown = @($named | Where-Object { $names -notcontains $_ })
                    if ($unknown.Count) { $problem = "has no parameter $($unknown -join ', ')"; continue }
                    if ($positional + $named.Count -gt $names.Count) { $problem = "takes $($names.Count) argument(s) but the call passes $($positional + $named.Count)"; continue }
                    $covered = @($names | Select-Object -First $positional) + $named
                    $missing = @($overload.Params | Where-Object { -not $_.Optional -and $covered -notcontains $_.Name } | ForEach-Object { $_.Name })
                    if ($missing.Count) { $problem = "is called without required argument(s) $($missing -join ', ')"; continue }
                    $badOut = @($overload.Params | Where-Object { $_.Mode -ne 'IN' -and $argText.ContainsKey($_.Name) -and $argText[$_.Name] -notmatch '^:?[\w.$#]+$' } | ForEach-Object { $_.Name })
                    if ($badOut.Count) { $problem = "passes an expression to OUT parameter(s) $($badOut -join ', ') (PLS-00363)"; continue }
                    $fits = $true; break
                }
                if (-not $fits) {
                    Add-Failure 'plsql' "$where : $package.$member $problem (PLS-00306). Match the call to the spec."
                }
            }
        }
    }
}

# --- Report ------------------------------------------------------------------
Write-Host ''
if ($script:warnings.Count -gt 0) {
    Write-Host "Warnings ($($script:warnings.Count))" -ForegroundColor Yellow
    foreach ($warning in $script:warnings) { Write-Host "  - $warning" -ForegroundColor Yellow }
    Write-Host ''
}
if ($script:failures.Count -gt 0) {
    Write-Host "DELIVERY GATE FAIL ($($script:failures.Count) blocking)" -ForegroundColor Red
    foreach ($failure in $script:failures) { Write-Host "  - $failure" -ForegroundColor Red }
    exit 1
}
if ($Strict -and $script:warnings.Count -gt 0) {
    Write-Host 'DELIVERY GATE FAIL (-Strict treats warnings as errors)' -ForegroundColor Red
    exit 1
}
Write-Host 'DELIVERY GATE PASS' -ForegroundColor Green
exit 0
