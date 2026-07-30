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
      models: [claude-opus-5, claude-sonnet-4-6, claude-haiku-4-5-20251001]
    deepseek:
      base_url: https://api.deepseek.com/anthropic
      models: ["deepseek-v4-pro[1m]", deepseek-v4-flash]
      default_model: deepseek-v4-pro[1m]
      subagent_model: deepseek-v4-pro[1m]
      effort_level: max
    kimi:
      base_url: https://api.kimi.com/coding
      models: [kimi-k2.5, kimi-k2]
    glm:
      base_url: https://api.z.ai/api/anthropic
      models: [glm-5.2, glm-4.7]
      default_model: glm-5.2
      subagent_model: glm-5.2
    newapi:
      base_url: https://newapi.3689403.xyz/
      models: [glm-5.2, glm-4.7]
      default_model: glm-5.2
      subagent_model: glm-5.2

  # Account configurations (model selection + settings)
  accounts:
    # Native Anthropic (OAuth)
    anthropic:
      model: claude-opus-5[1m]
    opus:
      provider: anthropic # Use anthropic provider
      model: claude-opus-5[1m]
      small_model: claude-haiku-4-5-20251001

    # Third-party accounts (format: provider@label)
    deepseek@private:
      provider: deepseek
      model: deepseek-v4-pro[1m]
      small_model: deepseek-v4-flash
      haiku_model: deepseek-v4-flash
      sonnet_model: deepseek-v4-pro[1m]
      opus_model: deepseek-v4-pro[1m]
      subagent_model: deepseek-v4-pro[1m]
      effort_level: max
    kimi@private:
      model: kimi-k2.5
      small_model: kimi-k2.5
      haiku_model: kimi-k2.5
      sonnet_model: kimi-k2.5
      opus_model: kimi-k2.5
      timeout_ms: 300000
    newapi@private:
      provider: newapi
      model: glm-5.2
      small_model: glm-4.7
      haiku_model: glm-4.7
      sonnet_model: glm-5.2
      opus_model: glm-5.2
      subagent_model: glm-5.2
      auto_compact_window: 1000000
```

## Environment Variable Mapping

| Account Field         | Environment Variable              |
| --------------------- | --------------------------------- |
| `model`               | `ANTHROPIC_MODEL`                 |
| `small_model`         | `ANTHROPIC_SMALL_FAST_MODEL`      |
| `haiku_model`         | `ANTHROPIC_DEFAULT_HAIKU_MODEL`   |
| `sonnet_model`        | `ANTHROPIC_DEFAULT_SONNET_MODEL`  |
| `opus_model`          | `ANTHROPIC_DEFAULT_OPUS_MODEL`    |
| `subagent_model`      | `CLAUDE_CODE_SUBAGENT_MODEL`      |
| `auto_compact_window` | `CLAUDE_CODE_AUTO_COMPACT_WINDOW` |
| `effort_level`        | `CLAUDE_CODE_EFFORT_LEVEL`        |
| `timeout_ms`          | `API_TIMEOUT_MS`                  |

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
    provider: deepseek
    model: deepseek-v4-pro[1m]
    small_model: deepseek-v4-flash
    haiku_model: deepseek-v4-flash
    sonnet_model: deepseek-v4-pro[1m]
    opus_model: deepseek-v4-pro[1m]
    subagent_model: deepseek-v4-pro[1m]
    effort_level: max
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
