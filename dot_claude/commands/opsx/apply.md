# /opsx:apply - OpenSpec Apply

Apply implementation phase for an OpenSpec change.

## Usage

```text
/opsx:apply <change-name>
```

## Steps

1. Inspect current state:
   - `openspec status --change <change-name> --json`
2. Fetch apply-phase instructions:
   - `openspec instructions apply --change <change-name> --json`
3. Apply `superpowers:test-driven-development` during implementation.
4. Implement only scoped minimal changes from the change artifacts.
5. Re-check state:
   - `openspec status --change <change-name> --json`
6. Suggest `/opsx:verify <change-name>` and ask explicit yes/no before execution.

## Failure Handling

- If implementation or tests fail, use `superpowers:systematic-debugging` and retry.
