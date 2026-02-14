#!/usr/bin/env bash
set -euo pipefail

AGE_BIN="$HOME/.nix-profile/bin/age"

# Fast path: prefer profile-managed age binary.
if [[ -x "$AGE_BIN" ]]; then
    exec "$AGE_BIN" "$@"
fi

# Fallback to any age already in PATH.
if command -v age >/dev/null 2>&1; then
    exec "$(command -v age)" "$@"
fi

# Source nix environment if not already available.
if ! command -v nix >/dev/null 2>&1; then
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        # shellcheck disable=SC1091
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
fi

if ! command -v nix >/dev/null 2>&1; then
    echo "Error: age is not found and nix is unavailable" >&2
    exit 1
fi

# Install age once into user profile, then execute it.
nix --extra-experimental-features 'nix-command flakes' profile add "nixpkgs#age" >/dev/null
if [[ -x "$AGE_BIN" ]]; then
    exec "$AGE_BIN" "$@"
fi

# Last-resort fallback.
exec nix --extra-experimental-features 'nix-command flakes' run "nixpkgs#age" -- "$@"
