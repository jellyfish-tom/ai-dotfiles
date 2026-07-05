#!/usr/bin/env bash

# shellcheck source=install-caveman.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install-caveman.sh"

install_cursor_plugin() {
  local root="$1"
  local plugin_name="$2"
  local plugin_dir="$root/shared/plugins/$plugin_name"
  local cursor_home
  cursor_home="$(cursor_home_dir)"

  if [[ ! -d "$plugin_dir" ]]; then
    echo "Plugin not found: $plugin_name (expected at $plugin_dir)" >&2
    return 1
  fi

  if [[ -d "$plugin_dir/cursor/rules" ]]; then
    mkdir -p "$cursor_home/rules"
    cp "$plugin_dir/cursor/rules/"*.mdc "$cursor_home/rules/" 2>/dev/null || true
  fi

  if [[ -d "$plugin_dir/cursor/skills" ]]; then
    mkdir -p "$cursor_home/skills"
    cp -R "$plugin_dir/cursor/skills/"* "$cursor_home/skills/" 2>/dev/null || true
  fi

  if [[ -d "$plugin_dir/cursor/hooks" ]]; then
    mkdir -p "$cursor_home/hooks"
    for hook_script in "$plugin_dir/cursor/hooks/"*.sh; do
      [[ -f "$hook_script" ]] || continue
      local hook_dest="$cursor_home/hooks/$(basename "$hook_script")"
      cp "$hook_script" "$hook_dest"
      chmod +x "$hook_dest"
    done

    local fragment="$plugin_dir/cursor/hooks/hooks-fragment.json"
    if [[ -f "$fragment" && -f "$cursor_home/hooks.json" ]]; then
      local merged
      # shellcheck disable=SC2016
      merged="$(python3 -c 'import json,sys; b=json.load(open(sys.argv[1])); f=json.load(open(sys.argv[2])); h=b.setdefault("hooks",{}); [h.setdefault(e,[]).extend(v) for e,v in f.items()]; print(json.dumps(b,indent=2))' "$cursor_home/hooks.json" "$fragment")" \
        && echo "$merged" > "$cursor_home/hooks.json" \
        || echo "Warning: could not merge hooks-fragment.json for plugin '$plugin_name'. Add manually: $fragment"
    fi
  fi

  local mcp_block="$plugin_dir/mcp/cursor.json"
  if [[ -f "$mcp_block" ]]; then
    cp "$mcp_block" "$cursor_home/plugins-$plugin_name-mcp.json.example"
    echo ""
    echo "Plugin '$plugin_name': add the following block to ~/.cursor/mcp.json → mcpServers:"
    cat "$mcp_block"
    echo ""
  fi

  local plugin_notes
  plugin_notes="$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('installNotes',''))" "$plugin_dir/plugin.json" 2>/dev/null || true)"
  [[ -n "$plugin_notes" ]] && echo "Note: $plugin_notes"

  echo "Installed plugin: $plugin_name"
}

install_cursor_user_baseline() {
  local root="$1"
  local cursor_home
  cursor_home="$(cursor_home_dir)"

  mkdir -p "$cursor_home/rules"
  mkdir -p "$cursor_home/skills"

  cp "$root/editors/cursor/user/rules/"*.mdc "$cursor_home/rules/"
  if [ -d "$root/editors/cursor/user/skills" ]; then
    cp -R "$root/editors/cursor/user/skills/"* "$cursor_home/skills/" 2>/dev/null || true
  fi
  install_file_with_backup "$root/editors/cursor/mcp.json.example" "$cursor_home/mcp.json"
  install_caveman_skills "$root"

  if [[ -d "$root/editors/cursor/user/hooks" ]]; then
    mkdir -p "$cursor_home/hooks"
    install_file_with_backup "$root/editors/cursor/user/hooks/hooks.json" "$cursor_home/hooks.json"
    for hook_script in "$root/editors/cursor/user/hooks/"*.sh; do
      local hook_dest="$cursor_home/hooks/$(basename "$hook_script")"
      cp "$hook_script" "$hook_dest"
      chmod +x "$hook_dest"
    done
    echo "Installed Cursor hooks to $cursor_home/hooks"
  fi

  echo "Installed Cursor user rules to $cursor_home/rules"
  echo "Manual step: copy sections from $root/editors/cursor/user/user-rules.md into Cursor Settings → Rules → User"
}

