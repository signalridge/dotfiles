# /opsx:continue - OpenSpec Continue

Continue an existing OpenSpec change and fetch the _next ready artifact_ instructions.

## Usage

```text
/opsx:continue <change-name>
```

## Steps

1. Inspect current state (this determines the next artifact id):
   - `openspec status --change <change-name> --json`
2. Determine the next artifact id from status (valid ids: `proposal`, `design`, `specs`, `tasks`).
3. Fetch instructions for that specific artifact id:
   - `openspec instructions <artifact-id> --change <change-name> --json`

   Examples:
   - `openspec instructions proposal --change skills-collection --json`
   - `openspec instructions design --change skills-collection --json`

4. Update required artifacts directly based on OpenSpec instructions.
5. Suggest `/opsx:apply` as the next step and ask explicit yes/no before execution.
