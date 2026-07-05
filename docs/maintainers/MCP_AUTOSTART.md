# MCP Autostart

Autostart mode uses source-of-truth `stdio` MCP definitions and exposes bridged local HTTP endpoints through the active `mcp.json` that VS Code reads.

The launcher now also keeps managed bridged entries in the active `mcp.json` aligned with the source file and supports a `--status` mode for one-place bridge health plus config-drift checks.

## User-level autostart

Copy:

- `mcp.autostart.active.json.example` to your VS Code user `mcp.json`
- `mcp.autostart.sources.json.example` to your VS Code user `mcp.autostart.sources.json`

## Workspace autostart

Copy:

- `project/.vscode/mcp.autostart.active.json.example` to `.vscode/mcp.json`
- `project/.vscode/mcp.autostart.sources.json.example` to `.vscode/mcp.autostart.sources.json`
- `project/.vscode/tasks.json.example` to `.vscode/tasks.json`
- `project/scripts/startMcpAutostart.mjs` to `scripts/startMcpAutostart.mjs`

The workspace task runs `node scripts/startMcpAutostart.mjs` directly, so you do not need to patch the target repo's `package.json`.

You can also add the `Check MCP Autostart Status` task from `project/.vscode/tasks.json.example` to inspect bridge health and whether the active `mcp.json` still matches the source-of-truth autostart file.

## Required runtime pieces

- `node`
- `npx`
- `supergateway` resolvable via `npx -y supergateway`
- any CLIs used by configured servers such as `codegraph`

## Missing values

The autostart launcher reports explicit missing env vars for any server that declares `requiredEnv`.

Example:

```text
skip user/atlassian: missing env JIRA_URL
```

## Verification

Use:

```bash
node scripts/startMcpAutostart.mjs --dry-run
node scripts/startMcpAutostart.mjs --status

export AI_DOTFILES="${AI_DOTFILES:-$HOME/ai-dotfiles}"
"$AI_DOTFILES/tools/validate.sh" --repo /path/to/your-repo
```

`--status` reports two things in one place:

- whether each managed bridge is healthy
- whether the active `mcp.json` entry still matches the expected local bridge URL

VS Code's `Running` label is separate: it reflects VS Code's own MCP lifecycle, not raw bridge health.
