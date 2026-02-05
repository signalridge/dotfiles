# Keys Manager Guide

Unified command for managing SSH/GPG/Age keys with encrypted git backup.

## Overview

`keys-manage` is a unified tool that combines backup and restore functionality for your sensitive keys. It uses:

- **OpenSSL**: AES-256-CBC encryption with PBKDF2 (100,000 iterations)
- **FZF**: Interactive file selection and version browsing
- **Git**: Version control and remote backup
- **Incremental backups**: Only changed files are backed up

Repository note:

- The **control files** (`backup-list.txt` and `backup-metadata.json`) are stored **encrypted** in git as
  `backup-list.txt.enc` and `backup-metadata.json.enc`.
- Plaintext working copies exist **only locally** (gitignored), so you can `select/add/remove` without a password.

**Replaces**: `keys-backup` and `keys-restore` commands

## Quick Start

### First Time Setup

```bash
# 1. Initialize encrypted repository
keys-manage init

# 2. Select files to backup
keys-manage select

# 3. Sync (encrypt + commit + push)
keys-manage sync    # or: keys-manage backup

# 4. Verify backup integrity
keys-manage verify
```

### Interactive Menu (Recommended)

```bash
keys-manage menu
# Or just:
keys-manage
```

The interactive menu provides guided workflows with rich previews.

## Commands

### Backup Commands

#### `init` - Initialize Repository

Initialize or setup the encrypted backup repository.

```bash
keys-manage init                    # Interactive password prompt
keys-manage init -p <password>      # Provide password
```

**First time setup:**

1. Clones remote repository (if exists)
2. Or creates new local repository
3. Sets up encrypted control files (`*.enc`) and local plaintext working copies (gitignored)

**Subsequent runs:**

- Ensures the repo is on the encrypted control-file layout
- Does not push automatically; use `keys-manage sync` to pull/push

#### `select` - Select Files (Replace)

Select files to backup using FZF multi-select. **Replaces** current backup list.

```bash
keys-manage select
```

**Features:**

- Auto-discovers keys in `~/.ssh`, `~/.gnupg`, `~/.config/age`
- Rich preview (file metadata, key type, content)
- Status indicators (✓ ⚠ ⊕ ⊗)
- Multi-select (Tab/Ctrl-A)
- Custom file paths under `$HOME` via yazi browser

Note:

- `select/add/remove` only edit your local plaintext control files.
- Run `keys-manage sync` to encrypt/commit/push the updated list and backup changes.

**Keybindings:**

- `Tab`: Toggle selection
- `Ctrl-A`: Select all
- `Ctrl-D`: Deselect all
- `Ctrl-/`: Toggle preview
- `ESC`: Cancel

#### `add` - Add Files (Append)

Add files to backup list without replacing existing selections.

```bash
keys-manage add
```

**Features:**

- If `yazi` is installed: browse under `$HOME` and add any files you pick
- Otherwise: use FZF to browse files under `$HOME` (pruned; may be slow)
- Appends to existing list and deduplicates automatically

#### `remove` - Remove Files

Remove files from backup list.

```bash
keys-manage remove
```

**Features:**

- Shows current backup list
- Multi-select for removal
- Confirmation prompt before removing

#### `sync` (or `backup`) - Incremental Backup + Push

Backup changed files to encrypted repository.

```bash
keys-manage sync                    # Detect changes, encrypt, commit, push
keys-manage backup                  # Alias of sync
```

**Process:**

1. Detects changes (SHA256 checksums)
2. Backs up only modified files
3. Updates metadata
4. Commits to git (including encrypted control files)
5. Pulls/pushes to remote

Conflict handling (control files):

- If another machine updated the encrypted control files and you also have local pending edits,
  `sync` may ask which side to keep.
- You can preselect a policy via `KEYS_MANAGE_CONTROL_CONFLICT_POLICY=local|remote|abort|prompt`.

**Features:**

- Incremental (only changed files)
- Preserves permissions (600 for private keys, 644 for public)
- Automatic metadata updates
- Git commit with timestamp

