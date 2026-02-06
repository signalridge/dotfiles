# shellcheck shell=bash
# Source nix environment if not already available.
if ! command -v nix &>/dev/null; then
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        # shellcheck disable=SC1091
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
fi
