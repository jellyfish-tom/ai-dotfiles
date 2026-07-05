---
description: Use CodeGraph MCP for structural codebase questions such as symbol lookup, callers, callees, impact, and focused architecture context.
applyTo: '**'
---

# CodeGraph

This project has a CodeGraph MCP server (`codegraph_*` tools) configured. CodeGraph is a tree-sitter-parsed knowledge graph of every symbol, edge, and file. Reads are sub-millisecond and return structural information that grep cannot.

## When to prefer CodeGraph over native search

Use CodeGraph for structural questions such as what calls what, what would break, where a symbol is defined, or what a symbol signature looks like. Use native grep/read only for literal text queries such as strings, comments, or log messages, or after you already have a specific file open.

| Question                                      | Tool                |
| --------------------------------------------- | ------------------- |
| "Where is X defined?" / "Find symbol named X" | `codegraph_search`  |
| "What calls function Y?"                      | `codegraph_callers` |
| "What does Y call?"                           | `codegraph_callees` |
| "What would break if I changed Z?"            | `codegraph_impact`  |
| "Show me Y's signature / source / docstring"  | `codegraph_node`    |
| "Give me focused context for a task or area"  | `codegraph_context` |
| "See several related symbols' source at once" | `codegraph_explore` |
| "What files exist under path/"                | `codegraph_files`   |
| "Is the index healthy?"                       | `codegraph_status`  |

## Rules of thumb

- Answer directly instead of delegating exploration when the task is primarily about structure or architecture.
- Trust CodeGraph results and avoid re-verifying them with grep unless you need a literal text detail.
- Do not grep first when looking up a symbol by name. `codegraph_search` is faster and returns kind, location, and signature in one call.
- Do not chain `codegraph_search` and `codegraph_node` when you just want context. `codegraph_context` is usually the better first call.
- Do not loop `codegraph_node` over many symbols. Use one `codegraph_explore` call when you need several related sources.
- The index lags file writes slightly, so avoid querying CodeGraph immediately after editing a file in the same turn.

## If `.codegraph/` does not exist

If the MCP server reports that CodeGraph is not initialized, ask the user whether they want the index created before continuing with structural exploration.
