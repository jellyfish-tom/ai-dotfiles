# Agentmemory setup

Persistent memory for AI coding agents via [agent-memory.dev](https://www.agent-memory.dev/). This guide covers the macOS LaunchAgent setup, storage layout, and migration to a new laptop.

Portable artifacts live in this repository under `shared/agentmemory/` (path: `$AI_DOTFILES/shared/agentmemory/`).

## What it does

- runs a local memory server on `http://localhost:3111`
- exposes a viewer UI at `http://localhost:3113`
- lets VS Code, Copilot, and other MCP clients reuse one shared memory store

## Architecture

```text
VS Code (app A)      ──┐
VS Code (other app) ──┼── MCP ──► localhost:3111 ──► ~/agentmemory-runtime/data/
VS Code (side proj) ──┘              ▲
                          LaunchAgent (login + KeepAlive)
```

## File locations

| What                    | Path                                                  |
| ----------------------- | ----------------------------------------------------- |
| Memory data             | `~/agentmemory-runtime/data/`                         |
| Config                  | `~/.agentmemory/.env`                                 |
| Preferences             | `~/.agentmemory/preferences.json`                     |
| Start script            | `~/agentmemory-runtime/start-agentmemory.sh`          |
| LaunchAgent plist       | `~/Library/LaunchAgents/com.agentmemory.server.plist` |
| Logs                    | `~/agentmemory-runtime/logs/`                         |
| VS Code user MCP config | `~/Library/Application Support/Code/User/mcp.json`    |
| Portable copies         | `$AI_DOTFILES/shared/agentmemory/`                     |

## Fresh install

### 1. Install agentmemory

```bash
npm install -g @agentmemory/agentmemory
```

### 2. Install the LaunchAgent

```bash
export AI_DOTFILES="${AI_DOTFILES:-$HOME/ai-dotfiles}"

chmod +x "$AI_DOTFILES/shared/agentmemory/install-launchagent.sh"
"$AI_DOTFILES/shared/agentmemory/install-launchagent.sh"
```

### 3. Configure provider keys if needed

```bash
agentmemory init
```

### 4. Wire VS Code MCP

Add this block to your VS Code user `mcp.json` if it is not already present:

```json
"agentmemory": {
  "command": "npx",
  "args": ["-y", "@agentmemory/mcp"],
  "env": {
    "AGENTMEMORY_URL": "http://localhost:3111"
  },
  "type": "stdio"
}
```

### 5. Verify

```bash
agentmemory status
open http://localhost:3113
```

## Troubleshooting

- If the service is down, check `agentmemory status`.
- If VS Code cannot reach it, confirm `AGENTMEMORY_URL` in `mcp.json` and reload chat.
- Logs live under `~/agentmemory-runtime/logs/`.
