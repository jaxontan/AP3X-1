#!/usr/bin/env bash
# AP3X-1 prerequisite check for macOS and Linux.
# Checks every tool the harness and the local Docker sandbox need, then offers
# to install or start whatever is missing, one step at a time. AI agents
# (Claude Code, Codex, OpenCode, Antigravity) are intentionally not checked.

set -uo pipefail

YES=0
CHECK_ONLY=0
SKIP_DOCKER=0

for arg in "$@"; do
    case "$arg" in
        --yes|-y) YES=1 ;;
        --check-only) CHECK_ONLY=1 ;;
        --skip-docker) SKIP_DOCKER=1 ;;
        --help|-h)
            cat <<'EOF'
Usage: bash scripts/check-prereqs.sh [options]

Options:
  -y, --yes             Fix everything without asking
      --check-only      Only report; install nothing
      --skip-docker     Do not check Docker
  -h, --help            Show this help
EOF
            exit 0
            ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS="$(uname -s)"
ARCH="$(uname -m)"
RELOGIN=0

if [ "$OS" != "Darwin" ] && [ "$OS" != "Linux" ]; then
    echo "Unsupported operating system: $OS. On Windows run check.cmd." >&2
    exit 1
fi

export PATH="$HOME/.local/bin:/snap/bin:$PATH"
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"

if [ -t 1 ]; then
    C_OK=$'\033[32m'; C_FAIL=$'\033[31m'; C_WARN=$'\033[33m'; C_HEAD=$'\033[36m'; C_DIM=$'\033[2m'; C_END=$'\033[0m'
else
    C_OK=''; C_FAIL=''; C_WARN=''; C_HEAD=''; C_DIM=''; C_END=''
fi

head_line() { printf '\n%s%s%s\n' "$C_HEAD" "$1" "$C_END"; }
info() { printf '  %s%s%s\n' "$C_DIM" "$1" "$C_END"; }
warn() { printf '  %sWARN  %s%s\n' "$C_WARN" "$1" "$C_END"; }
have() { command -v "$1" >/dev/null 2>&1; }

run_sudo() {
    if [ "$(id -u)" -eq 0 ]; then "$@"
    elif have sudo; then sudo "$@"
    else echo "sudo is required to run: $*" >&2; return 1
    fi
}

confirm() {
    [ "$YES" -eq 1 ] && return 0
    local answer
    printf '  %s? [Y/n] ' "$1"
    { read -r answer </dev/tty; } 2>/dev/null || return 1
    case "$answer" in
        n|N|no|NO) return 1 ;;
        *) return 0 ;;
    esac
}

version_ge() {
    # version_ge 22.12.0 22.12.0 -> true when $1 >= $2
    [ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n -k3,3n | head -n 1)" = "$2" ]
}

pkg_install() {
    # pkg_install <apt names> <dnf names> <pacman names> <zypper names>
    if have apt-get; then run_sudo apt-get update && run_sudo apt-get install -y $1
    elif have dnf; then run_sudo dnf install -y $2
    elif have pacman; then run_sudo pacman -S --needed --noconfirm $3
    elif have zypper; then run_sudo zypper install -y $4
    else echo "No supported package manager (apt, dnf, pacman, zypper) was found." >&2; return 1
    fi
}

ensure_brew() {
    have brew && return 0
    info "Homebrew is needed for installs on macOS; its installer may ask for your password."
    confirm "Install Homebrew from https://brew.sh" || return 1
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
    have brew
}

first_line() { "$@" 2>&1 | sed -n '/./{p;q;}'; }

# Each check is four functions: check_<key> (sets DETAIL, returns 0 when OK),
# fix_<key>, and help_<key>, plus metadata from meta_<key>.
# meta sets NAME, REQUIRED (1/0), DEPENDS (space-separated keys), ACTION.

