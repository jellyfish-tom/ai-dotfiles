# Interactive Setup Wizard - Design

Date: 2026-07-05
Status: Implemented

## Problem

`tools/setup.sh` was flag-only. What happens when flags are omitted was not
obvious (bare invocation silently installed the VS Code baseline with all
defaults), and first-time users had to reverse-engineer the flag surface from
`--help`.

## Decisions (from brainstorming)

- **Trigger:** bare `setup.sh` (zero args) on a TTY launches the wizard; any
  flag takes the existing non-interactive path unchanged. Non-TTY bare
  invocation (CI) keeps legacy behavior.
- **Scope:** full flag surface - editor, profile, repo, plugins, extensions,
  workspace-mode, user-mcp-mode, user baseline.
- **Tech:** `@inquirer/prompts` fetched on demand into
  `~/.cache/ai-dotfiles/wizard/` (Node is already a hard dependency via
  `tools/lib/read-profile.mjs`), with a zero-dependency
  `node:readline` numbered-prompt fallback when offline. The wizard never
  hard-fails on missing inquirer. `AI_DOTFILES_WIZARD_UI=basic` forces the
  fallback (also used for testing).
- **Ending:** summary + the equivalent reusable `tools/setup.sh --flags...`
  command + confirm/edit/abort, then execution.

## Architecture (approach A: wizard as pure front-end)

```
setup.sh (no args, TTY) ──> node tools/lib/wizard.mjs
                              │ prompts + summary on stderr
                              │ argv, one arg per line, on stdout
                            exec setup.sh <argv>  ──> existing parse loop
```

The wizard only produces argv. All validation and install logic stays in
`setup.sh` - there is no second implementation to drift. Rejected
alternatives: interleaved bash prompts inside setup.sh (mixes prompt and
install logic, no reusable command output) and a separate `wizard.sh` entry
point (bare `setup.sh` would keep its surprising silent-install behavior).

## Components

- `tools/lib/wizard.mjs` - prompt backends (inquirer / readline), option
  discovery (profiles from `profiles/` + `$AI_DOTFILES_PROFILES/profiles/`,
  plugins from `shared/plugins/`), question flow with per-option
  explanations, repo-path pre-validation mirroring setup.sh guards
  (home/root refusal, must-be-directory), summary + shell-quoted command,
  confirm/edit/abort loop ("edit" re-runs questions with previous answers as
  defaults).
- `tools/setup.sh` - zero-arg TTY detection before the parse loop; reads
  argv lines from the wizard and re-execs itself. Empty output (abort or
  wizard failure) exits 1 without installing.

## Output contract

- All UI on stderr; stdout carries only the final argv (one arg per line).
- Abort / Ctrl+C / stdin EOF: exit 1, nothing on stdout.
- Editor-conditional questions: plugins only when Cursor is enabled;
  extensions and MCP modes only when VS Code is enabled; workspace-mode only
  when a repo is given.
- Flags are emitted only when they differ from setup.sh defaults, so the
  printed command is minimal and readable.

## Error handling

- Missing `node`: setup.sh prints a hint to use flags and exits 1.
- npm fetch failure (offline): notice on stderr, fallback prompts.
- Invalid numbered/checkbox input: re-prompt.

## Testing

- Piped-answer runs through the basic backend (cursor path, vscode path with
  non-default modes, abort, edit loop).
- PTY end-to-end (`script(1)`) with sandbox `$HOME`: wizard -> exec ->
  full install.
- Non-TTY bare invocation with sandbox `$HOME`: legacy behavior preserved.
- `--help` and flag invocations bypass the wizard.
