# /opsx:ff - OpenSpec Fast-Forward

Fast-forward artifact progression for an OpenSpec change when decisions are already clear.

## Usage

```text
/opsx:ff <change-name>
```

## Steps

1. Check status and blockers (this determines which artifacts are ready):
   - `openspec status --change <change-name> --json`
2. For each artifact that is `ready` in status, fetch its instructions explicitly (valid ids: `proposal`, `design`, `specs`, `tasks`):
   - `openspec instructions <artifact-id> --change <change-name> --json`
3. Complete remaining artifacts directly.
4. Suggest `/opsx:apply` as the next step and ask explicit yes/no before execution.
