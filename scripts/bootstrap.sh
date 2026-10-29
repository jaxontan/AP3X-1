#!/usr/bin/env bash
# Oracle APEX Harness bootstrap for macOS and Linux.
# Installs only free developer tools; never asks for or stores API keys.

set -euo pipefail

YES=0
WITH_DOCKER=0
SKIP_OPENCODE=0
DRY_RUN=0

for arg in "$@"; do
    case "$arg" in
        --yes|-y) YES=1 ;;
        --with-docker) WITH_DOCKER=1 ;;
        --skip-opencode) SKIP_OPENCODE=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --help|-h)
            cat <<'EOF'
Usage: bash scripts/bootstrap.sh [options]

Options:
  -y, --yes             Install without asking for confirmation
      --with-docker     Also install Docker (needed only for the local Oracle sandbox)
      --skip-opencode   Do not install OpenCode
      --dry-run         Print the plan without installing anything
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

export PATH="$HOME/.local/bin:/snap/bin:$PATH"

say() { printf '\n%s\n' "$1"; }
ok() { printf '  OK    %s\n' "$1"; }
warn() { printf '  WARN  %s\n' "$1"; }

have() { command -v "$1" >/dev/null 2>&1; }

have_python() {
    have python3 && python3 -c 'import sys' >/dev/null 2>&1
}

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  DRY RUN:'
        printf ' %s' "$@"
        printf '\n'
        return 0
    fi
    "$@"
}

run_sudo() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  DRY RUN: sudo'
        printf ' %s' "$@"
        printf '\n'
        return 0
    fi
    if have sudo; then
        sudo "$@"
    else
        "$@"
    fi
}

persist_path_file() {
    local rc="$1"
    mkdir -p "$(dirname "$rc")" 2>/dev/null || true
    touch "$rc" 2>/dev/null || return 0
    if ! grep -Fq '# >>> apex-harness path >>>' "$rc" 2>/dev/null; then
        {
            printf '\n# >>> apex-harness path >>>\n'
            printf 'export PATH="$HOME/.local/bin:$HOME/.opencode/bin:/snap/bin:$PATH"\n'
            printf '# <<< apex-harness path <<<\n'
        } >> "$rc"
    fi
}

persist_paths() {
    [ "$DRY_RUN" -eq 1 ] && return 0
    case "$(basename "${SHELL:-bash}")" in
        zsh)
            persist_path_file "$HOME/.zshrc"
            ;;
        bash)
            persist_path_file "$HOME/.bashrc"
            if [ -f "$HOME/.bash_profile" ]; then
                persist_path_file "$HOME/.bash_profile"
            else
                persist_path_file "$HOME/.profile"
            fi
            ;;
        *)
            persist_path_file "$HOME/.profile"
            ;;
    esac
}

confirm() {
    [ "$YES" -eq 1 ] && return 0
    local answer
    printf '%s [Y/n] ' "$1"
    read -r answer
    case "$answer" in
        n|N|no|NO) return 1 ;;
        *) return 0 ;;
    esac
}

node_major() {
    if ! have node; then
        echo 0
        return
    fi
    node -p "process.versions.node.split('.')[0]" 2>/dev/null || echo 0
}

java_major() {
    if ! have java; then
        echo 0
        return
    fi
    java -version 2>&1 | sed -n 's/.*version "\([0-9][0-9]*\).*/\1/p' | head -n 1
}

add_missing() {
    MISSING="${MISSING}  - $1
"
}

MISSING=""
NODE_MAJOR="$(node_major)"
JAVA_MAJOR="$(java_major)"
if ! have git; then add_missing "Git"; fi
if ! have node || [ "${NODE_MAJOR:-0}" -lt 20 ]; then add_missing "Node.js 22+"; fi
if ! have_python; then add_missing "Python 3"; fi
if ! have uv; then add_missing "uv"; fi
if [ "${JAVA_MAJOR:-0}" -lt 21 ]; then add_missing "JDK 21"; fi
if [ ! -x "$ROOT/tools/sqlcl/bin/sql" ]; then add_missing "SQLcl"; fi
if [ "$SKIP_OPENCODE" -eq 0 ] && ! have opencode; then add_missing "OpenCode"; fi
if [ "$WITH_DOCKER" -eq 1 ] && ! have docker; then add_missing "Docker"; fi
if ! have pwsh; then add_missing "PowerShell 7"; fi

