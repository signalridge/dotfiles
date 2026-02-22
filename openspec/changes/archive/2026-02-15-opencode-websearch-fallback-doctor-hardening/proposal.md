## Why

OpenCode startup currently fails when `oh-my-opencode` is configured with `websearch.provider = "tavily"` but `TAVILY_API_KEY` is not exported in the shell environment. In this repository, Tavily credentials are intentionally managed through `gopass` wrappers, so hard runtime dependency on a global environment variable creates avoidable breakage.

## What Changes

- Change managed oh-my-opencode default websearch provider from `tavily` to `exa` to prevent startup hard-failure when `TAVILY_API_KEY` is absent.
- Extend `opencode-manage doctor` to report explicit websearch provider readiness, including Tavily env-key warning when Tavily is selected.
- Harden manage scripts by fixing format-string-safe prompts and summary rendering so diagnostics output is reliable and readable.
- Update OpenCode workflow documentation and rendering tests to reflect the managed provider default and diagnostics behavior.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `opencode-native-configuration`: Clarify managed websearch default behavior for startup-safe operation.
- `opencode-workflow-integration`: Extend diagnostics and script robustness expectations for day-2 operations.

## Impact

- `private_dot_config/opencode/oh-my-opencode.jsonc.tmpl`
- `dot_local/bin/executable_opencode-manage.tmpl`
- `dot_local/bin/executable_codex-manage.tmpl`
- `dot_local/bin/executable_claude-manage.tmpl`
- `docs/opencode-provider.md`
- `tests/test_opencode_config_rendering.sh`
