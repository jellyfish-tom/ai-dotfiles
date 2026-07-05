# Portability allowlist

`tools/check-generic-portability.sh` scans the public ai-dotfiles tree for project-specific strings (market names, internal routes, profile-only filenames that used to leak, etc.). Files listed in `tools/portability-allowlist.txt` are **exempt** because they intentionally document multi-repo layout, worked examples, or user-global rules that reference optional profiles.

## When to allowlist

| Case                                                  | Example paths                                                      |
| ----------------------------------------------------- | ------------------------------------------------------------------ |
| Multi-repo inventory / stack map                      | `docs/AI-STACK.md`                                                 |
| Maintainer docs with profile names as examples        | `docs/maintainers/`                                                |
| Hybrid Obsidian + repo docs with worked example paths | `knowledge-base.instructions.md`, `obsidian.instructions.md`       |
| User-global rules citing optional profile behavior    | `git-workflow.mdc`, `operator-choice-gate.mdc`, `002-obsidian.mdc` |
| Workspace template with placeholder repo folders      | `dev.code-workspace.example`                                       |
| User skill mirror of generic skill (same content)     | `editors/cursor/user/skills/jira-browser-verify/SKILL.md`          |

## When not to allowlist

- New generic instructions, skills, or prompts that embed a single customer's market, brand, or routes - **genericize the text** instead.
- Profile overlay content under `ai-dotfiles-profiles` (not scanned here).

## Blocked pattern (current)

`novus`, `creditea`, `credit24`, `provident`, `ipf-demo`, `figma-to-novus`, `novus-operator-context`, `loan-app`, `acq-[0-9]+`

`browser-verify.instructions.md` is **not** blocked - it is a generic install filename after the shared port.

## Update process

1. Prefer fixing portable wording in `profiles/generic/` first.
2. If exemption is required, add one line to `tools/portability-allowlist.txt` and a row to the table above.
3. Run `tools/check-generic-portability.sh` or `tools/verify-maintainer.sh`.
