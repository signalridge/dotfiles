#!/usr/bin/env bash
# Clone (or verify) the gopass password store. Not a template: run by
# .chezmoiscripts/run_onchange_after_06_setup-gopass.sh.tmpl and, on a fresh
# machine, by the read-source-state hook (.bootstrap/pre-source-state.sh), so
# the store exists before chezmoi reads the source state: .chezmoiignore and
# several templates look at it, and they are evaluated only once per apply.
#
# Usage: setup-gopass-store.sh <store repository URL>
# Required env:
#   - NIXPKGS_BOOTSTRAP_REV  (.chezmoidata/versions.yaml) to install gopass into
#                            the isolated bootstrap profile when aqua's is not
#                            available yet
# Optional env:
#   - GOPASS_STORE_CLONE=yes to clone without the confirmation prompt
# Prerequisite: ~/.ssh/main (restored by .bootstrap/restore-keys.sh).
set -euo pipefail

repo="${1:?usage: setup-gopass-store.sh <store repository URL>}"
case "$repo" in
git@github.com:*) repo="https://github.com/${repo#git@github.com:}" ;;
ssh://git@github.com/*) repo="https://github.com/${repo#ssh://git@github.com/}" ;;
esac

store_dir="$HOME/.local/share/gopass/stores/root"
config="${XDG_CONFIG_HOME:-$HOME/.config}/gopass/config"
# Same isolated profile as .bootstrap/restore-keys.sh; templates fall back to it
# (.chezmoitemplates/gopass/command.tmpl) until aqua's gopass is usable.
bootstrap_profile="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/dotfiles-bootstrap"

echo ":: [06] Setting up gopass password store"

# A valid store is a cloned git repo; a bare empty directory (for example,
# one left by a failed clone) must not count as initialized.
if [[ -d "$store_dir" ]] && [[ ! -d "$store_dir/.git" ]] &&
    [[ -z "$(ls -A "$store_dir" 2>/dev/null)" ]]; then
    echo "⚠ Removing empty gopass store directory (not a valid store): $store_dir"
    rmdir "$store_dir"
fi

if [[ ! -f "$HOME/.ssh/main" ]]; then
    echo "⚠ Age encryption key not found at ~/.ssh/main" >&2
    echo "Please run: chezmoi apply" >&2
    exit 1
fi

# gopass: aqua's (once installed and configured), else the bootstrap profile's.
gopass_works() { command -v gopass >/dev/null 2>&1 && gopass --version >/dev/null 2>&1; }
if ! gopass_works && [[ -x "$bootstrap_profile/bin/gopass" ]]; then
    export PATH="$bootstrap_profile/bin:$PATH"
fi
if ! gopass_works; then
    if ! command -v nix >/dev/null 2>&1 &&
        [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        # shellcheck disable=SC1091
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    rev="${NIXPKGS_BOOTSTRAP_REV:-}"
    if [[ ! "$rev" =~ ^[0-9a-f]{40}$ ]] || ! command -v nix >/dev/null 2>&1; then
        echo "⚠ gopass not installed (and no Nix to bootstrap it)" >&2
        echo "Please run: chezmoi apply" >&2
        exit 1
    fi
    echo ":: Installing gopass with nix (isolated bootstrap profile)..."
    mkdir -p "$(dirname "$bootstrap_profile")"
    nix --extra-experimental-features 'nix-command flakes' profile add \
        --profile "$bootstrap_profile" "github:NixOS/nixpkgs/${rev}#gopass" >/dev/null
    export PATH="$bootstrap_profile/bin:$PATH"
    gopass_works || {
        echo "✗ gopass still unavailable after the bootstrap install" >&2
        exit 1
    }
fi

# chezmoi writes the full ~/.config/gopass/config (private_dot_config/gopass/
# config.tmpl), but not before it has read the source state. Seed the fields
# gopass needs to find and decrypt the store; the managed file replaces it.
if [[ ! -f "$config" ]]; then
    mkdir -p "$(dirname "$config")"
    (
        umask 077
        cat >"$config" <<EOF
# Seeded by .bootstrap/setup-gopass-store.sh; replaced by chezmoi on apply.
[mounts]
	crypto = age
	path = ${store_dir}

[mounts.root]
	source_url = ${repo}

[age]
	ssh-key-path = ${HOME}/.ssh/main
	sshkeys = true
EOF
    )
fi

verify_store() {
    local first_password

    if ! gopass ls >/dev/null 2>&1; then
        echo "✗ gopass cannot read the password store" >&2
        return 1
    fi

    first_password="$(gopass ls --flat 2>/dev/null | head -n 1 || true)"
    if [[ -n "$first_password" ]] && ! gopass show "$first_password" >/dev/null 2>&1; then
        echo "✗ gopass cannot decrypt '$first_password' with ~/.ssh/main" >&2
        return 1
    fi
}

if [[ -d "$store_dir/.git" ]]; then
    verify_store || exit 1
    echo "✓ gopass store already exists and is readable"
    exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Clone gopass password store from Git"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will clone your password store from:"
echo "  $repo"
echo ""
echo "Note: gopass decrypts it with ~/.ssh/main (age, SSH key)"
echo ""

confirm="${GOPASS_STORE_CLONE:-}"
if [[ -z "$confirm" ]]; then
    if ! read -r -p "Clone password store now? (yes/no): " confirm; then
        echo ""
        echo "Cancelled"
        exit 0
    fi
fi

if [[ "$confirm" != "yes" ]]; then
    echo ""
    echo "Skipped. You can clone later with:"
    printf '  gopass clone %q\n' "$repo"
    echo ""
    exit 0
fi

# Move age native identities out of the active config path if they exist.
# gopass is configured to use ~/.ssh/main, but existing identity material should
# never be deleted by bootstrap automation.
age_dir="${XDG_CONFIG_HOME:-$HOME/.config}/gopass/age"
if [[ -d "$age_dir" ]]; then
    backup_dir="${age_dir}.backup.$(date +%Y%m%d%H%M%S)"
    echo "Backing up age identities directory to: $backup_dir"
    mv "$age_dir" "$backup_dir"
    chmod 700 "$backup_dir" 2>/dev/null || true
fi

echo ""
echo "Cloning password store..."
# --check-keys=false: Don't generate new keys, use existing SSH key
gopass clone --check-keys=false "$repo"

echo ""
echo "✓ gopass password store cloned successfully"
echo ""

# Verify the clone before allowing run_onchange to record success.
echo "Verifying decryption..."
verify_store || exit 1
echo "✓ Store is readable (using SSH key: ~/.ssh/main)"
