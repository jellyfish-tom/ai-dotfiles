# Profile contract

Each installable profile is a directory under `profiles/<name>/` in this repository.

## Required layout

```
profiles/<name>/
├── profile.json          # contract: setup defaults + validation + parity
├── profile.manifest      # optional: .github paths to delete after overlay (see below)
├── AGENTS.md             # optional: repo entrypoint when scaffolded
├── github/               # VS Code / Copilot overlay (copied to .github/)
├── cursor/               # Cursor overlay (copied to .cursor/)
│   ├── rules/
│   ├── commands/
│   └── docs/
└── test-personas/        # optional: copied to .mlem/test-personas/
```

## profile.json schema

| Key | Purpose |
|-----|---------|
| `id` | Profile id (matches directory name and `--profile` value) |
| `displayName` | Human label |
| `setup.editor` | `vscode` \| `cursor` \| `both` |
| `setup.workspaceMode` | VS Code: `direct` \| `autostart` |
| `setup.userMcpMode` | VS Code user MCP: `direct` \| `autostart` |
| `setup.installExtensions` | boolean |
| `validation.vscode` | Required instructions, agents, skill count, prompts, forbidden paths |
| `validation.cursor` | Required rules, commands, docs |
| `parity.pairs` | `{ github, cursor }` path pairs for drift checks |

`check-profile-parity.sh` compares the **install stack** (generic + profile overlay + cursor scaffold), not the profile overlay alone. Generic-layer files such as `knowledge-base` and `obsidian` instructions are expected in live repos without being duplicated in the profile directory.

See [profiles/_starter/profile.json](../../profiles/_starter/profile.json) for a minimal reference.

## profile.manifest

Optional list of paths **relative to `.github/`**. Each line is applied after generic install and profile overlay copy (`setup.sh` → `apply_profile_cleanup`):

1. **`rm -rf` that path** under the target repo’s `.github/` if it exists.
2. **Excluded from parity expected stack** (`check-profile-parity.sh` filters the same paths).

Lines may use `#` comments (full-line or trailing). Blank lines are ignored.

### When to list a path

| Situation | Example | Action |
|-----------|---------|--------|
| Profile **replaces** a generic file with a different path | `prompts/figma-to-code.prompt.md` → novus ships `figma-to-novus` | List the generic path so the duplicate is removed from `.github/` |
| Generic copies to `.github/` but the **canonical install is elsewhere** | `skills/jira-browser-verify` → `~/.cursor/skills/` | List so `.github/skills/jira-browser-verify` is not left behind |

### When not to list a path

| Situation | Correct approach |
|-----------|-------------------|
| Generic skill should **stay** in `.github/skills/` | Omit from profile overlay; **do not** add to manifest |
| Generic instruction with no profile replacement | Omit from profile overlay only (no manifest entry) |

**Trap:** Listing a generic `.github/skills/<name>` in manifest deletes that skill on the next setup and breaks parity skill counts. Deduping a moved-to-generic skill = remove it from the profile `github/` tree only.

See [profiles/_starter/profile.manifest](../../profiles/_starter/profile.manifest) and novus `profile.manifest` in ai-dotfiles-profiles for working examples.

## Cursor command scaffold

`editors/cursor/project/commands/*.md.example` installs to `.cursor/commands/` (`.example` stripped) when the profile does not ship `cursor/commands/*.md`. Profiles with custom slash commands (e.g. novus) overlay their own files and skip the scaffold.

**Caveman:** installed once via user baseline (`~/.cursor/rules/005-caveman.mdc`). Do not duplicate caveman prose in `AGENTS.md`, `copilot-instructions.md`, or repo `.cursor/rules/caveman.mdc`.

## Install and validate

Use the same profile name on both commands:

```bash
export AI_DOTFILES=~/ai-dotfiles
```

```bash
"$AI_DOTFILES/tools/setup.sh" --editor both --profile _starter --repo /path/to/app
```

```bash
"$AI_DOTFILES/tools/validate.sh" --editor both --profile _starter --repo /path/to/app
```

## Maintainer commands

```bash
"$AI_DOTFILES/tools/pack.sh" --profile _starter --repo /path/to/app
```

```bash
"$AI_DOTFILES/tools/check-profile-parity.sh" --profile _starter --repo /path/to/app
```

```bash
"$AI_DOTFILES/tools/check-rule-parity.sh" --profile _starter
```
