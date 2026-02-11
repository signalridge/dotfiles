# gopass New Device Setup Guide

Complete workflow for restoring gopass password manager on a new device.

## Prerequisites

- Access to your `keys-manage` backup repository (Git remote)
- Keys-backup encryption password (used by `keys-manage` / OpenSSL)
- GitHub SSH access
- Network connection

## Step 1: Initialize chezmoi

```bash
# Clone your dotfiles repository and apply configuration
chezmoi init --apply https://github.com/YOUR_USERNAME/dotfiles.git
```

chezmoi will automatically:

1. Install required tools (git, openssl, age, gopass)
2. (If `useEncryption` enabled) Clone your keys-backup repo and restore `~/.ssh/main` (prompts for repo URL + backup password)
3. Create gopass configuration file `~/.config/gopass/config`

## Step 2: Clone Password Store

### Option A: Automatic (Recommended)

During `chezmoi apply`, you'll be prompted:

```text
Clone password store now? (yes/no):
```

Type `yes` to auto-clone.

### Option B: Manual

```bash
# Get repository URL from your dotfiles configuration
REPO_URL=$(yq -r '.gopass.repository // "git@github.com:signalridge/password-store.git"' ~/.chezmoidata/gopass.yaml 2>/dev/null || echo "git@github.com:signalridge/password-store.git")

gopass clone "$REPO_URL"
```

## Step 3: Verification

```bash
# List all passwords
gopass ls

# Test token helpers (AI tools)
claude-token --check kimi@private
codex-token --check deepseek@smoke
```

If you are migrating from legacy key paths, re-add keys via `claude-manage add-key` or `codex-manage add-key`.

## Configuration Details

### Automatically Created Files

1. **`~/.ssh/main`** - age encryption private key (restored from keys-backup repo)
2. **`~/.ssh/main.pub`** - age encryption public key
3. **`~/.config/gopass/config`** - gopass configuration:

```toml
[mounts]
    crypto = age
    path = /Users/username/.local/share/gopass/stores/root

[age]
    ssh-key-path = /Users/username/.ssh/main

[core]
    autopush = true
    autosync = true
    # ... other settings
```

4. **`~/.local/share/gopass/stores/root/.age-recipients`** - public key list (from Git):

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIERhZXwpwu3dcWOyNU/LfSe/D83R+aImQ9k6Ss4dBwKX
```

### Why No Manual Public Key Configuration?

The `.age-recipients` file is already in the Git repository and will be automatically retrieved when cloning.

## Key Configuration Options

### `age.ssh-key-path`

```toml
[age]
    ssh-key-path = /Users/username/.ssh/main
```

**Purpose:** Tells gopass where to find the age decryption key.

**Why needed:** The key is named `main` instead of the standard `id_ed25519`. If using standard names, this configuration is optional.

### `mounts.crypto`

```toml
[mounts]
    crypto = age
```

**Purpose:** Forces gopass to use age backend (instead of default GPG).

## Parameterizing Repository URL

### Method 1: Create `.chezmoidata/gopass.yaml`

```yaml
gopass:
  repository: git@github.com:YOUR_USERNAME/password-store.git
```

### Method 2: Use in Scripts

```bash
# In setup scripts or manual commands
GOPASS_REPO=$(yq -r '.gopass.repository' ~/.chezmoidata/gopass.yaml 2>/dev/null || echo "git@github.com:signalridge/password-store.git")

gopass clone "$GOPASS_REPO"
```

## Troubleshooting

### Error: "Age encryption key not found"

**Solution:** Re-run `chezmoi apply` and make sure `useEncryption=true`, and that you can access your keys repository.

If you want to avoid prompts:

```bash
export KEYS_REPO=git@github.com:YOUR_USERNAME/keypairs.git
export KEYS_BACKUP_PASSWORD='...'
chezmoi apply
```

### Error: gopass clone fails

**Solution:** Check SSH key is added to GitHub:

```bash
ssh -T git@github.com
```

### Error: Cannot decrypt passwords

**Solution:** Verify `~/.ssh/main` permissions:

```bash
chmod 600 ~/.ssh/main
chmod 644 ~/.ssh/main.pub
```

## Technical Details

### Encryption Workflow

1. **Encryption:** Uses public key from `.age-recipients`
2. **Decryption:** Uses private key from `~/.ssh/main`

### File Extensions

- Old GPG backend: `.gpg` files
- New age backend: `.age` files

### Multi-Device Sync

**Shared across devices:**

- Same SSH key (restored from keys-backup repo)
- Same Git repository (password store)

**Device-specific:**

- gopass configuration (synced via chezmoi, but paths may differ)

## Security Recommendations

1. **Backup SSH key:**
   - Primary: keys-backup Git repository (`keys-manage`)
   - Physical: Encrypted USB (optional)

2. **Key permissions:**

   ```bash
   chmod 600 ~/.ssh/main       # Private key: owner read/write only
   chmod 644 ~/.ssh/main.pub   # Public key: world readable
   ```

3. **Backup password security:**
   - Use a strong keys-backup encryption password
   - Store it in a secure password manager

## Related Files

- `migrate-gopass-to-age.sh` - Initial migration script (current device)
- `.chezmoiscripts/run_before_01_setup-encryption-key.sh.tmpl` - Restore/ensure encryption key
- `.chezmoiscripts/run_onchange_after_04_setup-gopass.sh.tmpl` - Clone password store
- `private_dot_config/gopass/config.tmpl` - gopass configuration template
- `.chezmoidata/gopass.yaml` - Repository URL configuration (optional)
