#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_REPO=""
SKIP_SMOKE_TEST=0
TEMP_ROOT=""

cleanup() {
  if [[ -n "$TEMP_ROOT" && -d "$TEMP_ROOT" ]]; then
    rm -rf "$TEMP_ROOT"
  fi
}

trap cleanup EXIT

run_smoke_tests() {
  local generic_repo
  local example_repo

  TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ai-dotfiles-verify.XXXXXX")"
  generic_repo="$TEMP_ROOT/generic-repo"
  example_repo="$TEMP_ROOT/example-repo"

  echo "Running clean-room smoke test for the generic VS Code scaffold..."
  "$ROOT/tools/setup.sh" --editor vscode --skip-user-baseline --repo "$generic_repo" --workspace-mode direct
  "$ROOT/tools/validate.sh" --editor vscode --repo "$generic_repo"

  echo "Running clean-room smoke test for the _starter profile (both editors)..."
  "$ROOT/tools/setup.sh" --editor both --profile _starter --skip-user-baseline --repo "$example_repo"
  "$ROOT/tools/validate.sh" --editor both --profile _starter --repo "$example_repo"

  if [[ -n "${AI_DOTFILES_PROFILES:-}" && -d "${AI_DOTFILES_PROFILES}/profiles" ]]; then
    local profile_dir profile_name private_repo
    for profile_dir in "$AI_DOTFILES_PROFILES"/profiles/*/; do
      [[ -d "$profile_dir" ]] || continue
      profile_name="$(basename "$profile_dir")"
      [[ "$profile_name" == "_starter" ]] && continue
      private_repo="$TEMP_ROOT/profile-${profile_name}-repo"
      echo "Running optional smoke test for profile: $profile_name"
      "$ROOT/tools/setup.sh" --editor both --profile "$profile_name" --skip-user-baseline --repo "$private_repo"
      "$ROOT/tools/validate.sh" --editor both --profile "$profile_name" --repo "$private_repo"
    done
  fi
}

usage() {
  cat <<'EOF'
Usage: verify-maintainer.sh [--repo PATH]

Options:
  --repo PATH          Forward the target repository to validate.sh
  --skip-smoke-test    Skip the clean-room scaffold smoke tests
  --help               Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      TARGET_REPO="$2"
      shift 2
      ;;
    --skip-smoke-test)
      SKIP_SMOKE_TEST=1
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

echo "Running maintainer verification..."
validate_cmd=("$ROOT/tools/validate.sh" --editor both)
if [[ -n "$TARGET_REPO" ]]; then
  validate_cmd+=(--repo "$TARGET_REPO")
fi

"${validate_cmd[@]}"
"$ROOT/tools/check-generic-portability.sh"
"$ROOT/tools/check-rule-parity.sh"

if [[ -n "${AI_DOTFILES_PROFILES:-}" && -d "${AI_DOTFILES_PROFILES}/profiles" ]]; then
  profile_dir=""
  profile_name=""
  for profile_dir in "$AI_DOTFILES_PROFILES"/profiles/*/; do
    [[ -d "$profile_dir" ]] || continue
    profile_name="$(basename "$profile_dir")"
    "$ROOT/tools/check-rule-parity.sh" --profile "$profile_name"
  done
fi

if [[ $SKIP_SMOKE_TEST -eq 0 ]]; then
  run_smoke_tests
fi

echo "Maintainer verification complete."
