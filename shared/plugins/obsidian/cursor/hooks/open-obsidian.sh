#!/bin/bash
# workspaceOpen hook: ensure Obsidian is running so the Local REST API MCP
# (obsidian server @ 127.0.0.1:27123) is reachable. Fires on IDE workspace
# open, outside any agent session.
# -g = don't bring to foreground, -j = launch hidden. Idempotent.

cat > /dev/null  # consume hook stdin

if ! pgrep -xq Obsidian; then
  open -gja Obsidian
fi

echo '{}'
exit 0
