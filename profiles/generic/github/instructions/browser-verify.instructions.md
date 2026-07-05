---
description: Browser QA and Jira acceptance verification - operator gate, supplement discovery, and reporting workflow.
applyTo: "**"
---

# Browser verification

Use for manual QA, smoke tests, UI bug reproduction, and Jira acceptance checks in a running app.

## Default skill

Load the `jira-browser-verify` skill (`~/.cursor/skills/jira-browser-verify/` or `.github/skills/jira-browser-verify/` when copied to the repo).

It defines the MCP loop: discover project supplement → build requirements inventory → operator gate → execute → report.

## Project supplement (read first)

Before browsing, read the **first file that exists**:

1. `.cursor/docs/browser-verify.project.md`
2. `.github/docs/browser-verify.project.md`
3. `docs/browser-verify.project.md`

When present, the supplement is authoritative for dev-server commands, URLs, route maps, persona paths, operator gates, and escalation rules specific to that repo.

## Operator gate (generic)

Ask and stop when required context is missing. Do not infer scope from branch names.

| Parameter       | When to require               | Examples                            |
| --------------- | ----------------------------- | ----------------------------------- |
| region / market | profile or supplement says so | project-specific codes              |
| brand           | profile or supplement says so | project brand names                 |
| task id         | Jira-driven verification      | ticket key                          |
| surface         | flow is ambiguous             | route, feature folder, product area |
| environment     | not the agreed local default  | stage URL, mock mode                |

If the project supplement defines a stricter gate, follow it.

## Copilot agent (optional)

When the repo ships `.github/agents/browser-verify.agent.md`, use it for a stricter QA-only flow that must not edit code. It should still load `jira-browser-verify` and read the project supplement.

## Playwright-only flows

When the operator explicitly needs Playwright MCP scripting (not Cursor browser MCP), a repo may ship an optional `webapp-testing` skill. That is not the default browser QA path.

## Reporting

Do not declare pass from the final URL alone when transient routes matter. Record scope, environment, steps, evidence, pass/fail per acceptance criterion, blockers, and next step.
