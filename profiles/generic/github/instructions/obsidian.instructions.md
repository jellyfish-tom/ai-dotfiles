---
description: Obsidian vault operations for AI agents - MCP, plugins, templates, maintenance.
applyTo: "**"
---

# Obsidian (agent operations)

## MCP connection

- **Plugin:** Local REST API with MCP (in Obsidian)
- **Cursor config:** `~/.cursor/mcp.json` → `http://127.0.0.1:27123/mcp` (HTTP, not HTTPS - self-signed TLS breaks Cursor)
- **Auth:** Bearer token from plugin settings
- **Requires:** Obsidian app running with plugin enabled

**Workspace split (configured):** the vault is **not** in the Cursor workspace. Agents use **Obsidian MCP** for vault I/O. Operators read vault notes in the **Obsidian app**.

## Citing vault notes in chat

Use Obsidian URI links so clicks open Obsidian (not Cursor):

```markdown
[novus mlem](obsidian://open?vault=Obsidian%20Vault&file=Projects/novus/mlem/README)
```

| Parameter | Value                                        |
| --------- | -------------------------------------------- |
| `vault`   | `Obsidian%20Vault`                           |
| `file`    | vault-relative path (e.g. `Work/IPF/Domain`) |

Do not use `` `~/Documents/Obsidian Vault/...` `` path citations for vault notes in user-facing output.

## Sensitive paths (do not read via MCP unless asked)

- `Personal/admin-sensitive/`
- `Personal/Domek/Dane.md`
- Notes tagged `sensitive` in frontmatter

## Installed plugin stack (operator)

Tier 1–3 installed: Git, Templater, Dataview, Tasks, Omnisearch, QuickAdd, Excalidraw, Periodic Notes, Calendar, Kanban, Breadcrumbs, Meta Bind, Linter, Homepage, Advanced URI, Shell commands, Paste image rename, Table Editor.

Agents: prefer **Dataview** queries in dashboard notes; use **Templater** paths from `Templates/`; do not rely on plugin UIs in automation.

## Write conventions

- **Wikilinks:** `[[note-name]]` or `[[Projects/flow-observer/research/ollama-timeline]]`
- **Attachments:** `Work/` or note-adjacent folders; rename on paste (plugin)
- **Tags:** prefer frontmatter `tags:` over inline `#tag` for Dataview
- **New project page:** `Projects/{repo}/{topic}.md` with `type: project-note`

## Maintenance (agents)

When creating documentation:

1. Classify with [knowledge-base.instructions.md](./knowledge-base.instructions.md) gate.
2. Place file in correct tree; add frontmatter.
3. Update repo stub or `docs/README.md` if repo routing changes.
4. Link from `Home.md` or project index when the note is a long-lived entry point.

## Troubleshooting

| Symptom            | Fix                                                            |
| ------------------ | -------------------------------------------------------------- |
| MCP `fetch failed` | Use `http://127.0.0.1:27123/mcp`; enable HTTP server in plugin |
| Tools missing      | Obsidian not running or plugin disabled                        |
| Stale graph        | Normal - file watcher ~1s lag                                  |
