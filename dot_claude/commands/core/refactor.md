# /refactor - Safe Refactoring

Refactor code while ensuring behavior remains unchanged.

## Refactoring Principles

1. **Tests First**: Ensure adequate test coverage before refactoring
2. **Small Steps**: One change at a time, verify after each
3. **No Behavior Change**: Refactoring ≠ Bug fixing ≠ Feature adding
4. **Continuous Verification**: Run tests frequently

## Workflow

### Pre-Refactoring Checklist

- [ ] Tests exist and pass
- [ ] Understand current behavior
- [ ] Identify the smell/problem
- [ ] Plan the refactoring steps

### During Refactoring

```
1. Make one small change
2. Run tests
3. Commit if green
4. Repeat
```

### Post-Refactoring

- [ ] All tests still pass
- [ ] Code is cleaner/simpler
- [ ] No regressions introduced

## Usage

```
/refactor extract <code description>    # Extract method/function
/refactor rename <old> to <new>         # Rename with all references
/refactor simplify <file or function>   # Simplify complex code
/refactor move <what> to <where>        # Move to better location
```

## Common Refactorings

### Extract Method/Function

**Before:**

```python
def process_order(order):
    # Calculate total
    total = 0
    for item in order.items:
        total += item.price * item.quantity
    total *= (1 - order.discount)

    # Send notification
    email = order.customer.email
    send_email(email, f"Order total: {total}")
```

**After:**

```python
def process_order(order):
    total = calculate_total(order)
    notify_customer(order.customer, total)

def calculate_total(order):
    subtotal = sum(item.price * item.quantity for item in order.items)
    return subtotal * (1 - order.discount)

def notify_customer(customer, total):
    send_email(customer.email, f"Order total: {total}")
```

### Simplify Conditionals

**Before:**

```python
if user is not None:
    if user.is_active:
        if user.has_permission('admin'):
            return True
return False
```

**After:**

```python
if user and user.is_active and user.has_permission('admin'):
    return True
return False

# Or even better:
return bool(user and user.is_active and user.has_permission('admin'))
```

### Replace Magic Numbers

**Before:**

```python
if response.status_code == 200:
    process_data(response.json())
elif response.status_code == 404:
    log_not_found()
```

**After:**

```python
from http import HTTPStatus

if response.status_code == HTTPStatus.OK:
    process_data(response.json())
elif response.status_code == HTTPStatus.NOT_FOUND:
    log_not_found()
```

## Code Smells to Address

| Smell                  | Refactoring                |
| ---------------------- | -------------------------- |
| Long method            | Extract Method             |
| Duplicate code         | Extract + Reuse            |
| Long parameter list    | Introduce Parameter Object |
| Feature envy           | Move Method                |
| Data clumps            | Extract Class              |
| Primitive obsession    | Replace with Object        |
| Switch statements      | Replace with Polymorphism  |
| Speculative generality | Remove unused abstraction  |

## Safety Tips

- Use IDE refactoring tools when available
- `git diff` after each step to review changes
- Commit frequently with clear messages
- Keep a TODO list of remaining refactorings
- Don't refactor and add features simultaneously
