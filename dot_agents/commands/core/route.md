# /route - Workflow Classification Router

Classify requests with deterministic `C0/C1/C2/C3` routing before implementation.

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

1. Read-only request (no file edits) -> `C0`
2. `DiscoveryScore >= 3` or `N = 2` or `A = 2` -> `C3`
3. Else `ControlScore >= 3` or `I = 2` or `R = 2` -> `C2`
4. Else -> `C1`

## Execution Mode

- `C0`: advisory-only; no implementation.
- `C1`: direct implementation.
- `C2`: OpenSpec-governed implementation.
- `C3`: Spec-Kit initiative workflow.
  - If `C3` and (`I = 2` or `R = 2`), switch to `Governed` mode and enter OpenSpec gate before coding.

## Required Output Contract

```markdown
## Intake Card

- Category: C0 | C1 | C2 | C3
- Scores: N/A/I/R = x/x/x/x
- DiscoveryScore: x
- ControlScore: x
- Execution Mode: Direct | Governed
- Route Reason: <one sentence>
- Next Step: <single command>
```

## C3 Bootstrap Commands

- Claude Code: `specify init --here --ai claude --script sh`
- Codex CLI: `specify init --here --ai codex --script sh`
- OpenCode: `specify init --here --ai opencode --script sh`

If Codex prompt discovery is missing after init, use a project-scoped fallback:

```bash
export CODEX_HOME="$PWD/.codex"
```
