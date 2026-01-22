# /context - Codebase Context Analysis

Analyze and understand project structure, dependencies, and architecture.

## Usage

```
/context                    # Full project overview
/context path/to/dir        # Analyze specific directory
/context --deps             # Focus on dependencies
/context --entry            # Find entry points
```

## Analysis Steps

### 1. Project Detection

Identify project type by checking for:

- `pyproject.toml` / `setup.py` → Python
- `package.json` → Node.js/JavaScript
- `Cargo.toml` → Rust
- `go.mod` → Go
- `flake.nix` → Nix

### 2. Structure Analysis

```bash
# Get directory structure
find . -type f -name "*.py" | head -20
tree -L 3 -I 'node_modules|.git|__pycache__|.venv'
```

### 3. Dependency Analysis

**Python:**

```bash
cat pyproject.toml | grep -A 50 '\[project\]'
uv tree  # if uv project
```

**Node.js:**

```bash
cat package.json | jq '.dependencies, .devDependencies'
```

### 4. Entry Points

Look for:

- `main.py`, `app.py`, `index.py`
- `src/main.py`, `src/index.ts`
- `[project.scripts]` in pyproject.toml
- `"main"` in package.json
- `if __name__ == "__main__":`

## Output Format

```markdown
## Project Overview: <name>

### Technology Stack

- **Language:** Python 3.12
- **Framework:** FastAPI
- **Package Manager:** uv
- **Testing:** pytest

### Directory Structure
```

src/
├── api/ # API routes and endpoints
├── core/ # Business logic
├── models/ # Data models
└── utils/ # Utilities

```

### Key Files
| File | Purpose |
|------|---------|
| `src/main.py` | Application entry point |
| `src/core/config.py` | Configuration management |
| `src/api/routes.py` | API route definitions |

### Dependencies
**Production:**
- fastapi
- uvicorn
- pydantic

**Development:**
- pytest
- ruff

### Entry Points
- CLI: `uv run python -m myapp`
- Web: `uvicorn src.main:app`

### Conventions
- Uses src layout
- Tests in `tests/` directory
- Config via environment variables
```

## When to Use

- **New to a project**: Get quick orientation
- **Before making changes**: Understand impact
- **Code review**: Understand project context
- **Documentation**: Generate project overview

## Tips

- Check for existing documentation first
- Look at recent commits for active areas
- Check CI/CD config for build/test commands
- Review `.claude/CLAUDE.md` for project-specific rules
