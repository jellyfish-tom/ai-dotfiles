#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/agentmemory"

mkdir -p "$HOME/agentmemory-runtime/logs"

cp "$SRC/start-agentmemory.sh" "$HOME/agentmemory-runtime/"
chmod +x "$HOME/agentmemory-runtime/start-agentmemory.sh"

sed "s|__HOME__|$HOME|g" "$SRC/com.agentmemory.server.plist" \
  > "$HOME/Library/LaunchAgents/com.agentmemory.server.plist"

UID_NUM="$(id -u)"
DOMAIN="gui/$UID_NUM"
LABEL="com.agentmemory.server"

launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
launchctl bootstrap "$DOMAIN" "$HOME/Library/LaunchAgents/com.agentmemory.server.plist"
launchctl enable "$DOMAIN/$LABEL"
launchctl kickstart -k "$DOMAIN/$LABEL"

echo "LaunchAgent installed. Run: agentmemory status"
