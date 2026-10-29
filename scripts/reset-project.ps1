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

# Reset requirement.md template
$template = @"
# Application Page Design & Requirements

<!-- 
Describe your application pages and requirements below.
The AI assistant will strictly follow this architecture rather than inventing its own.
-->

## 1. Overview & Business Intent
- **Application Name**: [e.g. Customer Portal / Inventory Tracker]
- **Target Audience & Roles**: [e.g. Staff, Manager, Administrator]
- **Core Purpose**: [What problem does this application solve?]

---

## 2. Page Map & Layout Design

### Page 1: Home / Dashboard
- **Page Type**: Normal Page
- **Authorization**: Public / Authenticated
- **Regions & Components**:
  - Summary metrics or navigation cards
  - Quick-start action links

### Page 10: [Main Report / Queue]
- **Page Type**: Interactive Report / Classic Report
- **Authorization**: [e.g. Staff or Manager]
- **Regions & Components**:
  - Report table showing key records
  - Filter items or search bar
- **Buttons & Actions**:
  - "Create New" button redirecting to Page 11

### Page 11: [Entry Form / Details Dialog]
- **Page Type**: Modal Dialog Form
- **Authorization**: [e.g. Staff]
- **Form Fields / Page Items**:
  - [Field 1: Name, Type, Required/Optional]
  - [Field 2: Amount / Category LOV]
- **Buttons & Processes**:
  - "Cancel" button (close dialog)
  - "Submit" / "Save" button (triggers database package call)

---

## 3. Business Rules & Validations
- **Rule 1**: [e.g. Fields A and B are mandatory before submission]
- **Rule 2**: [e.g. Approval threshold or state transition rules]
- **Rule 3**: [e.g. Rejections require a mandatory explanation]
"@

$reqPath = Join-Path $working 'page-design\requirement.md'
[System.IO.File]::WriteAllText($reqPath, $template.TrimEnd() + "`n", (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Reset complete. Ready for new project design in working/page-design/requirement.md" -ForegroundColor Green
