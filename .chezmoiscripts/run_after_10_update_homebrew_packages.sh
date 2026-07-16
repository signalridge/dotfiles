#!/bin/bash

set -euo pipefail

# Periodic upgrade check (7-day interval)
# New packages are installed by nix-darwin (script 02)

LAST_UPDATE_FILE="$HOME/.cache/brew-last-update"
CURRENT_TIME=$(date +%s)
LAST_UPDATE=0
UPDATE_INTERVAL=$((7 * 86400)) # 7 days

mkdir -p "$(dirname "$LAST_UPDATE_FILE")"
if [[ -f "$LAST_UPDATE_FILE" ]]; then
    LAST_UPDATE_RAW="$(cat "$LAST_UPDATE_FILE" 2>/dev/null || true)"
    if [[ "$LAST_UPDATE_RAW" =~ ^[0-9]+$ ]]; then
        LAST_UPDATE="$LAST_UPDATE_RAW"
    fi
fi
DAYS_AGO=$(((CURRENT_TIME - LAST_UPDATE) / 86400))

echo ":: [10] Updating Homebrew packages"

# Ensure common Homebrew locations are discoverable in non-interactive shells.
PATH="/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"
brew_cmd="$(command -v brew 2>/dev/null || true)"
if [[ -z "$brew_cmd" ]]; then
    echo "    Skipped (brew not found)"
    exit 0
fi

if ((CURRENT_TIME - LAST_UPDATE > UPDATE_INTERVAL)); then
    echo "    Last update: ${DAYS_AGO} days ago, checking for updates..."
    "$brew_cmd" update

    outdated=$("$brew_cmd" outdated --greedy)
    if [[ -z "$outdated" ]]; then
        echo "    All packages up to date"
    else
        echo "    Upgrading outdated packages..."
        "$brew_cmd" upgrade --greedy
        "$brew_cmd" cleanup
    fi

    # Advance the interval only after the complete update succeeds. Otherwise a
    # failed upgrade/cleanup would suppress retries for another seven days.
    tmp_update_file="$(mktemp "${LAST_UPDATE_FILE}.XXXXXX")"
    printf '%s\n' "$CURRENT_TIME" >"$tmp_update_file"
    mv "$tmp_update_file" "$LAST_UPDATE_FILE"
else
    echo "    Skipped (last update: ${DAYS_AGO} days ago)"
fi
