# Dot-source this file to install Windows prerequisites without winget.
#
# Windows Sandbox, LTSC, Server, and some locked-down corporate images ship
# without winget (App Installer). Install-WithoutWinget downloads the vendor's
# official installer for a winget package ID and runs it silently.

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-InstallerArch {
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') { return 'arm64' }
    return 'x64'
}

function Save-InstallerDownload {
    param([string]$Url, [string]$FileName)

    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $directory = Join-Path ([IO.Path]::GetTempPath()) ('apex-harness-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $path = Join-Path $directory $FileName

    Write-Host "  Downloading $Url" -ForegroundColor DarkGray
    $previousProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $Url -OutFile $path -UseBasicParsing
    }
    finally {
        $ProgressPreference = $previousProgress
    }
    return $path
}

# Runs an installer and waits; asks for elevation (UAC) when not already an administrator.
function Start-SilentInstaller {
    param([string]$File, [string]$Arguments)

    $options = @{ FilePath = $File; ArgumentList = $Arguments; Wait = $true; PassThru = $true }
    if (-not (Test-IsAdministrator)) { $options.Verb = 'RunAs' }
    $process = Start-Process @options
    # 3010 = success, restart required.
    if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 3010) {
        throw "Installer $([IO.Path]::GetFileName($File)) failed with exit code $($process.ExitCode)."
    }
}

function Install-MsiFromUrl {
    param([string]$Url, [string]$FileName)

    $msi = Save-InstallerDownload -Url $Url -FileName $FileName
    try {
        Start-SilentInstaller -File 'msiexec.exe' -Arguments ('/i "{0}" /qn /norestart' -f $msi)
    }
    finally {
        Remove-Item -LiteralPath (Split-Path -Parent $msi) -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-ExeFromUrl {
    param([string]$Url, [string]$FileName, [string]$Arguments)

    $exe = Save-InstallerDownload -Url $Url -FileName $FileName
    try {
        Start-SilentInstaller -File $exe -Arguments $Arguments
    }
    finally {
        Remove-Item -LiteralPath (Split-Path -Parent $exe) -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-WithoutWinget {
    param([string]$Id)

    $arch = Get-InstallerArch
    Write-Host "  winget is not available; using the official installer for $Id instead." -ForegroundColor Yellow

    switch ($Id) {
        'Git.Git' {
            $assetPattern = if ($arch -eq 'arm64') { '^Git-[\d.]+-arm64\.exe$' } else { '^Git-[\d.]+-64-bit\.exe$' }
            $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest' -UseBasicParsing
            $asset = $release.assets | Where-Object { $_.name -match $assetPattern } | Select-Object -First 1
            if (-not $asset) { throw 'Could not find the Git for Windows installer in the latest release.' }
            Install-ExeFromUrl -Url $asset.browser_download_url -FileName $asset.name -Arguments '/VERYSILENT /NORESTART /NOCANCEL /SP- /SUPPRESSMSGBOXES'
        }
        'OpenJS.NodeJS.LTS' {
            # Windows PowerShell 5.1 emits a JSON array as one object; assign first so it enumerates.
            $releases = Invoke-RestMethod -Uri 'https://nodejs.org/dist/index.json' -UseBasicParsing
            $lts = $releases | Where-Object { $_.lts } | Select-Object -First 1
            if (-not $lts) { throw 'Could not find the current Node.js LTS release.' }
            $name = 'node-{0}-{1}.msi' -f $lts.version, $arch
            Install-MsiFromUrl -Url "https://nodejs.org/dist/$($lts.version)/$name" -FileName $name
        }
        'Python.Python.3.12' {
            # 3.12.10 is the final 3.12 release with a Windows installer.
            $suffix = if ($arch -eq 'arm64') { 'arm64' } else { 'amd64' }
            $name = "python-3.12.10-$suffix.exe"
            Install-ExeFromUrl -Url "https://www.python.org/ftp/python/3.12.10/$name" -FileName $name -Arguments '/quiet InstallAllUsers=0 PrependPath=1 Include_test=0'
        }
        'astral-sh.uv' {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command 'irm https://astral.sh/uv/install.ps1 | iex'
            if ($LASTEXITCODE -ne 0) { throw "The uv installer failed with exit code $LASTEXITCODE." }
        }
        'Microsoft.OpenJDK.21' {
            $suffix = if ($arch -eq 'arm64') { 'aarch64' } else { 'x64' }
            $name = "microsoft-jdk-21-windows-$suffix.msi"
            Install-MsiFromUrl -Url "https://aka.ms/download-jdk/$name" -FileName $name
        }
        'Docker.DockerDesktop' {
            $suffix = if ($arch -eq 'arm64') { 'arm64' } else { 'amd64' }
            Install-ExeFromUrl -Url "https://desktop.docker.com/win/main/$suffix/Docker%20Desktop%20Installer.exe" -FileName 'DockerDesktopInstaller.exe' -Arguments 'install --quiet --accept-license'
        }
        default {
            throw "No direct installer is known for $Id. Install 'App Installer' from the Microsoft Store to get winget, or install it manually."
        }
    }
}
