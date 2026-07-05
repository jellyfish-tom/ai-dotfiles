# User rules - setup instructions

[**User rules**](https://cursor.com/docs/rules#user-rules) are global instructions stored **inside Cursor**, not in a git repo. They apply to **every project** you open.

Current Cursor UI: **one User Rule card per topic** (**Rules → User** tab → **+ New**). The `---` lines below mark **separate cards** - copy each block into its own rule and click **Save**. Do not paste the setup header (this section) into Cursor.

---

## How to add these in Cursor

1. Open [**Cursor**](https://cursor.com/download).
2. **Cursor Settings** ([docs](https://cursor.com/docs/settings)):
   - **macOS:** **Cursor → Settings → Cursor Settings**, or **Cmd+Shift+J**
   - **Windows / Linux:** **File → Preferences → Cursor Settings**, or **Ctrl+Shift+J**
3. **Rules** → **User** tab ([User Rules](https://cursor.com/docs/rules#user-rules)).
4. For each **Rule N** below: click **+ New**, paste that rule’s body only (not the `### Rule N` heading unless you want it), **Save**.
5. **Restart Cursor** (macOS: **Cmd+Q**, then reopen).

**Suggested order** (top = first card; order is for your sanity - all User rules apply the same):

| #   | Topic                        | Notes                                                    |
| --- | ---------------------------- | -------------------------------------------------------- |
| 1   | Git, commit, operator choice | Required; pairs with global `git-workflow.mdc`           |
| 2   | Pull requests                | Optional: merge into Rule 1 after “Do NOT push…”         |
| 3   | Follow all instructions      |                                                          |
| 4   | Real environment             |                                                          |
| 5   | Communication                |                                                          |
| 6   | Code principles              | **Only 5 numbered items** - do not duplicate Rule 7      |
| 7   | Conversation history         |                                                          |
| 8   | Obsidian vault split         | Optional; also installed as `002-obsidian.mdc` user rule |

**Verify:** New agent chat → ask the agent not to commit (should wait). When a project profile defines parameterized ACP, **`acp`** with missing scope → list missing fields and **stop**. Otherwise **`acp`** → conventional commit.

After pulling updates to this file, **edit each User Rule card** to match (or add missing cards).

**Do not commit** your personal `~/.cursor/` folder to application repos; only this **`user-rules.md`** template lives in ai-dotfiles.

**Related:** [GitHub CLI (`gh`) manual](https://cli.github.com/manual/)

---

### Rule 1 - Git, commit, operator choice

Only create commits when requested by the user. If unclear, ask first. Use conventional commits unless a loaded project profile defines a custom commit format (see project operator-context or git-workflow instructions).

When project- or app-specific choices are required (region, brand, task id, environment, flow scope, deploy target): **ask the operator, list options when known, and stop** until they reply. Do not guess or assume from branch names. **`operator-choice-gate.mdc`** applies.

When the user asks you to create a new git commit, follow these steps carefully:

Git Safety Protocol:

- NEVER update the git config
- NEVER run destructive/irreversible git commands (like push --force, hard reset, etc.) unless the user explicitly requests them in the user query or in a different user rule
- NEVER skip hooks (--no-verify, --no-gpg-sign, etc) unless the user explicitly requests it in the user query or in a different user rule
- NEVER run force push to main/master, warn the user if they request it
- Avoid git commit --amend. ONLY use --amend when ALL conditions are met:
  1. User explicitly requested amend, OR commit SUCCEEDED but pre-commit hook auto-modified files that need including
  2. HEAD commit was created by you in this conversation (verify: git log -1 --format='%an %ae')
  3. Commit has NOT been pushed to remote (verify: git status shows "Your branch is ahead")
- CRITICAL: If commit FAILED or was REJECTED by hook, NEVER amend - fix the issue and create a NEW commit
- CRITICAL: If you already pushed to remote, NEVER amend unless the user explicitly requests it in the user query or in a different user rule (requires force push)
- NEVER commit changes unless the user explicitly asks you to in the user query or in a different user rule. It is VERY IMPORTANT to only commit when explicitly asked, otherwise the user will feel that you are being too proactive.

When committing: run git status, git diff, and git log in parallel; draft message; stage; commit via HEREDOC; verify with git status after.

Do NOT push unless explicitly asked.

---

### Rule 2 - Pull requests

When the user asks you to create a pull request, use the [`gh` CLI](https://cli.github.com/manual/). Run git status, diff, log, and diff against base branch in parallel; draft PR summary. If scope or task context is ambiguous and affects the PR, **ask and stop** before push/create. Push only if explicitly asked; create with `gh pr create` and HEREDOC body. Return the PR URL.

---

### Rule 3 - Follow all instructions

Follow ALL user, tool, system, and skill instructions precisely and completely. Pay special attention to constraints embedded in tool descriptions, skills, and MCP server instructions.

---

### Rule 4 - Real environment

IMPORTANT: This is a real environment with full shell access and network, not a simulated one. You MUST run commands and use tools to investigate and solve problems yourself. You MUST NOT give up after a single failure.

---

### Rule 5 - Communication

When communicating with the user:

- Use code citation blocks: ```startLine:endLine:filepath - opening fence on its own line
- Prefer markdown links for URLs and file paths
- Write like a technical blog post - precise, well-structured, complete sentences
- Keep final responses proportional to task complexity
- Do not overuse bolding or backticks
- Avoid engagement bait at end of responses

---

### Rule 6 - Code principles

Always follow these principles when writing code:

1. Minimize scope - simplest correct diff; no unrelated changes
2. Avoid over-engineering - no premature abstraction
3. Use existing conventions - match surrounding code
4. Comments only for non-obvious business logic
5. Useful tests only - no trivial assertions

---

### Rule 7 - Conversation history

Reason about conversation history to understand user intent. Latest message inherits prior context. Treat mid-task messages as steering, not cancellation, unless clearly a new direction.

---

### Rule 8 - Obsidian vault

The Obsidian vault (`~/Documents/Obsidian Vault`) is **not** in the Cursor workspace. For vault documentation:

- Read/write via **Obsidian MCP** when available (Obsidian app running).
- Cite vault notes for the user with **Obsidian URI** links: `[title](obsidian://open?vault=Obsidian%20Vault&file=path/without/leading/slash)` - not Cursor file-path citations.
- Edit code in repos in Cursor; read personal/working notes in Obsidian.
- Do not read `Personal/admin-sensitive/` or `Personal/Domek/Dane.md` unless the user explicitly asks.