meta_git() { NAME="Git"; REQUIRED=1; DEPENDS=""; ACTION="Install Git"; }
check_git() { have git || { DETAIL="not found"; return 1; }; DETAIL="$(git --version)"; }
fix_git() {
    if [ "$OS" = "Darwin" ]; then ensure_brew && brew install git
    else pkg_install git git git git
    fi
}
help_git() { echo "Install Git from https://git-scm.com/downloads"; }

meta_curl() { NAME="curl and unzip"; REQUIRED=1; DEPENDS=""; ACTION="Install curl and unzip"; }
check_curl() {
    have curl && have unzip && { DETAIL="$(first_line curl --version | cut -d' ' -f1-2)"; return 0; }
    DETAIL="missing:$(have curl || printf ' curl')$(have unzip || printf ' unzip')"; return 1
}
fix_curl() {
    if [ "$OS" = "Darwin" ]; then ensure_brew && brew install curl unzip
    else pkg_install "curl unzip ca-certificates" "curl unzip" "curl unzip" "curl unzip"
    fi
}
help_curl() { echo "Install curl and unzip with your package manager."; }

meta_node() { NAME="Node.js 22.12+"; REQUIRED=1; DEPENDS="curl"; ACTION="Install Node.js 22 LTS"; }
check_node() {
    have node || { DETAIL="not found"; return 1; }
    local v; v="$(node --version)"
    if version_ge "${v#v}" 22.12.0; then DETAIL="$v"; else DETAIL="$v is too old (need 22.12 or newer)"; return 1; fi
}
fix_node() {
    if [ "$OS" = "Darwin" ]; then ensure_brew && brew install node@22 && brew link --overwrite --force node@22
    elif have apt-get; then
        curl -fsSL https://deb.nodesource.com/setup_22.x | run_sudo bash - && run_sudo apt-get install -y nodejs
    elif have dnf; then
        curl -fsSL https://rpm.nodesource.com/setup_22.x | run_sudo bash - && run_sudo dnf install -y nodejs
    else pkg_install nodejs "nodejs npm" "nodejs npm" "nodejs22 npm22"
    fi
}
help_node() { echo "Install the LTS release from https://nodejs.org/ (or use nvm: https://github.com/nvm-sh/nvm)."; }

meta_npm() { NAME="npm"; REQUIRED=1; DEPENDS="node"; ACTION="Install npm"; }
check_npm() { have npm || { DETAIL="not found"; return 1; }; DETAIL="$(npm --version)"; }
fix_npm() {
    if [ "$OS" = "Darwin" ]; then fix_node
    else pkg_install npm npm npm npm
    fi
}
help_npm() { echo "npm ships with Node.js; reinstall Node.js from https://nodejs.org/"; }

meta_python() { NAME="Python 3"; REQUIRED=1; DEPENDS=""; ACTION="Install Python 3"; }
check_python() {
    have python3 && python3 -c 'import sys' >/dev/null 2>&1 || { DETAIL="not found"; return 1; }
    DETAIL="$(python3 --version 2>&1)"
}
fix_python() {
    if [ "$OS" = "Darwin" ]; then ensure_brew && brew install python@3.12
    else pkg_install "python3 python3-venv" python3 python python3
    fi
}
help_python() { echo "Install Python 3 from https://www.python.org/downloads/"; }

meta_uv() { NAME="uv"; REQUIRED=1; DEPENDS="curl"; ACTION="Install uv into ~/.local/bin"; }
check_uv() { have uv || { DETAIL="not found"; return 1; }; DETAIL="$(uv --version)"; }
fix_uv() {
    if [ "$OS" = "Darwin" ] && have brew; then brew install uv
    else curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
}
help_uv() { echo "See https://docs.astral.sh/uv/getting-started/installation/"; }

