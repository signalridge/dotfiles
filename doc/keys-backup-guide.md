# SSH Keys Backup/Restore System Guide

Production-grade SSH keys backup system with FZF interface, incremental backups, and version control.

## Overview

The keys-backup system provides secure, version-controlled backup and restore of SSH keys using:

- **Encryption**: AES-256-CBC via transcrypt
- **Version Control**: Git-based history with FZF selection
- **Incremental Backups**: SHA256 checksum-based change detection
- **Rich UI**: FZF interface with live preview and status indicators
- **Safety**: Automatic rollback capability and dry-run mode

## Installation

The system consists of four scripts (automatically installed via chezmoi):

```bash
~/.local/bin/
├── keys-lib          # Shared library (~400 lines)
├── keys-backup       # Backup CLI (~470 lines)
├── keys-restore      # Restore CLI (~560 lines)
└── keys-migrate      # Migration tool (~150 lines)
```

## Quick Start

### Initial Backup

```bash
# Interactive file selection with FZF
keys-backup backup interactive

# Or use auto-discovery
keys-backup backup
```

### Restore from Backup

```bash
# Interactive version selection
keys-restore restore

# Restore specific version
keys-restore restore --commit abc123
```

### Check Status

```bash
# Show backup status
keys-backup status

# Show restore status
keys-restore status
```

## Architecture

### Repository Structure

```
$HOME/.local/share/keys-backup/
├── .git/                       # Git repository
├── .transcrypt/cipher          # Encryption key
├── .gitattributes             # Encryption configuration
├── ssh-keys/                  # Encrypted backup files
│   ├── id_ed25519
│   ├── id_ed25519.pub
│   ├── main
│   └── config
├── backup-list.txt            # Selected file paths (encrypted)
├── backup-metadata.json       # File checksums & timestamps (encrypted)
└── backup-history.log         # Event log (plaintext)
```

### Metadata Format (v2)

```json
{
  "version": 2,
  "filters": {
    "include_patterns": ["*"],
    "exclude_patterns": ["*.pub", "known_hosts*", "authorized_keys*"],
    "custom_paths": []
  },
  "files": {
    "/Users/user/.ssh/main": {
      "sha256": "abc123...",
      "size": 464,
      "mtime": 1704067200,
      "last_backup": "2024-01-01T00:00:00Z",
      "backup_count": 5
    }
  }
}
```

## Commands Reference

### keys-backup

```bash
# Commands
keys-backup backup [mode]       # Backup files (auto/full/interactive)
keys-backup select              # Select files with FZF
keys-backup verify              # Verify integrity
keys-backup history             # Show backup history
keys-backup status              # Show current status

# Options
-p, --password PWD              # Transcrypt password
-r, --reconfigure              # Force reconfiguration
--dry-run                      # Preview without changes
--path PATH                    # Add custom path

# Examples
keys-backup                              # Show status
keys-backup backup                       # Incremental backup
keys-backup backup full                  # Full backup all files
keys-backup backup interactive           # Select files then backup
keys-backup select                       # Select files with FZF
keys-backup verify                       # Check integrity
keys-backup --path ~/.gnupg/secret.key   # Add custom file
```

### keys-restore

```bash
# Commands
keys-restore restore [commit]   # Restore files from backup
keys-restore list-versions      # Browse versions with FZF
keys-restore diff [commit]      # Preview changes
keys-restore validate           # Validate repository
keys-restore status             # Show restore status

# Options
-p, --password PWD              # Transcrypt password
-c, --commit HASH              # Specific commit
--dry-run                      # Preview without changes
--no-backup                    # Skip current state backup (dangerous)

# Examples
keys-restore                         # Show status
keys-restore restore                 # Interactive version selection
keys-restore list-versions           # Browse versions with FZF
keys-restore diff HEAD~1             # Preview previous version
keys-restore restore --commit abc123 # Restore specific version
keys-restore --dry-run               # Preview restore
keys-restore validate                # Check integrity
```

### keys-migrate

Migrates v1 backups to v2 format with metadata support.

```bash
keys-migrate

# Features:
- Creates backup-metadata.json from existing backups
- Calculates checksums for all files
- Initializes backup history
- Creates rollback branch
```

## Features

### 1. FZF File Selection

Interactive file selection with rich preview:

