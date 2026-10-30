[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$isWindowsHost = $env:OS -eq 'Windows_NT'
$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root 'tools'
$sqlcl = Join-Path $tools 'sqlcl'
$sqlExe = if ($isWindowsHost) { 'sql.exe' } else { 'sql' }
$zip = Join-Path ([System.IO.Path]::GetTempPath()) 'sqlcl-latest.zip'
$url = 'https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip'

function Get-CurlPath {
    $command = Get-Command 'curl.exe' -CommandType Application -ErrorAction SilentlyContinue
    if (-not $command) {
        $command = Get-Command 'curl' -CommandType Application -ErrorAction SilentlyContinue
    }
    if (-not $command) {
        throw 'curl is required to download SQLcl. Install curl and re-run scripts/install-sqlcl.ps1.'
    }
    if ($command.Path) { return $command.Path }
    return $command.Name
}

function Get-SqlclDownloadSize {
    param(
        [string]$Curl,
        [string]$Uri
    )

    $headers = & $Curl -sS -L -I --connect-timeout 30 --max-time 60 --no-progress-meter $Uri
    if ($LASTEXITCODE -ne 0) {
        Write-Warning ("Could not read the SQLcl download size (curl exit {0}); the download will run without a size check." -f $LASTEXITCODE)
        return [long]0
    }

    $lengthMatches = [regex]::Matches(($headers -join "`n"), '(?im)^\s*Content-Length:\s*(\d+)\s*$')
    if ($lengthMatches.Count -eq 0) {
        return [long]0
    }
    return [long]$lengthMatches[$lengthMatches.Count - 1].Groups[1].Value
}

function Invoke-SqlclDownload {
    param(
        [string]$Curl,
        [string]$Uri,
        [string]$Path,
        [long]$ExpectedSize
    )

    $maxAttempts = 10
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $existing = [long]0
        if (Test-Path -LiteralPath $Path) {
            $existing = (Get-Item -LiteralPath $Path).Length
        }

        if ($ExpectedSize -gt 0 -and $existing -eq $ExpectedSize) {
            Write-Host ("Using the complete SQLcl archive already at {0} ({1:N0} bytes)." -f $Path, $existing) -ForegroundColor Green
            return
        }

        if ($ExpectedSize -gt 0 -and $existing -gt $ExpectedSize) {
            Write-Warning 'The cached SQLcl archive is larger than the published file; restarting the download.'
            Remove-Item -LiteralPath $Path -Force
            $existing = [long]0
        }

        if ($existing -gt 0) {
            Write-Host ("Resuming SQLcl download at {0:N0} bytes (attempt {1}/{2})..." -f $existing, $attempt, $maxAttempts) -ForegroundColor Cyan
        }
        else {
            Write-Host ("Downloading SQLcl (attempt {0}/{1})..." -f $attempt, $maxAttempts) -ForegroundColor Cyan
        }

        $curlArguments = @(
            '-L', '--fail', '-sS', '--no-progress-meter',
            '--connect-timeout', '30',
            '--output', $Path
        )
        if ($existing -gt 0) {
            $curlArguments = @('-C', '-') + $curlArguments
        }

        & $Curl @curlArguments $Uri
        $exitCode = $LASTEXITCODE

        $actual = [long]0
        if (Test-Path -LiteralPath $Path) {
            $actual = (Get-Item -LiteralPath $Path).Length
        }

        if ($ExpectedSize -gt 0 -and $actual -eq $ExpectedSize) {
            Write-Host ("Downloaded SQLcl ({0:N0} bytes)." -f $actual) -ForegroundColor Green
            return
        }
        if ($ExpectedSize -le 0 -and $exitCode -eq 0) {
            Write-Host ("Downloaded SQLcl ({0:N0} bytes)." -f $actual) -ForegroundColor Green
            return
        }

        if ($exitCode -eq 33) {
            Write-Warning 'The download server rejected the resume request; restarting from the beginning.'
            Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        }
        elseif ($exitCode -ne 0) {
            Write-Warning ("curl exited with code {0}; {1:N0} bytes are cached for resume." -f $exitCode, $actual)
        }
        else {
            Write-Warning ("Download incomplete ({0:N0} of {1:N0} bytes); resuming." -f $actual, $ExpectedSize)
        }

        Start-Sleep -Seconds ([Math]::Min(3 * $attempt, 15))
    }

    throw 'SQLcl download failed after repeated resumable attempts. Check the network or proxy, then re-run scripts/install-sqlcl.ps1.'
}

