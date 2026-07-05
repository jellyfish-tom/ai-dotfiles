# Agentmemory (optional global service)

Persistent cross-session memory for VS Code, Cursor, and other MCP clients via [agent-memory.dev](https://www.agent-memory.dev/).

Full guide: [docs/agentmemory.md](docs/agentmemory.md)

## Quick setup on macOS

```bash
export AI_DOTFILES="${AI_DOTFILES:-$HOME/ai-dotfiles}"

npm install -g @agentmemory/agentmemory

chmod +x "$AI_DOTFILES/shared/agentmemory/install-launchagent.sh"
"$AI_DOTFILES/shared/agentmemory/install-launchagent.sh"

agentmemory init
agentmemory status
```

Ensure your editor MCP config includes the `agentmemory` block from the editor template (`editors/vscode/mcp.json.example` or `editors/cursor/mcp.json.example`), then reload your editor or restart chat.

Viewer: `open http://localhost:3113`

## See also

- [README.md](../../README.md)
- [MCP setup](../../docs/maintainers/MCP_SETUP.md)
