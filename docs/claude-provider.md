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
- `cliproxy` (local CLIProxyAPI gateway)

The configured accounts are:

- `anthropic`, `opus`, `haiku` — native Anthropic accounts
- `deepseek@private`
- `doubao@private`
- `kimi@private`
- `cliproxy@private`

Provider URLs, model lists, defaults, and account model routing are maintained
in `.chezmoidata/claude.yaml`. Do not copy model names from an old example in
this document; the YAML file is the source of truth.

## CLIProxyAPI (OpenAI OAuth → Claude Code)

`cliproxy@private` sends Claude Code's Anthropic-compatible requests to the
localhost-only CLIProxyAPI server, which authenticates upstream with its own
OpenAI Codex OAuth login. Pi and the native Anthropic account are unchanged.
The account uses `gpt-6.1-sol` by default and for Sonnet, `gpt-6-luna` for
small/Haiku, and `gpt-6-astra` for Opus. The older `gpt-6-sol` remains a manual
rollback option. Confirm the selected models appear in the authenticated
proxy's `/v1/models` before use; a public API listing does not establish Codex
OAuth entitlement.

1. The proxy's inbound key lives in gopass at
   `claude/cliproxy/private/api_key` (shared by the proxy config and
   `claude-token`); never commit it or an OAuth token. On a new machine, create
   it with `openssl rand -hex 32 | gopass insert -f -m claude/cliproxy/private/api_key`.
2. Apply chezmoi after the key is present. Machines without the key skip the
   proxy config and its LaunchAgent; if the key exists but cannot be decrypted,
   rendering fails rather than starting an unauthenticated server. If the key
   was restored by the same apply, apply again to render the config and agent.
3. CLIProxyAPI is managed by the existing **aqua** toolchain, not Homebrew or
   an ad hoc binary download. `private_dot_config/aquaproj-aqua/aqua.yaml` pins
   the official `router-for-me/CLIProxyAPI` release; the local registry maps
   its binary to `cliproxyapi` and verifies `checksums.txt`. A full
   `chezmoi apply` runs the aqua install step automatically. Check with
   `command -v cliproxyapi` afterward.

4. Complete the interactive OpenAI login with
   `cliproxyapi --config "$HOME/.cli-proxy-api/config.yaml" --codex-login`
   (callback port 1455). CLIProxyAPI stores its rotating OAuth credentials
   under `~/.cli-proxy-api/`, outside the repository and gopass.
5. On macOS, `chezmoi apply` installs and loads the per-user LaunchAgent
   `com.signalridge.cliproxyapi`. It starts at login and restarts on exit;
   it is **not** a system-wide service while logged out. If the proxy was
   started manually, stop it with Ctrl-C **before** applying to avoid a port
   conflict. Check `launchctl print gui/$(id -u)/com.signalridge.cliproxyapi`
   and `~/Library/Logs/cliproxyapi.launchd.log` if it does not start.
   It binds only `127.0.0.1:8317`, with management API disabled. Confirm the
   three models via authenticated `/v1/models`, then run
   `claude-manage test cliproxy@private` before switching accounts.
6. Use `claude-with cliproxy@private` for one session, or
   `claude-manage switch cliproxy@private` to persist the default (restart
   Claude Code afterward). The default model is `gpt-6.1-sol`; Claude Code's
   `effortLevel` is user-owned, so set it to `high` with `/effort high` once
   and subsequent chezmoi applies preserve that choice. A fresh settings
   file on this account also seeds `high`. Switch back with
   `claude-manage switch anthropic`.

Claude Code may not know this non-Anthropic model ID in its own catalog. The
`cliproxy@private` account explicitly assumes a 1,000,000-token context via
`CLAUDE_CODE_MAX_CONTEXT_TOKENS` (without changing the model ID sent to the
proxy) and auto-compacts at 870,000 tokens. The intended 130,000-token
reserve is **unverified** on the Codex OAuth route: OpenAI's public API lists
922,000 maximum input tokens for 6.1 Sol, which would leave only 52,000
between this trigger and that limit if the routes behave alike. If requests
fail before compaction, lower the account's window and compact threshold
together. For both the new default and the older manual rollback Sol,
CLIProxyAPI's conditional Codex payload override clamps a Claude Code request
for `xhigh` to upstream `high`; requests for `low`, `medium`, or `high` remain
unchanged. This is a local policy (6.1 supports xhigh), independent of the
client-side `effortLevel: high` default.

> **Risk:** CLIProxyAPI routes Codex OAuth traffic through the ChatGPT Codex
> backend rather than the public Platform API. Check the provider's terms and
> account eligibility before use; a proxy does not grant extra entitlement.

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
| `max_context_tokens`           | `CLAUDE_CODE_MAX_CONTEXT_TOKENS` (for unknown model IDs)         |
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
