# /opsx:archive - OpenSpec Archive

Archive a completed OpenSpec change after verification passes.

## Usage

```text
/opsx:archive <change-name>
```

## Execution Safety

- `archive` is a finalizing step and requires explicit yes/no confirmation.
- Never run as part of automatic chained execution.

## Steps

1. Confirm the latest `/opsx:verify` is green:
   - `openspec status --change <change-name> --json`
2. Ask explicit confirmation to archive.
3. Archive only after approval:
   - `openspec archive <change-name> --yes`
4. Confirm archived state:
   - `openspec status --change <change-name> --json`
