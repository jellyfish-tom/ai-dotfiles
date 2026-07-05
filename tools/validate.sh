#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AI_DOTFILES_ROOT="$ROOT"
# shellcheck source=lib/common.sh
source "$ROOT/tools/lib/common.sh"
# shellcheck source=lib/profile.sh
source "$ROOT/tools/lib/profile.sh"

EDITOR="both"
TARGET_REPO=""
EXPECT_PROFILE=""
EXIT_CODE=0

usage() {
  cat <<'EOF'
Usage: validate.sh [--editor MODE] [--profile NAME] [--repo PATH]

Options:
  --editor MODE     vscode | cursor | both (default: both)
  --profile NAME    Require profile contract checks on the target repository
  --repo PATH       Validate a scaffolded target repository
  --expect-profile  Deprecated alias for --profile
  --expect-novus    Deprecated alias for --profile novus
  --help            Show this help
EOF
}

pass() { printf 'PASS %s\n' "$1"; }
warn() { printf 'WARN %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; EXIT_CODE=1; }

file_contains() {
  local file_path="$1"
  local needle="$2"
  grep -Fq "$needle" "$file_path"
}

json_array_items() {
  local json="$1"
  node -e 'const data=JSON.parse(process.argv[1]); (Array.isArray(data)?data:[]).forEach((item)=>process.stdout.write(String(item)+"\n"))' "$json"
}

validate_profile_vscode_repo() {
  local repo_path="$1"
  local profile_dir="$2"
  local validation_json
  local item
  local skill_count
  local expected_skill_count
  local agents_md_contains

  validation_json="$(profile_validation_json "$profile_dir" vscode)"

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    if [[ -f "$repo_path/.github/$item" ]]; then
      pass "Profile instruction exists: $item"
    else
      fail "Profile instruction missing: $item"
    fi
  done < <(json_array_items "$(node -e 'process.stdout.write(JSON.stringify(JSON.parse(process.argv[1]).requiredInstructions||[]))' "$validation_json")")

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    if [[ -f "$repo_path/.github/agents/$item.agent.md" ]]; then
      pass "Profile agent exists: $item"
    else
      fail "Profile agent missing: $item"
    fi
  done < <(json_array_items "$(node -e 'process.stdout.write(JSON.stringify(JSON.parse(process.argv[1]).requiredAgents||[]))' "$validation_json")")

  expected_skill_count="$(node -e 'const v=JSON.parse(process.argv[1]); process.stdout.write(String(v.skillCount??""))' "$validation_json")"
  if [[ -n "$expected_skill_count" ]]; then
    skill_count="$(find "$repo_path/.github/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
    if [[ "$skill_count" -eq "$expected_skill_count" ]]; then
      pass "Profile repo ships $expected_skill_count skills"
    else
      fail "Profile expected $expected_skill_count skills, found $skill_count"
    fi
  fi

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    if [[ -f "$repo_path/.github/$item" ]]; then
      pass "Profile prompt exists: $item"
    else
      fail "Profile prompt missing: $item"
    fi
  done < <(json_array_items "$(node -e 'process.stdout.write(JSON.stringify(JSON.parse(process.argv[1]).requiredPrompts||[]))' "$validation_json")")

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    if [[ -f "$repo_path/.github/$item" ]]; then
      fail "Forbidden path should not remain in profile scaffold: $item"
    else
      pass "Forbidden path absent: $item"
    fi
  done < <(json_array_items "$(node -e 'process.stdout.write(JSON.stringify(JSON.parse(process.argv[1]).forbiddenPaths||[]))' "$validation_json")")

  agents_md_contains="$(node -e 'process.stdout.write(JSON.stringify(JSON.parse(process.argv[1]).agentsMdMustContain||[]))' "$validation_json")"
  if [[ "$agents_md_contains" != "[]" ]]; then
    if [[ -f "$repo_path/AGENTS.md" ]]; then
      local missing=0
      while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        if file_contains "$repo_path/AGENTS.md" "$item"; then
          pass "AGENTS.md references: $item"
        else
          fail "AGENTS.md missing expected reference: $item"
          missing=1
        fi
      done < <(json_array_items "$agents_md_contains")
      if [[ $missing -eq 0 ]]; then
        pass "AGENTS.md contains expected workflow references"
      fi
    else
      fail "AGENTS.md is missing"
    fi
  fi
}

validate_profile_cursor_repo() {
  local repo_path="$1"
  local profile_dir="$2"
  local validation_json
  local item

  validation_json="$(profile_validation_json "$profile_dir" cursor)"

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    if [[ -f "$repo_path/.cursor/rules/$item" ]]; then
      pass "Profile Cursor rule exists: $item"
    else
      fail "Profile Cursor rule missing: $item"
    fi
  done < <(json_array_items "$(node -e 'process.stdout.write(JSON.stringify(JSON.parse(process.argv[1]).requiredRules||[]))' "$validation_json")")

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    if [[ -f "$repo_path/.cursor/commands/$item" ]]; then
      pass "Profile Cursor command exists: $item"
    else
      fail "Profile Cursor command missing: $item"
    fi
  done < <(json_array_items "$(node -e 'process.stdout.write(JSON.stringify(JSON.parse(process.argv[1]).requiredCommands||[]))' "$validation_json")")

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    if [[ -f "$repo_path/.cursor/docs/$item" ]]; then
      pass "Profile Cursor doc exists: $item"
    else
      fail "Profile Cursor doc missing: $item"
    fi
  done < <(json_array_items "$(node -e 'process.stdout.write(JSON.stringify(JSON.parse(process.argv[1]).requiredDocs||[]))' "$validation_json")")
}

validate_vscode_user() {
  local user_config_dir
  local user_prompts_dir
  user_config_dir="$(vscode_user_config_dir)"
  user_prompts_dir="$(vscode_user_prompts_dir)"

  if [[ -f "$user_config_dir/mcp.json" ]]; then
    pass "VS Code user MCP config exists at $user_config_dir/mcp.json"
  else
    warn "VS Code user MCP config is missing at $user_config_dir/mcp.json"
  fi

  if compgen -G "$user_prompts_dir/*.instructions.md" >/dev/null; then
    pass "VS Code user instruction files exist in $user_prompts_dir"
  else
    warn "no VS Code user instruction files found in $user_prompts_dir"
  fi
}

validate_cursor_user() {
  local cursor_home
  cursor_home="$(cursor_home_dir)"

  if compgen -G "$cursor_home/rules/*.mdc" >/dev/null; then
    pass "Cursor user rules exist in $cursor_home/rules"
  else
    warn "no Cursor user rules found in $cursor_home/rules"
  fi

  if [[ -f "$cursor_home/skills/jira-browser-verify/SKILL.md" ]]; then
    pass "Cursor user skill exists: jira-browser-verify"
  else
    warn "Cursor user skill missing: jira-browser-verify (run setup --editor cursor)"
  fi

  if [[ -f "$cursor_home/mcp.json" ]]; then
    pass "Cursor user MCP config exists at $cursor_home/mcp.json"
  else
    warn "Cursor user MCP config is missing at $cursor_home/mcp.json"
  fi
}

validate_caveman_stack() {
  local target_dir="$1"

  if [[ -f "$target_dir/skills-lock.json" ]]; then
    pass "skills-lock.json exists at $target_dir/skills-lock.json"
  else
    warn "skills-lock.json missing at $target_dir (run setup --editor cursor)"
  fi

  if [[ -f "$target_dir/.agents/skills/caveman/SKILL.md" ]]; then
    pass "Caveman skills installed in $target_dir/.agents/skills"
  else
    warn "Caveman skills missing in $target_dir/.agents/skills (needs node/npx; run setup --editor cursor)"
  fi
}

validate_vscode_repo() {
  local repo_path="$1"

  if [[ -f "$repo_path/.github/copilot-instructions.md" ]]; then
    pass "VS Code repo scaffold entrypoint exists"
  else
    fail "VS Code repo scaffold entrypoint is missing"
  fi

  if [[ -f "$repo_path/.github/skills/jira-browser-verify/SKILL.md" ]]; then
    pass "VS Code jira-browser-verify skill exists"
  else
    warn "VS Code jira-browser-verify skill missing"
  fi

  if [[ -f "$repo_path/.github/docs/browser-verify.project.md" ]]; then
    pass "VS Code browser-verify project supplement exists"
  else
    warn "VS Code browser-verify project supplement missing"
  fi

  if [[ -f "$repo_path/.vscode/mcp.json" ]]; then
    pass "VS Code workspace MCP config exists"
  else
    warn "VS Code workspace MCP config is missing"
  fi

  if [[ -f "$repo_path/scripts/startMcpAutostart.mjs" ]]; then
    if node --check "$repo_path/scripts/startMcpAutostart.mjs" >/dev/null 2>&1; then
      pass "VS Code workspace autostart launcher passes syntax check"
    else
      fail "VS Code workspace autostart launcher failed syntax check"
    fi
  fi
}

validate_cursor_repo() {
  local repo_path="$1"

  if compgen -G "$repo_path/.cursor/rules/*.mdc" >/dev/null; then
    pass "Cursor project rules exist"
  else
    warn "Cursor project rules are missing"
  fi

  local cursor_home
  cursor_home="$(cursor_home_dir)"
  if [[ -f "$repo_path/.cursor/rules/005-caveman.mdc" || -f "$repo_path/.cursor/rules/caveman.mdc" ]]; then
    pass "Cursor project caveman rule exists"
  elif [[ -f "$cursor_home/rules/005-caveman.mdc" ]]; then
    pass "Caveman rule provided by user-global ~/.cursor/rules/005-caveman.mdc"
  else
    warn "Caveman rule missing (install user baseline: ~/.cursor/rules/005-caveman.mdc)"
  fi

  if [[ -f "$repo_path/.cursor/docs/browser-verify.project.md" ]]; then
    pass "Cursor browser-verify project supplement exists"
  else
    warn "Cursor browser-verify project supplement missing"
  fi

  if [[ -f "$repo_path/.cursor/mcp.json" || -f "$repo_path/.codegraph/config.json" ]]; then
    pass "Cursor project MCP or codegraph config exists"
  else
    warn "Cursor project MCP and codegraph config are missing"
  fi

  validate_caveman_stack "$repo_path"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --editor)
      EDITOR="$2"
      shift 2
      ;;
    --repo)
      TARGET_REPO="$2"
      shift 2
      ;;
    --profile|--expect-profile)
      EXPECT_PROFILE="$2"
      shift 2
      ;;
    --expect-novus)
      EXPECT_PROFILE="${PRIVATE_PROFILE_ID:-novus}"
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

