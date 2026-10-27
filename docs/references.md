# External References

## Oracle APEX Developer Cookbook (reviewed, not vendored)

Source: https://github.com/srinivaskikkuru/Developer-Cookbook

The repository collects practical Oracle APEX standards. It is useful as a style and review reference, but it has no license file, so it was not copied into this harness. Link to it or obtain permission before redistributing its content.

| File | What it covers | Harness use |
| --- | --- | --- |
| `Oracle-Apex-Developer-Cookbook.md` | Naming, SQL/PLSQL, page and region design, Interactive Reports, JavaScript, CSS, security, performance, version control, testing, deployment, maintenance. | Review checklist for generated APEX apps. |
| `apex-auth-process.md` | Authentication and authorization design with Azure/SAML social login, ERP and Active Directory data sources, RBAC. | Reference for auth design; verify against current APEX documentation. |
| `Oracle-apex-js-standards.md` | JavaScript and jQuery standards for APEX, including `let`/`const`, strict mode, modular functions, and file layout. | Front-end review checklist. |
| `HTML and CSS.md` | HTML and CSS standards for APEX applications. | Front-end review checklist. |
| `Oracle SQL & PL/SQL/SQL Coding Standards Cookbook.md` | SQL formatting, naming, query patterns, and PL/SQL conventions. | SQL review checklist; the vendored `db` skills remain authoritative. |
| `Common Oracle Utility Packages and Tables.md` | Common Oracle utility packages, dictionary tables, and diagnostic queries. | Discovery aid; verify object names and privileges on the target database. |

Recommended adoption:

- Use the cookbook's naming conventions as a review heuristic, not as a hard rule. Match the existing application first.
- Treat the authentication document as a design discussion. APEX authentication schemes and current Oracle guidance take precedence.
- Do not copy SQL or PL/SQL from the cookbook without checking it against the target Oracle Database version and the vendored `db` skills.

## Vendored upstream documentation

- Oracle Skills repository: https://github.com/oracle/skills
  - APEX routing: `skills/apex/SKILL.md`
  - Database routing: `skills/db/SKILL.md`
- GitHub Spec Kit: https://github.com/github/spec-kit
  - Specification workflow: `.specify/templates/` and `.opencode/commands/speckit.*.md`
- ECC: https://github.com/affaan-m/ECC
  - Curated meta-skills: `skills/harness/`

## OpenCode

- V2 documentation: https://opencode.ai/v2/docs/
- Project configuration: `opencode.jsonc`
- Agents: `.opencode/agents/`
- Commands: `.opencode/commands/`
