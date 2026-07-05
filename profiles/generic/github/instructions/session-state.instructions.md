---
description: When to read and update .ai/ session-state files for multi-step work, and when to skip them.
applyTo: "**"
---

# Session state (`.ai/`)

Use tracked files under `.ai/` to avoid context drift on **substantial** work. Skip them for small, local, or answer-only tasks.

## When to use

Treat a prompt as substantial when it involves one or more of:

- multi-step implementation, refactor, or migration
- debugging that may need several investigation and fix cycles
- changes across multiple files or subsystems
- architecture planning with decisions, blockers, or handoff notes

## Before the first substantive edit

Read existing files when present:

- `.ai/progress.md`
- `.ai/change-log.md`
- `.ai/open-questions.md`
- `.ai/session-resume.md`

Create only the files you need; repos do not require a full scaffold up front.

## While working

- Update files as progress happens - not one large catch-up at the end.
- Touch only files that materially changed during the current task.
- Replace stale content in `.ai/session-resume.md` rather than appending noise.

## File roles

| File                    | Role                                                                        |
| ----------------------- | --------------------------------------------------------------------------- |
| `.ai/progress.md`       | Built vs remaining, current step, next step                                 |
| `.ai/change-log.md`     | Plain-English log of what changed and why                                   |
| `.ai/open-questions.md` | Blockers, missing inputs, approval-needed decisions, unresolved API details |
| `.ai/session-resume.md` | Compact handoff for the next chat session                                   |

## Handoff between chats

- **Same repo, next session:** prefer `.ai/session-resume.md` (this instruction).
- **Durable cross-tool handoff:** vault `Session-logs/` per [knowledge-base.instructions.md](./knowledge-base.instructions.md).
- **Structured reset:** load the `session-handoff` skill (Cursor user skill at `~/.cursor/skills/session-handoff/`).

## When not to use

Do not create or update `.ai/` files when the task is a single edit, a quick question, or work that finishes in one response without continuity benefit.
