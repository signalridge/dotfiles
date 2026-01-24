#!/bin/bash
# Setup encryption key before chezmoi can decrypt files
set -euo pipefail

echo ":: [01] Setting up encryption key"

# Source nix environment
if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Install age if not available (required for chezmoi to decrypt .age files)
if ! command -v age &>/dev/null; then
    echo "📦 Installing age..."
    nix --extra-experimental-features 'nix-command flakes' profile add nixpkgs#age
fi

# Install gopass if not available
if ! command -v gopass &>/dev/null; then
    echo "📦 Installing gopass..."
    nix --extra-experimental-features 'nix-command flakes' profile add nixpkgs#gopass
fi

KEY_FILE="$HOME/.ssh/main"
KEY_PUB="$HOME/.ssh/main.pub"

if [[ -f "$KEY_FILE" ]]; then
    echo "✓ Encryption key already exists: $KEY_FILE"
    exit 0
fi

echo "Encryption key not found: $KEY_FILE"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Try gopass
if command -v gopass &>/dev/null; then
    # Check if gopass is initialized (has a store)
    if gopass list &>/dev/null; then
        echo "Fetching key from gopass..."
        tmpfile=$(mktemp "$HOME/.ssh/key.XXXXXX")
        chmod 600 "$tmpfile"
        if gopass show main_keypair/private_key 2>/dev/null | tr -d '\r' >"$tmpfile"; then
            mv "$tmpfile" "$KEY_FILE"
            gopass show main_keypair/public_key >"$KEY_PUB"
            chmod 600 "$KEY_FILE"
            chmod 644 "$KEY_PUB"
            echo "✓ Key imported from gopass"
            exit 0
        else
            rm -f "$tmpfile"
            echo "⚠ Failed to fetch from gopass"
        fi
    fi
fi

# gopass not initialized - guide user to set it up
if command -v gopass &>/dev/null; then
    echo ""
    echo "gopass is installed but not initialized or key not found."
    echo ""
    echo "To set up gopass:"
    echo "  1. Import your GPG key: gpg --import <your-key>"
    echo "  2. Clone password store: gopass clone git@github.com:signalridge/password-store.git"
    echo ""
    echo "After setup, run: chezmoi apply"
    echo ""
    exit 1
fi

# Manual setup required
echo ""
echo "Please set up your encryption key:"
echo ""
echo "  Option 1: Copy from another machine"
echo "    scp ~/.ssh/main ~/.ssh/main.pub $(whoami)@$(hostname):~/.ssh/"
echo ""
echo "  Option 2: Set up gopass (recommended)"
echo "    1. Install: nix profile add nixpkgs#gopass"
echo "    2. Import GPG key: gpg --import <your-key>"
echo "    3. Clone: gopass clone git@github.com:signalridge/password-store.git"
echo ""
echo "Then run: chezmoi apply"
echo ""
exit 1
