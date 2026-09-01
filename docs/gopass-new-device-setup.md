# Gopass New-Device Setup

This guide describes the encryption-enabled path of this repository. It uses
HTTPS GitHub access and the existing `gh` credential helper; SSH URLs are
legacy input and are normalized to HTTPS.

## Prerequisites

- Access to the keys-manage backup repository
- Its OpenSSL encryption password
- The gopass repository URL
- Network access
- A GitHub credential method: an existing `gh` login, `GH_TOKEN`/`GITHUB_TOKEN`,
  or an interactive `gh` device-code login

## 1. Initialize chezmoi

Use the downloaded-script form so the first-run prompts can read from the
terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/signalridge/dotfiles/main/init.sh -o /tmp/init.sh
sh /tmp/init.sh
```

Choose `useEncryption = true` and provide `keysRepository` and
`gopassRepository` when prompted. The relevant order is:

1. Script `00` installs or upgrades pinned Nix.
2. Script `01` clones/pulls `keysRepository` and restores the keys-manage files.
3. The restored `~/.ssh/main` key lets chezmoi decrypt its age-managed files.
4. Script `06` verifies or clones the gopass store from `gopassRepository`.

If the key repository is private and credentials are not configured, script `01`
can use a GitHub device-code login. For unattended use, provide
`GH_TOKEN`/`GITHUB_TOKEN` and `KEYS_BACKUP_PASSWORD` securely in the environment.

When `useEncryption = false`, script `01`, script `06`, the gopass config, and
managed `~/.ssh/*` targets are ignored. No gopass store is expected in that
profile.

## 2. Clone the password store

### Automatic

During `chezmoi apply`, script `06` asks:

```text
Clone password store now? (yes/no):
```

Answer `yes`. The script runs `gopass clone --check-keys=false`, then verifies
that the store is readable with `~/.ssh/main`.

### Manual

The URL is stored as the top-level chezmoi data key `gopassRepository`, not in a
`gopass.yaml` file:

```bash
# Inspect the configured value without inventing a repository name.
chezmoi data --format json | jq -r '.gopassRepository'

gopass clone --check-keys=false https://github.com/YOUR_USER/YOUR_PASSWORD_STORE.git
gopass ls
```

The generated config is `~/.config/gopass/config` and points at:

```text
store: ~/.local/share/gopass/stores/root
age key: ~/.ssh/main
```

## 3. Verify AI credentials

The Claude/Codex account managers use tool-scoped gopass namespaces. For
example:

```bash
gopass ls
claude-token --check kimi@private
codex-token --check deepseek@private
```

Native Anthropic/OpenAI accounts use their native OAuth flows and do not need an
API-key entry. Other providers need keys in paths such as:

```text
claude/kimi/private/api_key
codex/deepseek/private/api_key
```

Pi and aichat use separate service-scoped paths under `pi/`; do not merge a Kimi
Code key with the Moonshot platform key. See [the Claude provider guide](claude-provider.md)
for account operations.

## Important generated files

- `~/.ssh/main` — age/SSH private key restored by keys-manage
- `~/.ssh/main.pub` — recipient/public key, generated when possible
- `~/.config/gopass/config` — age-backed gopass configuration
- `~/.local/share/gopass/stores/root/` — cloned password store
- `~/.local/share/keys-backup/` — local keys-manage repository

The gopass store contains `.age-recipients`; do not create a second native age
identity directory unless you intentionally manage it separately. Script `06`
backs up an existing `~/.config/gopass/age` directory before cloning.

## Troubleshooting

### Age key is missing

Confirm that encryption is enabled and that the keys repository is configured:

```bash
chezmoi data --format json | jq '{useEncryption, keysRepository, gopassRepository}'
chezmoi apply
```

For a private GitHub repository, authenticate over HTTPS:

```bash
gh auth status
gh auth login -h github.com -p https
```

For an unattended host, use a PAT through `GH_TOKEN` rather than putting a token
in a URL or command line.

### Gopass cannot decrypt entries

```bash
chmod 600 ~/.ssh/main
chmod 644 ~/.ssh/main.pub 2>/dev/null || true
gopass ls
gopass show keys-manage/password 2>/dev/null || true
```

If the encryption password is for the keys backup (not a gopass entry), set it
only for the current command/session with `KEYS_BACKUP_PASSWORD` or answer the
TTY prompt. Do not put it in process arguments.

## Related files

- `.chezmoi.toml.tmpl` — prompts and data keys
- `.chezmoiscripts/run_before_01_setup-encryption-key.sh.tmpl` — restore keys
- `.chezmoiscripts/run_onchange_after_06_setup-gopass.sh.tmpl` — clone/verify gopass
- `private_dot_config/gopass/config.tmpl` — generated gopass configuration
- `dot_local/bin/executable_keys-manage.tmpl` — keys backup/restore command
- `docs/keys-manage-guide.md` — keys-manage operations
