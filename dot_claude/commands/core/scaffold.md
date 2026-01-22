# /scaffold - Project Scaffolding

Create new project structures with best-practice templates.

## Available Templates

### Python (uv)

```
/scaffold python <name>
```

Creates:

```
<name>/
├── pyproject.toml      # uv project config
├── src/
│   └── <name>/
│       ├── __init__.py
│       └── main.py
├── tests/
│   ├── __init__.py
│   └── test_main.py
├── .envrc              # direnv (layout python)
├── .gitignore
├── .python-version
└── README.md
```

**pyproject.toml:**

```toml
[project]
name = "<name>"
version = "0.1.0"
description = ""
requires-python = ">=3.11"
dependencies = []

[project.optional-dependencies]
dev = ["pytest", "ruff"]

[tool.ruff]
line-length = 88
target-version = "py311"

[tool.pytest.ini_options]
testpaths = ["tests"]
```

### TypeScript (Node)

```
/scaffold ts <name>
```

Creates:

```
<name>/
├── package.json
├── tsconfig.json
├── src/
│   └── index.ts
├── tests/
│   └── index.test.ts
├── .envrc
├── .gitignore
└── README.md
```

### FastAPI

```
/scaffold fastapi <name>
```

Creates:

```
<name>/
├── pyproject.toml
├── src/
│   └── <name>/
│       ├── __init__.py
│       ├── main.py          # FastAPI app
│       ├── api/
│       │   ├── __init__.py
│       │   └── routes.py
│       ├── core/
│       │   ├── __init__.py
│       │   └── config.py
│       └── models/
│           └── __init__.py
├── tests/
│   └── test_api.py
├── .envrc
└── README.md
```

### CLI Tool (Python)

```
/scaffold cli <name>
```

Creates:

```
<name>/
├── pyproject.toml        # with [project.scripts]
├── src/
│   └── <name>/
│       ├── __init__.py
│       ├── cli.py        # Click/Typer CLI
│       └── main.py
├── tests/
└── README.md
```

### Nix Flake

```
/scaffold nix <name>
```

Creates:

```
<name>/
├── flake.nix
├── flake.lock
├── .envrc               # use flake
└── README.md
```

## vs Shell Functions

| Shell Function                        | /scaffold             |
| ------------------------------------- | --------------------- |
| `create_py_project` - minimal uv init | Full project template |
| `create_direnv_venv` - just .envrc    | Complete structure    |

**Use shell for:** Quick experiments, throwaway code
**Use /scaffold for:** Real projects, proper structure

## Post-Scaffold Steps

After scaffolding:

```bash
cd <name>
direnv allow           # Enable environment
uv sync               # Install dependencies (Python)
git init && git add . && git commit -m "chore: initial scaffold"
```

## Customization

Each template follows these conventions:

- Uses `src/` layout for Python packages
- Includes basic test structure
- Has `.envrc` for direnv integration
- Follows project naming conventions

For project-specific customization, create a `.claude/CLAUDE.md` in the new project.