```
┌─ Select files to backup (Tab: multi-select, Ctrl-A: all) ─────┐
│ ✓ /Users/user/.ssh/main                                       │
│ ⚠ /Users/user/.ssh/config                                     │
│ ⊕ /Users/user/.ssh/id_ed25519                                 │
└────────────────────────────────────────────────────────────────┘
┌─ File Preview ─────────────────────────────────────────────────┐
│ Path: /Users/user/.ssh/main                                    │
│ Size: 464 bytes                                                │
│ Modified: 2024-01-01 12:00:00                                  │
│ Permissions: -rw-------                                        │
│ Type: Ed25519                                                  │
│                                                                 │
│ ━━━ Backup Info ━━━                                            │
│ Last backup: 2024-01-01T00:00:00Z                              │
│ Backup count: 5                                                │
│                                                                 │
│ ━━━ Preview ━━━                                                │
│ [Private key content - first 10 lines]                         │
│ ...                                                             │
└────────────────────────────────────────────────────────────────┘
```

**Status Indicators:**
- `✓` Green - Up to date (backed up, no changes)
- `⚠` Yellow - Modified (backed up but changed since)
- `⊕` Cyan - New file (not in backup list)
- `⊗` Red - Removed (was backed up, now excluded)
- `○` Gray - Available (not selected)

**Keyboard Shortcuts:**
- `Tab` - Multi-select
- `Ctrl-A` - Select all
- `Ctrl-D` - Deselect all
- `Ctrl-R` - Reload list
- `Ctrl-/` - Toggle preview

### 2. Incremental Backup

Only backs up changed files based on SHA256 checksums:

```bash
# Auto mode (default) - only changed files
keys-backup backup

# Full mode - all files
keys-backup backup full

# Dry run - preview without changes
keys-backup backup --dry-run
```

Change detection:
```
[2/5] Detecting changes...
  ⚠ Changed: config

Mode: Incremental (1 of 3 files changed)
```

### 3. Version History with FZF

Browse and select backup versions interactively:

```bash
# Interactive version selection
keys-restore list-versions
```

```
┌─ Select backup version ────────────────────────────────────────┐
│ abc123 2024-01-15 Incremental backup: 2 files                  │
│ def456 2024-01-10 Full backup: 3 files                         │
│ ghi789 2024-01-05 Backup SSH keys                              │
└────────────────────────────────────────────────────────────────┘
┌─ Commit Details ───────────────────────────────────────────────┐
│ commit abc123                                                   │
│ Date:   Mon Jan 15 12:00:00 2024                                │
│                                                                 │
│  ssh-keys/config | 2 +-                                         │
│  ssh-keys/main   | 0                                            │
│  2 files changed, 1 insertion(+), 1 deletion(-)                 │
└────────────────────────────────────────────────────────────────┘
```

### 4. Diff Preview

Preview changes before restoring:

```bash
keys-restore diff HEAD~1
```

```
━━━ Diff: Current vs abc123 ━━━

✓ No changes: main
⚠ Changed: config
  Local:  1a2b3c4d5e6f7g8h...
  Backup: 9h8g7f6e5d4c3b2a...

  Diff preview:
  -Host github.com
  +Host github.com gitlab.com
     IdentityFile ~/.ssh/main
```

### 5. Safety Features

**Auto-backup before restore:**
```
[2/5] Backing up current state...
✓ Backed up 3 files to: ~/.ssh/backup-20240115-120000
```

**Confirmation prompt:**
```
Restore from abc123? (y/n):
```

**Rollback instructions:**
```
Rollback available:
  Current state saved to: ~/.ssh/backup-20240115-120000
  To rollback: cp ~/.ssh/backup-20240115-120000/* ~/.ssh/
```

### 6. Verification

Verify backup integrity with checksum comparison:

```bash
keys-backup verify
```

```
Verifying backup integrity...

✓ OK: main
✓ OK: config
✓ OK: id_ed25519

✅ All 3 files verified
```

### 7. Custom Paths

Add files outside ~/.ssh to backup:

```bash
# Add custom file
keys-backup --path ~/.gnupg/private-keys-v1.d/secret.key

# Interactive selection includes custom paths
keys-backup select
```

## Workflows

### Daily Backup Workflow

```bash
# Check status
keys-backup status

# Backup changed files
keys-backup backup

# Verify backup
keys-backup verify
```

### New Device Setup

```bash
# Clone and restore
keys-restore restore

# Verify restored files
ls -lah ~/.ssh/
```

