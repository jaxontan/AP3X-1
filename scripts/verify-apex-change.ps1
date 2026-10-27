[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$AppDirectory,

    [string]$BaseRef = 'HEAD',

    [switch]$Strict
)

$ErrorActionPreference = 'Stop'

$script:failures = @()
$script:warnings = @()

function Add-Failure {
    param([string]$Message)
    $script:failures += $Message
}

function Add-Warning {
    param([string]$Message)
    $script:warnings += $Message
}

function Test-PathWithin {
    param(
        [string]$Path,
        [string]$Parent
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    $fullParent = [System.IO.Path]::GetFullPath($Parent).TrimEnd('\', '/')
    if ($fullPath.Equals($fullParent, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    return $fullPath.StartsWith(
        $fullParent + [System.IO.Path]::DirectorySeparatorChar,
        [System.StringComparison]::OrdinalIgnoreCase
    )
}

function Get-AddedLines {
    param(
        [string]$RepoRoot,
        [string]$RelativePath,
        [string]$Reference,
        [bool]$Tracked
    )

    if (-not $Tracked) {
        return @(Get-Content -LiteralPath (Join-Path $RepoRoot $RelativePath) -Encoding UTF8)
    }

    $diff = & git -C $RepoRoot diff -U0 $Reference -- $RelativePath 2>$null
    if ($LASTEXITCODE -ne 0) {
        return @()
    }

    return @(
        $diff |
            Where-Object { $_ -match '^\+' -and $_ -notmatch '^\+\+\+' } |
            ForEach-Object { $_.Substring(1) }
    )
}

$repoRoot = & git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
    Write-Error 'Not inside a Git repository.'
    exit 2
}
$repoRoot = [System.IO.Path]::GetFullPath($repoRoot.Trim()).TrimEnd('\', '/')

if ($AppDirectory) {
    if (-not (Test-Path -LiteralPath $AppDirectory -PathType Container)) {
        Write-Error "Application directory does not exist: $AppDirectory"
        exit 2
    }
    $appRoot = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $AppDirectory).Path).TrimEnd('\', '/')
    if (-not (Test-PathWithin -Path $appRoot -Parent $repoRoot)) {
        Write-Error "Application directory is outside the repository: $appRoot"
        exit 2
    }
}
else {
    $appRoot = $repoRoot
}

$tracked = @(& git -C $repoRoot ls-files)
$changed = @(
    & git -C $repoRoot diff --name-only --diff-filter=ACMRTUXB $BaseRef -- 2>$null
    & git -C $repoRoot ls-files --others --exclude-standard 2>$null
) | Where-Object { $_ } | Sort-Object -Unique

$files = @()
foreach ($relative in $changed) {
    $full = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $relative))
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        continue
    }
    if ($AppDirectory -and -not (Test-PathWithin -Path $full -Parent $appRoot)) {
        continue
    }
    $files += Get-Item -LiteralPath $full
}

Write-Host 'APEX change verification' -ForegroundColor Cyan
Write-Host "Repository: $repoRoot"
Write-Host "Base:       $BaseRef"
if ($AppDirectory) {
    Write-Host "App:        $appRoot"
}
Write-Host "Files:      $($files.Count)"
Write-Host ''

if ($files.Count -eq 0) {
    Write-Host 'No changed files to verify.' -ForegroundColor Green
    exit 0
}

$whitespace = & git -C $repoRoot diff --check $BaseRef -- 2>&1
if ($LASTEXITCODE -ne 0 -or $whitespace) {
    Add-Failure ("git diff --check reported whitespace errors:`n" + (($whitespace | Out-String).Trim()))
}

$sensitiveNames = @('.env', '*.pem', '*.key', '*.p12', '*.jks', 'cwallet.sso', 'ewallet.p12')
$textExtensions = @(
    '.apx', '.sql', '.plsql', '.pks', '.pkb', '.prc', '.fnc', '.trg',
    '.md', '.txt', '.ps1', '.cmd', '.json', '.jsonc', '.yml', '.yaml'
)
$sqlExtensions = @('.apx', '.sql', '.plsql', '.pks', '.pkb', '.prc', '.fnc', '.trg')

$hardSecretPatterns = @(
    @{ Name = 'private key'; Pattern = '-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----' },
    @{ Name = 'JDBC thin credentials'; Pattern = 'jdbc:oracle:thin:[^@\s]+/[^@\s]+@' },
    @{ Name = 'AWS access key'; Pattern = '\b(AKIA|ASIA)[0-9A-Z]{16}\b' },
    @{ Name = 'GitHub token'; Pattern = '\b(ghp_[0-9A-Za-z]{36}|github_pat_[0-9A-Za-z_]{20,})\b' },
    @{ Name = 'Slack token'; Pattern = '\bxox[baprs]-[0-9A-Za-z-]{10,}\b' },
    @{ Name = 'OpenAI-style key'; Pattern = '\bsk-[A-Za-z0-9]{20,}\b' },
    @{ Name = 'SQLCL_CONNECTION_STRING assignment'; Pattern = 'SQLCL_CONNECTION_STRING\s*=\s*["''][^"'']{8,}["'']' }
)

$softSecretPatterns = @(
    @{ Name = 'saved-connection password'; Pattern = '-savepwd\s+\S+/\S+@'; Message = 'Do not commit a connection command containing a password. Use a saved SQLcl connection.' },
    @{ Name = 'literal password assignment'; Pattern = '(?i)password\s*[:=]\s*["''][^"'']{4,}["'']'; Message = 'Review the password-like value; use a credential store, not source.' }
)

