#!/usr/bin/env bash
# chezmoi [hooks.read-source-state.pre] hook, registered by .chezmoi.toml.tmpl.
#
# WHY. chezmoi evaluates .chezmoiignore (and fixes the set of target files) when
# it reads the source state, before any run_before_ script. Several targets and
# templates depend on the gopass store (sing-box, openconnect-auto, ss-exit, the
# EasyTier role), so on a fresh machine, where scripts 01/06 restored the keys
# and cloned the store only mid-apply, the first apply left them out and a
# second apply was needed. This hook does that work before the source state is
# read, so one apply sees the store: Nix (00) -> keys (01) -> store (06), each
# step the same implementation the numbered scripts run.
#
# It runs before EVERY chezmoi command that reads the source state (apply,
# diff, managed, ...), so once a machine is ready it must be a near-free no-op
# (three file tests), and it must never invoke chezmoi itself (recursion).
#
# Usage: pre-source-state.sh <useEncryption> <keysRepository> <gopassRepository>
# Set DOTFILES_SKIP_BOOTSTRAP_HOOK=1 to bypass it.
set -euo pipefail

[[ "${1:-false}" == true ]] || exit 0
[[ -z "${DOTFILES_SKIP_BOOTSTRAP_HOOK:-}" ]] || exit 0
keys_repo="${2:-}"
gopass_repo="${3:-}"

store_dir="$HOME/.local/share/gopass/stores/root"
gopass_config="${XDG_CONFIG_HOME:-$HOME/.config}/gopass/config"
if [[ -f "$HOME/.ssh/main" && -d "$store_dir/.git" && -f "$gopass_config" ]]; then
    exit 0
fi

# The cold path prompts (sudo for Nix, the keys-backup password, GitHub device
# login, the clone confirmation). Without a terminal leave it to scripts 01/06,
# exactly as before this hook existed.
if [[ ! -t 0 ]] && ! { : </dev/tty; } 2>/dev/null; then
    echo ":: [hook] secrets not bootstrapped yet; no terminal, deferring to scripts 01/06" >&2
    exit 0
fi

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
versions="$(dirname "$here")/.chezmoidata/versions.yaml"
pin() {
    local value
    value="$(sed -n "s/^  $1: *//p" "$versions" | head -n 1)"
    value="${value//\"/}"
    [[ -n "$value" ]] || {
        echo "Error: pin '$1' not found in $versions" >&2
        exit 1
    }
    printf '%s\n' "$value"
}

echo ":: [hook] Bootstrapping secrets before chezmoi reads the source state"

# 1. Nix (bootstrap tools for step 2 come from it).
if ! command -v nix >/dev/null 2>&1 &&
    [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
if ! command -v nix >/dev/null 2>&1; then
    NIX_INSTALLER_VERSION="$(pin nixInstaller)"
    NIX_VERSION="$(pin nixVersion)"
    NIX_INSTALLER_SHA256_AARCH64_DARWIN="$(pin nixInstallerAarch64DarwinSha256)"
    NIX_INSTALLER_SHA256_AARCH64_LINUX="$(pin nixInstallerAarch64LinuxSha256)"
    NIX_INSTALLER_SHA256_X86_64_LINUX="$(pin nixInstallerX8664LinuxSha256)"
    export NIX_INSTALLER_VERSION NIX_VERSION NIX_INSTALLER_SHA256_AARCH64_DARWIN \
        NIX_INSTALLER_SHA256_AARCH64_LINUX NIX_INSTALLER_SHA256_X86_64_LINUX
    sh "$here/install-nix.sh"
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

NIXPKGS_BOOTSTRAP_REV="$(pin nixpkgsBootstrapRev)"
export NIXPKGS_BOOTSTRAP_REV

# 2. Keys (~/.ssh/main decrypts the store and chezmoi's encrypted files).
if [[ -n "$keys_repo" ]]; then
    KEYS_REPO="${KEYS_REPO:-$keys_repo}" bash "$here/restore-keys.sh"
fi

# 3. Password store.
if [[ -n "$gopass_repo" ]]; then
    bash "$here/setup-gopass-store.sh" "$gopass_repo"
fi
