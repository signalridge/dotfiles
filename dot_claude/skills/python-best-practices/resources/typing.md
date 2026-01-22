# Advanced Python Typing

## Modern Type Syntax (Python 3.10+)

```python
# Union types with |
def process(value: str | int | None) -> str:
    ...

# Optional is just X | None
def get_user(id: int) -> User | None:
    ...
```

## Generic Types

```python
from typing import TypeVar, Generic

T = TypeVar('T')

class Container(Generic[T]):
    def __init__(self, value: T) -> None:
        self.value = value

    def get(self) -> T:
        return self.value
```

## TypedDict

```python
from typing import TypedDict

class UserDict(TypedDict):
    id: int
    name: str
    email: str | None
```

## Protocol (Structural Typing)

```python
from typing import Protocol

class Drawable(Protocol):
    def draw(self) -> None: ...

# Any class with draw() method satisfies Drawable
class Circle:
    def draw(self) -> None:
        print("Drawing circle")

def render(item: Drawable) -> None:
    item.draw()
```

## Callable

```python
from typing import Callable

# Function that takes int, returns str
Processor = Callable[[int], str]

def apply(fn: Processor, value: int) -> str:
    return fn(value)
```

## Type Aliases

```python
from typing import TypeAlias

UserId: TypeAlias = int
UserData: TypeAlias = dict[str, str | int | None]
Handler: TypeAlias = Callable[[Request], Response]
```
