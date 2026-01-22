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

# Install 1password-cli if not available (unfree license)
if ! command -v op &>/dev/null; then
    echo "📦 Installing 1password-cli..."
    NIXPKGS_ALLOW_UNFREE=1 nix --extra-experimental-features 'nix-command flakes' profile add nixpkgs#_1password-cli --impure
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

# Try 1Password CLI
if command -v op &>/dev/null; then
    # Check: service account token or has configured accounts (not just command success)
    if [[ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]] || [[ -n "$(op account list 2>/dev/null)" ]]; then
        echo "Fetching key from 1Password..."
        tmpfile=$(mktemp "$HOME/.ssh/key.XXXXXX")
        chmod 600 "$tmpfile"
        if op read "op://Personal/main/private key?ssh-format=openssh" 2>/dev/null | tr -d '\r' >"$tmpfile"; then
            mv "$tmpfile" "$KEY_FILE"
            op read "op://Personal/main/public key" >"$KEY_PUB"
            chmod 600 "$KEY_FILE"
            chmod 644 "$KEY_PUB"
            echo "✓ Key imported from 1Password"
            exit 0
        else
            rm -f "$tmpfile"
            echo "⚠ Failed to fetch from 1Password"
        fi
    fi
fi

# Try interactive login if op is available
if command -v op &>/dev/null; then
    echo ""
    echo "No 1Password session found. Would you like to sign in interactively? [y/N]"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Add account if none configured
        if [[ -z "$(op account list 2>/dev/null)" ]]; then
            echo "No account configured. Adding account..."
            op account add
        fi

        echo "Signing in to 1Password..."
        if eval "$(op signin)"; then
            echo "Fetching key from 1Password..."
            tmpfile=$(mktemp "$HOME/.ssh/key.XXXXXX")
            chmod 600 "$tmpfile"
            if op read "op://Personal/main/private key?ssh-format=openssh" | tr -d '\r' >"$tmpfile"; then
                mv "$tmpfile" "$KEY_FILE"
                op read "op://Personal/main/public key" >"$KEY_PUB"
                chmod 600 "$KEY_FILE"
                chmod 644 "$KEY_PUB"
                echo "✓ Key imported from 1Password"
                exit 0
            else
                rm -f "$tmpfile"
                echo "⚠ Failed to fetch from 1Password"
            fi
        else
            echo "⚠ 1Password sign in failed"
        fi
    fi
fi

# Manual setup required
echo ""
echo "Please set up your encryption key:"
echo ""
echo "  Option 1: Copy from another machine"
echo "    scp ~/.ssh/main ~/.ssh/main.pub $(whoami)@$(hostname):~/.ssh/"
echo ""
if [[ "$OSTYPE" == darwin* ]]; then
    echo "  Option 2: Enable 1Password desktop integration"
    echo "    1Password → Settings → Developer → CLI integration"
    echo ""
fi
echo "Then run: chezmoi apply"
echo ""
exit 1
