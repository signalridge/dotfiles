# OpenCode Native Configuration

OpenCode in this repository is managed in native mode.

## Status

- `opencode-manage`, `opencode-with`, and `opencode-token` are removed.
- Use the native `opencode` CLI directly.
- Provider/account default is controlled by `opencodeProviderAccount` in `~/.config/chezmoi/chezmoi.toml`.

## Managed Files

- `~/.config/opencode/opencode.jsonc` from `private_dot_config/opencode/opencode.jsonc.tmpl`
- `~/.config/opencode/oh-my-opencode.jsonc` from `private_dot_config/opencode/oh-my-opencode.jsonc.tmpl`
- `~/.config/opencode/AGENTS.md` from `private_dot_config/opencode/AGENTS.md.tmpl`

## Key Storage

Third-party provider keys are stored in gopass under:

- `opencode/{provider}/{account}/api_key`

Examples:

```bash
gopass show -o opencode/harui/private/api_key
gopass show -o opencode/kimi/private/api_key
```

## Usage

```bash
# Native OpenCode invocation
opencode run -m harui/gpt-5.3-codex "say ok"

# Verify config rendering after template changes
bash tests/test_opencode_config_rendering.sh
```
