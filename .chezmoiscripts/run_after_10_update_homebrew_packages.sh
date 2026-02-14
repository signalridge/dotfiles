#!/bin/bash

set -euo pipefail

# Periodic upgrade check (7-day interval)
# New packages are installed by nix-darwin (script 02)

LAST_UPDATE_FILE="$HOME/.cache/brew-last-update"
CURRENT_TIME=$(date +%s)
LAST_UPDATE=0
UPDATE_INTERVAL=$((7 * 86400)) # 7 days

[[ -f "$LAST_UPDATE_FILE" ]] && LAST_UPDATE=$(cat "$LAST_UPDATE_FILE")
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
    echo "$CURRENT_TIME" >"$LAST_UPDATE_FILE"

    outdated=$("$brew_cmd" outdated --greedy)
    if [[ -z "$outdated" ]]; then
        echo "    All packages up to date"
    else
        echo "    Upgrading outdated packages..."
        "$brew_cmd" upgrade --greedy
        "$brew_cmd" cleanup
    fi
else
    echo "    Skipped (last update: ${DAYS_AGO} days ago)"
fi
