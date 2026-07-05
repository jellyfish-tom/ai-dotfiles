---
name: session-handoff
description: Generate a compact handoff summary of progress, architecture, and goals to reset context and move to a new chat. Also runs at model-switch gates during phased plan execution. Use when the user asks to reset context, handoff to a new chat, clear memory, start fresh, or when a plan phase assigned to one model is complete.
---

# Session Handoff & Context Reset

## Quick Start

When the user wants to reset context, handoff to a new chat, or clear memory, follow this workflow to preserve key data and slash token costs.

This skill is also the **handoff gate** for phased, model-tiered execution (see the `model-tiering-handoff` rule): run it whenever a plan phase assigned to one model finishes, then stop and tell the user to switch models.

### Step 1: Interactive QA (Ask First)

Before generating the summary, ask the user a few quick questions to ensure high-quality context for the next chat. Use the `AskQuestion` tool if available, or ask conversationally. For example:

1. "Are there any specific files, branches, or Jira tickets the next session MUST focus on?"
2. "Are there any recent decisions or 'do not redo' constraints I should emphasize?"
3. "What is the exact immediate next step you want the new session to tackle?"

_Wait for the user's response before proceeding to Step 2._

### Step 2: Generate and Save the Summary

Once you have the answers, create or update a handoff file (prefer `.ai/session-resume.md` or `AI_CONTEXT.md` in the project root).

Use this concise structure for the file:

```markdown
# Session Handoff

## TL;DR

- [3-5 bullets on where we are right now]

## Goals

- [Current objective and success criteria]

## Model phases & handoff protocol

- [Per-phase tier → model assignment; the gate rule; "no MAX Mode"]

## Architecture & Decisions

- [Stack, key paths, patterns in use]
- [Choices already made so we don't re-debate them]

## Current State

- [What's done, in progress, blocked]

## Next Steps

- [1-3 ordered, actionable items]

## References

- [Crucial files using @path/to/file, branches, tickets, or environment notes]
```

Include the **Model phases & handoff protocol** section whenever the work is a phased, model-tiered plan, so a fresh session enforces the model assignment without the plan open.

### Step 3: Provide Handoff Instructions

After saving the file, tell the user exactly how to proceed. Provide a copy-pasteable prompt for their new chat:

```text
**Handoff file saved to `[Filename]`.**

To start fresh:
1. Open a new chat (Cmd/Ctrl + N) or type `/clear`.
2. Paste this into the new chat:

> Continue this work. Context: @[Filename]
>
> Immediate task: [State the single next action]
```

## Model-switch gate (phased execution)

When invoked at the end of a model-tiered plan phase (not a generic context reset):

1. Update `<workspace>/.ai/session-resume.md` with the structure above, marking completed tasks, current branch/commit, and the exact next task.
2. **Verify-before-handoff**: confirm typecheck + lint + targeted tests are green before writing the gate; never hand off red.
3. Update task statuses in the plan file frontmatter (finished phase → `completed`).
4. STOP and notify the user - do not start the next phase yourself:

   > Phase [X] complete (verified green). Handoff updated to `<workspace>/.ai/session-resume.md`. **Switch model to [next-tier model]**, start a new chat, paste:
   > `Continue this work. Context: @.ai/session-resume.md - Immediate task: [next task]`

Tier → model mapping and selection policy live in the `model-tiering-handoff` rule (single source of truth).

## Core Principles

- **Keep it compact**: The summary should fit on one screen.
- **No massive code dumps**: Use file references (`@path/to/file`) instead of pasting code.
- **Preserve decisions**: Clearly state what has already been decided so the next agent doesn't reinvent the wheel.
