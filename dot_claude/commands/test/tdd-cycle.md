# /tdd-cycle - Test-Driven Development

Implement features using TDD: Red → Green → Refactor with multi-layer validation.

## Multi-Layer Test Pyramid

```
         ╱╲
        ╱  ╲  L3: E2E Tests (few, slow)
       ╱────╲     Complete user journeys
      ╱      ╲
     ╱   L2   ╲   Integration Tests (some)
    ╱──────────╲      Component interactions
   ╱            ╲
  ╱     L1       ╲    Unit Tests (many, fast)
 ╱────────────────╲       Isolated logic
╱       L0         ╲  Static Analysis (instant)
╲══════════════════╱      Linting, types
```

| Layer  | Speed   | Scope        | When to Run   |
| ------ | ------- | ------------ | ------------- |
| **L0** | Instant | Syntax/Types | Every save    |
| **L1** | Fast    | Single unit  | Every change  |
| **L2** | Medium  | Integration  | Before commit |
| **L3** | Slow    | Full system  | Before merge  |

## TDD Workflow

### Phase 1: Red (Write Failing Test)

Write a test for the desired behavior BEFORE implementation.

```python
# tests/test_user.py
def test_user_can_change_email():
    # Arrange
    user = User(email="old@example.com")

    # Act
    user.change_email("new@example.com")

    # Assert
    assert user.email == "new@example.com"
```

Run test to confirm it fails:

```bash
uv run pytest tests/test_user.py::test_user_can_change_email -v
```

Expected: Test should fail (feature doesn't exist yet)

### Phase 2: Green (Make Test Pass)

Write the MINIMAL code to make the test pass.

```python
# src/user.py
class User:
    def __init__(self, email: str):
        self.email = email

    def change_email(self, new_email: str) -> None:
        self.email = new_email  # Simplest implementation
```

Run test again:

```bash
uv run pytest tests/test_user.py::test_user_can_change_email -v
```

Expected: Test should pass

### Phase 3: Refactor (Improve Code)

Now improve the code while keeping tests green.

```python
# Add validation, but tests still pass
def change_email(self, new_email: str) -> None:
    if not self._is_valid_email(new_email):
        raise ValueError("Invalid email format")
    self.email = new_email
```

Add test for new behavior:

```python
def test_user_rejects_invalid_email():
    user = User(email="valid@example.com")
    with pytest.raises(ValueError):
        user.change_email("not-an-email")
```

### Phase 4: Layer Validation

After Red-Green-Refactor, validate all layers:

```bash
# L0: Static Analysis (must pass)
ruff check . && ruff format --check .

# L1: Unit Tests (must pass)
uv run pytest tests/unit/ -v

# L2: Integration Tests (should pass)
uv run pytest tests/integration/ -v

# L3: E2E (before merge)
uv run pytest tests/e2e/ -v
```

## Cycle Rules

1. **Never write production code without a failing test**
2. **Write only enough test to fail** (compilation failures count)
3. **Write only enough code to pass the test**
4. **Refactor only when tests are green**
5. **Validate L0 continuously, L1 frequently, L2/L3 at checkpoints**

## Test Structure: Arrange-Act-Assert

```python
def test_something():
    # Arrange: Set up test data and conditions
    user = User(name="Test")

    # Act: Perform the action being tested
    result = user.greet()

    # Assert: Verify the expected outcome
    assert result == "Hello, Test!"
```

## Test Patterns by Layer

### L1: Unit Tests

```python
# Test isolated logic
def test_calculate_discount():
    assert calculate_discount(100, 0.1) == 90

# Test edge cases
def test_calculate_discount_zero():
    assert calculate_discount(100, 0) == 100

# Test error handling
def test_calculate_discount_invalid():
    with pytest.raises(ValueError):
        calculate_discount(-100, 0.1)
```

### L2: Integration Tests

```python
# Test component interaction
async def test_user_service_creates_user(db_session):
    service = UserService(db_session)
    user = await service.create_user("test@example.com")
    assert user.id is not None
    assert await db_session.get(User, user.id) is not None
```

### L3: E2E Tests

```python
# Test complete user journey
def test_user_registration_flow(browser):
    browser.goto("/register")
    browser.fill("[name=email]", "new@example.com")
    browser.fill("[name=password]", "secure123")
    browser.click("button[type=submit]")
    assert browser.url == "/dashboard"
```

## Quick Commands

```bash
# Run specific test
uv run pytest tests/test_file.py::test_name -v

# Run with coverage
uv run pytest --cov=src tests/

# Run tests matching pattern
uv run pytest -k "user" -v

# Run last failed tests
uv run pytest --lf

# Run by layer
uv run pytest tests/unit/ -v          # L1
uv run pytest tests/integration/ -v   # L2
uv run pytest tests/e2e/ -v           # L3

# Run fast tests only
uv run pytest -m "not slow" -v

# Watch mode (requires pytest-watch)
uv run ptw -- tests/
```

## When to TDD

**Good fit:**

- New features with clear requirements
- Bug fixes (write test that exposes bug first)
- Complex logic that needs verification
- API design (tests clarify interface)

**Less suitable:**

- Exploratory/prototype code
- UI/visual changes
- Integration with external systems (use L2/L3 tests)

## Related

- `/test` - Run tests with coverage analysis
- `@test-fix` - Multi-layer test execution and fixing agent
