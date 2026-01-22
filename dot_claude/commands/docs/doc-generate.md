# /doc-generate - Documentation Generation

Generate or update documentation for code.

## Usage

```
/doc-generate [FILE or DIRECTORY]
```

## Documentation Types

### API Documentation

For modules, classes, and functions:

```python
def process_user(user_id: int, options: dict | None = None) -> User:
    """Process and return user with applied options.

    Args:
        user_id: The unique identifier of the user.
        options: Optional processing options.
            - validate: Whether to validate user data (default: True)
            - enrich: Whether to enrich with external data (default: False)

    Returns:
        Processed User object with updated fields.

    Raises:
        UserNotFoundError: If user_id doesn't exist.
        ValidationError: If user data is invalid.

    Example:
        >>> user = process_user(123, {"validate": True})
        >>> print(user.status)
        'processed'
    """
```

### README Generation

For a project or module:

````markdown
# Project Name

Brief description of what this does.

## Installation

```bash
uv add project-name
```
````

## Quick Start

```python
from project import main_function
result = main_function()
```

## Features

- Feature 1
- Feature 2

## Configuration

| Option | Type | Default   | Description |
| ------ | ---- | --------- | ----------- |
| opt1   | str  | "default" | Description |

## License

MIT

````

### CLI Documentation
For command-line tools:

```markdown
## Usage

```bash
tool-name [OPTIONS] COMMAND [ARGS]
````

## Commands

### `init`

Initialize a new project.

```bash
tool-name init [--template NAME]
```

**Options:**

- `--template, -t`: Template to use (default: "basic")

### `run`

Run the main process.

```bash
tool-name run [--config PATH]
```

```

## Workflow

### Step 1: Analyze Code
- Identify public API (exported functions, classes)
- Find undocumented or poorly documented items
- Check existing documentation for accuracy

### Step 2: Generate Documentation
For each undocumented item:
1. Analyze function signature and body
2. Identify parameters, return types, exceptions
3. Write clear, concise docstring
4. Add usage example if complex

### Step 3: Validate
- Ensure documentation matches code
- Check for broken links or references
- Verify examples are runnable

## Principles
- Document **why**, not just **what**
- Keep examples minimal but complete
- Update docs when code changes
- Don't document obvious things
```
