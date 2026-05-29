#!/usr/bin/env bash
set -euo pipefail

AGE_BIN="$HOME/.nix-profile/bin/age"

# Isolated bootstrap profile. Kept strictly separate from the default profile
# (~/.nix-profile), which flakey-profile manages declaratively. flakey-profile
# installs packages in a representation the modern `nix profile` command does NOT
# track, so a bare `nix profile add` against the default profile rewrites its
# manifest from scratch and silently drops every flakey-installed package
# (tmux, wget, git, ...). Installing age here instead never touches that profile.
BOOTSTRAP_PROFILE="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/dotfiles-bootstrap"
BOOTSTRAP_AGE="$BOOTSTRAP_PROFILE/bin/age"

# Fast path: age managed by flakey-profile in the default profile (steady state).
if [[ -x "$AGE_BIN" ]]; then
    exec "$AGE_BIN" "$@"
fi

# Previously bootstrapped age (cold start, before the profile switch has run).
if [[ -x "$BOOTSTRAP_AGE" ]]; then
    exec "$BOOTSTRAP_AGE" "$@"
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

# Install age once into the ISOLATED bootstrap profile (never the default profile),
# then execute it. This bootstraps decryption on a cold device without clobbering
# the flakey-profile-managed default profile.
# `nix profile add --profile` does NOT create the parent dir (unlike the default
# profile), so ensure it exists first or the add fails on a cold device.
mkdir -p "$(dirname "$BOOTSTRAP_PROFILE")" 2>/dev/null || true
nix --extra-experimental-features 'nix-command flakes' profile add \
    --profile "$BOOTSTRAP_PROFILE" "nixpkgs#age" >/dev/null 2>&1 || true
if [[ -x "$BOOTSTRAP_AGE" ]]; then
    exec "$BOOTSTRAP_AGE" "$@"
fi

# Last-resort fallback: ephemeral run, no profile mutation.
exec nix --extra-experimental-features 'nix-command flakes' run "nixpkgs#age" -- "$@"
