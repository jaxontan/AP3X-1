[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Archive
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$working = Join-Path $repoRoot 'working'

if ($Archive) {
    $archiveDir = Join-Path $repoRoot ("archive\project-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    Write-Host "Archiving current working/ to $archiveDir..." -ForegroundColor Cyan
    Copy-Item -Path "$working\*" -Destination $archiveDir -Recurse -Force
}

Write-Host "Cleaning working directory..." -ForegroundColor Yellow

# Clean app and database
Remove-Item -LiteralPath (Join-Path $working 'app') -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $working 'database') -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $working 'page-design\credentials.md') -Force -ErrorAction SilentlyContinue

# Reset page-design files from templates:
#   requirement.md         - user-owned intent (reset to the blank starter)
#   application-design.md  - agent-owned technical design (removed; the agent regenerates it)
$templates = Join-Path $repoRoot 'docs/templates'
$pageDesign = Join-Path $working 'page-design'
New-Item -ItemType Directory -Path $pageDesign -Force | Out-Null

Remove-Item -LiteralPath (Join-Path $pageDesign 'application-design.md') -Force -ErrorAction SilentlyContinue

$stray = Join-Path $pageDesign 'requirements.md'
if (Test-Path -LiteralPath $stray) {
    Write-Warning "Removing stray working/page-design/requirements.md. The only user file is requirement.md (singular)."
    Remove-Item -LiteralPath $stray -Force
}

$reqTemplate = Join-Path $templates 'requirement.template.md'
if (-not (Test-Path -LiteralPath $reqTemplate)) {
    throw "Missing template: $reqTemplate"
}
$template = [System.IO.File]::ReadAllText($reqTemplate).Replace("`r`n", "`n")
$reqPath = Join-Path $pageDesign 'requirement.md'
[System.IO.File]::WriteAllText($reqPath, $template.TrimEnd() + "`n", (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Reset complete. Describe your app in working/page-design/requirement.md; the agent will write application-design.md for your approval." -ForegroundColor Green
