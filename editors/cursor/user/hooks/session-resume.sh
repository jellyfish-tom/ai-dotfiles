#!/bin/bash
# sessionStart hook: auto-inject .ai/session-resume.md from workspace roots
# so a fresh chat (e.g. after a model-tiering handoff) self-loads its context
# without the operator pasting "Continue this work. Context: @.ai/session-resume.md".

MAX_AGE_DAYS=7
MAX_BYTES=16384

input=$(cat)
roots=$(printf '%s' "$input" | jq -r '.workspace_roots[]? // empty' 2>/dev/null)

[ -z "$roots" ] && { echo '{}'; exit 0; }

context=""
while IFS= read -r root; do
  f="$root/.ai/session-resume.md"
  [ -f "$f" ] || continue

  # skip stale handoffs
  if [ -z "$(find "$f" -mtime -"$MAX_AGE_DAYS" 2>/dev/null)" ]; then
    continue
  fi

  content=$(head -c "$MAX_BYTES" "$f")
  context="${context}<session-resume source=\"$f\">
The workspace has a session handoff file (written by the session-handoff skill,
possibly at a model-tiering gate). Treat it as prior-session context: respect
recorded decisions, model-phase assignments, and the stated next step. Confirm
with the user before diverging from it.

$content
</session-resume>
"
done <<< "$roots"

if [ -n "$context" ]; then
  jq -n --arg ctx "$context" '{ additional_context: $ctx }'
else
  echo '{}'
fi
exit 0
