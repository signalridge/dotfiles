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
3. Else `DiscoveryScore >= 3` or `N = 2` or `A = 2` -> `C4`
4. Else `I = 2` and `R = 2` -> `C4`
5. Else `ControlScore >= 3` or `I = 2` or `R = 2` -> `C3`
6. Else -> `C2`

## Execution Mode

- `C1`: advisory-only; no implementation.
- `C2`: direct implementation for small deterministic change.
- `C3`: OpenSpec-governed implementation for medium change.
- `C4`: Spec-Kit initiative workflow, then OpenSpec-governed implementation.
- If category is `C3` or `C4`, switch to `Governed` mode and enter OpenSpec gate before coding.

## Required Output Contract

```markdown
## Intake Card

- Category: C1 | C2 | C3 | C4
- Scores: N/A/I/R = x/x/x/x
- DiscoveryScore: x
- ControlScore: x
- Execution Mode: Direct | Governed
- Route Reason: <one sentence>
- Next Step: <single command>
```

## C4 Bootstrap Commands

- Claude Code: `specify init --here --ai claude --script sh`
- Codex CLI: `specify init --here --ai codex --script sh`
- OpenCode: `specify init --here --ai opencode --script sh`

If Codex prompt discovery is missing after init, use a project-scoped fallback:

```bash
export CODEX_HOME="$PWD/.codex"
```