install_cursor_repo_scaffold() {
  local root="$1"
  local target_repo="$2"
  local profile="$3"
  local profile_dir=""

  mkdir -p "$target_repo/.cursor/rules" "$target_repo/.cursor/commands" "$target_repo/.cursor/docs" "$target_repo/.codegraph" "$target_repo/.mlem/test-personas"

  cp "$root/editors/cursor/project/rules/"*.mdc "$target_repo/.cursor/rules/" 2>/dev/null || true
  if [[ -d "$root/profiles/generic/docs" ]]; then
    cp "$root/profiles/generic/docs/"*.md "$target_repo/.cursor/docs/" 2>/dev/null || true
  fi
  install_caveman_skills "$target_repo"
  cp "$root/editors/cursor/project/.cursorignore.template" "$target_repo/.cursorignore" 2>/dev/null || true
  cp "$root/shared/codegraph/config.json.example" "$target_repo/.codegraph/config.json"

  if [[ -f "$root/editors/cursor/project/mcp.json.example" ]]; then
    install_file_with_backup "$root/editors/cursor/project/mcp.json.example" "$target_repo/.cursor/mcp.json"
  fi

  local profile_commands_installed=false

  if [[ -n "$profile" ]]; then
    if ! profile_dir="$(resolve_profile_dir "$profile")"; then
      echo "Profile not found: $profile" >&2
      exit 1
    fi

    if [[ -d "$profile_dir/cursor/rules" ]]; then
      cp "$profile_dir/cursor/rules/"*.mdc "$target_repo/.cursor/rules/"
    fi

    if [[ -d "$profile_dir/cursor/commands" ]]; then
      shopt -s nullglob
      local profile_command_files=("$profile_dir/cursor/commands"/*.md)
      shopt -u nullglob
      if [[ ${#profile_command_files[@]} -gt 0 ]]; then
        cp "${profile_command_files[@]}" "$target_repo/.cursor/commands/"
        profile_commands_installed=true
      fi
    fi

    if [[ -d "$profile_dir/cursor/docs" ]]; then
      cp "$profile_dir/cursor/docs/"*.md "$target_repo/.cursor/docs/" 2>/dev/null || true
    fi

    if [[ -d "$profile_dir/test-personas" ]]; then
      cp "$profile_dir/test-personas/"*.example.json "$target_repo/.mlem/test-personas/" 2>/dev/null || true
    fi

    echo "Applied Cursor profile overlay: $profile"
  elif [[ -d "$root/profiles/generic/test-personas" ]]; then
    cp "$root/profiles/generic/test-personas/"*.example.json "$target_repo/.mlem/test-personas/" 2>/dev/null || true
  fi

  if [[ "$profile_commands_installed" == false && -d "$root/editors/cursor/project/commands" ]]; then
    shopt -s nullglob
    local command_starters=("$root/editors/cursor/project/commands/"*.md.example)
    shopt -u nullglob
    for example_path in "${command_starters[@]}"; do
      local command_name="${example_path##*/}"
      command_name="${command_name%.example}"
      install_file_with_backup "$example_path" "$target_repo/.cursor/commands/$command_name"
    done
    if [[ ${#command_starters[@]} -gt 0 ]]; then
      echo "Installed Cursor command scaffold (${#command_starters[@]} file(s))"
    fi
  fi

  append_git_info_exclude_snippet \
    "$target_repo" \
    "$root/shared/snippets/git-info-exclude.ai-tooling.mlem" \
    "ai-dotfiles: ai-tooling local exclude"
}
