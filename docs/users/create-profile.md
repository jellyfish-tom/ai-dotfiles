# Create your own profile

A **profile** is a named bundle of rules, agents, instructions, skills, and prompts that `setup.sh` overlays on top of the generic scaffold when you bootstrap a project. It is how you encode your team's conventions and tooling without modifying the shared engine.

## Quickstart

```bash
export AI_DOTFILES="${AI_DOTFILES:-$HOME/ai-dotfiles}"
cd "$AI_DOTFILES"

# 1. Copy the example profile as a starting point
cp -R profiles/_starter profiles/myteam

# 2. Edit the manifest
#    - Change "id" and "displayName" in profiles/myteam/profile.json
#    - Update validation.vscode / validation.cursor to match what your profile ships

# 3. Install it into a project
tools/setup.sh --editor both --profile myteam --repo /path/to/your-app

# 4. Validate the install
tools/validate.sh --editor both --profile myteam --repo /path/to/your-app
```

## What to put in your profile

| You want to add                                         | Where it goes                                           |
| ------------------------------------------------------- | ------------------------------------------------------- |
| Repo-wide Cursor rules (coding style, operator context) | `profiles/myteam/cursor/rules/*.mdc`                    |
| Cursor slash commands                                   | `profiles/myteam/cursor/commands/*.md`                  |
| Copilot instructions                                    | `profiles/myteam/github/instructions/*.instructions.md` |
| Agent definitions                                       | `profiles/myteam/github/agents/*.agent.md`              |
| Prompt templates                                        | `profiles/myteam/github/prompts/*.prompt.md`            |
| Team-specific skills                                    | `profiles/myteam/github/skills/<skill>/SKILL.md`        |
| Custom `AGENTS.md`                                      | `profiles/myteam/AGENTS.md`                             |

Files are merged with the generic scaffold - your profile adds or replaces, not from scratch.

## Removing generic files you don't want

If your profile replaces a generic file at a different path (e.g. you ship `figma-to-myapp.prompt.md` instead of the generic `figma-to-code.prompt.md`), list the generic path in `profiles/myteam/profile.manifest`:

```
# profiles/myteam/profile.manifest
prompts/figma-to-code.prompt.md
```

`setup.sh` will delete the listed paths from `.github/` after the overlay.

## `profile.json` fields

```json
{
  "id": "myteam",
  "displayName": "My Team",
  "setup": {
    "editor": "both",
    "workspaceMode": "direct",
    "userMcpMode": "direct",
    "installExtensions": false
  },
  "validation": {
    "vscode": {
      "requiredInstructions": [],
      "requiredAgents": [],
      "skillCount": 5,
      "requiredPrompts": [],
      "forbiddenPaths": [],
      "agentsMdMustContain": []
    },
    "cursor": {
      "requiredRules": [],
      "requiredCommands": [],
      "requiredDocs": []
    }
  },
  "parity": {
    "pairs": []
  }
}
```

Set `validation` fields to match exactly what your profile ships - `validate.sh` uses them to confirm the install is correct.

## Private profiles

If your profile contains proprietary content, keep it in a separate private repo and point `AI_DOTFILES_PROFILES` to it:

```bash
export AI_DOTFILES_PROFILES="$HOME/my-private-profiles"
```

`setup.sh` resolves profiles from `$AI_DOTFILES_PROFILES/profiles/<name>/` when set, falling back to `$AI_DOTFILES/profiles/<name>/`. `verify-maintainer.sh` will smoke-test all profiles found under `$AI_DOTFILES_PROFILES/profiles/`.

## See also

- [PROFILE_CONTRACT.md](../maintainers/PROFILE_CONTRACT.md) - full contract reference
- [PLUGIN_CONTRACT.md](../maintainers/PLUGIN_CONTRACT.md) - for user-global integrations (hooks, MCP)
- [AI-STACK.md](../AI-STACK.md) - how profiles fit into the layer model