java_major() {
    have java || { echo 0; return; }
    local m; m="$(java -version 2>&1 | sed -n 's/.*version "\([0-9][0-9]*\).*/\1/p' | head -n 1)"
    echo "${m:-0}"
}
meta_java() { NAME="Java (JDK 21+)"; REQUIRED=1; DEPENDS=""; ACTION="Install JDK 21"; }
check_java() {
    have java || { DETAIL="not found"; return 1; }
    DETAIL="$(first_line java -version)"
    [ "$(java_major)" -ge 21 ] || { DETAIL="$DETAIL is too old (need 21 or newer)"; return 1; }
}
fix_java() {
    if [ "$OS" = "Darwin" ]; then ensure_brew && brew install --cask temurin@21
    else pkg_install openjdk-21-jdk java-21-openjdk-devel jdk21-openjdk java-21-openjdk-devel
    fi
}
help_java() { echo "Install a JDK 21 from https://adoptium.net/temurin/releases/?version=21"; }

meta_sqlcl() { NAME="SQLcl (tools/sqlcl)"; REQUIRED=1; DEPENDS="java curl"; ACTION="Download SQLcl into tools/sqlcl"; }
check_sqlcl() {
    [ -x "$ROOT/tools/sqlcl/bin/sql" ] || { DETAIL="not found in tools/sqlcl"; return 1; }
    DETAIL="$ROOT/tools/sqlcl/bin/sql"
}
fix_sqlcl() {
    local tmp; tmp="$(mktemp -d 2>/dev/null || mktemp -d -t apex-harness)"
    curl -fL --retry 3 -o "$tmp/sqlcl.zip" "https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip" &&
        mkdir -p "$ROOT/tools" && rm -rf "$ROOT/tools/sqlcl" &&
        unzip -q "$tmp/sqlcl.zip" -d "$ROOT/tools" && chmod +x "$ROOT/tools/sqlcl/bin/sql"
    local code=$?
    rm -rf "$tmp"
    return $code
}
help_sqlcl() { echo "Unzip https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip into tools/"; }

meta_pwsh() { NAME="PowerShell 7"; REQUIRED=1; DEPENDS="curl"; ACTION="Install PowerShell 7"; }
check_pwsh() { have pwsh || { DETAIL="not found"; return 1; }; DETAIL="$(pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')"; }
fix_pwsh() {
    if [ "$OS" = "Darwin" ]; then ensure_brew && brew install --cask powershell; return; fi
    if have snap && run_sudo snap install powershell --classic; then return 0; fi
    local pwsh_arch="x64" url dest="$HOME/.local/powershell"
    case "$ARCH" in aarch64|arm64) pwsh_arch="arm64" ;; esac
    url="$(curl -fsSL https://api.github.com/repos/PowerShell/PowerShell/releases/latest \
        | grep -o "\"browser_download_url\": *\"[^\"]*linux-${pwsh_arch}.tar.gz\"" \
        | head -n 1 | cut -d'"' -f4)"
    [ -n "$url" ] || return 1
    mkdir -p "$dest" "$HOME/.local/bin" && curl -fsSL "$url" | tar -xz -C "$dest" &&
        chmod +x "$dest/pwsh" && ln -sf "$dest/pwsh" "$HOME/.local/bin/pwsh"
}
help_pwsh() { echo "See https://learn.microsoft.com/powershell/scripting/install/installing-powershell"; }

meta_docker() {
    NAME="Docker"; REQUIRED=1; DEPENDS="curl"
    if [ "$OS" = "Darwin" ]; then ACTION="Install Docker Desktop with Homebrew"; else ACTION="Install Docker Engine (official get.docker.com script)"; fi
}
check_docker() { have docker || { DETAIL="not found"; return 1; }; DETAIL="$(docker --version)"; }
fix_docker() {
    if [ "$OS" = "Darwin" ]; then ensure_brew && brew install --cask docker; return; fi
    local tmp; tmp="$(mktemp)"
    curl -fsSL https://get.docker.com -o "$tmp" && run_sudo sh "$tmp"
    local code=$?
    rm -f "$tmp"
    [ $code -eq 0 ] && run_sudo systemctl enable --now docker >/dev/null 2>&1
    return $code
}
help_docker() {
    if [ "$OS" = "Darwin" ]; then echo "Install Docker Desktop from https://www.docker.com/products/docker-desktop/"
    else echo "Install Docker Engine: https://docs.docker.com/engine/install/"
    fi
}

