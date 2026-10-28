[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$AppDirectory
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $AppDirectory -PathType Container)) {
    Write-Error "Application directory does not exist: $AppDirectory" -ErrorAction Continue
    exit 2
}

$resolved = (Resolve-Path $AppDirectory).Path
$files = @(Get-ChildItem $resolved -Recurse -File -Filter '*.apx')
$changed = 0
$scanned = 0
$bomStripped = 0
$utf16Files = @()

foreach ($file in $files) {
    $scanned++
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)

    if ($bytes.Length -ge 2 -and (($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) -or ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF))) {
        $utf16Files += $file.FullName
        continue
    }

    $start = 0
    $hasUtf8Bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    if ($hasUtf8Bom) {
        $start = 3
    }

    $hasCr = $false
    for ($i = $start; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -eq 13) {
            $hasCr = $true
            break
        }
    }

    if (-not $hasUtf8Bom -and -not $hasCr) {
        continue
    }

    $output = New-Object System.Collections.Generic.List[byte]
    for ($i = $start; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -eq 13) {
            if (($i + 1) -lt $bytes.Length -and $bytes[$i + 1] -eq 10) {
                continue
            }
            $output.Add(10)
        }
        else {
            $output.Add($bytes[$i])
        }
    }

    if ($PSCmdlet.ShouldProcess($file.FullName, 'Convert to UTF-8 without BOM and LF endings')) {
        [System.IO.File]::WriteAllBytes($file.FullName, $output.ToArray())
        $changed++
        if ($hasUtf8Bom) {
            $bomStripped++
        }
    }
}

if ($utf16Files.Count -gt 0) {
    Write-Host 'UTF-16 .apx files cannot be normalized byte-for-byte. Save these files as UTF-8 and re-run:' -ForegroundColor Red
    $utf16Files | ForEach-Object { Write-Host "  $_" }
    exit 2
}

Write-Host ("Scanned {0} .apx file(s); normalized {1} to LF and removed a BOM from {2}." -f $scanned, $changed, $bomStripped) -ForegroundColor Green
exit 0
