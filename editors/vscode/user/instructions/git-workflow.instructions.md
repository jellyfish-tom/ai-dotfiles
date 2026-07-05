---
description: "Use when handling git workflow, testing, commit, push, add/commit/push, or ACP requests. Enforces no automatic test runs and no automatic commits or pushes."
---

# Git Workflow Rules

## Critical: No Automatic Test Runs

- Never run `npm test`, `npm run test`, or any other test command without the user's explicit request.
- Do not run tests "to verify" changes unless the user explicitly asked for tests.
- Explicit requests include phrases such as `run tests`, `test this`, `check if tests pass`, or `npm test`.
- If tests seem useful, ask the user first.

## Critical: No Automatic Commits Or Pushes

- Never run `git commit` or `git push` without the user's explicit request.
- You may stage files proactively with `git add` only when preparing for a commit the user clearly requested.
- Wait for an explicit request such as `commit`, `push`, `acp`, `commit this`, or `push it` before committing or pushing.
- If intent is unclear, ask first.

## ACP Rules

When the user explicitly requests `acp`, `add commit push`, or `commit and push`:

1. Analyze uncommitted changes with `git status` and `git diff --stat`.
2. Stage all changes with `git add -A`.
3. Create a concise conventional commit message from the diff (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`).
4. Run `git commit -m "..."` and `git push` only when the user requested push.

When a loaded project profile defines a custom commit format, follow that profile's git-workflow or operator-context instructions instead.

## Safety: Destructive Commands

- Do not execute destructive or data-loss commands without explicit written approval.
- Destructive commands include deletion, truncation, overwrite, database drops, clean/reset operations, or irreversible bulk modification.
- When such a command seems necessary, first describe the command and its effect, then wait for confirmation.
- Prefer non-destructive alternatives by default.