meta_compose() { NAME="Docker Compose v2"; REQUIRED=1; DEPENDS="docker"; ACTION="Install the Docker Compose plugin"; }
check_compose() { DETAIL="$(docker compose version 2>/dev/null | head -n 1)"; [ -n "$DETAIL" ] || { DETAIL="not found"; return 1; }; }
fix_compose() {
    if [ "$OS" = "Darwin" ]; then ensure_brew && brew upgrade --cask docker; return; fi
    if have apt-get; then run_sudo apt-get update && { run_sudo apt-get install -y docker-compose-plugin || run_sudo apt-get install -y docker-compose-v2; }
    else pkg_install docker-compose-plugin docker-compose-plugin docker-compose docker-compose
    fi
}
help_compose() { echo "Install the Compose plugin: https://docs.docker.com/compose/install/linux/"; }

meta_engine() { NAME="Docker engine running"; REQUIRED=1; DEPENDS="docker"; ACTION="Start the Docker engine"; }
check_engine() {
    local out
    if out="$(docker info --format '{{.ServerVersion}}' 2>&1)"; then DETAIL="server $out"; return 0; fi
    case "$out" in
        *"permission denied"*) DETAIL="running, but your user cannot access it (not in the docker group)" ;;
        *) DETAIL="not running" ;;
    esac
    return 1
}
fix_engine() {
    if [ "$OS" = "Darwin" ]; then
        open -a Docker || return 1
    elif docker info 2>&1 | grep -q "permission denied"; then
        run_sudo usermod -aG docker "$USER" || return 1
        RELOGIN=1
        info "Added $USER to the docker group. Log out and back in (or run: newgrp docker) for it to apply."
        return 0
    else
        run_sudo systemctl start docker || run_sudo service docker start || return 1
    fi
    printf '  Waiting for the Docker engine (up to 3 minutes)'
    local i=0
    while [ $i -lt 36 ]; do
        docker info >/dev/null 2>&1 && { printf ' ready.\n'; return 0; }
        printf '.'; sleep 5; i=$((i + 1))
    done
    printf '\n'
    return 1
}
help_engine() {
    if [ "$OS" = "Darwin" ]; then echo "Open Docker Desktop from Applications and wait until it says \"Engine running\"."
    else
        echo "Start it:   sudo systemctl start docker"
        echo "Allow you:  sudo usermod -aG docker \$USER   (then log out and back in)"
    fi
}

meta_npmdeps() { NAME="npm packages (Playwright)"; REQUIRED=0; DEPENDS="npm"; ACTION="Run npm ci in the repository"; }
check_npmdeps() {
    if [ -f "$ROOT/node_modules/playwright/package.json" ] && [ -f "$ROOT/node_modules/@axe-core/playwright/package.json" ]; then
        DETAIL="playwright $(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$ROOT/node_modules/playwright/package.json" | head -n 1)"
        return 0
    fi
    DETAIL="not installed (needed only for design verification)"; return 1
}
fix_npmdeps() { (cd "$ROOT" && npm ci); }
help_npmdeps() { echo "In the repository folder run: npm ci"; }

meta_chromium() { NAME="Playwright Chromium"; REQUIRED=0; DEPENDS="npmdeps"; ACTION="Download Chromium for Playwright"; }
check_chromium() {
    if (cd "$ROOT" && node -e "const fs=require('fs');const {chromium}=require('playwright');process.exit(fs.existsSync(chromium.executablePath())?0:1)") >/dev/null 2>&1; then
        DETAIL="installed"; return 0
    fi
    DETAIL="not installed (about 300 MB download)"; return 1
}
fix_chromium() {
    if [ "$OS" = "Linux" ]; then (cd "$ROOT" && npx playwright install --with-deps chromium)
    else (cd "$ROOT" && npx playwright install chromium)
    fi
}
help_chromium() { echo "In the repository folder run: npx playwright install chromium"; }