$sqlPatterns = @(
    @{ Name = 'swallowed exception'; Pattern = '(?i)\bWHEN\s+OTHERS\s+THEN\s+NULL\b'; Message = 'WHEN OTHERS THEN NULL hides failures. Log and RAISE or map to a user-safe error.' },
    @{ Name = 'dynamic SQL concatenation'; Pattern = '(?i)\bEXECUTE\s+IMMEDIATE\b[^\n;]*\|\|'; Message = 'Dynamic SQL concatenation needs DBMS_ASSERT and bound values; review for injection.' },
    @{ Name = 'destructive DDL'; Pattern = '(?i)\b(DROP|TRUNCATE)\s+(TABLE|USER|SCHEMA|TABLESPACE)\b'; Message = 'Destructive DDL requires explicit approval, a migration, and a rollback path.' },
    @{ Name = 'ALTER SYSTEM'; Pattern = '(?im)^\s*ALTER\s+SYSTEM\b'; Message = 'ALTER SYSTEM requires explicit DBA approval.' },
    @{ Name = 'GRANT to PUBLIC'; Pattern = '(?i)\bGRANT\b[^\n;]*\bTO\s+PUBLIC\b'; Message = 'Grants to PUBLIC broaden the attack surface; prefer a least-privilege role.' },
    @{ Name = 'DELETE without WHERE on this line'; Pattern = '(?i)^\s*DELETE\s+FROM\s+\S+\s*;?\s*$'; Message = 'Confirm the DELETE is bounded and reviewed; multi-line statements need manual review.' },
    @{ Name = 'UPDATE without WHERE on this line'; Pattern = '(?i)^\s*UPDATE\s+\S+\s+SET\b(?![^\n]*\bWHERE\b)'; Message = 'Confirm the UPDATE is bounded and reviewed; multi-line statements need manual review.' },
    @{ Name = 'transaction control in changed code'; Pattern = '(?i)^\s*(COMMIT|ROLLBACK)\s*;'; Message = 'Confirm transaction ownership; APEX page processes normally own the boundary.' },
    @{ Name = 'APEX v() context switch'; Pattern = "(?i)\bv\s*\(\s*'[A-Z0-9_]+'\s*\)"; Message = 'Prefer :ITEM binds in SQL and explicit parameters in PL/SQL packages.' }
)

foreach ($file in $files) {
    $relative = $file.FullName.Substring($repoRoot.Length).TrimStart('\', '/')
    $isTracked = $tracked -contains $relative
    $extension = $file.Extension.ToLowerInvariant()

    if ($file.Name -ne '.env.example') {
        foreach ($pattern in $sensitiveNames) {
            if ($file.Name -like $pattern) {
                Add-Failure "Sensitive file changed: $relative"
            }
        }
    }

    if ($extension -eq '.apx') {
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        if ($bytes -contains 13) {
            Add-Failure "APEXLang file uses CRLF: $relative. Run scripts/normalize-apx-tree.ps1."
        }
    }

    if ($textExtensions -contains $extension) {
        $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        foreach ($rule in $hardSecretPatterns) {
            if ([regex]::IsMatch($text, $rule.Pattern)) {
                Add-Failure "Potential $($rule.Name) in $relative"
            }
        }
        foreach ($rule in $softSecretPatterns) {
            if ([regex]::IsMatch($text, $rule.Pattern)) {
                Add-Warning "$($rule.Message) ($relative)"
            }
        }
    }

    if ($sqlExtensions -contains $extension) {
        $added = Get-AddedLines -RepoRoot $repoRoot -RelativePath $relative -Reference $BaseRef -Tracked $isTracked
        if ($added.Count -gt 0) {
            $addedText = $added -join "`n"
            foreach ($rule in $sqlPatterns) {
                if ([regex]::IsMatch($addedText, $rule.Pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)) {
                    Add-Warning "$($rule.Message) ($relative)"
                }
            }
        }
    }
}

if ($AppDirectory -and $appRoot -ne $repoRoot) {
    $versionFile = Join-Path $appRoot '.apex\apexlang.json'
    if (Test-Path -LiteralPath $versionFile) {
        try {
            $config = Get-Content -LiteralPath $versionFile -Raw -Encoding UTF8 | ConvertFrom-Json
            $version = [string]$config.mmdVersion
            if (-not $version) {
                Add-Failure "Missing mmdVersion in $versionFile"
            }
            elseif ($version -notmatch '^26\.(1|2)(\.|$)') {
                Add-Failure "Unsupported APEXLang version '$version'. This harness supports 26.1.x and 26.2.x."
            }
        }
        catch {
            Add-Failure "Invalid JSON in $versionFile : $($_.Exception.Message)"
        }
    }
    else {
        Add-Warning "No .apex/apexlang.json under $appRoot; version lock was not verified."
    }
}

Write-Host ''
if ($script:warnings.Count -gt 0) {
    Write-Host "Warnings ($($script:warnings.Count))" -ForegroundColor Yellow
    foreach ($warning in $script:warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
    Write-Host ''
}

if ($script:failures.Count -gt 0) {
    Write-Host "FAIL ($($script:failures.Count) errors)" -ForegroundColor Red
    foreach ($failure in $script:failures) {
        Write-Host "  - $failure" -ForegroundColor Red
    }
    exit 1
}

if ($Strict -and $script:warnings.Count -gt 0) {
    Write-Host 'FAIL (-Strict treats warnings as errors)' -ForegroundColor Red
    exit 1
}

Write-Host 'PASS: no blocking issues found.' -ForegroundColor Green
if ($script:warnings.Count -gt 0) {
    Write-Host 'Review the warnings above before deployment.' -ForegroundColor Yellow
}
exit 0
