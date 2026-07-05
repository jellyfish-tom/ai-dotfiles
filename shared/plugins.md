# VS Code extensions and agent tooling

VS Code does not use editor-specific marketplace bundles for this setup. The closest equivalents are:

- regular VS Code extensions
- MCP servers installed from the MCP gallery or declared in `mcp.json`
- Copilot customizations in `.github/` and your user prompts folder

## Recommended replacements

### Workflow and planning

| Purpose                            | Recommended VS Code replacement                                            |
| ---------------------------------- | -------------------------------------------------------------------------- |
| planning, TDD, debugging workflows | repo `.github/skills/`, project `.github/prompts/`, and Copilot agent mode |
| consistent coding rules            | `.github/instructions/` and `user/instructions/`                           |
| reusable guided prompts            | `.github/prompts/*.prompt.md`                                              |

### Git, PR, and review tooling

| Purpose                           | Recommended VS Code replacement                                        |
| --------------------------------- | ---------------------------------------------------------------------- |
| git history and blame             | `eamodio.gitlens`                                                      |
| GitHub PR and workflow visibility | `github.vscode-github-actions`, built-in GitHub integrations, `gh` CLI |
| CI and review workflows           | prompt templates plus Copilot instructions                             |

### Browser automation

| Purpose                          | Recommended VS Code replacement                      |
| -------------------------------- | ---------------------------------------------------- |
| local browser automation in chat | Playwright MCP in `mcp.json` or from the MCP gallery |
| UI testing in the editor         | `ms-playwright.playwright`                           |
| browser-driven QA workflows      | `.github/skills/webapp-testing/SKILL.md`, `.github/agents/browser-verify.agent.md` |

## Optional MCP additions

The default `mcp.json.example` includes Figma, codegraph, and agentmemory. Common additions in VS Code are:

| MCP block           | Purpose                         | When to add                                                        |
| ------------------- | ------------------------------- | ------------------------------------------------------------------ |
| `obsidian`          | Vault read/write via MCP        | when using hybrid repo + Obsidian knowledge base                   |
| Atlassian Cloud MCP | Cloud Jira or Confluence access | when you use Atlassian Cloud instead of Jira Server or Data Center |
| Playwright          | browser automation              | when you want browser tools available in chat                      |

## Installation flow

1. Install regular VS Code extensions from `extensions.txt`.
2. Configure user or workspace MCP servers in `mcp.json`.
3. Copy the repo or project `.github` customizations into the target repo.
4. Open chat and use the prompts or skills exposed by those customizations.

## Verify installation

1. Open the Extensions view and confirm your recommended extensions are installed.
2. Run `MCP: List Servers` and confirm your configured servers are available.
3. Open a repository with `.github` customizations and confirm prompts, instructions, or skills are discovered.

## See also

- [README.md](../README.md)
- [extensions.txt](../extensions.txt)
- [mcp.json.example](../mcp.json.example)
