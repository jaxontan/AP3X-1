# Harness Pairing and No-API-Key Matrix

The Oracle APEX harness is host-agnostic. `AGENTS.md` is the canonical instruction set; each host gets a thin adapter that points back to it.

## Matrix

| Host | Project entry point | Zero-API-key path | Cost caveat |
| --- | --- | --- | --- |
| OpenCode | `opencode.jsonc`, `skills/` | Free model configured in `opencode.jsonc` | Free-tier limits may apply |
| Codex CLI | `AGENTS.md` | `codex --oss --local-provider ollama` with a local Ollama model | Local model quality and hardware dependent |
| Claude Code / VS Code Claude | `CLAUDE.md`, `.claude/skills/oracle-apex/` | `/login` with an existing Claude subscription; keep `ANTHROPIC_API_KEY` unset | Claude Code has no official $0 local-model mode |
| Antigravity | `AGENTS.md`, `.agents/rules/`, `.agents/skills/` | Sign in with a Google account; free tier | Free-tier quotas apply |
| DSH (DeepSeek Harness) | `AGENTS.md`, `.agents/skills/` | `ollama launch dsh` or a local-provider plugin | DSH is a developer preview |
| Other `AGENTS.md`-aware extension | `AGENTS.md` | Depends on the host and model | Verify the host does not silently use a paid key |

**No API keys means:** no `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `GEMINI_API_KEY`, `DEEPSEEK_API_KEY`, or `OPENROUTER_API_KEY` is required by this harness. Existing environment variables are never read by the harness; `scripts/harness-doctor.ps1 -StrictNoKeys` warns if any are present.

## OpenCode

The bootstrap installs the toolchain but not OpenCode. Install OpenCode first (below), then start from the repository root (make sure your prompt is inside the project folder, not `C:\Windows\System32`):

**Windows**
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
. .\scripts\set-env.ps1
opencode --version
opencode
```

**macOS / Linux (PowerShell 7)**
```bash
pwsh -NoProfile -Command ". ./scripts/set-env.ps1; opencode --version; opencode"
```

To install the optional project-local 2.x binary on Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-opencode-v2.ps1
```

On macOS/Linux, use OpenCode's official installer: `curl -fsSL https://opencode.ai/v2/install | bash`. If the Windows machine policy blocks dot-sourcing, use the process-scoped line; it does not change the machine policy. You can also run scripts individually with `powershell -NoProfile -ExecutionPolicy Bypass -File <script>`.

`opencode.jsonc` pins a free model by default. Change it only to another zero-cost model.

The project also configures the SQLcl MCP server as `oracle-sqlcl`. Check it with `opencode mcp list` (or `opencode2 mcp list` when the optional 2.x binary is installed); it should report `connected`. The cross-platform wrapper is `scripts/sqlcl-mcp.mjs`; it is launched by Node and locates Java plus `tools/sqlcl` (or `SQLCL_BIN`). The older `scripts/sqlcl-mcp.cmd` remains only as a Windows fallback. Keep the permission for `oracle-sqlcl_*` at `ask` unless you intentionally want unattended database calls.

`opencode.jsonc` uses the OpenCode V1 `permission` object, which both supported runtimes accept. OpenCode 2.x converts those rules to its ordered `permissions` model. A `permissions` key is rejected by OpenCode 1.x with `V2 permissions are not supported by OpenCode V1`, so do not add one. The harness allows routine shell work, asks before destructive filesystem/git operations and database DDL/DML, asks before paths outside the workspace, and denies reads of `.env`, `.pem`, `.key`, `.p12`, `.jks`, and wallet files. Use `opencode debug config` and `opencode2 debug config` to verify the resolved rules; `harness-doctor.ps1` fails if either installed runtime rejects the config or an agent.

## Codex CLI

Codex reads `AGENTS.md` from the project root. Install the Codex CLI separately; this harness does not bundle it.

### Local Ollama, no API key

