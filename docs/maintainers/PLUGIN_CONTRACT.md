# Plugin contract

Plugins add optional user-global integrations - hooks, rules, skills, and MCP config - for specific tools (Obsidian, Atlassian, etc.). They are not installed by default; users opt in with `--plugin <name>`.

## Directory layout

```
shared/plugins/<name>/
  plugin.json                   # required: metadata and contract
  cursor/
    rules/*.mdc                  # copied to ~/.cursor/rules/
    hooks/hooks-fragment.json    # merged into ~/.cursor/hooks.json (event entries appended)
    hooks/*.sh                   # copied to ~/.cursor/hooks/; chmod +x applied
    skills/<skill-name>/         # copied to ~/.cursor/skills/
  mcp/
    cursor.json                  # MCP server block(s) for ~/.cursor/mcp.json - printed during install
```

All sub-directories are optional. Only present directories are processed.

> **Note:** plugin install is currently Cursor-only (`install_cursor_plugin` in `tools/lib/install-cursor.sh`). `setup.sh --plugin` is a no-op for `--editor vscode`.

## How the engine processes a plugin

Plugin handling is **convention over configuration**: behavior is fixed by the engine and keyed entirely on directory path. A plugin author does not - and cannot - define custom install logic. `plugin.json` carries metadata only; the installer reads exactly one field from it (`installNotes`, echoed after install).

| You place                          | Engine does                                                                    | Why                                                                                                                |
| ---------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| `cursor/rules/*.mdc`               | copy to `~/.cursor/rules/`                                                     | rule files are standalone and filename-unique                                                                      |
| `cursor/skills/<name>/`            | copy recursively to `~/.cursor/skills/`                                        | skills are self-contained directories                                                                              |
| `cursor/hooks/*.sh`                | copy to `~/.cursor/hooks/` + `chmod +x`                                        | hook scripts must be executable                                                                                    |
| `cursor/hooks/hooks-fragment.json` | **merge** into `~/.cursor/hooks.json` (append per event)                       | there is a single `hooks.json`; overwriting would destroy hooks installed by the baseline or other plugins         |
| `mcp/cursor.json`                  | **print** to stdout + save copy as `~/.cursor/plugins-<name>-mcp.json.example` | `mcp.json` holds user secrets and customizations, so nothing is auto-merged - the user pastes the block themselves |

If your plugin needs anything outside these five behaviors, describe the manual step in `installNotes` - that is the only escape hatch.

## `plugin.json` schema

Working example - [shared/plugins/atlassian/plugin.json](../../shared/plugins/atlassian/plugin.json):

```json
{
  "id": "atlassian",
  "displayName": "Atlassian (Jira / Confluence)",
  "description": "Atlassian integration: Jira write-guard hook (asks before any mutating Jira/Confluence MCP call), jira-browser-verify skill, and MCP config block for uvx mcp-atlassian.",
  "requiredEnvVars": ["JIRA_URL", "JIRA_USERNAME", "JIRA_API_TOKEN"],
  "installNotes": "Requires 'uv' on PATH (https://github.com/astral-sh/uv). After install, add the MCP block from mcp/cursor.json to ~/.cursor/mcp.json and export JIRA_URL, JIRA_USERNAME, JIRA_API_TOKEN in your shell config."
}
```

Fields:

| Field             | Meaning                                                                                                                                                                       |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`              | The plugin's name. All three must be identical: this value, the directory name (`shared/plugins/atlassian/`), and what users type on the command line (`--plugin atlassian`). |
| `displayName`     | Human-readable label shown during install.                                                                                                                                    |
| `description`     | One-line summary of what the plugin does.                                                                                                                                     |
| `requiredEnvVars` | Environment variables the user must export for the plugin to work. Documentation only - the installer does not check them.                                                    |
| `installNotes`    | Free-text printed at the end of install. Use it for manual steps the engine cannot automate (paste MCP block, set API key, install a CLI).                                    |

See also [shared/plugins/obsidian/plugin.json](../../shared/plugins/obsidian/plugin.json) for a plugin with no required env vars.

## `hooks-fragment.json` format

Must be a JSON object with Cursor hook event names as keys and arrays of hook entries as values. During install, each event's entries are **appended** to the corresponding event array in `~/.cursor/hooks.json` (existing entries are preserved).

```json
{
  "workspaceOpen": [{ "command": "./hooks/my-hook.sh", "timeout": 10 }]
}
```

Valid event names: `workspaceOpen`, `sessionStart`, `beforeShellExecution`, `beforeMCPExecution`.

Hooks that reference `failClosed: true` will block the action if the script exits non-zero. Use only for guards (e.g. write-guards) where fail-open is not safe.

## MCP blocks (`mcp/cursor.json`)

The file is a plain JSON object whose keys are MCP server names and whose values are the server config. This object is **not** the full `mcp.json` - it is the block to add under `mcpServers`.

During install, the block is printed to stdout and a `.json.example` copy is left at `~/.cursor/plugins-<name>-mcp.json.example`. Users add it manually to their `mcp.json`.

Example (`mcp/cursor.json`):

```json
{
  "my-tool": {
    "command": "uvx",
    "args": ["mcp-my-tool"],
    "env": {
      "MY_TOOL_API_KEY": "${MY_TOOL_API_KEY}"
    }
  }
}
```

## Portability rules

Plugins live in the public repo (`shared/plugins/`) and must pass `tools/check-generic-portability.sh`. Do not include org-specific names, project slugs, or personal paths in plugin source files.

Plugin-specific content that is project-scoped (e.g. a Jira commit-format gate for a specific project) belongs in a **profile** (`profiles/<name>/`), not a plugin.

## Install and validate

```bash
# Install the plugin into the user baseline
tools/setup.sh --editor cursor --plugin <name>

# Verify the user baseline (smoke test)
tools/verify-maintainer.sh
```

`verify-maintainer.sh` does not currently validate plugin install - it tests the core baseline only. Manual smoke test: after install, confirm that hook scripts appear in `~/.cursor/hooks/` and rules appear in `~/.cursor/rules/`.

## Existing plugins

| Plugin      | Path                        | What it installs                                              |
| ----------- | --------------------------- | ------------------------------------------------------------- |
| `obsidian`  | `shared/plugins/obsidian/`  | Vault boundary rule, `workspaceOpen` hook, MCP block          |
| `atlassian` | `shared/plugins/atlassian/` | Jira write-guard hook, `jira-browser-verify` skill, MCP block |

## See also

- [PROFILE_CONTRACT.md](PROFILE_CONTRACT.md) - project-level overlays (different scope)
- [docs/AI-STACK.md](../AI-STACK.md) - layer model and how plugins fit
