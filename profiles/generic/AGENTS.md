# Project Agent Guide

This repository keeps its canonical VS Code Copilot guidance in [.github/copilot-instructions.md](.github/copilot-instructions.md).

Use that file as the primary always-on repo guide.

- Read [.github/copilot-instructions.md](.github/copilot-instructions.md) first for repo map, workflow, validation, and session-state rules.
- Use scoped files under [.github/instructions](.github/instructions), [.github/prompts](.github/prompts), [.github/agents](.github/agents), and [.github/skills](.github/skills) when the task matches them.
- Keep changes narrow and validate with the smallest relevant check.

Keep this file thin. When repo AI guidance changes, update [.github/copilot-instructions.md](.github/copilot-instructions.md) first and use this file as the cross-agent compatibility entrypoint.

## Workflow Map

- Knowledge base (repo + Obsidian hybrid): .github/instructions/knowledge-base.instructions.md
- Session state (`.ai/` tracking): .github/instructions/session-state.instructions.md
- Session handoff: session-handoff skill (Cursor user skills)
- Jira Investigation: .github/agents/jira-investigator.agent.md
- Design-to-Code: .github/prompts/figma-to-code.prompt.md
- Security Review: .github/skills/security-review/SKILL.md
- GDPR/Privacy Review: .github/skills/gdpr-compliant/SKILL.md
- Onboarding Tours: .github/agents/onboarding-tour.agent.md
- Code Tours: .github/skills/code-tour/SKILL.md
- API Review: .github/prompts/api-review.prompt.md

- Browser QA: .github/instructions/browser-verify.instructions.md + `jira-browser-verify` skill
- Accessibility QA: .github/skills/accessibility-qa/SKILL.md

Optional profiles may add repo-specific supplements, design-system, or operator-context workflows.

## How to extend

- Add new agents to .github/agents/, prompts to .github/prompts/, skills to .github/skills/, and update .github/instructions/skill-routing.instructions.md for routing.
- For repo-specific flows, keep them in a dedicated profile folder and document how to install that profile.
