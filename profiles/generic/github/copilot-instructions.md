---
description: Project-level entrypoint for VS Code Copilot customizations copied from ai-dotfiles into a target repository.
---

# Project Copilot Instructions

Use this file as the always-on entrypoint for the copied project scaffold.

## Start Here

- Read [../AGENTS.md](../AGENTS.md) for the cross-agent entrypoint and workflow map.
- Read the scoped files under [.github/instructions](./instructions), [.github/prompts](./prompts), and [.github/agents](./agents) when the task matches them.
- Keep changes narrow and validate with the smallest relevant check.
- Preserve portability by preferring `${HOME}` and `${workspaceFolder}` in templates over machine-specific paths.

## Knowledge base

- Read [.github/instructions/knowledge-base.instructions.md](./instructions/knowledge-base.instructions.md) for hybrid repo + Obsidian vault documentation rules.
- Optional: Obsidian MCP in Cursor for vault read/write (`obsidian.instructions.md`).

## Session state

- Read [.github/instructions/session-state.instructions.md](./instructions/session-state.instructions.md) for multi-step `.ai/` tracking (progress, change-log, open-questions, session-resume).

## Project Template Map

- `.github/instructions/` contains project-level rules and routing guidance.
- `.github/prompts/` contains focused prompts for bounded workflows.
- `.github/agents/` contains reusable custom-agent definitions.
- `.github/docs/` contains project supplements loaded by related workflows.
- `.vscode/` contains workspace MCP templates.
- `profiles/` contains optional project-specific overlays installed via `--profile` (bundled under `profiles/`, e.g. `_starter`).

## Working Rules

- Treat this scaffold as a starting point. Remove or adapt project-specific files that do not fit the target repository.
- Keep generic instructions separate from any project-specific profile or add-on layer.
- Prefer incremental template changes that keep copied projects easy to understand.