#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AI_DOTFILES_ROOT="$ROOT"
# shellcheck source=lib/profile.sh
source "$ROOT/tools/lib/profile.sh"

VSCODE_PROMPTS_DIR="${VSCODE_PROMPTS_DIR:-$HOME/Library/Application Support/Code/User/prompts}"
CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}"
PROFILE=""
TARGET_REPO=""
DRY_RUN=0
SYNC_USER_BASELINE=0

usage() {
  cat <<'EOF'
Usage: pack.sh --profile NAME --repo PATH [--dry-run]

Sync a target repository checkout back into a profile directory.

Options:
  --profile NAME         Profile id to update (under profiles/<name>/)
  --repo PATH            Live repository checkout to pack from
  --sync-user-baseline   Also copy local VS Code prompts and Cursor user rules
                         into editors/ (opt-in; can overwrite generic public rules)
  --dry-run              Print the sync actions without copying files
  --help                 Show this help
EOF
}

run_cmd() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf 'DRY-RUN'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

copy_if_exists() {
  local source_path="$1"
  local dest_path="$2"

  if [[ -e "$source_path" ]]; then
    run_cmd mkdir -p "$(dirname "$dest_path")"
    run_cmd cp "$source_path" "$dest_path"
  fi
}

copy_glob_if_exists() {
  local source_dir="$1"
  local glob_pattern="$2"
  local dest_path="$3"
  local matches=()

  shopt -s nullglob
  matches=("$source_dir"/$glob_pattern)
  shopt -u nullglob

  if [[ ${#matches[@]} -gt 0 ]]; then
    run_cmd mkdir -p "$dest_path"
    run_cmd cp "${matches[@]}" "$dest_path"
  fi
}

rsync_if_exists() {
  local source_path="$1"
  local dest_path="$2"

  if [[ -e "$source_path" ]]; then
    run_cmd mkdir -p "$dest_path"
    if [[ $DRY_RUN -eq 1 ]]; then
      printf 'DRY-RUN rsync -a --delete %q/ %q/\n' "$source_path" "$dest_path"
    else
      rsync -a --delete "$source_path/" "$dest_path/"
    fi
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --repo)
      TARGET_REPO="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --sync-user-baseline)
      SYNC_USER_BASELINE=1
      shift
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

if [[ -z "$PROFILE" || -z "$TARGET_REPO" ]]; then
  echo "--profile and --repo are required" >&2
  usage >&2
  exit 1
fi

profile_dir="$(require_profile_dir "$PROFILE")"
profile_github_dir="$(profile_github_dir "$profile_dir")"
profile_cursor_dir="$(profile_cursor_dir "$profile_dir")"

echo "Refreshing profile from:"
echo "  PROFILE=$PROFILE"
echo "  PROFILE_DIR=$profile_dir"
echo "  VSCODE_PROMPTS_DIR=$VSCODE_PROMPTS_DIR"
echo "  CURSOR_HOME=$CURSOR_HOME"
echo "  TARGET_REPO=$TARGET_REPO"

run_cmd mkdir -p \
  "$ROOT/editors/vscode/user/instructions" \
  "$ROOT/editors/cursor/user/rules" \
  "$profile_github_dir/instructions" \
  "$profile_github_dir/prompts" \
  "$profile_github_dir/agents" \
  "$profile_github_dir/docs" \
  "$profile_github_dir/skills" \
  "$profile_cursor_dir/rules" \
  "$profile_cursor_dir/commands" \
  "$profile_cursor_dir/docs" \
  "$profile_dir/test-personas" \
  "$ROOT/shared/codegraph" \
  "$ROOT/editors/vscode/project/.vscode"

if [[ $SYNC_USER_BASELINE -eq 1 ]]; then
  copy_glob_if_exists "$VSCODE_PROMPTS_DIR" '*.instructions.md' "$ROOT/editors/vscode/user/instructions/"
  copy_glob_if_exists "$CURSOR_HOME/rules" '*.mdc' "$ROOT/editors/cursor/user/rules/"
fi

copy_if_exists "$TARGET_REPO/AGENTS.md" "$profile_dir/AGENTS.md"
copy_if_exists "$TARGET_REPO/.github/copilot-instructions.md" "$profile_github_dir/copilot-instructions.md"

copy_glob_if_exists "$TARGET_REPO/.github/instructions" '*.instructions.md' "$profile_github_dir/instructions/"
copy_glob_if_exists "$TARGET_REPO/.github/prompts" '*.prompt.md' "$profile_github_dir/prompts/"
copy_glob_if_exists "$TARGET_REPO/.github/agents" '*.agent.md' "$profile_github_dir/agents/"

rsync_if_exists "$TARGET_REPO/.github/skills" "$profile_github_dir/skills"

copy_glob_if_exists "$TARGET_REPO/.cursor/rules" '*.mdc' "$profile_cursor_dir/rules/"
copy_glob_if_exists "$TARGET_REPO/.cursor/commands" '*.md' "$profile_cursor_dir/commands/"

if [[ -e "$TARGET_REPO/.github/docs/browser-verify.project.md" ]]; then
  run_cmd cp "$TARGET_REPO/.github/docs/browser-verify.project.md" "$profile_github_dir/docs/"
  run_cmd cp "$TARGET_REPO/.github/docs/browser-verify.project.md" "$profile_cursor_dir/docs/browser-verify.project.md"
elif [[ -e "$TARGET_REPO/.cursor/docs/browser-verify.project.md" ]]; then
  run_cmd cp "$TARGET_REPO/.cursor/docs/browser-verify.project.md" "$profile_github_dir/docs/browser-verify.project.md"
  run_cmd cp "$TARGET_REPO/.cursor/docs/browser-verify.project.md" "$profile_cursor_dir/docs/"
fi

copy_glob_if_exists "$TARGET_REPO/.mlem/test-personas" '*.example.json' "$profile_dir/test-personas/"

copy_if_exists "$TARGET_REPO/.codegraph/config.json" "$ROOT/shared/codegraph/config.json.example"
copy_if_exists "$TARGET_REPO/.vscode/mcp.json" "$ROOT/editors/vscode/project/.vscode/mcp.json.example"
copy_if_exists "$TARGET_REPO/.vscode/mcp.autostart.sources.json" "$ROOT/editors/vscode/project/.vscode/mcp.autostart.sources.json.example"

echo "Done. Review tools/setup.sh and profiles/$PROFILE/ if the source setup changed."
echo "Run tools/check-profile-parity.sh --profile $PROFILE --repo $TARGET_REPO"
echo "Run tools/check-rule-parity.sh --profile $PROFILE"