require_supported_os

if command -v node >/dev/null 2>&1; then
  pass "node is available"
else
  fail "node is not available"
fi


if editor_enabled vscode "$EDITOR"; then
  validate_vscode_user
fi

if editor_enabled cursor "$EDITOR"; then
  validate_cursor_user
  if [[ -z "$TARGET_REPO" ]]; then
    validate_caveman_stack "$ROOT"
  fi
fi

if [[ -n "$TARGET_REPO" ]]; then
  if editor_enabled vscode "$EDITOR"; then
    validate_vscode_repo "$TARGET_REPO"
  fi

  if editor_enabled cursor "$EDITOR"; then
    validate_cursor_repo "$TARGET_REPO"
  fi

  if [[ -n "$EXPECT_PROFILE" ]]; then
    profile_dir="$(require_profile_dir "$EXPECT_PROFILE")"
    if editor_enabled vscode "$EDITOR"; then
      validate_profile_vscode_repo "$TARGET_REPO" "$profile_dir"
    fi
    if editor_enabled cursor "$EDITOR"; then
      validate_profile_cursor_repo "$TARGET_REPO" "$profile_dir"
    fi
  fi
fi

if [[ $EXIT_CODE -eq 0 ]]; then
  echo "Validation complete with no hard failures."
else
  echo "Validation complete with failures."
fi

exit $EXIT_CODE
