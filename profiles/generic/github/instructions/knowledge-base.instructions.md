---
description: Hybrid knowledge routing - repo normative docs vs Obsidian vault vs agentmemory. Use when creating, moving, or reading documentation.
applyTo: "**"
---

# Knowledge base (hybrid)

## Three layers (precedence)

| Priority | Store              | Path / tool                                                      | Holds                                                                                         |
| -------- | ------------------ | ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| 1        | **Repo**           | `docs/`, `.github/`, `AGENTS.md`, `.cursor/docs/`                | Contracts, specs, agent entrypoints, co-located feature docs, pipeline prompts tied to code   |
| 2        | **Obsidian vault** | Obsidian MCP (`obsidian` server) or `~/Documents/Obsidian Vault` | Working notes, research, product backlogs, migration epics, session logs, cross-project links |
| 3        | **agentmemory**    | MCP `agentmemory`                                                | Ephemeral cross-session recall (preferences, lessons); not durable specs                      |

Read **repo first**. Query **Obsidian** when repo docs are thin, moved, or operator names a vault note. Use **agentmemory** for short-lived recall, not canonical specs.

## Vault layout

```
Obsidian Vault/
├── Templates/              # Templater sources
├── 00-inbox/               # quick capture
├── Projects/{repo}/        # per-project working docs
│   └── repo-docs/          # symlink → {repo}/docs (read-only in vault)
├── Research/               # cross-cutting research
├── Session-logs/           # handoffs, debug sessions
├── AI/                     # tooling, local env setup
└── Home.md                 # dashboard
```

Default vault: `~/Documents/Obsidian Vault`.

**Cursor:** vault is **outside** the workspace. Use Obsidian MCP for vault access; cite vault notes with `obsidian://` links (see `obsidian.instructions.md`). Repo symlinks (e.g. `novus/.mlem/`) remain in workspace.

## Repo vs vault - decision gate

| Question                                                                | Location                |
| ----------------------------------------------------------------------- | ----------------------- |
| Would a PR reviewer need this?                                          | Repo                    |
| Does `AGENTS.md` or `docs/README.md` route agents here?                 | Repo                    |
| Is it a contract, ADR, commit convention, or layer prompt tied to code? | Repo                    |
| Is it draft, personal, cross-project, or a migration epic?              | Vault                   |
| Is it product ideation beyond current POC scope?                        | Vault                   |
| Is it a session handoff or investigation log?                           | Vault (`Session-logs/`) |

When moving repo → vault: leave a **stub** in the repo path pointing to the vault file. Update `docs/README.md` maps. Do not delete routing without a stub.

## Agent actions (Obsidian MCP)

When Obsidian MCP is enabled and Obsidian is running:

1. **Search** vault before re-deriving domain context the operator may have captured.
2. **Create** new working notes under `Projects/{repo}/` or `Session-logs/` with YAML frontmatter (see below).
3. **Do not** move normative contracts into the vault without operator approval.
4. **Link** vault notes to repo paths in `## References` (e.g. `flow-observer/docs/PLAN.md`).

If MCP is unavailable: read/write vault files directly when the vault folder is in the workspace.

## Frontmatter (vault + durable repo docs)

```yaml
---
type: project-note | daily | session-handoff | jira-context | adr | research
project: novus | flow-observer | aio-main | personal
status: draft | active | archived
tags: []
created: YYYY-MM-DD
---
```

Repo contracts may add `layer`, `market`, `jira` when useful for Dataview.

## Session handoff

Prefer vault for durable handoffs: `Session-logs/{project}/YYYY-MM-DD-handoff.md`.

Also acceptable: `.ai/session-resume.md` in repo for same-session Cursor continuity (see [session-state.instructions.md](./session-state.instructions.md)).

Load `session-handoff` skill for structure. Optionally duplicate summary to agentmemory.

## Templates

Vault templates live in `Templates/`. Use Templater or QuickAdd - do not invent ad-hoc formats.

| Template          | Use                         |
| ----------------- | --------------------------- |
| `daily-note`      | Periodic daily capture      |
| `session-handoff` | Context reset between chats |
| `jira-context`    | Ticket investigation        |
| `project-note`    | New project working page    |
| `research-note`   | Design spikes, comparisons  |

## Symlinks

`Projects/{repo}/repo-docs` symlinks to `{repo}/docs` - one file on disk, visible in Obsidian graph. Edit in Cursor or Obsidian.

### `.mlem/` (novus operator workspace)

| Repo path              | Vault                                        |
| ---------------------- | -------------------------------------------- |
| `.mlem/docs/`          | `Projects/novus/mlem/docs/`                  |
| `.mlem/test-personas/` | `Projects/novus/mlem/test-personas/`         |
| `.mlem/swagger.json`   | `Projects/novus/mlem/reference/swagger.json` |

Repo `.mlem/` holds symlinks only; canonical content in vault. `jira-browser-verify` keeps using `.mlem/` paths.

## Related

- [obsidian.instructions.md](./obsidian.instructions.md) - MCP setup, plugins, troubleshooting
- `session-handoff` skill - handoff workflow
