# /context - Codebase Context Analysis

Analyze the relevant code area before implementation.

## Usage

```text
/context
/context <path>
```

## Steps

1. Identify target files and boundaries.
2. Capture dependencies and calling paths.
3. Note conventions that must be preserved.

## Tri-MCP Routing Policy

When additional retrieval is needed during context analysis, use this priority map:

| Task Type                                  | Primary MCP | Fallback                         |
| ------------------------------------------ | ----------- | -------------------------------- |
| Library/framework/API docs                 | Context7    | Tavily, then built-in web search |
| General web/news/background                | Tavily      | Built-in web search              |
| Symbolic code navigation/refactor planning | Serena      | repo grep/codesearch + LSP       |

Notes:

- Prefer deterministic routing over ad-hoc tool switching.
- Keep queries minimal and avoid sensitive data.
- Runtime prerequisites are `node` + `uv` managed via `mise`.

## Output

- A concise map of key files, dependencies, and constraints.
