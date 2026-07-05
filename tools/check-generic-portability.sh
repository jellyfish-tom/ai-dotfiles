#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ALLOWLIST_FILE="$ROOT/tools/portability-allowlist.txt"
EXIT_CODE=0
ALLOWLIST_ENTRIES=()

# Project-specific strings that must not appear in portable generic/scaffold trees.
PATTERN='novus|creditea|credit24|provident|ipf-demo|figma-to-novus|novus-operator-context|loan-app|acq-[0-9]+'

load_allowlist() {
  local line

  if [[ ! -f "$ALLOWLIST_FILE" ]]; then
    return 0
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -n "$line" ]] && ALLOWLIST_ENTRIES+=("$line")
  done < "$ALLOWLIST_FILE"
}

path_is_allowlisted() {
  local rel_path="$1"
  local entry

  for entry in "${ALLOWLIST_ENTRIES[@]}"; do
    if [[ "$entry" == */ ]]; then
      if [[ "$rel_path" == "${entry%/}" || "$rel_path" == "${entry%/}/"* ]]; then
        return 0
      fi
    elif [[ "$rel_path" == "$entry" ]]; then
      return 0
    fi
  done

  return 1
}

load_allowlist

check_file() {
  local file_path="$1"
  local rel_path="${file_path#"$ROOT"/}"

  case "$file_path" in
    */tools/validate.sh|*/tools/check-generic-portability.sh|*/tools/portability-allowlist.txt)
      return 0
      ;;
  esac

  if path_is_allowlisted "$rel_path"; then
    return 0
  fi

  if grep -E -n -i "$PATTERN" "$file_path" >/dev/null 2>&1; then
    echo "FAIL portability leak in $file_path"
    grep -E -n -i "$PATTERN" "$file_path" || true
    EXIT_CODE=1
  fi
}

prune_find_paths() {
  printf '%s\n' \
    '*/node_modules/*' \
    '*/.git/*' \
    '*/.agents/*'
}

scan_tree() {
  local tree_path="$1"
  local prune_args=()

  if [[ ! -d "$tree_path" ]]; then
    return 0
  fi

  while IFS= read -r prune_path; do
    [[ -n "$prune_path" ]] && prune_args+=( -path "$prune_path" -o )
  done < <(prune_find_paths)

  if [[ ${#prune_args[@]} -gt 0 ]]; then
    unset 'prune_args[${#prune_args[@]}-1]'
    while IFS= read -r file_path; do
      check_file "$file_path"
    done < <(find "$tree_path" \( "${prune_args[@]}" \) -prune -o -type f -print | sort)
  else
    while IFS= read -r file_path; do
      check_file "$file_path"
    done < <(find "$tree_path" -type f | sort)
  fi
}

scan_tree "$ROOT/profiles/generic"
scan_tree "$ROOT/profiles/_starter"
scan_tree "$ROOT/editors"
scan_tree "$ROOT/docs"
scan_tree "$ROOT/shared"
scan_tree "$ROOT/tools"

check_file "$ROOT/README.md"

if [[ -d "$ROOT/profiles/novus" ]]; then
  echo "FAIL profiles/novus must not exist in the public repo"
  EXIT_CODE=1
fi

if [[ $EXIT_CODE -eq 0 ]]; then
  echo "PASS public tree contains no blocked project-specific strings"
fi

exit $EXIT_CODE
