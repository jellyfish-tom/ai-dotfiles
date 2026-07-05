# Troubleshooting

## `code` command not found

Extension installation in `scripts/setup.sh --install-extensions` requires the VS Code `code` CLI. Install it from the VS Code command palette if needed.

## `codegraph` command not found

The codegraph MCP templates require the `codegraph` CLI on `PATH`. Install it before enabling codegraph in direct or autostart mode.

## Atlassian MCP does not start

Requires the `atlassian` plugin installed via `setup.sh --plugin atlassian`. Check:

1. `uv` is on PATH (`curl -LsSf https://astral.sh/uv/install.sh | sh`).
2. `JIRA_URL`, `JIRA_USERNAME`, `JIRA_API_TOKEN` are exported in your shell config.
3. The MCP block from `shared/plugins/atlassian/mcp/cursor.json` is present in `~/.cursor/mcp.json`.

## agentmemory does not respond

`agentmemory` is optional. If it is not running locally, remove or disable that server from your active MCP config until the service is installed.

## Obsidian MCP `fetch failed`

`obsidian` is optional. Common causes:

1. Obsidian app not running, or Local REST API plugin disabled.
2. Using `https://127.0.0.1:27124` - Cursor rejects the self-signed cert. Use `http://127.0.0.1:27123/mcp` and enable the HTTP server in plugin settings.
3. Wrong API key in `Authorization: Bearer` header.

See `profiles/generic/github/instructions/obsidian.instructions.md`.

## Figma is listed but does not work

`Figma` uses the remote Figma MCP endpoint. The local setup only copies the config; it does not grant Figma access. Confirm your own Figma-side access and any required authentication in the editor.

## Console Ninja does not respond

`console-ninja` is optional. If `~/.console-ninja/mcp/` does not exist locally, remove or disable that server from your active MCP config until Console Ninja is installed.

## Autostart task runs but no MCP server appears

Check:

1. `node scripts/startMcpAutostart.mjs --status` and confirm whether the output reports `healthy` plus `config-ok`.
2. `.vscode/mcp.autostart.sources.json` exists.
3. `scripts/startMcpAutostart.mjs` exists and `.vscode/tasks.json` runs `node scripts/startMcpAutostart.mjs`.
4. `.vscode/mcp.json` contains the active bridged HTTP config, not the source `stdio` file.
5. The server logs under `tmp/mcp-autostart/` in the target repo.

If the bridges are healthy but VS Code still shows `Stopped`, remember that VS Code's `Running` label reflects VS Code's own MCP lifecycle, not raw bridge health. Starting the server from `MCP: List Servers` or using the server from chat can flip that state.

## Template copied but instructions do not seem active

Verify:

1. `.github/copilot-instructions.md` exists in the target repo.
2. `.github/` files were copied, not only `AGENTS.md`.
3. VS Code was reloaded after copying prompt or instruction files.
