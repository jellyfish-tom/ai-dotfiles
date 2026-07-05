# Cursor setup

Install Cursor AI config from **ai-dotfiles**.

## One-command bootstrap

Complete the [README quick start](../../README.md#-quick-start) first (`AI_DOTFILES`, clone location).

A **profile** (`--profile <name>`) selects the overlay from `profiles/<name>/` and applies its install defaults from `profile.json`. Use the same profile name when validating.

```bash
export AI_DOTFILES="${AI_DOTFILES:-$HOME/ai-dotfiles}"
```

```bash
"$AI_DOTFILES/tools/setup.sh" --editor cursor --profile _starter --repo /path/to/your-app
```

```bash
"$AI_DOTFILES/tools/validate.sh" --editor cursor --profile _starter --repo /path/to/your-app
```

To author a custom profile, see [PROFILE_CONTRACT.md](../maintainers/PROFILE_CONTRACT.md).

## What gets installed

| Source                                                                          | Destination                                                                                  |
| ------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `editors/cursor/user/rules/*.mdc`                                               | `~/.cursor/rules/`                                                                           |
| `editors/cursor/user/skills/*`                                                  | `~/.cursor/skills/`                                                                          |
| `editors/cursor/mcp.json.example`                                               | `~/.cursor/mcp.json`                                                                         |
| `editors/cursor/project/rules/*.mdc`                                            | `<repo>/.cursor/rules/` (generic)                                                            |
| `editors/cursor/project/commands/*.md.example`                                  | `<repo>/.cursor/commands/` (strip `.example`; skipped when profile ships `cursor/commands/`) |
| `profiles/generic/docs/*.md`                                                    | `<repo>/.cursor/docs/` (generic)                                                             |
| `profiles/<name>/cursor/rules/`                                                 | `<repo>/.cursor/rules/` (profile overlay)                                                    |
| `profiles/<name>/cursor/commands/`                                              | `<repo>/.cursor/commands/`                                                                   |
| `profiles/<name>/cursor/docs/`                                                  | `<repo>/.cursor/docs/`                                                                       |
| `profiles/<name>/test-personas/`                                                | `<repo>/.mlem/test-personas/`                                                                |
| [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) via installer | `<ai-dotfiles>/.agents/skills/` and `<repo>/.agents/skills/`                                 |

## Caveman token optimization

`setup.sh --editor cursor` installs the [caveman](https://github.com/JuliusBrussee/caveman) skill stack when `node` and `npx` are available:

- **Rules:** `005-caveman.mdc` in `~/.cursor/rules/` only (user baseline) - always-on terse mode (~75% fewer output tokens). Do not duplicate in `.cursor/rules/` per repo.
- **Skills:** `caveman`, `cavecrew`, `caveman-commit`, `caveman-compress`, `caveman-help`, `caveman-review`, `caveman-stats` → `.agents/skills/`.
- **Pin file:** `skills-lock.json` in the repo root records upstream hashes from `JuliusBrussee/caveman`.

Manual reinstall or upgrade:

```bash
cd "$AI_DOTFILES"
npx -y github:JuliusBrussee/caveman -- --only cursor --non-interactive
```

For a target repo only:

```bash
cd /path/to/your-app
npx -y github:JuliusBrussee/caveman -- --only cursor --non-interactive
```

`.agents/` and `skills-lock.json` are **local-only** (installed cache + caveman pin). `setup.sh --repo` appends them to `.git/info/exclude` so they stay out of `git status` without editing project `.gitignore`. Optional operator overlay patterns: `shared/snippets/git-info-exclude.operator-overlay.mlem.example`.

## Manual step: User Rules cards

Copy sections from `editors/cursor/user/user-rules.md` into **Cursor Settings → Rules → User** (one card per section). The setup script installs global `.mdc` rules automatically; the cards cover settings UI conventions.

## After bootstrap

1. Fully quit and restart Cursor (Cmd+Q on macOS)
2. If using Atlassian plugin: export `JIRA_URL`, `JIRA_USERNAME`, `JIRA_API_TOKEN`
3. Use slash commands: type `/` in agent input (e.g. `/jira-issue PROJ-123`)

## Cursor vs VS Code

| Capability     | Cursor                                                                 | VS Code                                                 |
| -------------- | ---------------------------------------------------------------------- | ------------------------------------------------------- |
| Project rules  | `.cursor/rules/*.mdc`                                                  | `.github/instructions/*.instructions.md`                |
| Workflows      | `.cursor/commands/*.md`                                                | `.github/prompts/` + agents                             |
| Skills         | `.github/skills/` (generic includes `jira-browser-verify`)             | `~/.cursor/skills/` + `.agents/skills/` (caveman stack) |
| Browser QA     | `jira-browser-verify` skill + `.github/docs/browser-verify.project.md` | same skill + `.cursor/docs/browser-verify.project.md`   |
| Knowledge base | `.github/instructions/knowledge-base.instructions.md`                  | same + optional Obsidian MCP in `~/.cursor/mcp.json`    |

### Obsidian (recommended split)

Hybrid = repo normative docs + vault working notes. Wired in ai-dotfiles at several layers (all portable except vault path and REST API key):

| Layer                | Source in ai-dotfiles                                                 | Installed to                                           |
| -------------------- | --------------------------------------------------------------------- | ------------------------------------------------------ |
| MCP server           | `editors/cursor/mcp.json.example` (`obsidian` block)                  | `~/.cursor/mcp.json` (set Bearer from Obsidian plugin) |
| User rule            | `editors/cursor/user/rules/002-obsidian.mdc`                          | `~/.cursor/rules/`                                     |
| User Rules card      | `editors/cursor/user/user-rules.md` Rule 8                            | Cursor Settings → Rules → User (manual)                |
| Hybrid routing       | `profiles/generic/github/instructions/knowledge-base.instructions.md` | `<repo>/.github/instructions/` via setup               |
| Vault ops            | `profiles/generic/github/instructions/obsidian.instructions.md`       | same                                                   |
| Multi-repo workspace | `editors/cursor/dev.code-workspace.example`                           | copy to `~/dev.code-workspace` (edit folder paths)     |

Setup steps:

1. Install Obsidian + Local REST API plugin; enable HTTP server on port 27123.
2. Add `obsidian` block from `editors/cursor/mcp.json.example` to `~/.cursor/mcp.json`.
3. **Do not** add the vault to the Cursor workspace - open a multi-repo `.code-workspace` with code repos only.
4. User rule `002-obsidian.mdc` is installed to `~/.cursor/rules/` - vault via MCP + `obsidian://` links.
5. Read `knowledge-base.instructions.md` and `obsidian.instructions.md` for hybrid rules.

Open workspace: **File → Open Workspace from File…** → your copied `dev.code-workspace`

Run `tools/check-rule-parity.sh --profile <name>` after editing paired content.
