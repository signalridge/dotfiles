# /route - Workflow Classification Router

Classify requests with deterministic `C1/C2/C3/C4` routing before implementation.

## Usage

```text
/route
/route <task or intent>
```

## Intake Inputs

Score each dimension from `0..4`:

- `N` (Novelty)
- `A` (Ambiguity)
- `I` (Impact)
- `R` (Risk)
- `V` (Reversibility cost)

Derived values:

- `DiscoveryScore = N + A`
- `ControlScore = I + R + V`

## Routing Rules (ordered)

1. Read-only request (no file edits) -> `C1`
2. If guardrail-sensitive or `Kind=G`, set floor category to `C3` and continue evaluating `C4` triggers.
3. If request explicitly calls for new project or major refactor -> `C4`.
4. If request implies greenfield / start-from-scratch / major-rewrite intent -> `C4`.
5. If `high_ambiguity` (`A >= 3` and `ControlScore >= 8`) -> `C4`.
6. Else if `ControlScore >= 8` (when `A < 3`), or (`A >= 3` and `DiscoveryScore >= 6`) -> `C3`.
7. Else if floor category is `C3` -> `C3`.
8. Else -> `C2`.

L4 precedence (when multiple triggers match): `major_refactor` > `new_project` > `high_ambiguity`.

## Execution Mode

- `C1`: advisory-only; no implementation.
- `C2`: direct implementation for deterministic change.
- `C3`: OpenSpec standard governed implementation (scan -> step-by-step -> validate -> archive).
- `C4`: OpenSpec discovery-first governed implementation (explore -> scope approval -> implement -> validate -> archive).
- If category is `C3` or `C4`, switch to `Governed` mode and enter OpenSpec gate before coding.

## OpenSpec Gate (C3/C4)

For `C3` and `C4`, enforce:

- First executable command MUST be: `openspec new change <change-name>`
- Optional wrapper shortcuts (when installed):
  - Claude Code: `/opsx:new <change-name>`
  - Codex/OpenCode: `/opsx-new <change-name>`
- If wrapper shortcuts are missing/outdated, run `openspec update` (or `openspec init --tools <tool>` if not initialized)

## Required Output Contract

```markdown
## Intake Card

- Category: C1 | C2 | C3 | C4
- Scores: N/A/I/R/V = x/x/x/x/x
- DiscoveryScore: x
- ControlScore: x
- GuardrailDomain: <domain | none>
- Execution Mode: Direct | Governed | Discovery-First
- Route Reason: <one sentence>
- Next Step: <single command>
```

If Codex prompt discovery is missing after init, use a project-scoped fallback:

```bash
export CODEX_HOME="$PWD/.codex"
```
