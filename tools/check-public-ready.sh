#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXIT_CODE=0
TEMP_ROOT=""

cleanup() {
  if [[ -n "$TEMP_ROOT" && -d "$TEMP_ROOT" ]]; then
    rm -rf "$TEMP_ROOT"
  fi
}

trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: check-public-ready.sh

Public publish gate: portability scan + _starter profile smoke test.
Run without AI_DOTFILES_PROFILES set to verify the public repo is safe to publish.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
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

if [[ -n "${AI_DOTFILES_PROFILES:-}" ]]; then
  echo "WARN AI_DOTFILES_PROFILES is set; unset for a clean public-ready check" >&2
fi

echo "Running generic portability scan..."
if ! "$ROOT/tools/check-generic-portability.sh"; then
  EXIT_CODE=1
fi

echo "Running _starter profile smoke test..."
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ai-dotfiles-public-ready.XXXXXX")"
example_repo="$TEMP_ROOT/example-repo"

if ! "$ROOT/tools/setup.sh" --editor both --profile _starter --skip-user-baseline --repo "$example_repo"; then
  EXIT_CODE=1
fi

if ! "$ROOT/tools/validate.sh" --editor both --profile _starter --repo "$example_repo"; then
  EXIT_CODE=1
fi

if [[ $EXIT_CODE -eq 0 ]]; then
  echo "PASS public-ready check complete."
else
  echo "FAIL public-ready check found issues."
fi

exit $EXIT_CODE
