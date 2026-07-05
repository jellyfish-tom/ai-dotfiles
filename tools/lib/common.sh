#!/usr/bin/env bash

ai_dotfiles_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")/.." && pwd)"
  cd "$script_dir/.." && pwd
}

require_supported_os() {
  case "$(uname -s)" in
    Darwin|Linux) ;;
    *)
      echo "Unsupported OS: $(uname -s)" >&2
      echo "Use manual copy steps from README.md on this platform." >&2
      exit 1
      ;;
  esac
}

vscode_user_config_dir() {
  case "$(uname -s)" in
    Darwin) printf '%s/Library/Application Support/Code/User' "$HOME" ;;
    Linux) printf '%s/.config/Code/User' "$HOME" ;;
  esac
}

vscode_user_prompts_dir() {
  printf '%s/prompts' "$(vscode_user_config_dir)"
}

cursor_home_dir() {
  printf '%s/.cursor' "$HOME"
}

install_file_with_backup() {
  local source_path="$1"
  local dest_path="$2"

  mkdir -p "$(dirname "$dest_path")"

  if [[ -f "$dest_path" ]] && ! cmp -s "$source_path" "$dest_path"; then
    local backup_path="$dest_path.backup.$(date +%Y%m%d%H%M%S)"
    cp "$dest_path" "$backup_path"
    echo "Backed up existing file to $backup_path"
  fi

  if [[ ! -f "$dest_path" ]] || ! cmp -s "$source_path" "$dest_path"; then
    cp "$source_path" "$dest_path"
    echo "Installed $dest_path"
  else
    echo "Already up to date: $dest_path"
  fi
}

# profile.manifest: delete listed .github/ paths after overlay (replaced or installed elsewhere).
# Do not list generic skills that must remain in .github/skills/ - see PROFILE_CONTRACT.md.
apply_profile_cleanup() {
  local profile_dir="$1"
  local target_repo="$2"
  local manifest_path="$profile_dir/profile.manifest"

  if [[ ! -f "$manifest_path" ]]; then
    return 0
  fi

  while IFS= read -r relative_path || [[ -n "$relative_path" ]]; do
    relative_path="${relative_path%%#*}"
    relative_path="$(printf '%s' "$relative_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    if [[ -z "$relative_path" ]]; then
      continue
    fi

    local target_path="$target_repo/.github/$relative_path"
    if [[ -e "$target_path" ]]; then
      rm -rf "$target_path"
      echo "Removed generic-only file: .github/$relative_path"
    fi
  done < "$manifest_path"
}

editor_enabled() {
  local editor="$1"
  local selected="$2"

  [[ "$selected" == "both" || "$selected" == "$editor" ]]
}

append_git_info_exclude_snippet() {
  local target_repo="$1"
  local snippet_path="$2"
  local marker="$3"
  local exclude_file="$target_repo/.git/info/exclude"

  if [[ ! -d "$target_repo/.git" ]]; then
    echo "Skipping git info exclude (not a git repo): $target_repo"
    return 0
  fi

  if [[ ! -f "$snippet_path" ]]; then
    echo "Skipping git info exclude; snippet missing: $snippet_path" >&2
    return 0
  fi

  mkdir -p "$(dirname "$exclude_file")"
  touch "$exclude_file"

  if grep -qF "$marker" "$exclude_file" 2>/dev/null; then
    echo "Git info exclude already contains: $marker"
    return 0
  fi

  {
    echo ""
    echo "# $marker"
    grep -v '^#' "$snippet_path" | sed '/^[[:space:]]*$/d'
  } >> "$exclude_file"

  echo "Appended git info exclude snippet to $exclude_file"
}
