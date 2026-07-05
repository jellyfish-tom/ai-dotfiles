#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AI_DOTFILES_ROOT="$ROOT"
# shellcheck source=lib/profile.sh
source "$ROOT/tools/lib/profile.sh"

PROFILE=""
EXIT_CODE=0

usage() {
  cat <<'EOF'
Usage: check-rule-parity.sh [--profile NAME]

Warns when paired VS Code instructions and Cursor rules diverge in presence or size.
EOF
}

pass() { printf 'PASS %s\n' "$1"; }
warn() { printf 'WARN %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; EXIT_CODE=1; }

check_pair() {
  local label="$1"
  local vscode_path="$2"
  local cursor_path="$3"

  if [[ -f "$vscode_path" && -f "$cursor_path" ]]; then
    pass "$label pair exists on both sides"
    local vscode_size cursor_size
    vscode_size="$(wc -c < "$vscode_path" | tr -d ' ')"
    cursor_size="$(wc -c < "$cursor_path" | tr -d ' ')"
    local ratio=0
    if [[ "$vscode_size" -gt 0 ]]; then
      ratio=$((cursor_size * 100 / vscode_size))
    fi
    if [[ $ratio -lt 50 || $ratio -gt 200 ]]; then
      warn "$label size mismatch (vscode=${vscode_size}b cursor=${cursor_size}b); review for drift"
    fi
  elif [[ -f "$vscode_path" && ! -f "$cursor_path" ]]; then
    warn "$label missing Cursor side: $cursor_path"
  elif [[ ! -f "$vscode_path" && -f "$cursor_path" ]]; then
    warn "$label missing VS Code side: $vscode_path"
  else
    warn "$label missing on both sides"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="$2"
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
  profile_dir="$(require_profile_dir "$PROFILE")"
  pairs_json="$(profile_parity_pairs "$profile_dir")"
  pair_count="$(node -e 'process.stdout.write(String(JSON.parse(process.argv[1]).length))' "$pairs_json")"

  for ((i = 0; i < pair_count; i++)); do
    github_rel="$(node -e "const p=JSON.parse(process.argv[1]); process.stdout.write(p[Number(process.argv[2])].github||'')" "$pairs_json" "$i")"
    cursor_rel="$(node -e "const p=JSON.parse(process.argv[1]); process.stdout.write(p[Number(process.argv[2])].cursor||'')" "$pairs_json" "$i")"
    label="$(basename "$github_rel" .instructions.md)"
    check_pair "$label" \
      "$profile_dir/github/$github_rel" \
      "$profile_dir/cursor/$cursor_rel"
  done
fi

check_pair "git-workflow-user" \
  "$ROOT/editors/vscode/user/instructions/git-workflow.instructions.md" \
  "$ROOT/editors/cursor/user/rules/git-workflow.mdc"

if [[ $EXIT_CODE -eq 0 ]]; then
  echo "Rule parity check complete."
else
  echo "Rule parity check complete with failures."
fi

exit $EXIT_CODE
