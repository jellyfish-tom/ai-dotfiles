#!/usr/bin/env bash

install_vscode_user_baseline() {
  local root="$1"
  local user_mcp_mode="$2"
  local user_config_dir
  local user_prompts_dir

  user_config_dir="$(vscode_user_config_dir)"
  user_prompts_dir="$(vscode_user_prompts_dir)"

  mkdir -p "$user_config_dir" "$user_prompts_dir"

  if [[ "$user_mcp_mode" == "autostart" ]]; then
    install_file_with_backup "$root/editors/vscode/mcp.autostart.active.json.example" "$user_config_dir/mcp.json"
    install_file_with_backup "$root/editors/vscode/mcp.autostart.sources.json.example" "$user_config_dir/mcp.autostart.sources.json"
  else
    install_file_with_backup "$root/editors/vscode/mcp.json.example" "$user_config_dir/mcp.json"
  fi

  cp "$root/editors/vscode/user/instructions/"*.instructions.md "$user_prompts_dir/"
  echo "Installed VS Code user instruction templates to $user_prompts_dir"
}

install_vscode_repo_scaffold() {
  local root="$1"
  local target_repo="$2"
  local profile="$3"
  local workspace_mode="$4"
  local profile_dir=""

  mkdir -p "$target_repo/.github" "$target_repo/.vscode" "$target_repo/.codegraph"

  cp -R "$root/profiles/generic/github/." "$target_repo/.github/"
  if [[ -d "$root/profiles/generic/docs" ]]; then
    mkdir -p "$target_repo/.github/docs"
    cp "$root/profiles/generic/docs/"*.md "$target_repo/.github/docs/" 2>/dev/null || true
  fi
  cp "$root/shared/codegraph/config.json.example" "$target_repo/.codegraph/config.json"

  if [[ -n "$profile" ]]; then
    if ! profile_dir="$(resolve_profile_dir "$profile")"; then
      echo "Profile not found: $profile" >&2
      exit 1
    fi
    if [[ -d "$profile_dir/github" ]]; then
      cp -R "$profile_dir/github/." "$target_repo/.github/"
    fi

    if [[ -f "$profile_dir/AGENTS.md" ]]; then
      cp "$profile_dir/AGENTS.md" "$target_repo/AGENTS.md"
    else
      cp "$root/profiles/generic/AGENTS.md" "$target_repo/AGENTS.md"
    fi

    apply_profile_cleanup "$profile_dir" "$target_repo"
    echo "Applied VS Code profile overlay: $profile"
  else
    cp "$root/profiles/generic/AGENTS.md" "$target_repo/AGENTS.md"
  fi

  if [[ "$workspace_mode" == "direct" ]]; then
    cp "$root/editors/vscode/project/.vscode/mcp.json.example" "$target_repo/.vscode/mcp.json"
    echo "Installed direct workspace MCP template"
  else
    mkdir -p "$target_repo/scripts"
    cp "$root/editors/vscode/project/.vscode/mcp.autostart.active.json.example" "$target_repo/.vscode/mcp.json"
    cp "$root/editors/vscode/project/.vscode/mcp.autostart.sources.json.example" "$target_repo/.vscode/mcp.autostart.sources.json"
    cp "$root/editors/vscode/project/.vscode/tasks.json.example" "$target_repo/.vscode/tasks.json"
    cp "$root/editors/vscode/project/scripts/startMcpAutostart.mjs" "$target_repo/scripts/startMcpAutostart.mjs"
    echo "Installed workspace MCP autostart templates"
    echo "Use 'node scripts/startMcpAutostart.mjs --status' or the VS Code task to verify bridge health"
  fi

  if [[ "$workspace_mode" == "autostart" && -f "$target_repo/scripts/startMcpAutostart.mjs" ]]; then
    if (cd "$target_repo" && node scripts/startMcpAutostart.mjs --dry-run); then
      echo "Workspace MCP autostart dry-run completed"
    else
      echo "Workspace MCP autostart dry-run reported issues; review output above" >&2
    fi
  fi
}

install_vscode_extensions() {
  local root="$1"

  if command -v code >/dev/null 2>&1; then
    grep -v '^#' "$root/shared/extensions.txt" | sed '/^$/d' | while read -r extension_id; do
      code --install-extension "$extension_id" >/dev/null || true
      echo "Installed extension: $extension_id"
    done
  else
    echo "Skipping extension install because the code CLI is not available."
  fi
}
