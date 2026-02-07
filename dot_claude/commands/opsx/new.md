# /opsx:new - OpenSpec New

Create a new OpenSpec change for L3/L4 work.

## Usage

```text
/opsx:new <change-name>
```

## Steps

1. If scope is unclear, run `superpowers:brainstorming` first.
2. Create change:
   - `openspec new change <change-name>`
3. Check readiness:
   - `openspec status --change <change-name> --json`
4. Suggest exactly one next step (`/opsx:continue` or `/opsx:ff`) and ask explicit yes/no before execution.
