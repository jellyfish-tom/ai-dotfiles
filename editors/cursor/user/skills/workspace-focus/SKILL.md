---
name: workspace-focus
description: Dynamically updates .cursorignore to block all monorepo apps/packages except the specific microservice the user is working on. Use when the user asks to focus on a specific app, isolate context, or block other microservices.
---

# Workspace Focus (Dynamic .cursorignore)

## Quick Start
When the user wants to isolate their workspace to a specific microservice/app in a monorepo, use this skill to dynamically append a whitelist to `.cursorignore`.

### Step 1: Ask for the target paths
Ask the user: "Which app(s) or package(s) do you want to focus on? (e.g., `apps/web`, `packages/ui`)"

### Step 2: Apply the Focus Block
Use the `Shell` tool to append the exact whitelist syntax to the project's `.cursorignore`. 

**Example Shell Command (Focusing on `apps/web` and `packages/ui`):**
```bash
cat << 'EOF' >> .cursorignore

# --- FOCUS MODE START ---
/*
!/apps/
/apps/*
!/apps/web/
!/packages/
/packages/*
!/packages/ui/
!/.cursor/
!/.cursorignore
!/.gitignore
!/package.json
# --- FOCUS MODE END ---
EOF
```

### Step 3: Unfocus (Reset)
If the user asks to "unfocus", "reset", or "show all files", remove the Focus Mode block from `.cursorignore`:
```bash
sed -i '' '/# --- FOCUS MODE START ---/,/# --- FOCUS MODE END ---/d' .cursorignore
```
