# Python Testing Best Practices

## Pytest Basics

```python
import pytest

def test_simple():
    assert 1 + 1 == 2

def test_exception():
    with pytest.raises(ValueError):
        int("not a number")
```

## Fixtures

```python
@pytest.fixture
def sample_user():
    return User(id=1, name="Test", email="test@example.com")

@pytest.fixture
def db_session():
    session = create_session()
    yield session
    session.rollback()
    session.close()

def test_with_user(sample_user):
    assert sample_user.name == "Test"
```

## Parametrize

```python
@pytest.mark.parametrize("input,expected", [
    (1, 2),
    (2, 4),
    (3, 6),
])
def test_double(input, expected):
    assert double(input) == expected
```

## Mocking

```python
from unittest.mock import Mock, patch, MagicMock

def test_with_mock():
    mock_api = Mock()
    mock_api.get_user.return_value = {"id": 1, "name": "Test"}

    result = process_user(mock_api, 1)

    mock_api.get_user.assert_called_once_with(1)

@patch('mymodule.external_api')
def test_with_patch(mock_api):
    mock_api.fetch.return_value = {"data": "test"}
    result = my_function()
    assert result == expected
```

## Test Organization

```
tests/
├── conftest.py          # Shared fixtures
├── test_models.py       # Model tests
├── test_api.py          # API tests
└── integration/
    └── test_full_flow.py
```

## Running Tests

```bash
uv run pytest                      # All tests
uv run pytest tests/test_api.py    # Single file
uv run pytest -k "test_user"       # By name pattern
uv run pytest -v                   # Verbose
uv run pytest --cov=src            # Coverage
```