### Migrate from v1

```bash
# Run migration tool
keys-migrate

# Verify migration
keys-backup status
keys-backup verify
```

### Emergency Restore

```bash
# List available versions
keys-restore list-versions

# Preview specific version
keys-restore diff abc123

# Restore with confirmation
keys-restore restore --commit abc123

# If something goes wrong, rollback
cp ~/.ssh/backup-20240115-120000/* ~/.ssh/
```

### Periodic Full Backup

```bash
# Force full backup (ignore change detection)
keys-backup backup full

# Verify all files
keys-backup verify
```

## Migration Guide

### From v1 to v2

The migration tool automatically upgrades legacy backups to v2 format with metadata support.

**Before Migration:**
```bash
# Check current status
cd ~/.local/share/keys-backup
git log --oneline | head -5
```

**Run Migration:**
```bash
keys-migrate
```

**What Happens:**
1. Creates backup branch `pre-migration-backup-YYYYMMDD-HHMMSS`
2. Generates `backup-metadata.json` from existing backups
3. Calculates checksums for all backed up files
4. Initializes `backup-history.log` from git history
5. Updates `.gitattributes` to encrypt metadata
6. Commits and pushes changes

**After Migration:**
```bash
# Verify migration
keys-backup status

# Check metadata
jq . ~/.local/share/keys-backup/backup-metadata.json

# Test incremental backup
echo "test" >> ~/.ssh/config
keys-backup backup  # Should only backup config

# Rollback if needed (optional)
cd ~/.local/share/keys-backup
git reset --hard pre-migration-backup-YYYYMMDD-HHMMSS
git push --force
```

### Backward Compatibility

- V2 can read v1 backups (just missing metadata)
- V1 scripts still work (basic functionality)
- Migration is safe (creates backup branch)
- No changes to encryption or git structure

## Troubleshooting

### Transcrypt Issues

**Problem:** "Transcrypt not configured"

```bash
cd ~/.local/share/keys-backup
transcrypt -c aes-256-cbc
```

**Problem:** "Failed to unlock transcrypt"

```bash
# Re-enter password
keys-backup backup -p "your-password"

# Or without -p for interactive prompt
keys-backup backup
```

### Git Issues

**Problem:** "Cannot reach remote repository"

```bash
# Check remote URL
cd ~/.local/share/keys-backup
git remote -v

# Update remote if needed
git remote set-url origin git@github.com:user/keys-backup.git
```

**Problem:** "Push rejected"

```bash
cd ~/.local/share/keys-backup
git pull --rebase
git push
```

### FZF Issues

**Problem:** "fzf not found"

```bash
# Install fzf
brew install fzf  # macOS
# or add to .chezmoidata/homebrew.yaml

# Verify installation
command -v fzf
```

### Metadata Issues

**Problem:** "Metadata format invalid"

```bash
# Validate JSON
jq empty ~/.local/share/keys-backup/backup-metadata.json

# Fix or regenerate
keys-migrate  # Re-run migration
```

**Problem:** "No metadata file (legacy v1)"

```bash
# Migrate to v2
keys-migrate
```

### File Permission Issues

**Problem:** "Permission denied" when restoring

```bash
# Fix SSH directory permissions
chmod 700 ~/.ssh

# Fix key permissions
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/id_*.pub
```

## Best Practices

### Security

1. **Strong Password**: Use a strong password for transcrypt encryption
2. **Private Repository**: Use a private git repository
3. **SSH Access**: Prefer SSH over HTTPS for git remote
4. **Regular Rotation**: Rotate encryption password periodically
5. **Access Control**: Limit repository access to trusted devices

### Backup Frequency

1. **After Key Creation**: Immediately backup new keys
2. **After Modification**: Backup when modifying config
3. **Before Migration**: Backup before major system changes
4. **Periodic Full**: Run full backup monthly
5. **Verification**: Verify backups weekly

### Maintenance

1. **Check Status**: Run `keys-backup status` regularly
2. **Verify Integrity**: Run `keys-backup verify` weekly
3. **Prune History**: Clean up old backups periodically
4. **Update Scripts**: Keep scripts up to date with chezmoi

### Disaster Recovery

1. **Multiple Backups**: Keep backups in multiple locations
2. **Test Restore**: Periodically test restore process
3. **Document Rollback**: Know how to rollback changes
4. **Emergency Access**: Have alternative access to repository