say "Oracle APEX Harness bootstrap ($OS $ARCH)"
printf 'Repository: %s\n' "$ROOT"
printf 'This installs free developer tools only. It does not request or store API keys.\n'

if [ -z "$MISSING" ]; then
    ok "All requested prerequisites are already installed."
else
    printf '\nMissing prerequisites:\n%s' "$MISSING"
    if [ "$DRY_RUN" -eq 0 ]; then
        confirm "Install these now?" || { echo "Cancelled. Nothing was changed."; exit 0; }
    fi
fi

install_homebrew() {
    if have brew; then
        return 0
    fi
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        return 0
    fi
    if [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
        return 0
    fi
    say "Homebrew is required to install the macOS prerequisites."
    printf 'The official Homebrew installer may ask for your macOS password.\n'
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  DRY RUN: install Homebrew from https://brew.sh\n'
        return 0
    fi
    confirm "Install Homebrew now?" || { echo "Cancelled."; exit 1; }
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

install_macos() {
    install_homebrew
    run brew install git node python@3.12 uv
    if [ "${JAVA_MAJOR:-0}" -lt 21 ]; then
        run brew install --cask temurin@21
    fi
    if ! have pwsh; then
        run brew install --cask powershell
    fi
    if [ "$WITH_DOCKER" -eq 1 ] && ! have docker; then
        run brew install --cask docker || warn "Docker Desktop was not installed; install it later if you need the local Oracle sandbox."
        warn "Start Docker Desktop once after installation."
    fi
}

install_pwsh_tarball() {
    local dest="$HOME/.local/powershell"
    local url=""
    local pwsh_arch="x64"
    case "$ARCH" in
        aarch64|arm64) pwsh_arch="arm64" ;;
    esac
    say "Installing PowerShell 7 without snap..."
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  DRY RUN: download the latest PowerShell linux-%s tarball\n' "$pwsh_arch"
        return 0
    fi
    url="$(curl -fsSL https://api.github.com/repos/PowerShell/PowerShell/releases/latest \
        | grep -o "\"browser_download_url\": *\"[^\"]*linux-${pwsh_arch}.tar.gz\"" \
        | head -n 1 | cut -d'"' -f4)"
    if [ -z "$url" ]; then
        warn "Could not find a PowerShell linux-x64 release."
        return 1
    fi
    mkdir -p "$dest" "$HOME/.local/bin"
    curl -fsSL "$url" | tar -xz -C "$dest"
    chmod +x "$dest/pwsh"
    ln -sf "$dest/pwsh" "$HOME/.local/bin/pwsh"
}

