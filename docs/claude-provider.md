# Claude Code Provider Tools

These wrappers manage Claude Code accounts declared in
`.chezmoidata/claude.yaml`. The rendered settings live at
`~/.claude/settings.json`; API keys are read from gopass when needed.

## Commands

| Command         | Role                                                       | Alias |
| --------------- | ---------------------------------------------------------- | ----- |
| `claude-with`   | Launch Claude Code with a selected account for one session | `ccw` |
| `claude-manage` | Change account data, keys, and the persistent default      | `ccm` |
| `claude-token`  | Read/check a key or print merged account configuration     | —     |

```bash
# Interactive picker
claude-with
claude-manage

# One-session routing
claude-with kimi@private
claude-with kimi@private -- --resume

# Persistent account management
claude-manage list
claude-manage current
claude-manage switch kimi@private
claude-manage test kimi@private
claude-manage doctor
```

`claude-token` does not switch accounts:

```bash
claude-token                         # current third-party token, if needed
claude-token kimi@private             # token for one account
claude-token --check kimi@private    # exit status only
claude-token --config kimi@private   # merged configuration as JSON
```

Native Anthropic accounts use Claude Code's OAuth/session authentication and do
not need a gopass key. Third-party accounts need a key before they can be
launched or tested.

## Current providers and accounts

The current provider definitions are:

- `anthropic` (native OAuth)
- `deepseek`
- `kimi`
- `glm`
- `qwen`
- `minimax`
- `doubao`

The configured accounts are:

- `anthropic`, `opus`, `haiku` — native Anthropic accounts
- `deepseek@private`
- `doubao@private`
- `kimi@private`

Provider URLs, model lists, defaults, and account model routing are maintained
in `.chezmoidata/claude.yaml`. Do not copy model names from an old example in
this document; the YAML file is the source of truth.

## API-key paths

Third-party Claude keys use the canonical gopass path:

```text
claude/<provider>/<account-label>/api_key
```

For example, the configured `kimi@private` account uses:

```bash
gopass insert claude/kimi/private/api_key
claude-token --check kimi@private
```

The account label is the part after `@`. A provider-only account uses the
`default` label internally. Keys are never committed to this repository.

## Account data and environment mapping

An account may select the following fields; the rendered settings/template maps
them as follows:

| YAML field                     | Claude Code setting                                              |
| ------------------------------ | ---------------------------------------------------------------- |
| `model`                        | `ANTHROPIC_MODEL`                                                |
| `small_model`                  | `ANTHROPIC_SMALL_FAST_MODEL`                                     |
| `haiku_model`                  | `ANTHROPIC_DEFAULT_HAIKU_MODEL`                                  |
| `sonnet_model`                 | `ANTHROPIC_DEFAULT_SONNET_MODEL`                                 |
| `opus_model`                   | `ANTHROPIC_DEFAULT_OPUS_MODEL`                                   |
| `subagent_model`               | `CLAUDE_CODE_SUBAGENT_MODEL`                                     |
| `timeout_ms`                   | `API_TIMEOUT_MS`                                                 |
| `disable_nonessential_traffic` | `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`                     |
| `attribution_header`           | `CLAUDE_CODE_ATTRIBUTION_HEADER`                                 |
| `disable_experimental_betas`   | `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1`                       |
| `supported_capabilities`       | the three `ANTHROPIC_DEFAULT_*_SUPPORTED_CAPABILITIES` variables |
| `auto_compact_window`          | `CLAUDE_CODE_AUTO_COMPACT_WINDOW`                                |

Values are resolved account-first, then provider, then the global defaults where
the template supports that fallback. The current global defaults include a
600-second API timeout and `disable_nonessential_traffic: false`.

## Adding or changing an account

For a configured account, use the manager:

```bash
claude-manage update-account kimi@private
claude-manage add-key kimi@private
claude-manage update-key kimi@private
claude-manage delete-key kimi@private
```

To add a new account, either use `claude-manage create-account` or edit the
`accounts` map in `.chezmoidata/claude.yaml`, then apply the relevant files:

```bash
chezmoi apply
claude-manage add-key deepseek@work
claude-manage test deepseek@work
```

Third-party account names use `provider@label`, for example
`deepseek@work` or `kimi@personal`. Native Anthropic aliases such as `opus` do
not use an `@label` suffix.

`claude-manage switch` persists `claudeProviderAccount` in chezmoi data and
applies the Claude settings while excluding the full script pipeline. Restart
Claude Code after switching so the new environment is used.

## Safety and isolation

`claude-with` clears inherited provider variables before launching and creates a
temporary settings file for the selected account. This prevents a third-party
`ANTHROPIC_BASE_URL` from leaking into a native Anthropic session, and keeps
settings JSON out of the process argument list.

The managed global Claude settings intentionally use
`defaultMode: "bypassPermissions"`, with explicit allow/deny rules and hooks.
The Git rewrite hook blocks some irreversible operations and asks for
confirmation for other risky operations. Review `dot_claude/settings.json.tmpl`
and `dot_claude/hooks/` before reusing this configuration elsewhere.