```powershell
ollama serve
ollama list
# If no coding model is installed, choose one that fits your hardware, for example:
# ollama pull qwen3.8

codex --oss --local-provider ollama -m <installed-model>
```

Codex's `--oss` path talks to Ollama on localhost and does not need an API key. The quality of APEX/PL/SQL output depends heavily on the local model; validate every `.apx` change with SQLcl.

### ChatGPT login

If you already have a ChatGPT plan, `codex login` uses that account without an API key. That is still a paid subscription; it is not an API-key charge.

## Claude Code and the VS Code Claude extension

Root `CLAUDE.md` points to `AGENTS.md` and the domain skills. A native project skill bridge is at `.claude/skills/oracle-apex/SKILL.md`.

```powershell
npm install -g @anthropic-ai/claude-code
claude
```

Then use `/login`. Keep these unset so subscription login is not overridden:

```powershell
Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
Remove-Item Env:ANTHROPIC_AUTH_TOKEN -ErrorAction SilentlyContinue
Remove-Item Env:CLAUDE_CODE_OAUTH_TOKEN -ErrorAction SilentlyContinue
```

Open the repository root in VS Code so the extension sees `CLAUDE.md` and `.claude/skills/`. Claude Code requires a Claude subscription or an Anthropic-compatible endpoint; there is no official free local-model mode. If you do not have a subscription, use Codex, Antigravity, DSH, or OpenCode instead.

## Antigravity

Install Antigravity from <https://antigravity.google/> or use the Antigravity CLI (`agy`). Sign in with a Google account; the free tier does not require an API key.

```powershell
# Launch the Antigravity CLI in this repository:
agy
```

Antigravity automatically reads:

- `AGENTS.md` (root instructions and rules)
- `.agents/rules/*.md` (project guidelines)
- `.agents/skills/` (skill bridges)
- `.agents/mcp_config.json` (workspace SQLcl MCP server integration)

Antigravity does not read the Claude Code `.mcp.json` file. Keep the SQLcl server entry in `.agents/mcp_config.json`; verify it inside an `agy` session with `/mcp list`.

The free tier has quotas. For heavy work, use it for design/review and run the deterministic APEX validation locally with SQLcl.

## DSH (DeepSeek Harness)

DSH is a plugin-based agent runtime. Its local skill discovery includes `<project>/.agents/skills`, so the Oracle APEX bridge is picked up automatically.

```powershell
npm install --global @deepseek-ai/dsh
ollama launch dsh
```

`ollama launch dsh` uses a local Ollama model with no account login or API key. If you configure DSH manually, use an OpenAI-compatible local endpoint such as `http://127.0.0.1:11434/v1`; a local server does not need a real key.

DSH is a developer preview and its configuration can change. The harness files (`AGENTS.md`, `.agents/skills/oracle-apex.md`) are deliberately plain Markdown so they survive plugin churn.

## Other agent extensions

If an extension supports project instructions, point it at `AGENTS.md`. If it supports project skills, add `.agents/skills/oracle-apex.md` or `.claude/skills/oracle-apex/SKILL.md` to its skill root. If it supports neither, paste the following into its custom instructions:

```text
Read AGENTS.md, then skills/apex-domains/SKILL.md and skills/apex-delivery/SKILL.md.
For APEX work, confirm 26.1 or 26.2, use the matching apexlang inventory and examples,
validate with scripts/validate-apex-app.ps1, and never deploy without explicit approval.
Do not request or use paid API keys.
```

## Model reality check

The harness improves routing, domain reasoning, and verification, but it cannot make a weak model produce production-grade APEXLang or PL/SQL. For the four target domains:

- Prefer a strong coding model for APEXLang generation and PL/SQL package design.
- Use the free/local model for exploration, documentation, and review, then validate deterministically.
- Keep SQLcl validation and PL/SQL tests as the gate, regardless of host or model.
- Never treat "the model said it works" as evidence.
