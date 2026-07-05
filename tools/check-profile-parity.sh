#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AI_DOTFILES_ROOT="$ROOT"
# shellcheck source=lib/profile.sh
source "$ROOT/tools/lib/profile.sh"

PROFILE=""
TARGET_REPO=""
EXIT_CODE=0

usage() {
  cat <<'EOF'
Usage: check-profile-parity.sh --profile NAME [--repo PATH]

Compares a live repository checkout against the effective install stack:
  profiles/generic/ + profile overlay + cursor project scaffold.

Profile overlay alone is not the full expected tree - generic-layer files
(knowledge-base, obsidian, caveman rule, etc.) are included automatically.
EOF
}

pass() { printf 'PASS %s\n' "$1"; }
warn() { printf 'WARN %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; EXIT_CODE=1; }

list_files() {
  local base_dir="$1"
  if [[ ! -d "$base_dir" ]]; then
    return 0
  fi
  find "$base_dir" -type f | sed "s|^$base_dir/||" | sort
}

read_manifest_paths() {
  local manifest_path="$1"
  if [[ ! -f "$manifest_path" ]]; then
    return 0
  fi
  while IFS= read -r relative_path || [[ -n "$relative_path" ]]; do
    relative_path="${relative_path%%#*}"
    relative_path="$(printf '%s' "$relative_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -n "$relative_path" ]] && printf '%s\n' "$relative_path"
  done < "$manifest_path"
}

path_excluded_by_manifest() {
  local path="$1"
  local exclusions="$2"
  local exclusion

  while IFS= read -r exclusion; do
    [[ -z "$exclusion" ]] && continue
    if [[ "$path" == "$exclusion" || "$path" == "$exclusion/"* ]]; then
      return 0
    fi
  done <<< "$exclusions"

  return 1
}

filter_out_paths() {
  local haystack="$1"
  local exclusions="$2"
  local path filtered=()

  if [[ -z "$exclusions" ]]; then
    printf '%s' "$haystack"
    return 0
  fi

  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if ! path_excluded_by_manifest "$path" "$exclusions"; then
      filtered+=("$path")
    fi
  done < <(printf '%s\n' "$haystack" | sed '/^$/d')

  if [[ ${#filtered[@]} -gt 0 ]]; then
    printf '%s\n' "${filtered[@]}" | sort
  fi
}

merge_unique_paths() {
  printf '%s\n' "$@" | sed '/^$/d' | sort -u
}

cursor_rule_aliases() {
  local rule_name="$1"
  printf '%s\n' "$rule_name"
  case "$rule_name" in
    005-caveman.mdc) printf '%s\n' 'caveman.mdc' ;;
    caveman.mdc) printf '%s\n' '005-caveman.mdc' ;;
  esac
}

cursor_rule_covered() {
  local live_rule="$1"
  local expected_rules="$2"
  local alias

  if printf '%s\n' "$expected_rules" | grep -Fxq "$live_rule"; then
    return 0
  fi

  while IFS= read -r alias; do
    [[ -z "$alias" ]] && continue
    if printf '%s\n' "$expected_rules" | grep -Fxq "$alias"; then
      return 0
    fi
  done < <(cursor_rule_aliases "$live_rule")

  return 1
}

cursor_scaffold_leftover() {
  case "$1" in
    000-project.mdc|005-caveman.mdc|caveman.mdc) return 0 ;;
  esac
  return 1
}

count_skill_files() {
  local paths="$1"
  printf '%s\n' "$paths" | grep -E '^skills/[^/]+/SKILL\.md$' | wc -l | tr -d ' '
}

build_expected_github_files() {
  local profile_github_dir="$1"
  local profile_dir="$2"
  local generic_github_dir="$ROOT/profiles/generic/github"
  local generic_files profile_files manifest_paths merged

  generic_files="$(list_files "$generic_github_dir")"
  profile_files="$(list_files "$profile_github_dir")"
  manifest_paths="$(read_manifest_paths "$profile_dir/profile.manifest")"
  merged="$(merge_unique_paths "$generic_files" "$profile_files")"
  filter_out_paths "$merged" "$manifest_paths"
}

build_expected_cursor_rules() {
  local profile_cursor_dir="$1"
  local profile_rules scaffold_rules rule_name

  profile_rules="$(list_files "$profile_cursor_dir/rules")"
  scaffold_rules=""

  shopt -s nullglob
  for rule_path in "$ROOT/editors/cursor/project/rules/"*.mdc; do
    rule_name="$(basename "$rule_path")"
    if [[ "$rule_name" == "000-project.mdc" && -n "$profile_rules" ]]; then
      continue
    fi
    scaffold_rules+="${rule_name}"$'\n'
  done
  shopt -u nullglob

  merge_unique_paths "$profile_rules" "$scaffold_rules"
}

install_stack_path_in_live() {
  local relative_path="$1"
  local target_repo="$2"

  if [[ -f "$target_repo/.github/$relative_path" ]]; then
    return 0
  fi

  case "$relative_path" in
    docs/browser-verify.project.md)
      [[ -f "$target_repo/.cursor/docs/browser-verify.project.md" ]]
      ;;
    *)
      return 1
      ;;
  esac
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

if [[ -z "$PROFILE" ]]; then
  echo "--profile is required" >&2
  usage >&2
  exit 1
fi

