---
name: jira-browser-verify
description: Verifies Jira task implementations in a running browser using MCP browser tools. Discovers optional project-specific instructions, derives required test inputs from the task and code, asks the operator for anything missing, then executes and reports against acceptance criteria. Use when the user asks to test, verify, or QA a Jira ticket in the browser, loan app, upgrade flow, or local dev UI.
---

# Jira browser verification

Verify that implemented UI/flow behavior matches Jira acceptance criteria in a **real running app**, not only via code review.

## Tools

Prefer **cursor-ide-browser** MCP when available (`browser_navigate`, `browser_lock`, `browser_snapshot`, `browser_fill`, `browser_fill_form`, `browser_click`, `browser_wait_for`, `browser_unlock`). Fall back to other browser MCP servers with the same loop: navigate → snapshot → act → snapshot.

Follow the hosting server's lock/order rules (navigate before lock; fresh snapshot after structural changes).

## Phase 0 - Discover project supplement (mandatory)

Before planning or browsing, search the **workspace root** for project-specific instructions. Read the **first file that exists**:

1. `.cursor/docs/browser-verify.project.md`
2. `.cursor/browser-verify.project.md`
3. `docs/browser-verify.project.md`

If found: treat it as authoritative for URLs, dev-server commands, route maps, personas paths, market/brand gates, and local conventions. If none exists: proceed with generic defaults and rely more on operator input.

Also scan (when relevant to the task): Jira/MCP, `docs/**`, `.mlem/docs/**`, flow guides, Storybook paths, and the implementation diff.

When Obsidian MCP is available or the vault is in the workspace: search `Projects/{repo}/` and `Session-logs/` for domain notes, flow maps, or prior QA context before asking the operator.

## Phase 1 - Build a requirements inventory

From **all** available sources (Jira summary/AC, user message, git diff, touched routes/components, project supplement), list what is needed to run a meaningful verification. Use categories:

| Category              | Examples                                                                 |
| --------------------- | ------------------------------------------------------------------------ |
| **Scope**             | market, brand, product surface, feature area, Jira key                   |
| **Environment**       | base URL, path prefix, env/stage, mocks on/off                           |
| **Runtime**           | dev server command, port, confirmation server is up                      |
| **Auth / persona**    | test user JSON, SSN, email, document id, OTP handling                    |
| **Entry strategy**    | full wizard from login vs deep-link to a route (and prerequisites)       |
| **Preconditions**     | feature flags, backend stubs, prior steps completed, session keys        |
| **Expected outcomes** | one row per AC: action → UI state → destination route/API                |
| **Known non-bugs**    | e.g. CMS keys showing as raw ids before publish                          |
| **Escalation**        | when to stop and ask the human (auth wall, stuck step, missing products) |

Map each AC to **concrete checks**: visible copy, control labels, enabled/disabled states, modal content, URL after navigation.

## Phase 2 - Gap analysis and operator gate

Compare the inventory to what you **already have** (in thread, files, inferable from repo).

**Do not open the browser** until required gaps are filled.

Send **one** message to the operator listing only what is **missing**, grouped by category. For each item:

- say **why** it is needed (which AC or step depends on it),
- give **allowed options** when known (from project supplement),
- mark items **optional** vs **blocking**.

Use this template:

```markdown
## Browser verification - inputs needed

**Task:** [Jira key + one-line intent]
**Project supplement:** [found: path | not found]

### Blocking (cannot start without these)

- …

### Optional (have defaults or can infer)

- …

Reply with the missing values (paste persona JSON, URL, or "use default X"). I will proceed when blocking items are provided.
```

**Stop** after sending. Resume only when the operator replies in the same thread with the requested data.

## Phase 3 - Preconditions

1. Confirm dev app is reachable (operator may already have it running; if not, start using command from project supplement or ask).
2. `browser_navigate` to entry URL.
3. `browser_lock` before interactions.
4. Apply persona (fill forms from operator-supplied data).

Prefer **full user journey** when AC covers routing, session storage, or submit → next step. Use **deep-link** only when project supplement allows it and prerequisites are documented or operator confirms session is seeded.

## Phase 4 - Execute checks

Verification has **three separate layers**. Do not collapse them into one fixed delay.

| Layer                                | What it proves                              | How to observe                                                                           |
| ------------------------------------ | ------------------------------------------- | ---------------------------------------------------------------------------------------- |
| **1. Navigation**                    | Router sent the user to the expected step   | **URL** changed to the expected path (or hash/search if relevant)                        |
| **2. Presentation**                  | The screen for that route actually rendered | `browser_snapshot` / screenshot - headings, buttons, modals, copy                        |
| **3. Backend** (when AC requires it) | APIs ran, mocks fired, errors logged        | `browser_network`, `browser_console_messages` - only for criteria that depend on network |

### URL-dependent checks - never use arbitrary sleeps

When an AC depends on reaching or leaving a route (including **brief** screens such as waiting/loading):

- **Do not** `wait N seconds` and assume the right page is showing.
- **Do** wait until the **URL actually changes** (read current URL from snapshot metadata or `browser_get`).
- After the URL matches: capture evidence **immediately** (snapshot; screenshot only if needed).
- If the AC also requires UI on that route: snapshot **after** URL match - URL alone is not enough for copy/layout.
- If the route is **transient** (auto-advances): optionally wait until URL **leaves** that path to prove advance - that is a second URL event, not a timer.

Use short **poll loops** (snapshot or URL read every ~300–500ms) with a **timeout** (e.g. 15–30s) only as a safety bound - not as the primary wait strategy. Prefer `browser_wait_for` when the MCP supports URL/text/selector conditions.

### Per-AC loop

1. `browser_snapshot` - locate elements by ref; note starting URL.
2. Perform **one** intentional action (click, fill, select).
3. **If AC depends on navigation:** poll until URL matches expected path (or leaves it, if testing exit) - record URL + time observed.
4. **If AC depends on UI:** `browser_snapshot` on the matched URL - verify headings, buttons, modals.
5. **If AC depends on API:** inspect network/console for the expected call or absence of errors.
6. Note **pass / fail / blocked** per layer in evidence (URL reached? UI seen? network?).

Rules:

- Do not guess credentials or market/brand when project supplement forbids it.
- Do not run `npm test` unless the operator asked.
- If stuck (wrong step, login loop, empty offer): **stop**, describe state, ask operator - do not thrash retries.
- Raw i18n key ids on screen → check project supplement; often **CMS not published**, not a FE defect.
- Inferring “waiting page worked” from the **final** URL only (e.g. already on offer) is **fail** for navigation-layer checks unless URL `waiting` was observed in between.

## Phase 5 - Report

```markdown
## Browser verification - [Jira key]

**Environment:** [URL, branch, surface]
**Persona:** [source, not the secrets themselves]
**Project supplement:** [path]

| AC  | Result            | Evidence                |
| --- | ----------------- | ----------------------- |
| 1   | pass/fail/blocked | URL, control text, note |

### Blockers

- …

### Out of scope / not tested

- …

### Follow-ups

- …
```

Unlock browser when finished (`browser_unlock`).

## Generic defaults (only if project supplement silent)

- Entry: operator-provided base URL + login path.
- Persona: operator must supply test data for regulated flows; never invent PII.
- Evidence-first: URL + snapshot over assumptions.

## What not to put in this skill

Keep **repository-specific** URLs, routes, CLI commands, operator catalogs (market/brand/Jira commit format), and persona file paths in the project's `browser-verify.project.md` only.
