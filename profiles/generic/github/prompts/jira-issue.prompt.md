---
description: Use when investigating a Jira issue, following related Jira and Figma references, and producing a bounded context report before planning or implementation.
---

Investigate a Jira issue deeply and return a structured investigation report before any implementation work.

Input:

- Treat the first Jira-looking token in the user's input as the Jira issue key, for example `PROJ-123`.
- If no Jira key is provided, ask for it and stop.

Rules:

- Your first output must be an investigation report, not an implementation plan.
- Do not write code, edit files, create commits, branches, stashes, or pull requests unless explicitly asked.
- If anything important is inaccessible, missing, or contradictory, call it out clearly.
- Follow direct references aggressively, but keep proactive discovery bounded and explain why something is considered related.

Required Jira investigation:

- Fetch the Jira issue by key using the available Jira tools.
- Review the important issue sections that are accessible, including summary, description, acceptance criteria or expected behavior, comments, linked issues, attachments or attachment metadata, and related URLs found in fields, comments, or attachments.
- Extract and summarize what the issue is about, the current behavior versus expected behavior, business or UX requirements, and explicit blockers, questions, or ambiguities.

Direct reference following:

- From the issue description, comments, links, and attachments, extract and follow accessible references such as other Jira issues, Figma links, Confluence links, PR or branch or commit links, and other accessible URLs.
- Prefer direct issue links and explicit Jira key mentions first.
- Stop after one level of follow-up unless a deeper link is clearly critical.
- If a linked resource is inaccessible, list it under gaps instead of guessing.

Proactive related-issue search:

- Also search for likely related Jira issues even if they are not explicitly linked.
- Use bounded heuristics only: same subsystem, component, labels, fix version, issue area, similar summary terms, same flow or bug keywords, or recent adjacent behavior.
- Cap proactive results at 5 issues and explain briefly why each looks related.

Figma and design context:

- If the issue or related artifacts contain a Figma link, use the Figma tools.
- Review the specific relevant node or nodes.
- If needed, get metadata first to narrow scope, then fetch design context.
- Do not invent missing design details.
- If Jira and Figma conflict, call out the conflict explicitly.

Optional workspace check:

- If the issue appears implementation-related and this workspace is relevant, briefly inspect the workspace for likely affected areas or existing related patterns.
- Keep this high-level unless the user explicitly asks for implementation planning.

Output format:

- Issue: summary of the main ticket in plain language
- Requirements: expected behavior, acceptance criteria, and notable constraints
- Evidence: key Jira comments, attachments, and referenced artifacts that materially affect understanding
- Direct links followed: Jira issues, Figma files, Confluence pages, and other accessible resources you inspected
- Related issues: up to 5 proactively found issues, each with a short reason it appears related
- Gaps or risks: inaccessible links, contradictions, missing information, or areas needing confirmation
- Suggested next step: choose the most sensible next action based on the evidence

After the report, ask whether to:

1. create an implementation plan
2. inspect the codebase for likely impact
3. implement the fix or change
4. refine the investigation

Then stop until the operator answers.

If the operator chooses implementation or planning that leads to code changes, and project-specific scope is not clear from the issue or their message, ask for the missing scope before editing files.
