# /opsx:verify - OpenSpec Verify

Run verification gates for an OpenSpec change.

## Usage

```text
/opsx:verify <change-name>
```

## Steps

1. Validate artifacts (CLI flags may drift; prefer the stable wrapper):
   - `just openspec-validate`
2. Check change status:
   - `openspec status --change <change-name> --json`
3. Run `superpowers:verification-before-completion` before finalization.
4. If all checks pass, suggest `/opsx:archive <change-name>` and ask explicit yes/no before execution.

## Notes

- Do not assume `openspec validate --change ...` exists; some versions use `--changes` (plural) instead.
- Keep validation behind `just openspec-validate` so we can centralize compatibility logic.

## Failure Handling

- If verification fails, use `superpowers:systematic-debugging`, fix issues, and rerun `/opsx:verify`.
- Archive remains blocked until verification is green.
