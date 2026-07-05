#!/bin/bash
set -euo pipefail

RUNTIME_DIR="$HOME/agentmemory-runtime"
LOG_DIR="$RUNTIME_DIR/logs"
HEALTH_URL="http://127.0.0.1:3111/agentmemory/health"

mkdir -p "$LOG_DIR"
cd "$RUNTIME_DIR"

if curl -sf "$HEALTH_URL" >/dev/null 2>&1; then
  exit 0
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

exec agentmemory >> "$LOG_DIR/agentmemory.log" 2>&1
