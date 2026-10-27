# ADR-0002: Pair one canonical harness with thin host adapters and a four-domain workflow

- Status: Accepted
- Date: 2026-10-27

## Context

The harness started as an OpenCode-only environment. It now needs to work when the user opens the repository in Codex, the VS Code Claude extension, Antigravity, DSH, or another `AGENTS.md`-aware agent. The same user also wants the agent to reason about business problems and solution design, not only emit APEXLang syntax.

Two constraints shape the decision:

1. **No paid API keys.** The user wants free tiers, local models, or an existing subscription login. Metered API keys are out of scope.
2. **Deterministic quality.** Hosts and models vary widely. The harness cannot rely on model memory for APEX syntax or on a model's claim that a change works.

Duplicating the full instruction set per host would drift. Installing every available agent framework would add services, credentials, and maintenance surface unrelated to APEX.

## Decision

- Keep `AGENTS.md` as the single canonical instruction set.
- Add thin, host-native adapters:
  - `CLAUDE.md` and `.claude/skills/oracle-apex/SKILL.md` for Claude Code and the VS Code Claude extension.
  - `.agents/skills/oracle-apex.md` and `.agents/rules/oracle-apex.md` for DSH and Antigravity.
  - Codex reads `AGENTS.md` directly; OpenCode keeps `opencode.jsonc`.
- Add `skills/apex-domains/` as the four-domain orchestration skill:
  1. business analysis and domain modeling,
  2. APEX application design,
  3. PL/SQL implementation,
  4. APEXLang implementation.
- Keep the vendored Oracle `apex` and `db` trees authoritative for syntax and database detail. The new skill routes to them; it does not replace them.
- Default OpenCode to zero-cost models and add `-StrictNoKeys` to the doctor. The doctor reports key names, never values, and does not read or use the keys.
- Give each host a no-key path where one exists. State clearly that Claude Code has no official $0 local-model mode and that local model quality is the main risk.
- Keep SQLcl validation, PL/SQL tests, and explicit deployment approval as the gates regardless of host or model.

## Alternatives considered

- **Duplicate full instructions per host.** Rejected: guaranteed drift, and every APEX rule would need to be updated in five places.
- **Install every host globally and configure them all.** Rejected for now: Claude Code, Antigravity, and DSH are not installed here; global configuration would add side effects before the adapters are proven. The portable files can be tested as the hosts become available.
- **Use paid API providers for quality.** Rejected: violates the no-paid-key constraint. The harness documents the quality trade-off instead of hiding it.
- **One giant APEX skill.** Rejected: business analysis, application design, PL/SQL, and APEXLang have different references and review criteria. The four-domain skill keeps each mode explicit while sharing one workflow.
- **Put business rules in page processes.** Rejected: rules would be unreachable from APIs, batch jobs, and other pages, and would be hard to test. Packages remain the implementation home.

## Consequences

- Adapters are small and must be kept in sync when `AGENTS.md` changes. The doctor checks that they exist.
- The four-domain skill adds a deliberate design step before coding. Small changes can skip the full ceremony, but new features should not.
- OpenCode's free model is convenient but may be weaker at complex APEXLang and PL/SQL. Validation remains mandatory; the harness does not claim model quality it cannot prove.
- Claude Code requires a subscription login or an Anthropic-compatible endpoint. Users without one should choose Codex, Antigravity, DSH, or OpenCode.
- DSH and Antigravity are not installed in this environment, so their adapters are prepared but not end-to-end tested. This is a known residual risk.
- No API key is stored or required. If a paid-key variable exists in the user's shell, the doctor warns and the harness ignores it.
