# /route - Workflow Classification Router

Classify requests with deterministic `C1/C2/C3/C4` routing before implementation.

## Usage

```text
/route
/route <task or intent>
```

## Intake Inputs

Score each dimension from `0..2`:

- `N` (Novelty)
- `A` (Ambiguity)
- `I` (Impact)
- `R` (Risk)

Derived values:

- `DiscoveryScore = N + A`
- `ControlScore = I + R`

## Routing Rules (ordered)

1. Read-only request (no file edits) -> `C1`
2. Request explicitly calls for new development, major feature, or major refactor -> `C4`
3. Request implies greenfield / start-from-scratch / new-system / major-rewrite intent -> `C4`
4. Else `DiscoveryScore >= 3` or `N = 2` or `A = 2` -> `C4`
5. Else `I = 2` and `R = 2` -> `C4`
6. Else `ControlScore >= 3` or `I = 2` or `R = 2` -> `C3`
7. Else -> `C2`

## Execution Mode

- `C1`: advisory-only; no implementation.
- `C2`: direct implementation for small deterministic change.
- `C3`: OpenSpec-governed implementation for medium change.
- `C4`: mandatory Spec-Kit gate workflow, then OpenSpec-governed implementation.
- If category is `C3` or `C4`, switch to `Governed` mode and enter OpenSpec gate before coding.
- If category is `C4`, Spec-Kit gate must pass before any write action.

## Route Split (C3 vs C4)

### C3 Mandatory OpenSpec Gate

For `C3`, enforce:

- First executable command MUST be:
  - Claude Code: `/opsx:new <change-name>`
  - Codex/OpenCode: `/opsx-new <change-name>`
- CLI fallback: `openspec new change <change-name>`
- If wrappers are missing/outdated, run `openspec update` (or `openspec init --tools <tool>` if not initialized)

### C4 Mandatory Spec-Kit Gate (Balanced)

For `C4`, enforce:

- First executable command MUST be:
  - Claude Code: `specify init --here --ai claude --script sh`
  - Codex CLI: `specify init --here --ai codex --script sh`
  - OpenCode: `specify init --here --ai opencode --script sh`
- Before gate passes, ONLY read-only commands are allowed: `ls`, `rg`, `cat`, `git status`
- Before gate passes, MUST NOT run: `openspec init`, file edits, source scaffolding, or implementation commands

Gate pass condition:

- Spec-Kit artifacts exist in target project (`.specify/` or `specs/`)
- Intake Card includes `Spec-Kit Gate: passed`

If gate is not passed:

- STOP and ask explicit yes/no for the single current-tool command above
- Do not provide alternative implementation paths
- Use `Spec-Kit Gate: waived` only when user explicitly asks to skip, and include `Waive Reason: <one sentence>`

After gate passes:

- Continue Spec-Kit discovery, then enter the same OpenSpec lifecycle as `C3` (wrapper or CLI fallback)

## Required Output Contract

```markdown
## Intake Card

- Category: C1 | C2 | C3 | C4
- Scores: N/A/I/R = x/x/x/x
- DiscoveryScore: x
- ControlScore: x
- Execution Mode: Direct | Governed
- Spec-Kit Gate: n/a | required | passed | waived
- Route Reason: <one sentence>
- Next Step: <single command>
```

If Codex prompt discovery is missing after init, use a project-scoped fallback:

```bash
export CODEX_HOME="$PWD/.codex"
```
