#!/usr/bin/env bash

AI_DOTFILES_ROOT="${AI_DOTFILES_ROOT:-}"

profile_lib_root() {
  if [[ -z "$AI_DOTFILES_ROOT" ]]; then
    AI_DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  fi
  printf '%s' "$AI_DOTFILES_ROOT"
}

resolve_profile_dir() {
  local profile_name="$1"
  local root
  root="$(profile_lib_root)"

  if [[ -n "${AI_DOTFILES_PROFILES:-}" && -d "${AI_DOTFILES_PROFILES}/profiles/${profile_name}" ]]; then
    printf '%s/profiles/%s' "$AI_DOTFILES_PROFILES" "$profile_name"
    return 0
  fi

  if [[ -d "${root}/profiles/${profile_name}" ]]; then
    printf '%s/profiles/%s' "$root" "$profile_name"
    return 0
  fi

  return 1
}

require_profile_dir() {
  local profile_name="$1"
  local profile_dir=""

  if ! profile_dir="$(resolve_profile_dir "$profile_name")"; then
    echo "Profile not found: $profile_name (looked in profiles/${profile_name}/ and AI_DOTFILES_PROFILES)" >&2
    exit 1
  fi

  if [[ ! -f "$profile_dir/profile.json" ]]; then
    echo "Profile missing profile.json: $profile_dir" >&2
    exit 1
  fi

  printf '%s' "$profile_dir"
}

profile_setup_field() {
  local profile_dir="$1"
  local field="$2"
  local root
  root="$(profile_lib_root)"
  node "$root/tools/lib/read-profile.mjs" setup-field "$profile_dir" "$field"
}

apply_profile() {
  local profile_name="$1"
  local profile_dir
  profile_dir="$(require_profile_dir "$profile_name")"

  PROFILE="$profile_name"
  EDITOR="$(profile_setup_field "$profile_dir" editor)"
  WORKSPACE_MODE="$(profile_setup_field "$profile_dir" workspaceMode)"
  USER_MCP_MODE="$(profile_setup_field "$profile_dir" userMcpMode)"

  if [[ "$(profile_setup_field "$profile_dir" installExtensions)" == "true" ]] && [[ $SKIP_EXTENSIONS -eq 0 ]]; then
    INSTALL_EXTENSIONS=1
  fi

}

profile_validation_json() {
  local profile_dir="$1"
  local section="$2"
  local root
  root="$(profile_lib_root)"
  node "$root/tools/lib/read-profile.mjs" validation-json "$profile_dir" "$section"
}

profile_parity_pairs() {
  local profile_dir="$1"
  local root
  root="$(profile_lib_root)"
  node "$root/tools/lib/read-profile.mjs" parity-pairs "$profile_dir"
}

profile_github_dir() {
  local profile_dir="$1"
  printf '%s/github' "$profile_dir"
}

profile_cursor_dir() {
  local profile_dir="$1"
  printf '%s/cursor' "$profile_dir"
}
