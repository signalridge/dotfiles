#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

command -v chezmoi >/dev/null 2>&1 || {
    echo "SKIP: chezmoi not found" >&2
    exit 0
}

out="$(chezmoi ignored --source "$ROOT" --override-data '{"useEncryption":false,"headless":false}')"
headless_out="$(chezmoi ignored --source "$ROOT" --override-data '{"useEncryption":true,"headless":true}')"
managed_scripts="$(chezmoi managed --source "$ROOT" --include=scripts)"
chezmoi_os="$(chezmoi execute-template --source "$ROOT" '{{ .chezmoi.os }}')"

require_line() {
    local expected="$1"
    if ! printf '%s\n' "$out" | grep -qxF "$expected"; then
        echo "expected ignored entry not found: $expected" >&2
        echo "--- ignored output ---" >&2
        printf '%s\n' "$out" >&2
        exit 1
    fi
}

forbid_line() {
    local unexpected="$1"
    if printf '%s\n' "$out" | grep -qxF "$unexpected"; then
        echo "unexpected ignored entry found: $unexpected" >&2
        echo "--- ignored output ---" >&2
        printf '%s\n' "$out" >&2
        exit 1
    fi
}

require_any_line() {
    local expected_a="$1"
    local expected_b="$2"
    if printf '%s\n' "$out" | grep -qxF "$expected_a"; then
        return 0
    fi
    if printf '%s\n' "$out" | grep -qxF "$expected_b"; then
        return 0
    fi
    echo "expected ignored entry not found: $expected_a or $expected_b" >&2
    echo "--- ignored output ---" >&2
    printf '%s\n' "$out" >&2
    exit 1
}

require_managed_script() {
    local expected="$1"
    if ! printf '%s\n' "$managed_scripts" | grep -qxF "$expected"; then
        echo "expected managed script not found: $expected" >&2
        echo "--- managed scripts ---" >&2
        printf '%s\n' "$managed_scripts" >&2
        exit 1
    fi
}

forbid_managed_script() {
    local unexpected="$1"
    if printf '%s\n' "$managed_scripts" | grep -qxF "$unexpected"; then
        echo "unexpected managed script found: $unexpected" >&2
        echo "--- managed scripts ---" >&2
        printf '%s\n' "$managed_scripts" >&2
        exit 1
    fi
}

# Always ignored (repo-only content).
require_line "docs"
require_line "tests"
forbid_line ".claude"

# When encryption is disabled, key-related scripts and targets must be ignored.
require_line ".chezmoiscripts/01_setup-encryption-key.sh"
require_line ".chezmoiscripts/06_setup-gopass.sh"
# Chezmoi may report source entries as either target-style or template/encrypted names.
require_any_line ".ssh/config" ".ssh/config.tmpl.age"

if [[ "$chezmoi_os" == "darwin" ]]; then
    require_line ".chezmoiscripts/15_load-systemd-user-units.sh"
    forbid_managed_script ".chezmoiscripts/15_load-systemd-user-units.sh"
else
    forbid_line ".chezmoiscripts/15_load-systemd-user-units.sh"
    require_managed_script ".chezmoiscripts/15_load-systemd-user-units.sh"
fi

out="$headless_out"
require_line ".chezmoiscripts/09_install-paperlib.sh"
require_line ".chezmoiscripts/13_load-launch-agents.sh"
# On Linux, the OS-specific ignore rules may collapse the child LaunchAgent
# path into the ignored parent Library directory.
require_any_line "Library/LaunchAgents/com.signalridge.qmk-hid-host.plist" "Library"
require_line ".config/hammerspoon"

echo "test_chezmoiignore: OK"
