#!/bin/bash
# beforeMCPExecution hook: ask before mutating Jira/Confluence via the
# atlassian MCP server. Read-only tools pass through. Enforces the
# operator rule "no Jira comments/transitions without operator confirmation"
# for every repo and every model.

input=$(cat)

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
server=$(printf '%s' "$input" | jq -r '(.command // .url // "")' 2>/dev/null)

# Only guard the atlassian server; allow all other MCP calls.
if ! printf '%s' "$server $tool" | grep -qi 'atlassian\|^jira_\|^confluence_'; then
  echo '{ "permission": "allow" }'
  exit 0
fi

# Mutating verbs => ask. Everything else (get/search/list/download) => allow.
if printf '%s' "$tool" | grep -qiE '(create|update|delete|add|transition|assign|link|remove|set|upload|attach|worklog|batch|move|label|sprint|version)'; then
  args=$(printf '%s' "$input" | jq -c '.tool_input // {}' 2>/dev/null | head -c 400)
  jq -n --arg tool "$tool" --arg args "$args" '{
    permission: "ask",
    user_message: ("Jira write operation: " + $tool),
    agent_message: ("Hook: " + $tool + " modifies Jira/Confluence and needs explicit operator approval (operator-choice-gate). Args: " + $args)
  }'
  exit 0
fi

echo '{ "permission": "allow" }'
exit 0
