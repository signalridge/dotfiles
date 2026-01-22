# Tech Stack Guidelines

Language-specific conventions and best practices for common tech stacks.

## Auto-Detection

```bash
# Detect tech stack from project files
detect_stack() {
    if [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        echo "python"
    elif [ -f "tsconfig.json" ]; then
        echo "typescript"
    elif [ -f "package.json" ] && grep -q '"type": "module"' package.json; then
        echo "javascript-esm"
    elif [ -f "package.json" ]; then
        echo "javascript"
    elif [ -f "go.mod" ]; then
        echo "go"
    elif [ -f "Cargo.toml" ]; then
        echo "rust"
    fi
}
```

---

## Python

### Environment

- Package manager: `uv` (never pip)
- Formatter: `ruff format`
- Linter: `ruff check --fix`
- Type checker: `mypy`
- Test runner: `pytest`

### Conventions

```python
# Modern syntax (3.10+)
def process(value: str | int | None) -> dict[str, Any]:
    """Brief description of what this does."""
    ...

# Prefer explicit imports
from collections.abc import Mapping  # not: from typing import Mapping

# Use pathlib for file operations
from pathlib import Path
config_path = Path.home() / ".config" / "app"

# Context managers for resources
with open(path) as f:
    content = f.read()

# Dataclasses for data containers
@dataclass
class Config:
    host: str
    port: int = 8080

# Explicit error handling
try:
    result = api.fetch(id)
except ConnectionError:
    logger.warning("API unavailable")
    result = cache.get(id)
```

### Project Structure

```
project/
├── src/
│   └── package_name/
│       ├── __init__.py
│       ├── main.py
│       └── utils.py
├── tests/
│   ├── unit/
│   └── integration/
├── pyproject.toml
└── README.md
```

---

## TypeScript

### Environment

- Package manager: `npm` or `pnpm`
- Formatter: `prettier`
- Linter: `eslint`
- Type checker: `tsc`
- Test runner: `vitest` or `jest`

### Conventions

```typescript
// Strict types, avoid any
interface UserConfig {
  host: string;
  port: number;
  options?: Record<string, unknown>;
}

// Prefer const and readonly
const config: Readonly<UserConfig> = {
  host: "localhost",
  port: 8080,
};

// Use type inference where obvious
const users = new Map<string, User>(); // explicit
const count = 0; // inferred as number

// Async/await over callbacks
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  if (!response.ok) {
    throw new Error(`Failed to fetch user: ${response.status}`);
  }
  return response.json();
}

// Nullish coalescing and optional chaining
const name = user?.profile?.name ?? "Anonymous";
```

### Project Structure

```
project/
├── src/
│   ├── components/
│   ├── services/
│   ├── types/
│   └── index.ts
├── tests/
├── tsconfig.json
├── package.json
└── README.md
```

---

## Go

### Environment

- Formatter: `gofmt`
- Linter: `golangci-lint`
- Test runner: `go test`

### Conventions

```go
// Error handling - always check errors
func ReadConfig(path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("read config: %w", err)
    }

    var config Config
    if err := json.Unmarshal(data, &config); err != nil {
        return nil, fmt.Errorf("parse config: %w", err)
    }

    return &config, nil
}

// Interfaces - accept interfaces, return structs
type Reader interface {
    Read(p []byte) (n int, err error)
}

func ProcessData(r Reader) error {
    // ...
}

// Table-driven tests
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive", 1, 2, 3},
        {"negative", -1, -2, -3},
        {"zero", 0, 0, 0},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            if got := Add(tt.a, tt.b); got != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d", tt.a, tt.b, got, tt.expected)
            }
        })
    }
}
```

### Project Structure

```
project/
├── cmd/
│   └── app/
│       └── main.go
├── internal/
│   ├── config/
│   └── service/
├── pkg/
│   └── utils/
├── go.mod
├── go.sum
└── README.md
```

---

## Rust

### Environment

- Package manager: `cargo`
- Formatter: `rustfmt`
- Linter: `clippy`
- Test runner: `cargo test`

### Conventions

```rust
// Use Result for fallible operations
fn read_config(path: &Path) -> Result<Config, ConfigError> {
    let content = fs::read_to_string(path)?;
    let config: Config = toml::from_str(&content)?;
    Ok(config)
}

// Prefer &str over String for function parameters
fn greet(name: &str) -> String {
    format!("Hello, {}!", name)
}

// Use iterators over loops
let sum: i32 = numbers.iter().filter(|n| **n > 0).sum();

// Derive traits when possible
#[derive(Debug, Clone, PartialEq)]
struct Point {
    x: f64,
    y: f64,
}

// Use type aliases for complex types
type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;
```

### Project Structure

```
project/
├── src/
│   ├── lib.rs
│   ├── main.rs
│   └── config.rs
├── tests/
│   └── integration_test.rs
├── Cargo.toml
└── README.md
```

---

## Common Patterns (All Languages)

### Error Handling

- Be specific with error types
- Wrap errors with context
- Log errors at the boundary
- Never silently swallow errors

### Testing

- Unit tests for logic
- Integration tests for boundaries
- Test error paths
- Use descriptive test names

### Naming

- Functions: verb phrases (`get_user`, `fetchData`)
- Classes/Types: noun phrases (`UserService`, `Config`)
- Booleans: question phrases (`is_valid`, `hasPermission`)
- Constants: SCREAMING_SNAKE_CASE
