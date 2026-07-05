# ai-dotfiles

## Configuration engine for AI coding environments.

One command installs rules, skills, agents, prompts, and MCP servers into **Cursor** or **VS Code + Copilot** - consistently, across every project you work on. Works on macOS and Linux (Windows: manual copy from templates).

The engine has two layers:

1. **An opinionated baseline, installed by default.** Every setup ships a curated foundation - coding conventions, git safety guards, token-saving output rules, session-management skills and hooks, and an MCP server template. This is deliberate: the baseline encodes practices the engine considers table stakes, and it installs as a whole. See [What comes preinstalled](#-what-comes-preinstalled-the-opinionated-baseline) for the full list and the available opt-outs.

2. **Your configuration, layered on top.** Project- and team-specific conventions live in **profiles** (per-repository bundles of rules, agents, prompts, and skills) and **plugins** (optional tool integrations such as Jira or Obsidian). Author a profile once and anyone on your team can reproduce the identical environment in any repository with a single `setup.sh` run. Private profiles can live in a separate repository (via `AI_DOTFILES_PROFILES`) and be shared like any other dependency.

The baseline is not a starter kit - it is a tuned countermeasure layer for the four cost centers of an unmanaged coding agent:

- **Tokens** - ~75% output reduction via terse-mode rules, model tiering, surgical-edit conventions
- **Mistakes** - execution-layer hooks that block destructive git and unapproved tool calls, enforced even if the model ignores instructions
- **Amnesia** - automatic session handoff and resume across chats and model switches
- **Drift** - validated, reproducible installs across machines and teammates

The full element-by-element breakdown: [docs/OPTIMIZATION-SURFACES.md](docs/OPTIMIZATION-SURFACES.md).

<br>

## 🚀 Quick start

**1. Clone**

```bash
git clone https://github.com/jellyfish-tom/ai-dotfiles.git ~/ai-dotfiles
```

**2. Make scripts find the repo** (add to `~/.zshrc`, `~/.bashrc`, etc.)

```bash
export AI_DOTFILES="$HOME/ai-dotfiles"
```

**3. Install into your project** (`_starter` is a ready-to-use example profile)

```bash
"$AI_DOTFILES/tools/setup.sh" --editor cursor --profile _starter --repo /path/to/your-app
```

That's it. Check it worked:

```bash
"$AI_DOTFILES/tools/validate.sh" --editor cursor --profile _starter --repo /path/to/your-app
```

Use `--editor vscode` if you're not on Cursor. When you're ready to encode your own team's conventions, copy `_starter` into your own profile - see [Make it yours](#-make-it-yours).

<br>

## 🧩 The three concepts

You only need to know three words:

| Concept     | What it is                                                                                  | Flag                            |
| ----------- | ------------------------------------------------------------------------------------------- | ------------------------------- |
| **Editor**  | Where config gets installed: Cursor (`.cursor/`) or VS Code (`.github/`, `.vscode/`)        | `--editor cursor\|vscode\|both` |
| **Profile** | A named bundle of rules, skills, and agents for a project type. Lives in `profiles/<name>/` | `--profile _starter`            |
| **Plugin**  | An optional tool integration (Jira, Obsidian, …): hooks, skills, MCP config                 | `--plugin atlassian`            |

Everything `setup.sh` does is: copy the pieces you picked into your editor's user config and your project.

<br>

## 📦 What comes preinstalled (the opinionated baseline)

The engine is not a blank slate. Any `setup.sh` run (unless you pass `--skip-user-baseline`) installs an opinionated user-level baseline **as a whole** - there is no per-item selection or opt-out:

- **Global rules** in `~/.cursor/rules/`: core coding conventions, caveman terse-output mode, git workflow guards, model tiering, operator choice gate
- **Skills** in `~/.cursor/skills/`: `session-handoff`, `workspace-focus`
- **Hooks** in `~/.cursor/hooks/`: git safety guard, session resume (your existing `hooks.json` is backed up, then overwritten)
- **Caveman skill stack** (7 skills from [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)) in `.agents/skills/`
- **MCP template** replacing `~/.cursor/mcp.json` (backed up first)

A `--repo` scaffold likewise brings a fixed set of project files (`.cursor/` rules, commands and docs, `.cursorignore`, codegraph config, git exclude entries).

Every element and the reasoning behind it is documented in [docs/AI-STACK.md](docs/AI-STACK.md). If you want granular control, review that document first - the current knobs are only `--skip-user-baseline` (skips the entire user baseline), omitting `--repo` (skips the project scaffold), and deleting unwanted files after install.

<br>

## 🍳 Common recipes

Editor config only, no project:

```bash
tools/setup.sh --editor cursor
```

Project scaffold without a profile:

```bash
tools/setup.sh --editor cursor --repo /path/to/app
```

Add Jira and Obsidian integrations:

```bash
tools/setup.sh --editor cursor --plugin atlassian --plugin obsidian
```

Everything at once:

```bash
tools/setup.sh --editor both --profile _starter --repo /path/to/app --plugin atlassian
```

Available plugins:

| Plugin      | What it adds                                                                         |
| ----------- | ------------------------------------------------------------------------------------ |
| `atlassian` | Jira write-guard hook, `jira-browser-verify` skill, MCP config for `mcp-atlassian`   |
| `obsidian`  | Vault boundary rule, hook that keeps Obsidian running, MCP config for Local REST API |

MCP config blocks are printed during install for you to paste into your `mcp.json` - nothing is auto-merged.

<br>

## 🎨 Make it yours

The point of the engine is that you don't fork it - you extend it. Copy `_starter`, encode your conventions, and hand the profile to your team so everyone bootstraps the same setup.

- **Create a profile** for your own stack: [docs/users/create-profile.md](docs/users/create-profile.md)
- **Share profiles privately** with teammates via `AI_DOTFILES_PROFILES` (a separate repo): [create-profile.md#private-profiles](docs/users/create-profile.md#private-profiles)
- **Write a plugin**: [docs/maintainers/PLUGIN_CONTRACT.md](docs/maintainers/PLUGIN_CONTRACT.md)
- **Find ready-made rules** to drop into profiles: [PatrickJS/awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules), github/awesome-copilot

<br>

## 📚 Documentation

| I want to…                       | Read                                                                                       |
| -------------------------------- | ------------------------------------------------------------------------------------------ |
| Set up Cursor                    | [docs/users/cursor.md](docs/users/cursor.md)                                               |
| Set up VS Code                   | [docs/users/vscode.md](docs/users/vscode.md)                                               |
| Create my own profile            | [docs/users/create-profile.md](docs/users/create-profile.md)                               |
| Configure MCP servers            | [docs/maintainers/MCP_SETUP.md](docs/maintainers/MCP_SETUP.md)                             |
| Understand the full stack        | [docs/AI-STACK.md](docs/AI-STACK.md)                                                       |
| See what this actually optimizes | [docs/OPTIMIZATION-SURFACES.md](docs/OPTIMIZATION-SURFACES.md)                             |
| Fix a broken install             | [docs/maintainers/TROUBLESHOOTING.md](docs/maintainers/TROUBLESHOOTING.md)                 |
| Maintain this repo               | [docs/maintainers/FOR_PROJECT_MAINTAINERS.md](docs/maintainers/FOR_PROJECT_MAINTAINERS.md) |

<br>

## 🗂️ Repository layout

```
├── profiles/        Profile bundles (generic scaffold + _starter)
├── shared/          Plugins, MCP servers, agentmemory, codegraph
├── editors/         Cursor and VS Code templates
├── tools/           setup.sh, validate.sh, maintainer scripts
└── docs/            users/ and maintainers/ guides
```
