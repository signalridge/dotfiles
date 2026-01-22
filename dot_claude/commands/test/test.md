# /test - TDD Workflow

Test-Driven Development workflow: Red → Green → Refactor.

## TDD Cycle

### 1. Red: Write a Failing Test

- Write the test FIRST, before implementation
- Test should fail for the right reason
- Test should be minimal and focused

### 2. Green: Make It Pass

- Write the MINIMUM code to pass the test
- Don't over-engineer at this stage
- It's okay if the code is ugly

### 3. Refactor: Improve the Code

- Clean up while keeping tests green
- Remove duplication
- Improve naming and structure

## Usage

```
/test add <feature description>    # Write test for new feature
/test fix <bug description>        # Write regression test for bug
/test coverage                     # Analyze test coverage
/test run [path]                   # Run tests
```

## Test Structure (Language-Agnostic)

```
describe "FeatureName"
  test "happy path should work correctly"
    result = function_under_test(valid_input)
    assert result == expected_output

  test "edge case: empty input returns empty result"
    result = function_under_test([])
    assert result == []

  test "edge case: invalid input raises error"
    expect_error(ValueError)
      function_under_test(None)

  test "error handling is graceful"
    result = function_under_test(invalid_input)
    assert result.is_error
```

## Running Tests by Language

| Language      | Command         | Coverage          |
| ------------- | --------------- | ----------------- |
| Python        | `uv run pytest` | `--cov=src`       |
| TypeScript/JS | `npm test`      | `--coverage`      |
| Go            | `go test ./...` | `-cover`          |
| Rust          | `cargo test`    | `cargo tarpaulin` |

## Test Naming Convention

```
test_<what>_<condition>_<expected>

Examples:
- test_login_valid_credentials_succeeds
- test_login_invalid_password_raises_error
- test_calculate_empty_list_returns_zero
```

## Best Practices

### Do

- Test behavior, not implementation
- One assertion per test (when possible)
- Use descriptive test names
- Test edge cases
- Keep tests independent

### Don't

- Test private methods directly
- Use sleep/time delays
- Test external services (mock them)
- Share state between tests
- Write tests after the fact (if possible)

## Mocking Principles

- Mock external dependencies (APIs, databases, file systems)
- Don't mock the unit under test
- Prefer dependency injection over patching
- Keep mocks simple and focused

## Coverage Goals

| Type           | Target |
| -------------- | ------ |
| Unit tests     | 80%+   |
| Critical paths | 100%   |
| Error handling | 100%   |
| Happy paths    | 100%   |
