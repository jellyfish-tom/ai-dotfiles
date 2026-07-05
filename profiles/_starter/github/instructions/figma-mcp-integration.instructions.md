---
description: Use when implementing from Figma, syncing design to code, or validating design-driven UI changes against Figma nodes and screenshots.
---

# Figma MCP Integration Rules

These rules define how to translate Figma inputs into code for this project.

## Required flow

1. Run `get_design_context` first for the exact node or nodes being implemented.
2. If the response is too large or truncated, run `get_metadata` to get the node map and then re-fetch only the required node or nodes.
3. Run `get_screenshot` for a visual reference of the variant being implemented.
4. Only after you have both the structured context and the screenshot should you pull assets and start implementation.
5. Translate the output into this project's conventions, styles, and framework. Reuse the project's color tokens, components, and typography wherever possible.
6. Validate against Figma before marking the work complete.

## Implementation rules

- Treat Figma MCP output as a design representation, not final project-ready code.
- Replace Tailwind-style utilities with this repo's preferred utilities, branded components, and tokens where appropriate.
- Reuse existing buttons, inputs, typography, icon wrappers, layouts, and routing or state patterns instead of duplicating them.
- Use the project's existing color system, typography scale, spacing, and assets consistently.
- Aim for visual parity with the design while still following the repo's design-system and architectural conventions.
