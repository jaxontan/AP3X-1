# Getting started

This guide is for anyone who wants to use the Oracle APEX Agent Harness without assembling the toolchain by hand. You need a computer with internet access, about 3 GB of free disk space, and permission to install software. Administrator or `sudo` access may be requested by the operating system.

The bootstrap installs free developer tools only. It does **not** ask for, print, or store an API key. The harness works with a free OpenCode model, an existing subscription login, Antigravity's free tier, or a local model.

## One command

### Windows 10 or 11

1. Download the repository as a ZIP and unzip it, or clone it if Git is already available.
2. Open the folder that contains `README.md` and `bootstrap.cmd`.
3. Double-click `bootstrap.cmd`, or open PowerShell in that folder and run:

```powershell
.\bootstrap.cmd
```

The wrapper starts PowerShell with the correct execution policy for this run. It does not change your machine-wide policy.

Useful options:

```powershell
.\bootstrap.cmd -DryRun                 # show the plan, install nothing
.\bootstrap.cmd -Yes                    # do not ask for confirmation
.\bootstrap.cmd -WithDocker             # also install Docker Desktop
.\bootstrap.cmd -SkipOpenCode           # do not install OpenCode
```

### macOS

1. Download and unzip the repository, or clone it.
2. Open **Terminal** and go to the repository folder:

```bash
cd path/to/Oracle_Apex-Harness
bash scripts/bootstrap.sh
```

If Homebrew is missing, the script explains this and asks before running the official Homebrew installer. macOS may ask for your password for Homebrew casks such as the JDK and PowerShell.

### Linux

The script supports Debian/Ubuntu (`apt`), Fedora/RHEL (`dnf`), Arch (`pacman`), and openSUSE (`zypper`).

```bash
cd path/to/Oracle_Apex-Harness
bash scripts/bootstrap.sh
```

On Linux, "Docker" means Docker Engine, not Docker Desktop. It is only needed for the optional local Oracle sandbox.

Useful options for macOS and Linux:

```bash
bash scripts/bootstrap.sh --dry-run      # show the plan, install nothing
bash scripts/bootstrap.sh --yes          # do not ask for confirmation
bash scripts/bootstrap.sh --with-docker  # also install Docker
bash scripts/bootstrap.sh --skip-opencode
```

## What gets installed

| Tool | Why the harness needs it | Windows | macOS | Linux |
| --- | --- | --- | --- | --- |
| Git | Clone/update projects | `Git.Git` via winget | Homebrew | Package manager |
| Node.js LTS | OpenCode, MCP launcher | `OpenJS.NodeJS.LTS` | Homebrew | Package manager / NodeSource 22 |
| Python 3 | SQLcl MCP helper and scripts | `Python.Python.3.12` | Homebrew | Package manager |
| uv | Python tool runner | `astral-sh.uv` | Homebrew | Official uv installer |
| JDK 21 | SQLcl and APEX validation | `Microsoft.OpenJDK.21` | Temurin 21 cask | OpenJDK 21 package |
| SQLcl | APEXLang validation, import, MCP | Downloaded into `tools/sqlcl` | Downloaded into `tools/sqlcl` | Downloaded into `tools/sqlcl` |
| PowerShell 7 | Harness doctor and scripts | Built in (5.1 is enough) | Homebrew cask | snap or GitHub release |
| OpenCode | Default free AI host | Project-local V2 binary | Official V2 installer | Official V2 installer |
| Docker (optional) | Local Oracle Database sandbox | Docker Desktop | Docker Desktop | Docker Engine |

The bootstrap also verifies the repository with `scripts/harness-doctor.ps1`. A successful run ends with:

```text
Harness is ready.
```

If it ends with a problem list, fix the named item and run the doctor again. The exact missing item is printed; you do not need to guess.

## After setup

Start OpenCode from the repository root:

```bash
opencode
```

Then open this repository in the agent and ask it to design, build, validate, or deploy an APEX application. The agent reads `AGENTS.md` automatically.

Optional AI hosts use the same repository but their own installers:

| Host | Entry point | Notes |
| --- | --- | --- |
| OpenCode | `opencode` | Installed by the bootstrap; free model supported |
| Antigravity | `agy` | Install with the vendor installer; workspace MCP uses `.agents/mcp_config.json` |
| Claude Code | `claude` | `npm install -g @anthropic-ai/claude-code` |
| Codex CLI | `codex` | `npm install -g @openai/codex` |
| DSH | `dsh` | `npm install -g @deepseek-ai/dsh` |

On Windows, use `npm.cmd` instead of `npm` if PowerShell blocks the `npm.ps1` shim. These hosts are optional; OpenCode is installed by the bootstrap. Do not create a metered API key just to use the harness. Use a host account login or a free/local model. The doctor warns when common paid-key environment variables are present.

## Database connection

Validation does not need a database. Deployment does. Use a SQLcl saved connection or the `SQLCL_CONNECTION_STRING` environment variable supplied by your database administrator. Never commit a password, wallet, token, or connection string to this repository.

For the optional local sandbox, see [`local-dev/README.md`](../local-dev/README.md). Start Docker first, then follow that guide. The sandbox is not required for APEXLang validation.

## Troubleshooting

| Symptom | What to do |
| --- | --- |
| `winget` is not recognized | Install **App Installer** from the Microsoft Store, then rerun `bootstrap.cmd`. |
| `opencode` is not recognized after setup | Close and reopen the terminal, or run `. .\scripts\set-env.ps1` in PowerShell. The bootstrap puts the project-local binary on `PATH` for new shells. |
| macOS cannot find `brew` | Run `/opt/homebrew/bin/brew shellenv` (Apple Silicon) or `/usr/local/bin/brew shellenv` (Intel), then retry. |
| Linux has an old Node.js | Install Node.js 22 from NodeSource, or rerun the bootstrap; it upgrades Node when the major version is below 20. |
| PowerShell says scripts are disabled | Use `bootstrap.cmd`, or run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\harness-doctor.ps1`. |
| Java-related SQLcl error | Confirm `JAVA_HOME` points to a JDK 21 `bin` directory. `scripts/set-env.ps1` finds `C:\Program Files\Microsoft\jdk-*`, Temurin, and common `/usr/lib/jvm/*21*` locations. |
| Docker sandbox does not start | Start Docker Desktop (Windows/macOS) or `sudo systemctl start docker` (Linux), then retry. |
| APEX version is unsupported | This harness supports APEX 26.1 and 26.2. Check `.apex/apexlang.json` or the target instance. |

For a deeper diagnosis, run the doctor and keep the full output:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\harness-doctor.ps1
```

On macOS/Linux:

```bash
pwsh -NoProfile -File scripts/harness-doctor.ps1
```
