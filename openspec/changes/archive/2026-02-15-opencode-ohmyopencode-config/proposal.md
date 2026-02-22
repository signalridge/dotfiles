## Why

This repository already has a mature cross-tool workflow for `Claude Code` and `Codex CLI`, based on:

- shared commands (`dot_agents/commands/core`),
- shared skills (`~/.agents/skills`),
- `manage/with/token` wrappers,
- tool-scoped `gopass` namespaces,
- consistent shell alias/completion UX.

OpenCode integration is working, but still not at the same operational depth.

### Confirmed gaps

- OpenCode template currently uses only part of high-value native config features.
- oh-my-opencode advanced controls (`agents`, richer `categories`, `disabled_*`, `experimental`) are not yet fully codified as managed, testable policy.
- Shared commands are not yet guaranteed through OpenCode-native command paths.
- Runtime strict mode (`OPENCODE_DISABLE_EXTERNAL_SKILLS=1`) requires explicit managed projection to keep skills/commands usable.
- Existing docs/tests focus on baseline render/wrapper behavior; they do not yet prove full workflow operability under policy constraints.
- OpenCode provider map is missing at least one third-party family already represented in existing repository Claude/Codex account surface.
- no-Claude policy boundaries are not yet explicit about upstream project instruction fallback behavior.

## Scope Strategy

This change follows one principle:

- **Comprehensive but not excessive**: include features that are stable, high-value, and testable in this repo.

Included:

- curated OpenCode native config profile,
- curated oh-my-opencode advanced profile (orchestration + policy + experimental),
- explicit command/skill projection (layered `commands/` mirror aligned with Claude-style directory symlink),
- no-Claude guardrails with guaranteed operability,
- wrapper diagnostics for day-2 troubleshooting,
- docs/tests aligned to real repo workflow.

Excluded:

- mirroring every upstream config field,
- speculative abstractions with no clear operational value,
- replacing existing Claude/Codex workflow.

## What Changes

- Upgrade OpenCode config from baseline to a curated operational profile (beyond model/provider/plugin/permission).
- Upgrade oh-my-opencode config from baseline to a curated advanced profile:
  - explicit orchestration controls (`sisyphus_agent`, `sisyphus.tasks`, `background_task`, `categories`),
  - explicit disable controls (`disabled_hooks` plus selected `disabled_*` governance),
  - explicit experimental matrix (user-confirmed per field).
- Add OpenCode-native projection for shared commands/skills from repository source-of-truth paths.
- Keep a single layered command projection topology in `commands/` (aligned with Claude-style directory symlink).
- Fix managed oh-my `skills.sources` to recursive project skill discovery (and remove command/prompt-as-skill mixing from defaults).
- Keep strict no-Claude policy, but make runtime behavior predictable and usable.
- Keep provider-family parity with existing Claude/Codex account surface.
- Extend `opencode-manage/with/token` expectations with diagnostics-oriented checks.
- Expand tests and documentation to validate end-to-end workflow behavior.
- Close three-tool UX drift by ensuring completion-exposed diagnostics commands are implemented for Claude/Codex/OpenCode wrappers.
- Clarify `dot_agents` abstraction boundaries: share commands/skills/policies centrally while keeping tool runtime config roots independent.
- Refresh install pins to latest verified upstream releases with aqua-first policy constraints documented.

## Capabilities

### Modified Capabilities

- `opencode-native-configuration`
- `opencode-no-claude-compat`
- `opencode-workflow-integration`

## Impact

- `private_dot_config/opencode/*` templates.
- `dot_local/bin/lib/ai/core.tmpl` and OpenCode wrappers.
- shell UX templates (`dot_custom/alias.sh`, `dot_custom/functions.sh`).
- OpenCode docs and tests.
