---
description: Use this always-on routing guide to select the correct repo skill, prompt, or custom agent for Jira investigation, browser QA, security, privacy, tours, and design-to-code workflows.
applyTo: '**'
---

# Skill Routing

Use the lightest matching customization, but do it deliberately when the task clearly matches one of these workflow types.

## Jira investigation

- For requests such as "investigate ticket", "understand this Jira", "follow Jira comments", or "gather issue context first", prefer `.github/prompts/jira-issue.prompt.md`.
- If the operator wants a stricter Jira-first research flow that should stop before planning or implementation, prefer `.github/agents/jira-investigator.agent.md`.

## Browser QA and verification

- For requests such as "verify in browser", "manual QA", "smoke test", "reproduce UI bug", or "check Jira acceptance criteria in the app", load the `jira-browser-verify` skill and read [browser-verify.instructions.md](./browser-verify.instructions.md).
- Read the project supplement at `.cursor/docs/browser-verify.project.md` or `.github/docs/browser-verify.project.md` when present before opening the browser.
- For a stricter QA-only agent that must not edit code, prefer `.github/agents/browser-verify.agent.md` when the repo ships it.
- Optional: `webapp-testing` skill only when the operator explicitly needs Playwright MCP scripting.

## Accessibility QA

- For requests such as "a11y check", "accessibility audit", "keyboard navigation test", "ARIA review", or "WCAG check this screen", load the `accessibility-qa` skill.
- Read the project browser supplement when present (see Browser QA section) for URLs, operator gates, and dev runtime.
- For a stricter QA-only agent that must not edit code, prefer `.github/agents/accessibility-qa.agent.md` when the repo ships it.

## Security and privacy

- For security audits, vulnerability checks, secret scans, auth and access-control review, or "is this secure?" requests, load the `security-review` skill.
- For privacy, retention, deletion, analytics consent, user-data handling, or "is this GDPR-compliant?" requests, load the `gdpr-compliant` skill.

## Code walkthroughs

- For onboarding tours, architecture walkthroughs, RCA walkthroughs, PR tours, or requests to explain a flow through code, load the `code-tour` skill instead of answering with an unstructured explanation.

## Design-to-code

- For Figma URLs, node-based implementation work, design sync, or screen recreation from design, prefer `.github/prompts/figma-to-code.prompt.md` and follow the Figma instructions.

## Knowledge base (Obsidian hybrid)

- Read [knowledge-base.instructions.md](./knowledge-base.instructions.md) before creating, moving, or searching documentation.
- Precedence: repo `docs/` and `.github/` → Obsidian vault (MCP) → agentmemory.
- Durable handoffs: vault `Session-logs/` or `session-handoff` skill.

## Session state (multi-step work)

- For substantial multi-step implementation, refactor, migration, or debugging, read [session-state.instructions.md](./session-state.instructions.md) and use `.ai/` files as described there.
- For a structured context reset between chats, load the `session-handoff` user skill (`~/.cursor/skills/session-handoff/`).

## Routing rule

- When one of the workflow types above clearly matches the request, explicitly use the mapped skill, prompt, or agent instead of relying on generic default behavior.
- When both a prompt and a custom agent match, use the custom agent for stricter bounded workflows and the prompt for lighter direct execution.