if ((Test-Path (Join-Path (Join-Path $sqlcl 'bin') $sqlExe)) -and -not $Force) {
    Write-Host "SQLcl already installed at $sqlcl. Use -Force to reinstall." -ForegroundColor Green
}
else {
    if (-not $isWindowsHost -and -not (Get-Command unzip -ErrorAction SilentlyContinue)) {
        throw 'unzip is required to extract SQLcl. Install unzip and re-run scripts/install-sqlcl.ps1.'
    }

    $curl = Get-CurlPath
    $expectedSize = Get-SqlclDownloadSize -Curl $curl -Uri $url
    if ($expectedSize -gt 0) {
        Write-Host ("Downloading SQLcl from {0} ({1:N0} bytes)" -f $url, $expectedSize) -ForegroundColor Cyan
    }
    else {
        Write-Host "Downloading SQLcl from $url" -ForegroundColor Cyan
    }

    Invoke-SqlclDownload -Curl $curl -Uri $url -Path $zip -ExpectedSize $expectedSize

    New-Item -ItemType Directory -Force -Path $tools | Out-Null
    if (Test-Path $sqlcl) { Remove-Item -Recurse -Force $sqlcl }

    try {
        if ($isWindowsHost) {
            Expand-Archive -Path $zip -DestinationPath $tools -Force
        }
        else {
            & unzip -q -o $zip -d $tools
            if ($LASTEXITCODE -ne 0) {
                throw 'unzip failed.'
            }
            & chmod +x (Join-Path (Join-Path $sqlcl 'bin') 'sql')
            if ($LASTEXITCODE -ne 0) {
                throw 'Could not make the SQLcl launcher executable.'
            }
        }
    }
    catch {
        Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
        throw ("SQLcl extraction failed: {0} The archive was deleted; re-run scripts/install-sqlcl.ps1 to download it again." -f $_.Exception.Message)
    }

    Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
    Write-Host "SQLcl extracted to $sqlcl" -ForegroundColor Green
}

$hasJava = [bool](Get-Command java -ErrorAction SilentlyContinue)
$hasJavaHome = $env:JAVA_HOME -and (Test-Path (Join-Path (Join-Path $env:JAVA_HOME 'bin') ($(if ($isWindowsHost) { 'java.exe' } else { 'java' }))))
if (-not $hasJava -and -not $hasJavaHome) {
    Write-Host 'Java not found. Installing JDK 21...' -ForegroundColor Yellow
    if ($isWindowsHost) {
        winget install --id Microsoft.OpenJDK.21 --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    }
    elseif ((& uname -s) -eq 'Darwin') {
        brew install --cask temurin@21
    }
    elseif (Get-Command apt-get -ErrorAction SilentlyContinue) {
        sudo apt-get update
        sudo apt-get install -y openjdk-21-jdk
    }
    elseif (Get-Command dnf -ErrorAction SilentlyContinue) {
        sudo dnf install -y java-21-openjdk-devel
    }
    elseif (Get-Command pacman -ErrorAction SilentlyContinue) {
        sudo pacman -S --needed --noconfirm jdk21-openjdk
    }
    elseif (Get-Command zypper -ErrorAction SilentlyContinue) {
        sudo zypper install -y java-21-openjdk-devel
    }
    else {
        throw 'Install JDK 21 manually and set JAVA_HOME.'
    }
    if ($LASTEXITCODE -ne 0) {
        throw 'JDK installation failed. Install JDK 21 manually and set JAVA_HOME.'
    }
}

. (Join-Path $PSScriptRoot 'set-env.ps1')
if (-not $env:SQLCL_BIN) {
    throw "SQLcl was extracted to $sqlcl, but its launcher was not found. Set SQLCL_BIN manually."
}

& $env:SQLCL_BIN -V
if ($LASTEXITCODE -ne 0) {
    throw 'SQLcl installation could not be verified.'
}

Write-Host 'SQLcl is ready. Run . ./scripts/set-env.ps1 (Windows: . .\scripts\set-env.ps1) in new shells.' -ForegroundColor Green
