## Pre-Analysis

- **Similar patterns**:
  - `private_dot_config/opencode/oh-my-opencode.jsonc.tmpl`
  - `dot_local/bin/executable_opencode-with.tmpl`
  - `dot_local/bin/executable_opencode-manage.tmpl`
- **Dependencies**:
  - chezmoi data resolution (`opencodeCompatibilityMode`)
  - oh-my-opencode `claude_code` and `disabled_hooks` policy fields
  - wrapper runtime env flags for strict mode
- **Conventions**:
  - strict mode remains default
  - no-Claude isolation remains baseline policy
  - diagnostics are human-readable and summary-based
- **Risk areas**:
  - accidental policy drift between template and launcher behavior
  - enabling compat mode without explicit visibility
  - false positives in provider-routing checks

## Design Decisions

1. Compatibility mode selector

- source: `chezmoi data` key `opencodeCompatibilityMode`
- allowed values: `strict` (default), `compat`
- unknown values normalize to `strict`

2. Template behavior by mode

- `strict`:
  - `claude_code.commands/skills/agents/hooks/plugins = false`
  - `disabled_hooks` includes `claude-code-hooks`
  - `sisyphus.tasks.claude_code_compat = false`
- `compat`:
  - same toggles set `true`
  - `claude-code-hooks` removed from disabled list
  - `sisyphus.tasks.claude_code_compat = true`

3. Launcher behavior by mode

- strict mode keeps:
  - `OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1`
  - `OPENCODE_DISABLE_EXTERNAL_SKILLS=1`
- compat mode omits strict isolation flags and uses only config/content + provider key env when needed

4. Doctor diagnostics enhancements

- validate actual rendered compatibility state against expected mode
- report built-in MCP enabled/disabled status for `websearch`, `context7`, `grep_app`
- extract providers referenced by categories/agents and check routability against OpenCode provider/native set

## Verification Strategy

- extend rendering tests with strict+compat assertions
- run full test suite
- validate and archive OpenSpec change
