---
description: Use when implementing a Figma design in a target repository, translating a figma.com URL or node into repo-aligned code, or starting a design-to-code workflow from chat.
---

Implement a Figma design in the target repository.

Use this prompt when you have a Figma URL, file key, or node id and want the agent to translate that design into repo-aligned code instead of starting from a blank plan.

Workflow:

1. If the Figma URL, file key, node id, or target surface is missing, ask for the missing input before editing.
2. Read `.github/instructions/figma-mcp-integration.instructions.md` and any relevant design-system or component-mapping instructions before implementation.
3. Use the required Figma flow: `get_design_context` first, then `get_screenshot`, then only the assets needed for the exact node being implemented.
4. Reuse existing UI primitives, tokens, assets, and surrounding route or component patterns before creating anything new.
5. If the change touches project-specific paths and scope is ambiguous, ask before editing.
6. Keep the diff narrow, preserve the target repo's established visual language, and avoid introducing parallel styling or component abstractions without immediate need.
7. Validate the touched files with editor diagnostics and the narrowest relevant check available.

Output expectations:

- Implement the requested code changes, not just a plan.
- Summarize what was reused from the existing design system or component library.
- Call out any remaining Figma mismatch, missing asset, or unresolved scope dependency.