#!/bin/bash
# beforeShellExecution hook: ask before destructive/irreversible git commands.
# Enforces git-workflow.mdc mechanically (rules are advisory; this is a hard stop).

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.command // empty' 2>/dev/null)

if [ -z "$cmd" ]; then
  echo '{ "permission": "allow" }'
  exit 0
fi

reason=""
case "$cmd" in
  *"push --force"*|*"push -f"*|*"--force-with-lease"*)
    reason="force push rewrites remote history" ;;
  *"reset --hard"*)
    reason="hard reset discards local changes irreversibly" ;;
  *"--no-verify"*|*"--no-gpg-sign"*)
    reason="skipping hooks bypasses the AI pre-commit review gate" ;;
  *"commit --amend"*)
    reason="amend rewrites the last commit (git-workflow.mdc restricts this)" ;;
  *"clean -f"*|*"clean -xf"*|*"clean -df"*|*"clean -fd"*)
    reason="git clean permanently deletes untracked files" ;;
  *"branch -D"*)
    reason="force branch delete discards unmerged work" ;;
  *"stash drop"*|*"stash clear"*)
    reason="dropped stashes are hard to recover" ;;
esac

if [ -n "$reason" ]; then
  jq -n --arg cmd "$cmd" --arg reason "$reason" '{
    permission: "ask",
    user_message: ("Destructive git command: " + $reason),
    agent_message: ("Hook flagged this command (" + $reason + "). Per git-workflow rules, destructive git commands need explicit operator approval. Command: " + $cmd)
  }'
  exit 0
fi

echo '{ "permission": "allow" }'
exit 0