#### `verify` - Verify Integrity

Verify backup integrity using checksums.

```bash
keys-manage verify
```

Compares SHA256 checksums of local files vs backup.

#### `history` - Show Event Log

Show last 20 backup events.

```bash
keys-manage history
```

### Restore Commands

#### `restore` - Restore Files

Restore files from backup with safety features.

```bash
keys-manage restore                 # FZF version picker
keys-manage restore HEAD~1          # Restore from specific commit
keys-manage restore --dry-run       # Preview without restoring
keys-manage restore --no-backup     # Skip safety backup (dangerous)
```

**Process:**

1. Preview restore plan
2. Confirmation prompt
3. Backup current state to `~/.local/share/keys-backup/restore-snapshots/<timestamp>/`
4. Restore files from backup
5. Set correct permissions
6. Re-encrypt restored file and create a new latest backup commit
7. Run `keys-manage sync` when you want to publish restore commit

**Safety Features:**

- Auto-backup current state (can be disabled with `--no-backup`)
- Dry-run preview support before restore
- Confirmation prompt
- Rollback instructions
- Writes restored content back into backup repo as latest commit

#### Preview Restore (Dry Run)

Preview a restore plan without writing files:

```bash
keys-manage restore --dry-run
keys-manage restore --dry-run --commit abc123
```

#### `versions` - Browse Versions

Browse backup versions with FZF.

```bash
keys-manage versions
```

**Features:**

- FZF commit picker
- Rich preview (git show --stat)
- Shows all commits affecting ssh-keys/

#### `validate` - Validate Repository

Validate repository integrity.

```bash
keys-manage validate
```

**Checks:**

- Git repository integrity (`git fsck`)
- Password availability (gopass)
- Remote connectivity
- Backup file count
- Metadata format

### Common Commands

#### `status` - Unified Status

Show backup and restore status.

```bash
keys-manage status
```

**Displays:**

- Repository info (URL, current commit, total backups)
- Metadata version and file count
- File status (unchanged, modified, new, missing)
- Sync recommendations

**Status Indicators:**

- ✓ Up to date (backed up, no changes)
- ⚠ Modified (backed up but changed since)
- ⊕ New file (not in backup list)
- ⊗ Removed (was backed up, now excluded)

#### `menu` - Interactive Menu

Launch interactive TUI menu.

```bash
keys-manage menu
# Or just:
keys-manage
```

## Options

### Global Options

```bash
-p, --password PWD    Encryption password (OpenSSL, otherwise from gopass/interactive)
-h, --help           Show help message
```

### Command-Specific Options

```bash
# restore
--commit HASH        Restore from specific commit
--dry-run            Preview without restoring
--no-backup          Skip safety backup (dangerous)
```

## Workflows

### Daily Backup

```bash
# Quick check
keys-manage status

# Backup if changes detected
keys-manage backup

# Verify
keys-manage verify
```

### Restore to New Machine

```bash
# 1. Initialize (clone repository)
keys-manage init -p <password>

# 2. Check status
keys-manage status

# 3. Restore latest version
keys-manage restore

# Or restore specific version
keys-manage versions        # Browse versions
keys-manage restore abc123  # Restore selected version
```

### Browse History

```bash
# View backup history
keys-manage history

# Browse all versions
keys-manage versions

# Preview restore plan from specific version
keys-manage restore --dry-run --commit HEAD~5
```

### Rollback After Restore

If you need to rollback after restore:

```bash
# Current state was backed up to:
ls ~/.local/share/keys-backup/restore-snapshots/<timestamp>/

# Rollback:
cp -R ~/.local/share/keys-backup/restore-snapshots/<timestamp>/. ~/
```

## File Discovery

Keys Manager auto-discovers files from:

### SSH Keys (`~/.ssh`)

- Private keys (RSA, ECDSA, Ed25519, DSA, OpenSSH format)
- Excludes: `*.pub`, `known_hosts*`, `authorized_keys*`, `*.lock`

### GPG Keys (`~/.gnupg`)

- Private keyring files
- Trust database

