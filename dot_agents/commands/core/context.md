# /context - Codebase Context Analysis

Analyze the relevant code area before implementation.

## Usage

```text
/context
/context <path>
```

## Steps

1. Identify target files and boundaries.
2. Capture dependencies and calling paths.
3. Note conventions that must be preserved.
4. Run classification-first routing (`/route`) before proposing implementation.
5. If category is `C2` or governed `C3`, suggest the next OpenSpec step and ask for explicit yes/no confirmation before execution.

## Output

- A concise map of key files, dependencies, and constraints.
- Include an `Intake Card` if implementation is requested.