## Advanced Usage

### Automation

```bash
# Cron job for daily backup
0 2 * * * /Users/user/.local/bin/keys-backup backup 2>&1 | logger -t keys-backup

# Pre-commit hook for auto-backup
cat > ~/.ssh/.git/hooks/pre-commit <<'EOF'
#!/bin/bash
keys-backup backup --dry-run || keys-backup backup
EOF
```

### Custom Filters

Edit metadata filters manually:

```bash
# Edit metadata
vim ~/.local/share/keys-backup/backup-metadata.json

# Update filters
{
  "version": 2,
  "filters": {
    "include_patterns": ["*", "*.pem"],
    "exclude_patterns": ["*.pub", "known_hosts*", "authorized_keys*"],
    "custom_paths": ["/etc/ssl/private/cert.key"]
  },
  ...
}
```

### Integration with Chezmoi

```yaml
# .chezmoidata.yaml
keysRepository: "git@github.com:user/keys-backup.git"

# Hooks for automation
[hooks.post-apply]
  command = "keys-backup"
  args = ["backup"]
```

## Architecture Details

### File Discovery

Uses `find` with smart filtering:
- Scans `~/.ssh` directory
- Excludes: `*.pub`, `known_hosts*`, `authorized_keys*`
- Detects key types: RSA, Ed25519, ECDSA, DSA, SSH Config

### Checksum Algorithm

SHA256 for cross-platform compatibility:
- macOS: `shasum -a 256`
- Linux: `sha256sum`

### Change Detection

Compares SHA256 hashes:
1. Calculate current file hash
2. Load stored hash from metadata
3. Compare hashes
4. If different → backup needed

### Git Operations

- Atomic commits per backup
- Descriptive commit messages with timestamps
- Full history preservation
- Remote sync after each backup

### Encryption

AES-256-CBC via transcrypt:
- Encrypts: `ssh-keys/`, `backup-list.txt`, `backup-metadata.json`
- Plaintext: `backup-history.log` (for debugging)
- Password-based encryption
- Compatible with git operations

## Performance

### Benchmarks

Typical performance on modern systems:

| Operation | Time | Files |
|-----------|------|-------|
| File discovery | <100ms | ~10 files |
| Checksum calculation | ~10ms | per file |
| FZF selection | Interactive | N/A |
| Incremental backup | ~1s | 1-2 changed files |
| Full backup | ~3s | 10 files |
| Verification | ~500ms | 10 files |
| Version restore | ~2s | 10 files |

### Optimization Tips

1. **Incremental Backups**: Use `auto` mode (default) instead of `full`
2. **Selective Backup**: Only include necessary files in backup list
3. **Local Operations**: Most operations are local (git pull/push only when needed)
4. **Caching**: Metadata cached in JSON for fast lookups

## Contributing

### Code Style

- Follow existing bash conventions
- Use shellcheck for validation
- Add comments for complex logic
- Test on both macOS and Linux

### Testing

```bash
# Shellcheck validation
shellcheck ~/.local/bin/keys-*

# Manual testing
keys-backup --help
keys-restore --help
keys-migrate --help

# Integration testing
keys-backup backup --dry-run
keys-restore restore --dry-run
```

### Adding Features

1. Update shared library (`keys-lib`)
2. Add command to CLI (`keys-backup` or `keys-restore`)
3. Update documentation
4. Test on multiple platforms
5. Submit PR with description

## Support

### Resources

- Source code: `~/.local/share/chezmoi/dot_local/bin/executable_keys-*.tmpl`
- Documentation: `~/.local/share/chezmoi/doc/keys-backup-guide.md`
- Issues: File issues in chezmoi repository

### Getting Help

```bash
# Show help
keys-backup --help
keys-restore --help

# Check status
keys-backup status
keys-restore status

# Validate setup
keys-restore validate
```

## Changelog

### v2.0 (Current)

- FZF interface with rich preview
- Incremental backup with checksum detection
- Version history with git integration
- Metadata tracking (SHA256, timestamps, counts)
- Diff preview before restore
- Safety features (auto-backup, rollback)
- Migration tool for v1 repos
- Comprehensive documentation

### v1.0 (Legacy)

- Basic backup/restore functionality
- Transcrypt encryption
- Manual file selection
- No metadata tracking
- No version selection
