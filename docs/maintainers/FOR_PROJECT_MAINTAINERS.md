# For Project Maintainers

Use the generic `profiles/generic/` scaffold as the default base. Public profiles ship in `profiles/_starter/`.

## Canonical content model

| Editor  | User baseline                       | Project scaffold           | Profile overlay                                       |
| ------- | ----------------------------------- | -------------------------- | ----------------------------------------------------- |
| VS Code | `editors/vscode/user/instructions/` | `profiles/generic/github/` | `profiles/<name>/github/` (bundled under `profiles/`) |
| Cursor  | `editors/cursor/user/rules/`        | `editors/cursor/project/`  | `profiles/<name>/cursor/`                             |

Profile `.github/` is canonical for skills, agents, and Copilot instructions. The Cursor overlay holds `.mdc` rules, slash commands, and project docs. Run `tools/check-rule-parity.sh --profile <name>` after editing paired content.

Shared MCP servers, agentmemory, codegraph, and optional Obsidian live under `shared/` and `profiles/generic/github/instructions/knowledge-base.instructions.md`.

**Optional third knowledge layer:** operators may keep working notes in an Obsidian vault (`~/Documents/Obsidian Vault`) while repo `docs/` stays normative. Agents route via `knowledge-base.instructions.md` + Obsidian MCP - not part of the generic scaffold install unless the operator configures it.

### Obsidian + hybrid split (where it lives)

| Concern                                | Canonical path                                                        | Portable?                       |
| -------------------------------------- | --------------------------------------------------------------------- | ------------------------------- |
| MCP `obsidian` server                  | `editors/cursor/mcp.json.example`                                     | Yes (Bearer key is per-machine) |
| Workspace boundary rule                | `editors/cursor/user/rules/002-obsidian.mdc`                          | Yes                             |
| User Rules card (duplicate)            | `editors/cursor/user/user-rules.md` Rule 8                            | Yes                             |
| Hybrid doc routing                     | `profiles/generic/github/instructions/knowledge-base.instructions.md` | Yes                             |
| Vault MCP ops + `obsidian://` links    | `profiles/generic/github/instructions/obsidian.instructions.md`       | Yes                             |
| Multi-repo workspace (no vault folder) | `editors/cursor/dev.code-workspace.example`                           | Paths are operator-specific     |
| Plugin recommendation                  | `shared/plugins.md`                                                   | Yes                             |

**Not portable / operator-local:** REST API key in `~/.cursor/mcp.json`, vault filesystem path if not default, copied `.code-workspace` paths, extra `.git/info/exclude` lines from `shared/snippets/git-info-exclude.operator-overlay.mlem.example` (e.g. hiding local `.github/` overlay from git status).

`setup.sh --editor cursor --repo PATH` appends `shared/snippets/git-info-exclude.ai-tooling.mlem` to `.git/info/exclude` so `.cursorignore`, `skills-lock.json`, `.agents/skills/`, and `.clinerules/` stay out of git without touching project `.gitignore`.

## Profiles

- **Public:** `profiles/_starter/` - smoke-test stand-in and reference implementation.
- **Custom:** add `profiles/<name>/` in this repo (see [PROFILE_CONTRACT.md](./PROFILE_CONTRACT.md)).

## Scripts

- `tools/pack.sh` - maintainer sync from live checkout into a profile; `--profile NAME --repo PATH` (add `--sync-user-baseline` only when intentionally refreshing user rules from your machine)
- `tools/setup.sh` - end-user bootstrap; `--editor vscode|cursor|both`, `--profile <name>`
- `tools/validate.sh` - end-user verification; `--profile <name>`
- `tools/check-generic-portability.sh` - blocks project-specific strings in public tree (see [PORTABILITY_ALLOWLIST.md](./PORTABILITY_ALLOWLIST.md))
- `tools/check-public-ready.sh` - public publish gate (portability + `_starter` smoke)
- `tools/check-profile-parity.sh` - compares profile against live repo; `--profile NAME --repo PATH`
- `tools/check-rule-parity.sh` - warns when paired mdc/instructions diverge
- `tools/verify-maintainer.sh` - chains validate, portability, parity, and clean-room smoke tests

## Review checklist

Before merging changes, check:

1. the public tree passes `tools/check-public-ready.sh`
2. new templates are documented in README or the relevant setup doc
3. new scripts pass syntax checks
4. bootstrap and validation flows still match the shipped files
5. `tools/check-generic-portability.sh` passes before merging scaffold changes
6. `tools/check-profile-parity.sh` passes when a profile changed (with `--repo`)
7. `tools/check-rule-parity.sh` passes when paired rules/instructions changed
8. `tools/verify-maintainer.sh` passes when shipped scaffold behavior changed
9. autostart templates still expose a readable status path for bridge health and config drift

## Legacy repos

**vscode-dotfiles** and **cursor-dotfiles** are deprecated. Do not maintain duplicate content in those repos.
