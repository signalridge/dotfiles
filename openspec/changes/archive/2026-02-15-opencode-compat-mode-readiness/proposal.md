## Why

Current OpenCode setup is intentionally strict and stable, but operators need a controlled way to opt into Claude compatibility ingress when desired, without losing deterministic diagnostics.

Confirmed gaps:

- no first-class switch between strict isolation and compatibility mode
- runtime launcher always enforces strict isolation env flags
- diagnostics do not explicitly validate compatibility mode drift or built-in MCP/model routing readiness

## What Changes

- add a managed compatibility mode selector via chezmoi data (`opencodeCompatibilityMode`: `strict` or `compat`)
- render oh-my-opencode compatibility toggles and hook/task compatibility settings based on selected mode
- make `opencode-with` enforce strict isolation only in strict mode; compat mode launches without forced isolation env flags
- expand `opencode-manage doctor` checks for:
  - compatibility profile drift
  - built-in MCP enable/disable state (`websearch`, `context7`, `grep_app`)
  - category/agent model provider routing readiness

## Scope

Included:

- compatibility-mode-aware rendering
- launcher behavior for both modes
- diagnostics and tests/docs updates

Excluded:

- changing default mode from strict
- redesigning user native MCP topology

## Capabilities

### Modified Capabilities

- `opencode-native-configuration`
- `opencode-workflow-integration`