### Age Keys (`~/.config/age`)

- Age encryption keys

### Custom Paths

Use yazi in FZF menu to add custom files under `$HOME`.

## Repository Structure

```
~/.local/share/keys-backup/
├── .git/                       # Git repository
├── .gitignore                  # Git ignore patterns
├── backup-files/               # OpenSSL encrypted backups
│   ├── Justfile                # Each file encrypted with AES-256-CBC
│   ├── .ssh/
│   │   ├── id_ed25519          # Encrypted private keys
│   │   └── config              # Encrypted config files
│   └── ...
├── backup-list.txt             # Selected files (plaintext list)
├── backup-metadata.json        # Metadata v2 (plaintext JSON)
├── backup-history.log          # Event log (plaintext)
└── restore-snapshots/          # Safety snapshots before restore
```

**Note**: Each file in `backup-files/` is independently encrypted with OpenSSL. Git stores the encrypted binary files directly (no git filters).

## Metadata Format (v2)

```json
{
  "version": 2,
  "filters": {
    "include_patterns": ["*"],
    "exclude_patterns": ["*.pub", "known_hosts*", "authorized_keys*"],
    "custom_paths": []
  },
  "files": {
    "/home/user/.ssh/id_ed25519": {
      "sha256": "abc123...",
      "size": 464,
      "mtime": 1234567890,
      "last_backup": "2025-01-15T10:30:00Z",
      "backup_count": 5
    }
  }
}
```

## Configuration

Configure in `~/.local/share/chezmoi/.chezmoidata/keys.yaml`:

```yaml
keysRepository: git@github.com:username/keys-backup.git
```

Or in `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
    keysRepository = "git@github.com:username/keys-backup.git"
```

## Encryption Details

Files are encrypted using **OpenSSL AES-256-CBC** with:

- **PBKDF2** key derivation (100,000 iterations)
- **Random salt** per file (different encryption each time, same decryption)
- **Binary storage** in git (no base64 encoding)

Each encryption produces different ciphertext (due to random salt), but decryption always produces the same plaintext. This is a security feature that prevents:

- Rainbow table attacks
- Pattern analysis
- File content correlation

## Troubleshooting

### Repository not initialized

```bash
keys-manage init
```

### Password not found

```bash
# Save password to gopass
keys-manage password save

# Or provide via command line
keys-manage -p "your-password" backup
keys-manage init -p <password>
```

### Push failed (non-fast-forward)

```bash
cd ~/.local/share/keys-backup
git pull --rebase
git push
```

### Authentication failed

```bash
# Test SSH connection
ssh -T git@github.com

# Add SSH key
ssh-add ~/.ssh/your_key

# Verify repository URL
git -C ~/.local/share/keys-backup remote get-url origin
```

### Cannot reach remote (offline)

Keys Manager works offline:

- Backups are saved locally
- Push will retry on next backup
- Status shows "working offline"

### Verification failures

```bash
# Check git integrity
cd ~/.local/share/keys-backup
git fsck

# Validate repository
keys-manage validate

# Re-backup specific files
keys-manage backup
```

## Migration from Old Commands

If you were using `keys-backup` and `keys-restore`:

### Command Mapping

| Old Command                  | New Command                                     |
| ---------------------------- | ----------------------------------------------- |
| `keys-backup init`           | `keys-manage init`                              |
| `keys-backup select`         | `keys-manage select`                            |
| `keys-backup add`            | `keys-manage add`                               |
| `keys-backup remove`         | `keys-manage remove`                            |
| `keys-backup backup`         | `keys-manage backup`                            |
| `keys-backup verify`         | `keys-manage verify`                            |
| `keys-backup history`        | `keys-manage history`                           |
| `keys-backup status`         | `keys-manage status`                            |
| `keys-restore restore`       | `keys-manage restore`                           |
| `keys-restore diff`          | `keys-manage restore --dry-run --commit <hash>` |
| `keys-restore list-versions` | `keys-manage versions`                          |
| `keys-restore validate`      | `keys-manage validate`                          |
| `keys-restore status`        | `keys-manage status`                            |

