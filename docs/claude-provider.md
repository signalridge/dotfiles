# Claude Code Provider Tools

Manage Claude Code API providers with multi-account support and FZF integration.

## Overview

| Tool            | Purpose                        | Alias |
| --------------- | ------------------------------ | ----- |
| `claude-with`   | Launch with temporary provider | `ccw` |
| `claude-manage` | Manage account configuration   | `ccm` |
| `claude-token`  | Internal token fetcher         | -     |

## claude-with

Wrapper script that launches Claude Code with a specified account via environment variables.

```bash
# FZF interactive picker
claude-with

# Launch with specific account
claude-with kimi@private
claude-with deepseek@work

# Pass arguments to claude
claude-with kimi@private -- --resume
```

## claude-manage

Manage default account configuration and API keys.

```bash
# FZF interactive manager
claude-manage

# List accounts
claude-manage list

# Get/set default account
claude-manage current              # Show current
claude-manage switch kimi@private  # Set default

# Add new account (interactive)
claude-manage add-account

# Add API key for account
claude-manage add-key kimi@private

# Update existing account API key
claude-manage update-key kimi@private

# Delete account API key
claude-manage delete-key kimi@private

# Test connectivity
claude-manage test kimi@private
```

## claude-token

Internal tool for fetching API tokens. Primarily called by `apiKeyHelper` and other tools.

```bash
# Get current account token (for apiKeyHelper)
claude-token

# Get token for specific account
claude-token kimi@private

# Check if token exists (exit code only)
claude-token --check kimi@private

# Get account config as JSON
claude-token --config kimi@private
```

## Configuration Structure

Configuration is in `.chezmoidata/claude.yaml`:

```yaml
claude:
  # Global defaults (accounts can override)
  defaults:
    timeout_ms: 600000

  # Provider definitions (base_url + available models)
  providers:
    anthropic:
      models:
        [
          claude-opus-4-5-20251101,
          claude-sonnet-4-5-20250929,
          claude-haiku-4-5-20251001,
        ]
    deepseek:
      base_url: https://api.deepseek.com/anthropic
      models: [deepseek-chat, deepseek-reasoner]
    kimi:
      base_url: https://api.kimi.com/coding
      models: [kimi-k2.5, kimi-k2]

  # Account configurations (model selection + settings)
  accounts:
    # Native Anthropic (OAuth)
    anthropic:
      model: claude-sonnet-4-5-20250929
      small_model: claude-sonnet-4-5-20250929
    opus:
      provider: anthropic # Use anthropic provider
      model: claude-opus-4-5-20251101
      small_model: claude-sonnet-4-5-20250929

    # Third-party accounts (format: provider@label)
    kimi@private:
      model: kimi-k2.5
      small_model: kimi-k2.5
      haiku_model: kimi-k2.5
      sonnet_model: kimi-k2.5
      opus_model: kimi-k2.5
      timeout_ms: 300000
```

## Environment Variable Mapping

| Account Field  | Environment Variable             |
| -------------- | -------------------------------- |
| `model`        | `ANTHROPIC_MODEL`                |
| `small_model`  | `ANTHROPIC_SMALL_FAST_MODEL`     |
| `haiku_model`  | `ANTHROPIC_DEFAULT_HAIKU_MODEL`  |
| `sonnet_model` | `ANTHROPIC_DEFAULT_SONNET_MODEL` |
| `opus_model`   | `ANTHROPIC_DEFAULT_OPUS_MODEL`   |
| `timeout_ms`   | `API_TIMEOUT_MS`                 |

## Data Storage

| Data                   | Location                                                   |
| ---------------------- | ---------------------------------------------------------- |
| Provider definitions   | `.chezmoidata/claude.yaml` → `providers`                   |
| Account configurations | `.chezmoidata/claude.yaml` → `accounts`                    |
| API keys               | gopass: `claude/{provider}/{account}/api_key`              |
| Default account        | `~/.config/chezmoi/chezmoi.toml` → `claudeProviderAccount` |

**Namespace policy:** prefixes are tool-scoped and fixed by wrapper context:

- `claude` wrappers -> `claude/...`
- `codex` wrappers -> `codex/...`
- `opencode` wrappers -> `opencode/...`

**Migration:** re-add keys with `claude-manage add-key` / `codex-manage add-key` to store them in canonical paths (`<tool>/{provider}/{account}/api_key`), then delete obsolete entries.

## VS Code Integration

Use `claude-with` as a command wrapper in VS Code settings:

```json
{
  "claude.codebase.commandWrapper": ["claude-with", "kimi@private", "--"]
}
```

## Workflow Examples

### Daily Development

```bash
# Default to anthropic (official)
claude

# Temporarily switch to Kimi for testing
claude-with kimi@private

# Need Kimi frequently? Set as default
claude-manage switch kimi@private
```

### New Machine Setup

```bash
# 1. Add account and API key
claude-manage add-account  # Interactive: select provider, enter name and model

# 2. Test connectivity
claude-manage test kimi@private

# 3. Set as default (optional)
claude-manage switch kimi@private
```

### Adding a New Account

1. Edit `.chezmoidata/claude.yaml`:

```yaml
accounts:
  deepseek@work:
    model: deepseek-reasoner
    small_model: deepseek-chat
    timeout_ms: 300000
```

2. Apply chezmoi and add key:

```bash
chezmoi apply
claude-manage add-key deepseek@work
```

### Multi-Account Switching

```bash
# Project A uses company account
claude-with deepseek@work

# Project B uses personal account
claude-with deepseek@personal
```
