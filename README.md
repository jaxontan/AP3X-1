# Oracle APEX Agent Harness

A developer harness for building, validating, and deploying Oracle APEX applications with AI coding agents. Works seamlessly across **OpenCode**, **Antigravity**, **Claude Code**, **Codex**, and **DSH** without requiring paid API keys.

---

## ⚡ Quick Start

### 1. Clone & Open the Repository Root
In PowerShell, make sure your working directory is the repository root:
```powershell
# Clone the repository (if not already cloned)
git clone https://github.com/<your-org>/Oracle_Apex-Harness.git

# Navigate into the project root folder
cd Oracle_Apex-Harness
```

> [!IMPORTANT]
> **Always run commands from the repository root.**
> If you opened PowerShell using "Run as Administrator", your terminal starts in `C:\Windows\System32`. You must `cd` into your cloned repository directory before running `.\scripts\...`, otherwise PowerShell will report `The term '.\scripts\set-env.ps1' is not recognized`.

### 2. Initialize the Environment & Verify Setup
In your PowerShell session:
```powershell
# Set execution policy for the current session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Load environment & run health check
. .\scripts\set-env.ps1
.\scripts\harness-doctor.ps1
```
*(Tip: On Windows, you can also simply run or double-click `.\doctor.cmd` from the repo root to execute the health check directly).*

When successful, the doctor checks all tools and files, ending with `Harness is ready.`

### 3. Launch Your AI Assistant
Start your preferred agent:
```powershell
# OpenCode:
opencode

# Or Antigravity CLI:
agy

# Or Claude Code:
claude
```
*(Or open this repository directly in the Antigravity IDE, VS Code, or Codex).*

### 4. Build & Validate
Use the built-in commands and skills inside your agent chat:

| Step | OpenCode Command | Antigravity (`agy`) Skill | Description |
| :--- | :--- | :--- | :--- |
| **1. Page Design** | `working/page-design/requirement.md` | `working/page-design/requirement.md` | User-defined page map, regions & rules |
| **2. PL/SQL** | `/apex.plsql <package>` | `/apex-plsql <package>` | Package APIs & transaction boundaries |
| **3. APEXLang** | `/apex.apexlang working/app` | `/apex-apexlang working/app` | Generate clean `.apx` APEXLang declarative code |
| **4. Validate** | *(Automatic on edit)* | *(Automatic on edit)* | Deterministic SQLcl compiler validation gate |

*(Note: Validation runs automatically whenever APEXLang code is generated or modified).*

---

## 🔄 End-to-End Pipeline Walkthrough: Idea ➔ APEX App

This harness uses a **streamlined vibe coding workflow** that transforms natural language business requirements directly into validated, production-grade Oracle APEX applications without unnecessary ceremony:

```mermaid
flowchart LR
    A["1. User Page Design<br/>working/page-design/requirement.md"] --> B["2. PL/SQL Logic<br/>/apex-plsql"]
    B --> C["3. APEX Declarative<br/>(Auto-Validated)"]
    C --> D["4. Deploy Preview<br/>/apex-deploy"]
```

### 📋 Example Walkthrough

Here is how a real feature travels through the harness:

#### Step 1: User Defines Page Design & Rules (`working/page-design/requirement.md`)
You specify the exact page layout, regions, and rules in `working/page-design/requirement.md`:
- **Page 1 (Dashboard):** Summary Cards with pending count badges & charts.
- **Page 10 (My Expenses):** Interactive Grid with a modal entry form.
- **Page 20 (Approval Queue):** Cards region with action dialogs for managers.
- **Rules:** Claims $\le \$1,000$ require Manager approval; claims $> \$1,000$ escalate to Director; rejections require a mandatory reason.

The agent strictly follows your architecture rather than inventing an arbitrary design.

---

#### Step 2: PL/SQL Implementation (`/apex-plsql` or `/apex.plsql`)
Business logic is implemented inside database packages (following the SmartDB contract):
```sql
create or replace package pkg_expense_mgmt as
  procedure submit_claim(p_claim_id in number);
  procedure approve_claim(p_claim_id in number, p_approver_id in number);
  procedure reject_claim(p_claim_id in number, p_approver_id in number, p_reason in varchar2);
end pkg_expense_mgmt;
/
```
> [!NOTE]
> Keeping business rules inside PL/SQL ensures data integrity, makes logic unit-testable via utPLSQL, and prevents complex SQL from leaking into APEX page processes.

---

#### Step 3: Generate Declarative APEXLang (Autonomous Auto-Validation)
The assistant creates declarative `.apx` files under `working/app/`. 

Every time an `.apx` file is generated or modified, the harness **automatically normalizes line endings and runs SQLcl `apex validate`** in the background—guaranteeing clean syntax without any manual validation commands:
```text
Validating APEX application: ...\working\app
SQLcl: ...\tools\sqlcl\bin\sql.exe
Validation successful.
APEX validation PASSED.
```
> [!IMPORTANT]
> The validation gate fails if there are compile diagnostics, UTF-8 BOM characters, CRLF line endings, or `ORA-` errors.

---

#### Step 4: Safe Deployment Preview & Import (`/apex-deploy` or `/apex.deploy`)
Deployments are strictly gated and previewed first using `-WhatIf`:
```powershell
# 1. Preview the import plan safely
powershell -ExecutionPolicy Bypass -File scripts/deploy-apex-app.ps1 -AppDirectory working/app -WhatIf

# 2. Deploy to target APEX instance once approved
powershell -ExecutionPolicy Bypass -File scripts/deploy-apex-app.ps1 -AppDirectory working/app
```

