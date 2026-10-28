# ADR-0005: Keep OpenCode configuration compatible with V1 and V2

- Status: Accepted
- Date: 2026-10-28

## Context

The harness previously required OpenCode 2.x because `opencode.jsonc` used the V2 `permissions` ruleset. On this workstation, the default `opencode` binary is 1.18.30 and rejects that key with:

```text
V2 permissions are not supported by OpenCode V1. Use V1 "permission" rules or run opencode2.
```

A project-local 2.2.0 binary is also installed. Requiring V2 makes the default command fail; maintaining two config files creates drift.

## Decision

- Use only the V1 `permission` object in `opencode.jsonc`.
- Do not add a `permissions` key. OpenCode 1.x rejects it even when `permission` is also present.
- Use V1 permission frontmatter in `.opencode/agents/*.md`. V1 calls the subagent tool `task`; V2 converts it to `subagent`.
- Keep global read denials for secrets. Do not add an agent-level `read: allow` that would override them.
- Verify both runtimes when both are installed:
  - `opencode debug config` and `opencode agent list`
  - `tools\opencode-v2\opencode.exe debug config` and `tools\opencode-v2\opencode.exe debug agents`
- Treat a mismatch as a harness failure in `scripts/harness-doctor.ps1`.

## Alternatives considered

- **Require OpenCode 2.x.** Rejected: the installed default is V1, and the user wants the harness to run without changing the host.
- **Maintain `opencode.jsonc` and `opencode.v2.jsonc`.** Rejected: duplicate permission rules drift and the wrong file is easy to load.
- **Use only V2 `permissions`.** Rejected: V1 fails at startup.
- **Remove permission rules to satisfy both.** Rejected: it removes the destructive-action and secret-read gates.

## Consequences

- The shared config cannot use V2-only ordered-rule features directly. V2 converts V1 rules at load time, and the resolved order is tested with `debug config`.
- V1 and V2 are both first-class supported runtimes for this repository.
- V2 remains optional. `install-opencode-v2.ps1` installs it only when the user wants it.
- Permission behavior must be re-tested after editing agent frontmatter or `opencode.jsonc`.
