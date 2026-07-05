# Optimization surfaces

What this stack actually optimizes, element by element, compared to running an AI editor with no setup at all.

The premise: an unmanaged coding agent has four cost centers - **tokens, mistakes, amnesia, and drift**. Every element installed by this engine is a countermeasure aimed at one of six surfaces below. For the layer model and install flow behind these elements, see [AI-STACK.md](AI-STACK.md).

---

## 1. Token and cost efficiency

The most explicit focus of the stack ([AI-STACK.md §8](AI-STACK.md#8-design-principles): "Token reduction", "Cost gates").

| Element                                          | Mechanism                                                                                 | Saving                                                                                |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Caveman mode (`005-caveman.mdc` + 7-skill stack) | Terse output style enforced globally                                                      | ~75% fewer output tokens on every response                                            |
| `MIN_TOKENS` + StrReplace-first (`000-core.mdc`) | Surgical diffs instead of full-file rewrites; `cp`/`mv` instead of read-write loops       | Output tokens proportional to the change, not the file                                |
| Model tiering (`model-tiering-handoff.mdc`)      | T0/T1/T2 task-to-model mapping; escalation only after 2 failed attempts on the same error | Cheap models do cheap work; no burning premium models on boilerplate or blind retries |
| `.cursorignore`                                  | Excludes build artifacts and junk from indexing                                           | Smaller, cleaner context per prompt                                                   |
| Codegraph as on-demand MCP                       | Structural code intelligence queried when needed, not injected every prompt               | Context cost paid only when the query has value                                       |

**Without the setup:** default verbose output, one model for everything, full-file rewrites, unfiltered context.

## 2. Safety and blast-radius control

The most defensible surface, because two of its guards are enforced at the tool-call layer - hooks that intercept execution - rather than instructions a model could rationalize past.

| Element                                                   | Enforcement                                                | Prevents                                                                          |
| --------------------------------------------------------- | ---------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `git-safety.sh` (`beforeShellExecution` hook)             | Blocks the command before it runs                          | Force push, hard reset, other destructive git                                     |
| Jira write-guard (`beforeMCPExecution` hook, fail-closed) | Blocks mutating Jira/Confluence MCP calls pending approval | Silent ticket edits                                                               |
| `git-workflow.mdc`                                        | Rule                                                       | Auto-commit, auto-push, auto-test without explicit request                        |
| Operator-choice-gate (`operator-choice-gate.mdc`)         | Rule                                                       | Guessing project parameters (region, brand, ticket id) from branch names or paths |
| AI pre-commit review (opt-in, `--git-hooks`)              | Git hook                                                   | Unreviewed AI-authored changes reaching commits                                   |

**Without the setup:** the agent's own judgment is the only barrier between a bad inference and a destroyed branch.

## 3. Session continuity

Counters agent amnesia across sessions and model switches ([AI-STACK.md](AI-STACK.md) layer L3).

| Element                                   | Mechanism                                                                             |
| ----------------------------------------- | ------------------------------------------------------------------------------------- |
| `session-resume.sh` (`sessionStart` hook) | Auto-injects `.ai/session-resume.md` into every fresh session                         |
| `session-handoff` skill                   | Writes the resume file at phase gates: decisions made, current state, exact next task |
| agentmemory MCP                           | Persistent cross-session memory store                                                 |

Combined with model tiering, this makes cross-model handoffs lossless: a T2 model plans, writes the handoff, and a T1 model resumes with full context.

**Without the setup:** every new chat starts cold; switching models loses all decisions and progress.

## 4. Consistency and reproducibility

The engine itself - [profiles, plugins](maintainers/PROFILE_CONTRACT.md), and the install/validate machinery.

- One command produces the same rules, skills, hooks, and MCP config on every machine and in every repo.
- Profiles make team environments identical: author once, every teammate bootstraps the same setup.
- `validate.sh`, `check-profile-parity.sh`, and `check-rule-parity.sh` catch drift between intended and installed state.

**Without the setup:** config drifts per machine, per teammate, per repo - silently.

## 5. Context quality

Not how _much_ context, but whether the model gets the _right_ facts at the right scope.

| Element                                                                | Contribution                                                                                                                         |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Layered rule precedence ([AI-STACK.md §1](AI-STACK.md#1-mental-model)) | User-global conventions vs repo rules vs path-scoped instructions vs on-demand skills - each instruction loads only where it applies |
| Codegraph MCP                                                          | Structural facts about the codebase (callers, callees, impact) instead of grep guesswork                                             |
| Figma MCP                                                              | Real design context for design-to-code work                                                                                          |
| Obsidian MCP                                                           | Knowledge-base access with an explicit vault boundary                                                                                |

**Without the setup:** one flat instruction blob (or none), and the model guesses at everything it cannot see.

## 6. Workflow leverage

One-off prompt engineering becomes versioned, shareable assets.

- Slash commands (`/jira-issue PROJ-123`) - parameterized, repeatable workflows
- Agents (`jira-investigator`, `onboarding-tour`) - role definitions with their own tool guidance
- Prompts (`figma-to-project`) - guided multi-step procedures
- Skills (`session-handoff`, `jira-browser-verify`, caveman stack) - on-demand capabilities

**Without the setup:** the same instructions retyped into chat, with per-session variance in quality.

---

## Summary

| Cost center | Surface                  | Primary countermeasures                          | Enforcement               |
| ----------- | ------------------------ | ------------------------------------------------ | ------------------------- |
| Tokens      | 1. Token/cost efficiency | Caveman mode, model tiering, surgical edits      | Rules + skills            |
| Mistakes    | 2. Safety                | git-safety hook, Jira write-guard, scope gates   | **Hooks (hard)** + rules  |
| Amnesia     | 3. Session continuity    | session-resume hook, handoff skill, agentmemory  | **Hooks (hard)** + skills |
| Drift       | 4. Reproducibility       | Engine + profiles + validate/parity scripts      | Scripts                   |
| -           | 5. Context quality       | Layered precedence, codegraph/Figma/Obsidian MCP | Structure                 |
| -           | 6. Workflow leverage     | Commands, agents, prompts, skills                | Assets                    |

Surfaces 2 and 3 are the strongest claims: they hold even against a model that ignores instructions, because hooks intercept at the execution layer.