profile_dir="$(require_profile_dir "$PROFILE")"
profile_github_dir="$(profile_github_dir "$profile_dir")"
profile_cursor_dir="$(profile_cursor_dir "$profile_dir")"

if [[ -z "$TARGET_REPO" ]]; then
  warn "--repo PATH is required for live parity comparison; skipping"
  exit 0
fi

if [[ ! -d "$TARGET_REPO/.github" ]]; then
  warn "live checkout not found at $TARGET_REPO; skipping github parity comparison"
else
  expected_github_files="$(build_expected_github_files "$profile_github_dir" "$profile_dir")"
  live_files="$(list_files "$TARGET_REPO/.github")"
  profile_files="$(list_files "$profile_github_dir")"

  stack_missing_from_live="$(comm -23 <(printf '%s\n' "$expected_github_files") <(printf '%s\n' "$live_files"))"
  extra_in_live="$(comm -23 <(printf '%s\n' "$live_files") <(printf '%s\n' "$expected_github_files"))"
  extra_in_profile="$(comm -13 <(printf '%s\n' "$live_files") <(printf '%s\n' "$profile_files"))"

  stack_gaps=()
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if ! install_stack_path_in_live "$path" "$TARGET_REPO"; then
      stack_gaps+=("$path")
    fi
  done < <(printf '%s\n' "$stack_missing_from_live")

  if [[ ${#stack_gaps[@]} -eq 0 ]]; then
    pass "live checkout includes full install stack (generic + profile)"
  else
    for path in "${stack_gaps[@]}"; do
      fail "install-stack file missing from live checkout: $path"
    done
  fi

  if [[ -n "$extra_in_live" ]]; then
    repo_local="$(printf '%s\n' "$extra_in_live" | grep -E '^workflows/' || true)"
    other_extra="$(comm -23 <(printf '%s\n' "$extra_in_live") <(printf '%s\n' "$repo_local"))"
    if [[ -n "$repo_local" ]]; then
      pass "repo-local .github paths ignored (workflows/, etc.)"
    fi
    if [[ -n "$other_extra" ]]; then
      warn "extra files in live .github outside install stack (review if intentional):"
      printf '%s\n' "$other_extra" | sed 's/^/  /'
    fi
  fi

  if [[ -n "$extra_in_profile" ]]; then
    while IFS= read -r path; do
      [[ -z "$path" ]] && continue
      if install_stack_path_in_live "$path" "$TARGET_REPO"; then
        pass "profile github/$path satisfied via alternate install path"
      else
        warn "profile github/$path not present in live .github:"
        printf '  %s\n' "$path"
      fi
    done < <(printf '%s\n' "$extra_in_profile")
  else
    pass "profile github overlay fully reflected in live .github"
  fi

  expected_skill_count="$(count_skill_files "$expected_github_files")"
  live_skill_count=0
  if [[ -d "$TARGET_REPO/.github/skills" ]]; then
    live_skill_count="$(find "$TARGET_REPO/.github/skills" -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')"
  fi

  if [[ "$expected_skill_count" == "$live_skill_count" ]]; then
    pass "github skill count matches install stack ($live_skill_count)"
  else
    fail "github skill count mismatch: expected=$expected_skill_count live=$live_skill_count"
  fi
fi

if [[ -d "$TARGET_REPO/.cursor/rules" ]]; then
  expected_cursor_rules="$(build_expected_cursor_rules "$profile_cursor_dir")"
  live_cursor_rules="$(list_files "$TARGET_REPO/.cursor/rules")"
  uncovered_cursor=()
  leftover_cursor=()

  while IFS= read -r live_rule; do
    [[ -z "$live_rule" ]] && continue
    if cursor_rule_covered "$live_rule" "$expected_cursor_rules"; then
      continue
    fi
    if cursor_scaffold_leftover "$live_rule"; then
      leftover_cursor+=("$live_rule")
      continue
    fi
    uncovered_cursor+=("$live_rule")
  done < <(printf '%s\n' "$live_cursor_rules")

  if [[ ${#uncovered_cursor[@]} -eq 0 ]]; then
    pass "live .cursor/rules matches install stack (profile + scaffold)"
  else
    fail "cursor rules in live checkout missing from install stack:"
    printf '  %s\n' "${uncovered_cursor[@]}"
  fi

  if [[ ${#leftover_cursor[@]} -gt 0 ]]; then
    warn "cursor scaffold leftovers in live checkout (safe to remove on next setup):"
    printf '  %s\n' "${leftover_cursor[@]}"
  fi
else
  warn "live .cursor/rules not found; skipping cursor parity"
fi

if [[ -f "$TARGET_REPO/AGENTS.md" && -f "$profile_dir/AGENTS.md" ]]; then
  if cmp -s "$TARGET_REPO/AGENTS.md" "$profile_dir/AGENTS.md"; then
    pass "profile AGENTS.md matches live checkout"
  else
    warn "profile AGENTS.md differs from live checkout"
  fi
elif [[ -f "$TARGET_REPO/AGENTS.md" && ! -f "$profile_dir/AGENTS.md" ]]; then
  fail "live AGENTS.md is missing from profile"
fi

if [[ $EXIT_CODE -eq 0 ]]; then
  echo "Profile parity check complete with no hard failures."
else
  echo "Profile parity check complete with failures."
fi

exit $EXIT_CODE
