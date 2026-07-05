# MCP Setup

This guide covers the baseline MCP configuration shipped by **ai-dotfiles** (VS Code editor layer).

## Choose a mode

- Use direct mode when you want the simplest setup and do not need automatic bridging for `stdio` servers.
- Use autostart mode when you want VS Code to talk to local HTTP bridge endpoints backed by `stdio` MCP servers.

In autostart mode, the launcher keeps the active `mcp.json` aligned with the source-of-truth `mcp.autostart.sources.json` for the managed bridged servers.

## User-level baseline

The simplest user-level setup is:

1. Copy `mcp.json.example` to your VS Code user MCP config path.
2. Copy the desired files from `user/instructions/` into your VS Code user prompts folder.
3. Reload VS Code or restart chat.

## Workspace baseline

The simplest workspace setup is:

1. Copy `profiles/generic/github/` into the target repository.
2. Copy `project/AGENTS.md` into the target repository, or the profile `AGENTS.md` when using `--profile`.
3. Copy `project/.vscode/mcp.json.example` to `.vscode/mcp.json` in the target repo, or use the autostart templates with `--workspace-mode autostart`.
4. Copy profile `.github/skills/` when the target repo should ship profile skills via `--profile`.

## Optional servers

- `Figma` is remote HTTP and requires your own Figma access.
- `codegraph` requires the `codegraph` CLI to be installed and available on `PATH`.
- `agentmemory` requires the local agentmemory service when enabled.
- `atlassian` (Jira/Confluence) - install via `setup.sh --plugin atlassian`; requires `uv` on PATH and `JIRA_URL`, `JIRA_USERNAME`, `JIRA_API_TOKEN` in your shell config.
- `obsidian` - install via `setup.sh --plugin obsidian`; requires Obsidian running with **Local REST API** plugin at `http://127.0.0.1:27123/mcp`.

The setup script copies the templates, but it does not provision these third-party dependencies or credentials for you. After setup, run `scripts/validate.sh` and read its warnings as the checklist of anything still missing for optional services.

## Recommended verification

Run:

```bash
export AI_DOTFILES="${AI_DOTFILES:-$HOME/ai-dotfiles}"

"$AI_DOTFILES/tools/validate.sh"
"$AI_DOTFILES/tools/validate.sh" --repo /path/to/your-repo
```

For an autostart workspace, also run:

```bash
cd /path/to/your-repo
node scripts/startMcpAutostart.mjs --status
```

This gives you one-place visibility into bridge health and whether the active `mcp.json` still matches the expected bridge URLs.