### No Changes Needed

Your existing repository works without changes:

- Backup list preserved
- Metadata compatible
- Encryption unchanged
- Git history intact

Just start using `keys-manage` instead of old commands.

## Security

- **Encryption**: AES-256-CBC with PBKDF2 (100,000 iterations) via OpenSSL
- **Permissions**: 600 for private keys, 644 for public keys, 700 for ~/.ssh
- **Git**: No plaintext keys ever committed
- **Safety**: Auto-backup before restore
- **Verification**: SHA256 checksums

## Best Practices

1. **Regular backups**: Run `keys-manage sync` (or `keys-manage backup`) after generating new keys
2. **Verify backups**: Run `keys-manage verify` periodically
3. **Test restores**: Occasionally test restore on a new machine
4. **Secure password**: Use strong encryption password (stored in gopass)
5. **Private repository**: Keep backup repository private
6. **SSH keys**: Use SSH keys for git authentication (not HTTPS)
7. **Backup safety snapshots**: Restore creates snapshots in `~/.local/share/keys-backup/restore-snapshots/` - keep these until verified

## Examples

### Example 1: First Time Setup

```bash
# Initialize repository
$ keys-manage init
Enter password for encryption: ********
Repository cloned
Password saved to gopass (keys-manage/password)
Repository initialized successfully

# Select files to backup
$ keys-manage select
# (FZF menu appears, select files with Tab, press Enter)
Selected 3 files (replaced backup list)
  /home/user/.ssh/id_ed25519
  /home/user/.ssh/id_rsa
  /home/user/.gnupg/secring.gpg

# Backup selected files
$ keys-manage backup
[1/5] Files in backup list:
  ⊕ id_ed25519
  ⊕ id_rsa
  ⊕ secring.gpg

[2/5] Detecting changes...
  ⚠ Changed: id_ed25519
  ⚠ Changed: id_rsa
  ⚠ Changed: secring.gpg

Detected: 3 of 3 files changed

[3/5] Backing up files...
  ✓ id_ed25519
  ✓ id_rsa
  ✓ secring.gpg

[4/5] Committing to git...

[5/5] Pushing to remote...
✓

✅ Backup Complete

Backed up 3 changed files
```

### Example 2: Restore on New Machine

```bash
# Initialize (clone repository)
$ keys-manage init -p mypassword
Repository cloned
Password saved to gopass (keys-manage/password)

# Check status
$ keys-manage status
Repository: /home/user/.local/share/keys-backup
  Remote: git@github.com:user/keys-backup.git
  Current: abc1234 - Backup: 3 files (2 hours ago)
  Total backups: 15

# Restore with FZF version picker
$ keys-manage restore
# (FZF menu appears, select version, press Enter)

[1/5] Preview changes...
Changed: id_ed25519
  Local:  missing...
  Backup: abc123...

[2/5] Backing up current state...
Backed up 0 files to: /home/user/.local/share/keys-backup/restore-snapshots/20250115-103000

Restore from abc1234? (y/n): y

[3/5] Checking out backup version...

[4/5] Restoring SSH keys...
  ✓ Restored: id_ed25519
  ✓ Restored: id_rsa
  ✓ Restored: secring.gpg

[5/5] Cleanup...

✅ Restore Complete

Restored 3 files
```

### Example 3: Browse and Restore Specific Version

```bash
# Browse all versions
$ keys-manage versions
# (FZF menu shows git log with previews)
# Select commit, press Enter

Selected commit: abc1234

# Preview restore plan from that version
$ keys-manage restore --dry-run --commit abc1234

# Restore that version
$ keys-manage restore abc1234
```

## See Also

- [OpenSSL](https://www.openssl.org/) - Cryptography toolkit
- [FZF](https://github.com/junegunn/fzf) - Command-line fuzzy finder
- [gopass](https://github.com/gopasspw/gopass) - Password manager
- Chezmoi documentation for configuration

## Support

Report issues at: https://github.com/anthropics/claude-code/issues
