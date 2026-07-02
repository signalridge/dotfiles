#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

command -v chezmoi >/dev/null 2>&1 || {
    echo "SKIP: chezmoi not found" >&2
    exit 0
}

default_data='{"useEncryption":false,"headless":false}'
headless_data='{"useEncryption":true,"headless":true}'
darwin_data='{"chezmoi":{"os":"darwin"},"useEncryption":false,"headless":false}'
linux_data='{"chezmoi":{"os":"linux"},"useEncryption":false,"headless":false}'

out="$(chezmoi ignored --source "$ROOT" --override-data "$default_data")"
headless_out="$(chezmoi ignored --source "$ROOT" --override-data "$headless_data")"
darwin_out="$(chezmoi ignored --source "$ROOT" --override-data "$darwin_data")"
darwin_managed_scripts="$(chezmoi managed --source "$ROOT" --include=scripts --override-data "$darwin_data")"
linux_out="$(chezmoi ignored --source "$ROOT" --override-data "$linux_data")"
linux_managed_scripts="$(chezmoi managed --source "$ROOT" --include=scripts --override-data "$linux_data")"

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

require_entry_in() {
    local haystack="$1"
    local expected="$2"
    local label="$3"
    if ! printf '%s\n' "$haystack" | grep -qxF "$expected"; then
        echo "expected entry not found in $label: $expected" >&2
        echo "--- $label ---" >&2
        printf '%s\n' "$haystack" >&2
        exit 1
    fi
}

forbid_entry_in() {
    local haystack="$1"
    local unexpected="$2"
    local label="$3"
    if printf '%s\n' "$haystack" | grep -qxF "$unexpected"; then
        echo "unexpected entry found in $label: $unexpected" >&2
        echo "--- $label ---" >&2
        printf '%s\n' "$haystack" >&2
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

# Platform-specific scripts should be selected by .chezmoiignore, not by
# rendering/running scripts that only print a platform skip message.
forbid_entry_in "$darwin_out" ".chezmoiscripts/09_install-paperlib.sh" "darwin ignored"
forbid_entry_in "$darwin_out" ".chezmoiscripts/17_load-launch-agents.sh" "darwin ignored"
require_entry_in "$darwin_out" ".chezmoiscripts/19_load-systemd-user-units.sh" "darwin ignored"
require_entry_in "$darwin_managed_scripts" ".chezmoiscripts/09_install-paperlib.sh" "darwin managed scripts"
require_entry_in "$darwin_managed_scripts" ".chezmoiscripts/17_load-launch-agents.sh" "darwin managed scripts"
forbid_entry_in "$darwin_managed_scripts" ".chezmoiscripts/19_load-systemd-user-units.sh" "darwin managed scripts"

require_entry_in "$linux_out" ".chezmoiscripts/02_init.sh" "linux ignored"
require_entry_in "$linux_out" ".chezmoiscripts/09_install-paperlib.sh" "linux ignored"
require_entry_in "$linux_out" ".chezmoiscripts/10_update_homebrew_packages.sh" "linux ignored"
require_entry_in "$linux_out" ".chezmoiscripts/17_load-launch-agents.sh" "linux ignored"
forbid_entry_in "$linux_out" ".chezmoiscripts/19_load-systemd-user-units.sh" "linux ignored"
forbid_entry_in "$linux_managed_scripts" ".chezmoiscripts/02_init.sh" "linux managed scripts"
forbid_entry_in "$linux_managed_scripts" ".chezmoiscripts/09_install-paperlib.sh" "linux managed scripts"
forbid_entry_in "$linux_managed_scripts" ".chezmoiscripts/10_update_homebrew_packages.sh" "linux managed scripts"
forbid_entry_in "$linux_managed_scripts" ".chezmoiscripts/17_load-launch-agents.sh" "linux managed scripts"
require_entry_in "$linux_managed_scripts" ".chezmoiscripts/19_load-systemd-user-units.sh" "linux managed scripts"

out="$headless_out"
require_line ".chezmoiscripts/09_install-paperlib.sh"
require_line ".chezmoiscripts/17_load-launch-agents.sh"
# On Linux, the OS-specific ignore rules may collapse the child LaunchAgent
# path into the ignored parent Library directory.
require_any_line "Library/LaunchAgents/com.signalridge.qmk-hid-host.plist" "Library"
require_line ".config/hammerspoon"

echo "test_chezmoiignore: OK"
