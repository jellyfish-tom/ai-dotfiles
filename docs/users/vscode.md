# VS Code setup

Install VS Code + GitHub Copilot AI config from **ai-dotfiles**.

## One-command bootstrap

Complete the [README quick start](../../README.md#-quick-start) first (`AI_DOTFILES`, clone location).

```bash
export AI_DOTFILES="${AI_DOTFILES:-$HOME/ai-dotfiles}"
```

Easiest path - run with no arguments for the interactive wizard (asks about editor, profile, plugins, repo, MCP modes; prints the equivalent flag command before installing):

```bash
"$AI_DOTFILES/tools/setup.sh"
```

Or pass flags directly:

```bash
"$AI_DOTFILES/tools/setup.sh" --editor vscode --profile _starter --repo /path/to/your-app
"$AI_DOTFILES/tools/validate.sh" --editor vscode --profile _starter --repo /path/to/your-app
```

To author a custom profile, see [PROFILE_CONTRACT.md](../maintainers/PROFILE_CONTRACT.md).

## What gets installed

| Source                                                 | Destination                                                    |
| ------------------------------------------------------ | -------------------------------------------------------------- |
| `editors/vscode/user/instructions/*.instructions.md`   | `~/Library/Application Support/Code/User/prompts/` (macOS)     |
| `editors/vscode/mcp*.example`                          | VS Code user `mcp.json` (+ autostart when profile requests it) |
| `profiles/generic/github/` + `profiles/<name>/github/` | `<repo>/.github/`                                              |
| `editors/vscode/project/.vscode/`                      | `<repo>/.vscode/`                                              |
| `editors/vscode/project/scripts/startMcpAutostart.mjs` | `<repo>/scripts/`                                              |
| `shared/extensions.txt`                                | via `code --install-extension` when profile enables extensions |

## After bootstrap

1. Run VS Code task **Start MCP Autostart** or `node scripts/startMcpAutostart.mjs` when using autostart mode
2. Reload VS Code window and restart chat
3. If using Atlassian plugin: export `JIRA_URL`, `JIRA_USERNAME`, `JIRA_API_TOKEN`

## VS Code-only features

These ship in the `.github/` layer and have no Cursor equivalent:

- `.github/agents/*.agent.md` - Copilot custom agents
- `.github/prompts/*.prompt.md` - Copilot prompt files
- `.github/skills/*/SKILL.md` - Copilot skills
- MCP autostart HTTP bridge (`.vscode/` + `startMcpAutostart.mjs`)

See also [MCP autostart](../maintainers/MCP_AUTOSTART.md).
