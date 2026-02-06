#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

command -v chezmoi >/dev/null 2>&1 || {
    echo "SKIP: chezmoi not found" >&2
    exit 0
}

out="$(chezmoi ignored --source "$ROOT" --override-data '{"useEncryption":false,"headless":false}')"

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

# Always ignored (repo-only content).
require_line "docs"
require_line "tests"
forbid_line ".claude"

# When encryption is disabled, key-related scripts and targets must be ignored.
require_line ".chezmoiscripts/01_setup-encryption-key.sh"
require_line ".chezmoiscripts/04_setup-gopass.sh"
require_line ".ssh/config"

echo "test_chezmoiignore: OK"
