# Python Best Practices

Guidelines for writing clean, maintainable Python code.

## Core Principles

1. **Use modern tooling**: uv for packages, ruff for formatting/linting
2. **Type everything**: Use type hints for all function signatures
3. **Test first**: Write tests before or alongside code
4. **Keep it simple**: Avoid premature optimization and over-engineering

## Package Management

Always use `uv` instead of `pip`:

```bash
# Create project
uv init myproject
cd myproject

# Add dependencies
uv add requests pydantic

# Add dev dependencies
uv add --dev pytest ruff

# Run commands
uv run python main.py
uv run pytest
```

## Code Style

### Formatting

```bash
# Format with ruff
ruff format .

# Lint and auto-fix
ruff check --fix .
```

### Type Hints

```python
# Good
def process_user(user_id: int, name: str) -> dict[str, Any]:
    ...

# Also good - use | for unions (Python 3.10+)
def get_value(key: str) -> str | None:
    ...

# For complex types
from typing import TypeAlias

UserDict: TypeAlias = dict[str, str | int | None]
```

### Docstrings

```python
def calculate_total(items: list[Item], discount: float = 0.0) -> Decimal:
    """Calculate the total price of items with optional discount.

    Args:
        items: List of items to calculate
        discount: Discount percentage (0.0 to 1.0)

    Returns:
        Total price after discount

    Raises:
        ValueError: If discount is not between 0 and 1
    """
    ...
```

## Project Structure

```
myproject/
├── pyproject.toml
├── src/
│   └── myproject/
│       ├── __init__.py
│       ├── main.py
│       └── utils.py
├── tests/
│   ├── __init__.py
│   └── test_main.py
└── .envrc
```

## Common Patterns

### Error Handling

```python
# Be specific with exceptions
try:
    result = api.fetch_data(user_id)
except ConnectionError:
    logger.warning("API unavailable, using cache")
    result = cache.get(user_id)
except ValueError as e:
    logger.error(f"Invalid user_id: {e}")
    raise

# Never bare except
# Bad: except:
# Good: except Exception:
```

### Context Managers

```python
# For resources
with open("file.txt") as f:
    content = f.read()

# Custom context manager
from contextlib import contextmanager

@contextmanager
def timer(name: str):
    start = time.time()
    yield
    print(f"{name}: {time.time() - start:.2f}s")
```

### Dataclasses

```python
from dataclasses import dataclass, field

@dataclass
class User:
    id: int
    name: str
    email: str
    roles: list[str] = field(default_factory=list)
    active: bool = True
```

## Anti-Patterns to Avoid

| Anti-Pattern         | Better Approach                  |
| -------------------- | -------------------------------- |
| Mutable default args | Use `None` and create inside     |
| Bare `except:`       | Catch specific exceptions        |
| `from x import *`    | Import specific names            |
| Magic numbers        | Use named constants              |
| Deep nesting         | Early returns, extract functions |

## Resources

- [resources/typing.md](resources/typing.md) - Advanced typing patterns
- [resources/testing.md](resources/testing.md) - Testing best practices
