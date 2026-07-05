#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AI_DOTFILES_ROOT="$ROOT"
# shellcheck source=lib/common.sh
source "$ROOT/tools/lib/common.sh"
# shellcheck source=lib/profile.sh
source "$ROOT/tools/lib/profile.sh"
# shellcheck source=lib/install-vscode.sh
source "$ROOT/tools/lib/install-vscode.sh"
# shellcheck source=lib/install-cursor.sh
source "$ROOT/tools/lib/install-cursor.sh"

EDITOR="vscode"
WORKSPACE_MODE="direct"
USER_MCP_MODE="direct"
TARGET_REPO=""
PROFILE=""
INSTALL_EXTENSIONS=0
SKIP_EXTENSIONS=0
INSTALL_USER_BASELINE=1
PLUGINS=()
_EDITOR_EXPLICIT=0
_WORKSPACE_MODE_EXPLICIT=0
_USER_MCP_MODE_EXPLICIT=0

usage() {
  cat <<'EOF'
Usage: setup.sh [options]

Options:
  --editor MODE               vscode | cursor | both (default: vscode)
  --profile NAME              Profile to install from profiles/<name>/ (e.g. _starter)
  --repo PATH                 Target repository to scaffold
  --workspace-mode MODE       direct | autostart (VS Code only; default: direct)
  --user-mcp-mode MODE        direct | autostart (VS Code only; default: direct)
  --install-extensions        Install VS Code extensions from shared/extensions.txt
  --skip-extensions           Do not install extensions even when profile.json would
  --skip-user-baseline        Do not copy user-level instructions, rules, or MCP templates
  --plugin NAME               Install optional plugin from shared/plugins/<name>/ (repeatable)
  --preset NAME               Deprecated alias for --profile
  --help                      Show this help

Examples:
  tools/setup.sh --editor vscode
  tools/setup.sh --editor both --profile _starter --repo /path/to/your-app
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --editor)
      EDITOR="$2"
      _EDITOR_EXPLICIT=1
      shift 2
      ;;
    --repo)
      TARGET_REPO="$2"
      shift 2
      ;;
    --profile|--preset)
      PROFILE="$2"
      shift 2
      ;;
    --workspace-mode)
      WORKSPACE_MODE="$2"
      _WORKSPACE_MODE_EXPLICIT=1
      shift 2
      ;;
    --user-mcp-mode)
      USER_MCP_MODE="$2"
      _USER_MCP_MODE_EXPLICIT=1
      shift 2
      ;;
    --install-extensions)
      INSTALL_EXTENSIONS=1
      shift
      ;;
    --skip-extensions)
      SKIP_EXTENSIONS=1
      shift
      ;;
    --skip-user-baseline)
      INSTALL_USER_BASELINE=0
      shift
      ;;
    --plugin)
      PLUGINS+=("$2")
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -n "$PROFILE" ]]; then
  _cli_editor="$EDITOR"
  _cli_workspace_mode="$WORKSPACE_MODE"
  _cli_user_mcp_mode="$USER_MCP_MODE"

  apply_profile "$PROFILE"

  [[ $_EDITOR_EXPLICIT -eq 1 ]] && EDITOR="$_cli_editor"
  [[ $_WORKSPACE_MODE_EXPLICIT -eq 1 ]] && WORKSPACE_MODE="$_cli_workspace_mode"
  [[ $_USER_MCP_MODE_EXPLICIT -eq 1 ]] && USER_MCP_MODE="$_cli_user_mcp_mode"
fi

case "$EDITOR" in
  vscode|cursor|both) ;;
  *)
    echo "Unsupported editor: $EDITOR" >&2
    exit 1
    ;;
esac

require_supported_os

if [[ "$WORKSPACE_MODE" != "direct" && "$WORKSPACE_MODE" != "autostart" ]]; then
  echo "Unsupported workspace mode: $WORKSPACE_MODE" >&2
  exit 1
fi

if [[ "$USER_MCP_MODE" != "direct" && "$USER_MCP_MODE" != "autostart" ]]; then
  echo "Unsupported user MCP mode: $USER_MCP_MODE" >&2
  exit 1
fi

if [[ -n "$TARGET_REPO" ]]; then
  if [[ -e "$TARGET_REPO" && ! -d "$TARGET_REPO" ]]; then
    echo "--repo must be a directory: $TARGET_REPO" >&2
    exit 1
  fi

  _repo_abs="$(cd "$TARGET_REPO" 2>/dev/null && pwd || true)"
  if [[ -n "$_repo_abs" ]]; then
    if [[ "$_repo_abs" == "$HOME" ]]; then
      echo "Refusing to scaffold into your home directory: $_repo_abs" >&2
      echo "Pass --repo pointing at a specific project directory." >&2
      exit 1
    fi
    if [[ "$_repo_abs" == "/" ]]; then
      echo "Refusing to scaffold into the filesystem root." >&2
      exit 1
    fi
  fi
fi

echo "Using root: $ROOT"
echo "Editor target: $EDITOR"

if [[ $INSTALL_USER_BASELINE -eq 1 ]]; then
  if editor_enabled vscode "$EDITOR"; then
    install_vscode_user_baseline "$ROOT" "$USER_MCP_MODE"
  fi

  if editor_enabled cursor "$EDITOR"; then
    install_cursor_user_baseline "$ROOT"
  fi
fi

if [[ ${#PLUGINS[@]} -gt 0 ]] && editor_enabled cursor "$EDITOR"; then
  for plugin in "${PLUGINS[@]}"; do
    install_cursor_plugin "$ROOT" "$plugin"
  done
fi

if [[ $INSTALL_EXTENSIONS -eq 1 ]] && editor_enabled vscode "$EDITOR"; then
  install_vscode_extensions "$ROOT"
fi


if [[ -n "$TARGET_REPO" ]]; then
  if editor_enabled vscode "$EDITOR"; then
    install_vscode_repo_scaffold "$ROOT" "$TARGET_REPO" "$PROFILE" "$WORKSPACE_MODE"
    echo "VS Code scaffold complete: $TARGET_REPO"
  fi

  if editor_enabled cursor "$EDITOR"; then
    install_cursor_repo_scaffold "$ROOT" "$TARGET_REPO" "$PROFILE"
    echo "Cursor scaffold complete: $TARGET_REPO"
  fi
fi

cat <<EOF

Setup complete.

Recommended next steps:
1. Run: $ROOT/tools/validate.sh --editor $EDITOR${PROFILE:+ --profile "$PROFILE"}${TARGET_REPO:+ --repo "$TARGET_REPO"}
2. Reload your editor or restart chat after copying user config.

External prerequisites:
- Figma requires your own Figma account access.
- codegraph requires the \`codegraph\` CLI on PATH.
- agentmemory is optional; see shared/agentmemory/README.md
- Caveman token-optimization skills require node/npx; see docs/users/cursor.md#caveman-token-optimization
- Plugins (Obsidian, Atlassian): re-run with --plugin <name> to add integrations
EOF