install_linux() {
    if have apt-get; then
        run_sudo apt-get update
        run_sudo apt-get install -y git curl unzip ca-certificates libicu-dev openjdk-21-jdk python3 python3-venv
        if ! have node || [ "${NODE_MAJOR:-0}" -lt 20 ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                printf '  DRY RUN: add NodeSource Node.js 22 repository and install nodejs\n'
            else
                curl -fsSL https://deb.nodesource.com/setup_22.x | run_sudo bash -
                run_sudo apt-get install -y nodejs
            fi
        fi
    elif have dnf; then
        run_sudo dnf install -y git curl unzip libicu java-21-openjdk-devel python3 nodejs npm
    elif have pacman; then
        run_sudo pacman -S --needed --noconfirm git curl unzip icu jdk21-openjdk python nodejs npm
    elif have zypper; then
        run_sudo zypper install -y git curl unzip libicu java-21-openjdk-devel python3 nodejs npm
    else
        echo "Unsupported Linux distribution: install Git, Node.js, Python 3, JDK 21, unzip, and PowerShell 7 manually." >&2
        exit 1
    fi

    if ! have uv; then
        if [ "$DRY_RUN" -eq 1 ]; then
            printf '  DRY RUN: install uv to %s/.local/bin\n' "$HOME"
        else
            curl -LsSf https://astral.sh/uv/install.sh | sh
        fi
        export PATH="$HOME/.local/bin:$PATH"
    fi

    if ! have pwsh; then
        if have snap && run_sudo snap install powershell --classic; then
            :
        else
            install_pwsh_tarball || warn "PowerShell 7 was not installed; install it from https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux"
        fi
    fi

    if [ "$WITH_DOCKER" -eq 1 ] && ! have docker; then
        if have snap; then
            run_sudo snap install docker || warn "Docker was not installed; install it later if you need the local Oracle sandbox."
        elif have apt-get; then
            run_sudo apt-get install -y docker.io docker-compose-v2 || warn "Docker was not installed; install it later if you need the local Oracle sandbox."
            run_sudo systemctl enable --now docker || warn "Could not start Docker automatically; start it manually."
        else
            warn "Install Docker Engine for your distribution; see https://docs.docker.com/engine/install/"
        fi
    fi
}

if [ "$OS" != "Darwin" ] && [ "$OS" != "Linux" ]; then
    echo "Unsupported operating system: $OS. This script supports macOS, Linux, and Windows (use bootstrap.cmd)." >&2
    exit 1
fi

if [ -n "$MISSING" ]; then
    case "$OS" in
        Darwin) install_macos ;;
        Linux) install_linux ;;
    esac
fi

if [ "$SKIP_OPENCODE" -eq 0 ] && ! have opencode; then
    say "Installing OpenCode..."
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  DRY RUN: curl -fsSL https://opencode.ai/v2/install | bash\n'
    else
        curl -fsSL https://opencode.ai/v2/install | bash
    fi
    export PATH="$HOME/.opencode/bin:$PATH"
fi

if [ ! -x "$ROOT/tools/sqlcl/bin/sql" ]; then
    say "Installing SQLcl into tools/sqlcl..."
    SQLCL_TMP="$(mktemp -d 2>/dev/null || mktemp -d -t apex-harness)"
    trap 'rm -rf "$SQLCL_TMP"' EXIT
    run curl -fL --retry 3 -o "$SQLCL_TMP/sqlcl.zip" "https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip"
    run mkdir -p "$ROOT/tools"
    run rm -rf "$ROOT/tools/sqlcl"
    run unzip -q "$SQLCL_TMP/sqlcl.zip" -d "$ROOT/tools"
    run chmod +x "$ROOT/tools/sqlcl/bin/sql"
fi

export PATH="$HOME/.local/bin:$HOME/.opencode/bin:/snap/bin:$PATH"
persist_paths

if [ "$DRY_RUN" -eq 1 ]; then
    printf '\nDry run complete. No software was installed and no files were changed.\n'
    exit 0
fi

if [ "$SKIP_OPENCODE" -eq 1 ] && ! have opencode; then
    warn "OpenCode was skipped. Install it before running the doctor."
    printf 'The rest of the toolchain is installed. Reopen your terminal to pick up PATH changes.\n'
    exit 0
fi

say "Verifying the harness"
if have pwsh; then
    set +e
    pwsh -NoProfile -File "$ROOT/scripts/harness-doctor.ps1"
    CODE=$?
    set -e
else
    warn "PowerShell 7 is not available, so the harness doctor could not run."
    CODE=1
fi

if [ "$CODE" -eq 0 ]; then
    printf '\nBootstrap complete. Start your agent with: opencode\n'
    printf 'Then open this repository in the agent and ask it to design or build your APEX app.\n'
else
    warn "Bootstrap finished, but the doctor reported problems above."
fi

exit "$CODE"
