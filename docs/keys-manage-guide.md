# Keys Manager Guide

`keys-manage` backs up and restores sensitive files through an encrypted Git
repository. It is installed as `~/.local/bin/keys-manage` when the repository is
applied.

## Design

- Repository: `~/.local/share/keys-backup`
- Encrypted file payloads: `backup-files/`
- Encrypted control files in Git: `backup-list.txt.enc` and
  `backup-metadata.json.enc`
- Local restore snapshots: `restore-snapshots/<timestamp>/`
- Encryption: OpenSSL AES-256-CBC, PBKDF2, 100,000 iterations, random salt
- Git transport: HTTPS; GitHub authentication uses the `gh` credential helper

Plaintext control files may be present locally for editing, but encrypted
payloads and control files are what should be committed. Never commit raw key
material.

## First setup

`keysRepository` is top-level chezmoi data. It can be supplied during the
`useEncryption` bootstrap prompt or stored in
`~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
keysRepository = "https://github.com/YOUR_USER/keypairs.git"
```

Then run:

```bash
keys-manage init
keys-manage select
keys-manage sync
keys-manage verify
```

`select` replaces the current list. Use `add` and `remove` for incremental
changes. `sync` is the operation that encrypts, commits, and pushes changes.
`backup` is an alias for `sync`.

The `keys-manage add --keys` picker scans common key directories (`~/.ssh`,
`~/.gnupg`, and `~/.config/age`) while excluding host/noise files such as
`known_hosts`, `authorized_keys`, and lock files. The general picker can select
other files under `$HOME`.

## Commands

```text
keys-manage                 # interactive menu
keys-manage init             # initialize or clone the repository
keys-manage select           # replace the backup list
keys-manage add              # append files
keys-manage remove           # remove files from the list
keys-manage sync             # encrypt, commit, and push
keys-manage backup           # alias of sync
keys-manage verify            # compare local files with backups
keys-manage status            # repository and file status
keys-manage history           # recent backup events
keys-manage restore           # restore a selected version
keys-manage versions          # browse versions
keys-manage validate          # validate repository/integrity
```

Restore supports a dry run and an explicit commit:

```bash
keys-manage restore --dry-run
keys-manage restore --dry-run --commit <commit>
keys-manage restore --commit <commit>
```

By default restore creates a safety snapshot before overwriting an existing
file, then writes a new backup commit for the restored file. Use
`--no-backup` only when you deliberately accept that there will be no local
rollback snapshot.

## Password handling

The password can be obtained from, in order, the current process cache, the
`KEYS_BACKUP_PASSWORD` environment variable, `gopass` at
`keys-manage/password`, or a TTY prompt. For automation, use a protected regular
file:

```bash
# Set this from a secret manager or protected process environment.
export KEYS_BACKUP_PASSWORD
keys-manage sync
keys-manage --password-file /path/to/mode-600-password-file sync
```

`-p/--password` is **rejected** so the password cannot appear in shell history
or process arguments. Do not put a password in a Git URL or a shared command
line.

You can manage the optional gopass entry with:

```bash
keys-manage password save
keys-manage password show
keys-manage password test
keys-manage password delete
```

## Restore safety

The restore implementation:

- refuses targets outside `$HOME` and unsafe symlink targets
- verifies checksums and preserves recorded permissions where available
- defaults private files to mode `600` and public-key files to `644`
- snapshots an existing file before replacement
- keeps temporary decrypted files outside the repository and removes them on exit

The bootstrap restore script (`run_before_01_setup-encryption-key.sh.tmpl`) is
separate from the interactive `keys-manage restore` command. It uses the backup
list to restore all required files during a new-device setup and requires
`~/.ssh/main` to be present before chezmoi decrypts age-managed files.

## HTTPS authentication

New configuration should use an HTTPS repository URL:

```bash
gh auth status
gh auth login -h github.com -p https
```

For an unattended cold start, the bootstrap accepts `GH_TOKEN` or
`GITHUB_TOKEN`. Legacy `git@github.com:...` and `ssh://git@github.com/...`
values are normalized to HTTPS by the bootstrap scripts.

## Useful checks

```bash
git -C ~/.local/share/keys-backup status
keys-manage status
keys-manage validate
keys-manage verify
```

For a rollback after restore:

```bash
cp -R ~/.local/share/keys-backup/restore-snapshots/<timestamp>/. "$HOME/"
```

## Related files

- `.chezmoi.toml.tmpl` — `keysRepository` and encryption data
- `.chezmoiscripts/run_before_01_setup-encryption-key.sh.tmpl` — new-device key restore
- `.chezmoiscripts/run_onchange_after_06_setup-gopass.sh.tmpl` — gopass setup
- `dot_local/bin/executable_keys-manage.tmpl` — command entry point
- `dot_local/bin/lib/keys-manage/` — backup, restore, status, and menu logic
- [Gopass new-device setup](gopass-new-device-setup.md)
- [Security policy](../SECURITY.md)