KEYS="git curl node npm python uv java sqlcl pwsh"
[ "$SKIP_DOCKER" -eq 0 ] && KEYS="$KEYS docker compose engine"
KEYS="$KEYS npmdeps chromium"

FAILED_KEYS=""

run_check() {
    # run_check <key>; records failures in FAILED_KEYS
    DETAIL=""
    FAILED_KEYS="$(printf '%s' " $FAILED_KEYS " | sed "s/ $1 / /g")"
    if "check_$1"; then return 0; fi
    FAILED_KEYS="$FAILED_KEYS $1"
    return 1
}

is_failed() { case " $FAILED_KEYS " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

print_row() {
    local key="$1" status color
    "meta_$key"
    if ! is_failed "$key"; then status="OK"; color="$C_OK"
    elif [ "$REQUIRED" -eq 1 ]; then status="FAIL"; color="$C_FAIL"
    else status="WARN"; color="$C_WARN"
    fi
    printf '  %s%-5s %-27s %s%s\n' "$color" "$status" "$NAME" "$2" "$C_END"
}

check_all() {
    local key
    for key in $KEYS; do
        run_check "$key"
        print_row "$key" "$DETAIL"
    done
}

print_help() {
    printf '  %sTo fix it yourself:%s\n' "$C_WARN" "$C_END"
    "help_$1" | sed 's/^/    /'
}

finish() {
    local key failures="" count=0
    for key in $FAILED_KEYS; do
        "meta_$key"
        if [ "$REQUIRED" -eq 1 ]; then failures="$failures${failures:+, }$NAME"; count=$((count + 1)); fi
    done
    printf '\n'
    [ "$RELOGIN" -eq 1 ] && warn "Log out and back in so Docker group membership applies, then run this check again."
    info "Open a new terminal if anything was installed, so it picks up the updated PATH."
    if [ "$count" -eq 0 ]; then
        printf '%sPrerequisite check finished: everything required is ready.%s\n' "$C_OK" "$C_END"
        exit 0
    fi
    printf '%sPrerequisite check finished: %s required item(s) still need attention: %s%s\n' "$C_FAIL" "$count" "$failures" "$C_END"
    exit 1
}

head_line "AP3X-1 prerequisite check ($OS $ARCH)"
printf 'Repository: %s\n' "$ROOT"
info "Checks developer tools and Docker only. AI agents are not checked or installed."
printf '\n'

check_all
[ -z "$FAILED_KEYS" ] && finish

if [ "$CHECK_ONLY" -eq 1 ]; then
    for key in $FAILED_KEYS; do
        "meta_$key"
        printf '\n%s%s: %s%s\n' "$C_WARN" "$NAME" "$("check_$key"; printf '%s' "$DETAIL")" "$C_END"
        print_help "$key"
    done
    finish
fi

head_line "Fixing what is missing"
info "Each step asks first. Answer n to skip it and see how to do it yourself."

for key in $KEYS; do
    run_check "$key" && continue
    "meta_$key"
    printf '\n%s%s: %s%s\n' "$C_WARN" "$NAME" "$DETAIL" "$C_END"

    blocked=""
    for dep in $DEPENDS; do
        if is_failed "$dep"; then "meta_$dep"; blocked="$blocked${blocked:+, }$NAME"; fi
    done
    "meta_$key"
    if [ -n "$blocked" ]; then
        info "Skipped: fix $blocked first."
        continue
    fi

    if ! confirm "$ACTION"; then
        print_help "$key"
        continue
    fi

    "fix_$key" || warn "The automatic fix reported an error."
    hash -r 2>/dev/null
    export PATH="$HOME/.local/bin:/snap/bin:$PATH"

    if run_check "$key"; then
        printf '  %sOK    %s: %s%s\n' "$C_OK" "$NAME" "$DETAIL" "$C_END"
    else
        warn "$NAME is still not ready: $DETAIL"
        print_help "$key"
    fi
done

head_line "Result"
FAILED_KEYS=""
check_all
finish
