---
description: Use this skill to analyze a codebase and automatically generate a custom ai-dotfiles profile based on detected technologies and standards.
---

# Profile Generator Skill

## Objective
Analyze the current repository to identify its tech stack, tools, and engineering standards, then create a new `ai-dotfiles` profile tailored to this environment.

## Step 1: Codebase Introspection
Use `codegraph_files` and `codegraph_search` to identify:
- **Language/Runtime**: (e.g., TypeScript, Python, Go, Rust)
- **Frameworks**: (e.g., Next.js, FastAPI, Spring Boot, React)
- **Package Managers**: (e.g., npm, poetry, cargo)
- **Testing Frameworks**: (e.g., Jest, Pytest, Vitest)
- **Linting/Formatting**: (e.g., ESLint, Prettier, Ruff)
- **CI/CD**: (e.g., GitHub Actions, GitLab CI)

## Step 2: Standards Detection
Identify project-specific standards by reading key configuration files:
- Check `package.json`, `tsconfig.json`, `pyproject.toml`, etc.
- Look for existing `.cursorrules` or `.mdc` files to incorporate.
- Analyze commit history to determine if "Conventional Commits" are used.

## Step 3: Profile Scaffolding
Once the stack is identified, determine the `ai-dotfiles` root path (check the `AI_DOTFILES` environment variable or ask the user) and create a new directory: `profiles/<project-name>/`.

1.  **Generate `AGENTS.md`**: Define the workflow map based on detected tools (e.g., if Jira is mentioned in commits, add the Jira agent).
2.  **Scaffold Instructions**: 
    - Create `.github/instructions/` with tech-stack specific rules.
    - Create `.cursor/rules/` with corresponding `.mdc` files.
3.  **Cross-Editor Parity**: Ensure every Cursor rule has a matching entry in the VS Code instructions to maintain parity.

## Step 4: Rule Recommendations
If the tech stack matches a known "Mega-Collection" pattern (e.g., Next.js 15), suggest or automatically fetch relevant rules from recommended libraries like `PatrickJS/awesome-cursorrules`.

## Execution Rule
- **DO NOT** overwrite existing profiles without confirmation.
- **ALWAYS** summarize the detected stack and ask for the profile name before creating files.
- **STOP** and report if the codebase is too ambiguous to categorize.

## Example Trigger
User: "Analyze this project and create an ai-dotfiles profile for it."
Agent: "I've analyzed the repo using CodeGraph. I detected a Next.js 15 app using Tailwind and Prisma. I will now scaffold a profile named 'nextjs-prisma-pro' with relevant rules. Proceed?"
---
