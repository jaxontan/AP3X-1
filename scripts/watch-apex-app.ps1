param(
    [Parameter(Position = 0)]
    [string]$AppDirectory = 'working/app'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$targetDir = (Resolve-Path (Join-Path $root $AppDirectory)).Path

if (-not (Test-Path $targetDir)) {
    Write-Error "Target application directory not found: $targetDir"
    exit 1
}

Write-Host "Watching for changes in $targetDir (*.apx)..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop watching." -ForegroundColor DarkGray

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $targetDir
$watcher.Filter = "*.apx"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$lastRun = [DateTime]::MinValue
$debounceSeconds = 2

$action = {
    $now = [DateTime]::Now
    if (($now - $lastRun).TotalSeconds -lt $debounceSeconds) {
        return
    }
    $script:lastRun = $now

    Clear-Host
    Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Change detected in $($Event.SourceEventArgs.Name). Validating..." -ForegroundColor Yellow

    try {
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/normalize-apx-tree.ps1') -AppDirectory $targetDir
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/validate-apex-app.ps1') -AppDirectory $targetDir
    }
    catch {
        Write-Host "Validation failed with error: $_" -ForegroundColor Red
    }
}

Register-ObjectEvent $watcher 'Changed' -Action $action | Out-Null
Register-ObjectEvent $watcher 'Created' -Action $action | Out-Null

try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
}
finally {
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    Get-EventSubscriber | Where-Object { $_.SourceIdentifier -match 'FileSystemWatcher' } | Unregister-Event
    Write-Host "`nStopped watching." -ForegroundColor Cyan
}
