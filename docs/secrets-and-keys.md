# Secrets and Keys

The encryption-enabled profile (`useEncryption = true`) uses three mechanisms:

| Mechanism   | Location                            | Protects                                          |
| ----------- | ----------------------------------- | ------------------------------------------------- |
| chezmoi age | `~/.ssh/main` + `~/.ssh/main.pub`   | `encrypted_*` source files (e.g. `~/.ssh/config`) |
| gopass      | `~/.local/share/gopass/stores/root` | API keys and service credentials                  |
| keys-manage | `~/.local/share/keys-backup`        | backups of key files, including `~/.ssh/main`     |

With `useEncryption = false`, scripts `01` and `06`, the gopass config and the
managed `~/.ssh/*` targets are ignored, and no gopass store is expected.

## New device

You need the keys-manage backup repository and its password, the gopass
repository URL, and a GitHub credential (see [GitHub access](#github-access)).
Download `init.sh` first so the prompts keep the terminal (see the README Quick
Start), choose `useEncryption = true`, and enter `keysRepository` and
`gopassRepository` when asked. The order is:

1. Script `00` installs or upgrades pinned Nix.
2. Script `01` clones/pulls `keysRepository` and restores every file on the
   backup list; it requires `~/.ssh/main` to be restorable.
3. The restored `~/.ssh/main` lets chezmoi decrypt its age-managed files.
4. Script `06` asks `Clone password store now? (yes/no):`, runs
   `gopass clone --check-keys=false`, and checks the store is readable. It backs up
   an existing `~/.config/gopass/age` directory first.

Manual clone, using the stored data key (there is no `gopass.yaml`):

```bash
chezmoi data --format json | jq -r '.gopassRepository'
gopass clone --check-keys=false https://github.com/YOUR_USER/YOUR_PASSWORD_STORE.git
gopass ls
```

The rendered `~/.config/gopass/config` points at the store above with
`~/.ssh/main` as the age identity. The store carries its own `.age-recipients`;
do not create a second native age identity unless you manage it separately.

## gopass layout

Claude Code and Codex use native OAuth (`claude /login`, `codex login`) and need
no entry. Other paths are service-scoped:

```text
pi/<service>/api_key                 # Pi custom providers and aichat
tavily/api_key                       # ~/.local/bin/mcp-tavily
claude/cliproxy/private/api_key      # CLIProxyAPI inbound client key (dsh-with)
keys-manage/password                 # optional keys-manage backup password
easytier/..., sing-box/..., jaist/... # network stack (docs/easytier.md)
social/<platform>/...                # oss-x-post skill publishing helpers
```

Keep the Kimi Code key (`pi/kimi`) separate from the Moonshot platform key
(`pi/moonshot`). `claude/cliproxy` is only a storage path, not a Claude provider;
see [DeepSeek Harness](deepseek-harness.md). Store only static secrets: the
templates and helpers read gopass and never write rotating tokens back.

## keys-manage

`~/.local/bin/keys-manage` keeps key files in an encrypted Git repository:
payloads in `backup-files/`, encrypted control files `backup-list.txt.enc` and
`backup-metadata.json.enc`, local restore snapshots in
`restore-snapshots/<timestamp>/`. Encryption is OpenSSL AES-256-CBC with PBKDF2
(100,000 iterations, random salt). Commit only encrypted payloads, never raw key
material.

`keysRepository` is top-level chezmoi data (`[data]` in
`~/.config/chezmoi/chezmoi.toml`). First setup:

```bash
keys-manage init      # initialize or clone the repository
keys-manage select    # replace the backup list (add/remove change it incrementally)
keys-manage sync      # encrypt, commit and push (alias: backup)
keys-manage verify    # compare local files with the backups
```

`add --keys` scans `~/.ssh`, `~/.gnupg` and `~/.config/age`, skipping
`known_hosts`, `authorized_keys` and lock files. Other commands: `status`,
`history`, `versions`, `validate`, `restore`, and `password save|show|test|delete`
for the optional gopass entry. Run `keys-manage` alone for the interactive menu.

Restore:

```bash
keys-manage restore --dry-run [--commit <commit>]
keys-manage restore --commit <commit>
cp -R ~/.local/share/keys-backup/restore-snapshots/<timestamp>/. "$HOME/"   # roll back
```

Restore refuses targets outside `$HOME` and unsafe symlinks, verifies checksums,
restores recorded permissions (private files `600`, public keys `644` by
default), snapshots an existing file before replacing it, and keeps decrypted
temporaries outside the repository. `--no-backup` skips the snapshot; use it only
deliberately. The bootstrap script `01` is separate from interactive restore.

## Passwords

The keys-manage password comes from, in order: the process cache,
`KEYS_BACKUP_PASSWORD`, gopass `keys-manage/password`, or a TTY prompt. For
automation use a protected file:

```bash
keys-manage --password-file /path/to/mode-600-password-file sync
```

`-p/--password` is rejected so a password never reaches shell history or process
arguments. Never put a password or token in a Git URL or a shared command line.

## GitHub access

All repository access is HTTPS through the `gh` credential helper; there are no
`insteadOf` rewrites. Legacy `git@github.com:` and `ssh://git@github.com/` values
for `keysRepository`/`gopassRepository` are normalized to HTTPS.

```bash
gh auth status
gh auth login -h github.com -p https
```

Bootstrap also accepts `GH_TOKEN`/`GITHUB_TOKEN` (unattended hosts) or an
interactive device-code login. Provide tokens and `KEYS_BACKUP_PASSWORD` through
the environment, never on a command line.

## Troubleshooting

```bash
# Age key missing: check the data, then re-apply.
chezmoi data --format json | jq '{useEncryption, keysRepository, gopassRepository}'

# gopass cannot decrypt
chmod 600 ~/.ssh/main
gopass ls

# keys-manage state
git -C ~/.local/share/keys-backup status
keys-manage status && keys-manage validate
```

## Related files

- `.chezmoi.toml.tmpl` — prompts and data keys
- `.chezmoiscripts/run_before_01_setup-encryption-key.sh.tmpl` — key restore
- `.chezmoiscripts/run_onchange_after_06_setup-gopass.sh.tmpl` — gopass clone/verify
- `private_dot_config/gopass/config.tmpl` — gopass configuration
- `dot_local/bin/executable_keys-manage.tmpl`, `dot_local/bin/lib/keys-manage/`
- [Security policy](../SECURITY.md)
