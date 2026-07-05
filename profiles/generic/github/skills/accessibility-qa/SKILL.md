---
name: accessibility-qa
description: Accessibility (a11y) verification in a running UI using browser MCP snapshots and interaction checks. Use for WCAG-oriented review, ARIA and semantics, keyboard navigation, focus order, labels, contrast red flags, and requests such as "a11y check", "accessibility audit", "keyboard test this flow", or "is this screen accessible?".
---

# Accessibility QA

Verify accessibility in a **real running app** when possible - not code review alone.

## Tools

Prefer browser MCP (`browser_navigate`, `browser_lock`, `browser_snapshot`, `browser_click`, `browser_press_key` or equivalent, `browser_unlock`). Use snapshot trees for roles, names, states, and focusable elements.

Optional: `webapp-testing` / Playwright MCP only when the operator explicitly needs scripted automation beyond interactive browser MCP.

## Phase 0 - Scope and supplement

Ask and stop when required context is missing (do not infer from branch names):

| Parameter                | When to require                                     | Examples                                                      |
| ------------------------ | --------------------------------------------------- | ------------------------------------------------------------- |
| surface / flow           | ambiguous                                           | page, route, modal, component area                            |
| environment              | not the agreed default                              | local URL, stage                                              |
| market / brand / task id | project supplement or operator-context rules say so | per `.cursor/docs/browser-verify.project.md` or profile rules |

Read the first project supplement that exists (same paths as `jira-browser-verify`):

1. `.cursor/docs/browser-verify.project.md`
2. `.github/docs/browser-verify.project.md`
3. `docs/browser-verify.project.md`

Use it for dev-server commands, URLs, and operator gates. Do not edit code unless the operator later asks for fixes.

## Phase 1 - Reach the target UI

- Confirm dev server or target URL with the operator when not already running.
- Navigate to the agreed entry point; use full flow when keyboard/focus order depends on prior steps.
- Take a fresh snapshot before each structural change (open modal, expand panel, route change).

## Phase 2 - Checklist (apply what fits the surface)

### Perceivable

- Images and icons: meaningful `alt` or `aria-label` / `aria-labelledby`; decorative images empty alt.
- Form fields: visible `<label>` association or `aria-label` / `aria-labelledby`; errors linked via `aria-describedby` when present.
- Headings: logical order (`h1` → `h2` …); no skipped levels that confuse structure.
- Color: do not rely on color alone for required meaning; note obvious contrast risks (flag for human follow-up - MCP may not measure contrast precisely).

### Operable (keyboard)

- All interactive controls reachable and activatable by keyboard (Tab / Shift+Tab / Enter / Space / arrows where appropriate).
- No keyboard trap without documented escape (Esc closes modal when expected).
- Focus visible on interactive elements after Tab.
- Logical focus order matches visual reading order where determinable from snapshots.

### Understandable

- Buttons and links have accessible names matching visible text or clear purpose.
- Error messages programmatically associated with fields when errors show.
- Dynamic updates: note missing `aria-live` / status region when content changes without focus move (flag if behavior seems announced-only-visually).

### Robust (ARIA and semantics)

- Prefer native elements (`button`, `a`, `input`) over div-with-click when inspectable.
- `role`, `aria-expanded`, `aria-selected`, `aria-current`, `aria-hidden` used consistently on custom widgets.
- Duplicate ids: none observed in snapshot scope.

## Phase 3 - Report (required)

Structure:

- **Scope:** surface, URL, environment, assumptions
- **Method:** browser MCP steps taken (not code-only review)
- **Findings:** each item = severity (blocker / major / minor / note), element or selector hint, WCAG-oriented category, observed vs expected
- **Keyboard trace:** short Tab path summary when relevant
- **Gaps:** could not reach UI, blocked auth, tool limits (contrast measurement, screen reader audio)
- **Suggested next step:** operator fix, design review, or deeper audit tool

Stop after reporting unless the operator asks to implement fixes.

## Copilot agent (optional)

When the repo ships `.github/agents/accessibility-qa.agent.md`, use it for a stricter QA-only flow that must not edit code. Still load this skill for the checklist and report format.
