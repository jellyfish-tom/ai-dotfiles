# Session Handoff - ai-dotfiles pack-back (2026-07-05)

## TL;DR

- AI-STACK.md fully refreshed 2026-07-05 (see §7 drift table - it is the checklist for this work).
- New live-only artifacts exist in `~/.cursor/`, `~/.config/`, and `novus/.cursor/` that `setup.sh` cannot reproduce; this session packs them back into ai-dotfiles + ai-dotfiles-profiles.
- All 4 new Cursor hooks are tested and working live; copy as-is, do not redesign.

## Goals

Pack back ALL 6 items so a clean-room `setup.sh` run reproduces the live stack. Success = `verify-maintainer.sh` green + each item below checked off.

1. Copy `~/.cursor/rules/model-tiering-handoff.mdc` → `editors/cursor/user/rules/`.
2. Sync `~/.cursor/skills/session-handoff/SKILL.md` → `editors/cursor/user/skills/session-handoff/` (tracked copy is stale, live version has the model-switch gate).
3. New `editors/cursor/user/hooks/`: `hooks.json` + `open-obsidian.sh` (workspaceOpen), `session-resume.sh` (sessionStart), `git-safety.sh` (beforeShellExecution), `jira-write-guard.sh` (beforeMCPExecution, failClosed). Wire install in `tools/lib/install-cursor.sh` (preserve exec bits; merge vs overwrite existing `~/.cursor/hooks.json` - decide, likely overwrite with warning like user-rules).
4. AI pre-commit dispatcher: copy `~/.config/git/hooks/pre-commit` + example conf (`~/.config/ai-review/Users__tomasz.morawski__novus.conf`, genericized) → `shared/git-hooks/`. **Decision made: opt-in setup flag** (e.g. `setup.sh --git-hooks`), do NOT set `core.hooksPath` by default. Document in README/MCP-style doc.
5. Jira MCP swap: update `editors/cursor/mcp.json.example`, `editors/vscode/mcp*.example`, `docs/maintainers/MCP_SETUP.md`, `editors/cursor/project/commands/jira-issue.md.example` (and generic `jira-investigator.agent.md` if it names the server) from `Jira-Server-MCP` → `atlassian` (`uvx mcp-atlassian`, env mapping JIRA_BASE_URL/JIRA_USER/JIRA_PAT → JIRA_URL/JIRA_USERNAME/JIRA_API_TOKEN). **Decision made: DELETE** `shared/mcp-servers/jira-server-mcp/` and `~/.cursor/mcp-servers/jira-server-mcp/`.
6. Novus commit gate: copy `novus/.cursor/hooks.json` + `novus/.cursor/hooks/commit-format-gate.sh` → `ai-dotfiles-profiles/profiles/novus/cursor/`; update novus `profile.json` if hooks need validation entries; the novus repo files stay untracked until operator commits.

After 1–6: update AI-STACK.md §7 rows to Resolved, re-run `tools/verify-maintainer.sh` and `check-profile-parity.sh --profile novus`.

## Model phases & handoff protocol

- Single phase, **T1 (Sonnet 4.6 Medium)** - mechanical copies + light installer wiring; escalate to T2 only if `install-cursor.sh` wiring or profile contract turns out gnarly (2-failed-attempts ratchet per `model-tiering-handoff` rule). No MAX Mode.
- On completion run session-handoff gate: verify-maintainer green → update this file → stop.

## Architecture & Decisions

- Repos: `~/ai-dotfiles` (public engine), `~/ai-dotfiles-profiles` (private overlays). Profile contract: `docs/maintainers/PROFILE_CONTRACT.md`; parity tools in `tools/`.
- Decisions locked this session (do not re-debate): git-hook install is **opt-in flag**; legacy jira-server-mcp is **deleted**, not archived; hooks live in user baseline (all projects), commit-format gate is novus-profile-only.
- Live sources of truth to copy FROM: `~/.cursor/hooks.json`, `~/.cursor/hooks/*.sh`, `~/.cursor/rules/model-tiering-handoff.mdc`, `~/.cursor/skills/session-handoff/`, `~/.config/git/hooks/pre-commit`, `novus/.cursor/hooks*`.
- Hook I/O schemas already verified against Cursor docs; scripts tested (20 cases). Copy verbatim.

## Current State

- Done: AI-STACK.md refresh; 4 user hooks + novus gate implemented, tested, live; open-obsidian moved to `workspaceOpen`.
- Not started: all 6 pack-back items above.
- Nothing committed anywhere this session (novus `.cursor/hooks*` untracked; ai-dotfiles tree clean except AI-STACK.md edits).

## Next Steps

1. Items 1–3 (user baseline copies + hooks install wiring), then `verify-maintainer.sh`.
2. Items 4–5 (git-hooks packaging with opt-in flag; atlassian template swap + deletions).
3. Item 6 (novus profile) + parity check; flip §7 drift rows to Resolved.

## References

- @docs/AI-STACK.md (§3.2 hooks tables, §7 drift table = checklist)
- @tools/lib/install-cursor.sh, @tools/setup.sh, @tools/verify-maintainer.sh
- @docs/maintainers/PROFILE_CONTRACT.md, @docs/maintainers/MCP_SETUP.md
- `~/ai-dotfiles-profiles/profiles/novus/`
- Operator commit rules: conventional commits in ai-dotfiles; ask before any commit.
