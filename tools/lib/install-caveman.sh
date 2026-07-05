#!/usr/bin/env bash

install_caveman_skills() {
  local target_dir="$1"

  if ! command -v node >/dev/null 2>&1 || ! command -v npx >/dev/null 2>&1; then
    echo "Skipping caveman skills install in $target_dir (node/npx not available)." >&2
    return 0
  fi

  if [[ ! -d "$target_dir" ]]; then
    echo "Skipping caveman skills install; directory missing: $target_dir" >&2
    return 0
  fi

  (
    cd "$target_dir"
    npx -y github:JuliusBrussee/caveman -- --only cursor --non-interactive
  )

  if [[ -f "$target_dir/.agents/skills/caveman/SKILL.md" ]]; then
    echo "Installed caveman skills in $target_dir/.agents/skills"
  else
    echo "WARN caveman skills install finished but $target_dir/.agents/skills/caveman/SKILL.md is missing" >&2
  fi
}