---

## 🐳 Disposable Local Database (DB + APEX + ORDS)

To test and develop locally without touching production or shared databases, you can spin up a disposable local database.

### ❓ Slim vs. Latest: What is the difference?

| Image Flavor | Size | Contains XML DB? | Can it run APEX? | Best For |
| :--- | :--- | :--- | :--- | :--- |
| **`slim`** (`gvenzl/oracle-free:23-slim`) | ~800 MB | ❌ No | ❌ **No** | Lightweight SQL & PL/SQL smoke tests only. |
| **`latest` / Standard** (`database/free:latest`) | ~1.1 GB | ✅ Yes | ✅ **Yes** | Smallest base DB that supports APEX. Requires ORDS & APEX installation. |
| **`adb-free:latest`** (Autonomous DB Free) | ~3 GB | ✅ Yes | ✅ **Yes (Preinstalled)** | **Smallest all-in-one image** with DB + APEX + ORDS ready out-of-the-box. |

> [!IMPORTANT]
> **Never use `slim` or `latest-lite` for APEX development.** APEX requires Oracle XML DB (`XDB`) and Oracle Text. The APEX installer halts immediately on `slim` images due to missing prerequisites.

---

### 🚀 Running the Smallest All-in-One Database (APEX + ORDS)

A pre-configured `docker-compose.yml` is ready in `local-dev/`:

```powershell
cd local-dev
docker compose up -d
```

Once started:
- **APEX URL:** [https://localhost:8443/ords/apex](https://localhost:8443/ords/apex)
- **Database Port:** `1521` (Service name: `FREEPDB1`)
- **Workspace:** `INTERNAL`
- **Admin User:** `ADMIN`
- **Default Password:** `Welcome123456#` (set via `ORACLE_PASSWORD` in your `.env`)

When you are done, dispose of the database with:
```powershell
docker compose down -v
```

*(Alternatively, run `powershell -File scripts/install-local-apex.ps1 -Execute` if you prefer the dedicated APEX 26.2 multi-container sandbox powered by `uc-local-apex-dev`).*

---

## 🛠️ Core Commands Reference

### 🎯 APEX & PL/SQL Domain Commands
| Command | Purpose |
| :--- | :--- |
| `/apex.plsql <package>` | Write robust PL/SQL packages encapsulating business logic |
| `/apex.apexlang <app-dir>` | Generate clean `.apx` APEXLang declarative definitions |

### 🔒 Quality & Deployment Gates
| Command | Purpose |
| :--- | :--- |
| `/apex.verify <app-dir>` | Static verification of changed files against rules |
| *(Auto-Validation)* | Automatically executes on every `.apx` save/generation |
| `/apex.review <app-dir>` | Trigger subagent review for APEXLang, security, SQL, and accessibility |
| `/apex.deploy <app-dir>` | Import into target DB (`-WhatIf` preview first; requires approval) |

---

## 🤖 Supported Coding Assistants (No-API-Key Paths)

This repository works with multiple host assistants without paid API keys:

| Assistant | Entry File | Free / No-Key Mode |
| :--- | :--- | :--- |
| **OpenCode** | `opencode.jsonc` | Free models pinned in configuration |
| **Antigravity** | `AGENTS.md` + `.agents/` | Google account free tier |
| **Claude Code** | `CLAUDE.md` + `.claude/` | Direct `/login` with existing subscription |
| **Codex CLI** | `AGENTS.md` | Local Ollama models (`--oss --local-provider ollama`) |
| **DSH** | `AGENTS.md` + `.agents/skills` | Local Ollama models |

---

## 🛡️ Safety & Engineering Rules

1. **Evidence over claims:** Never assume an APEX build passed; verify the output of `validate-apex-app.ps1`.
2. **Deterministic file format:** `.apx` files must use **UTF-8 (no BOM)** and **LF line endings** (CRLF causes SQLcl parser errors). Run `scripts/normalize-apx-tree.ps1` to auto-fix.
3. **Read-only by default:** Database connections are strictly read-only for metadata inspection until you explicitly approve DML/DDL or deployment.
4. **No secrets in files:** Never commit `.env`, passwords, or wallet credentials. Saved SQLcl connections (`conn -save <name> -savepwd`) are used for deployment.
5. **Separation of concerns:** Business logic belongs in PL/SQL packages; APEX page processes should only orchestrate package calls.

---

## 📂 Repository Layout

```text
Oracle_Apex-Harness/
├── applications/             # Generated APEXLang applications (.apx files)
├── local-dev/                # Disposable database (docker-compose.yml & audit scripts)
├── scripts/                  # Automation scripts (doctor, validate, deploy, normalize)
├── skills/                   # Vendored Oracle APEX, APEXLang, DB, & ECC meta-skills
├── tools/                    # Local toolchain (SQLcl 26.3, OpenCode v2)
├── AGENTS.md                 # Master agent operating rules and skill routing
├── CLAUDE.md                 # Claude Code adapter
├── opencode.jsonc            # OpenCode agent & permission configuration
└── README.md                 # This guide
```

---

## 🧪 Self-Tests & Doctor

Run harness diagnostics anytime:
```powershell
# Verify all CLI tools, skills, and configuration files
powershell -ExecutionPolicy Bypass -File scripts/harness-doctor.ps1

# Run offline gate self-tests (no database required)
powershell -ExecutionPolicy Bypass -File scripts/test-harness.ps1
```
