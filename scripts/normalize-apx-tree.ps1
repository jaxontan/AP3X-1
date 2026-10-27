[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$AppDirectory
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $AppDirectory -PathType Container)) {
    Write-Error "Application directory does not exist: $AppDirectory"
    exit 2
}

$resolved = (Resolve-Path $AppDirectory).Path
$files = @(Get-ChildItem $resolved -Recurse -File -Filter '*.apx')
$changed = 0
$scanned = 0

foreach ($file in $files) {
    $scanned++
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    if ($bytes -notcontains 13) {
        continue
    }

    $output = New-Object System.Collections.Generic.List[byte]
    for ($i = 0; $i -lt $bytes.Length; $i++) {
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

    if ($PSCmdlet.ShouldProcess($file.FullName, 'Convert CRLF to LF')) {
        [System.IO.File]::WriteAllBytes($file.FullName, $output.ToArray())
        $changed++
    }
}

Write-Host ("Scanned {0} .apx file(s); normalized {1} to LF." -f $scanned, $changed) -ForegroundColor Green
exit 0
