#!/bin/bash

set -eufo pipefail

# Periodic upgrade check (7-day interval)
# New packages are installed by nix-darwin (script 02)

LAST_UPDATE_FILE="$HOME/.cache/brew-last-update"
CURRENT_TIME=$(date +%s)
LAST_UPDATE=0
UPDATE_INTERVAL=$((7 * 86400)) # 7 days

[[ -f "$LAST_UPDATE_FILE" ]] && LAST_UPDATE=$(cat "$LAST_UPDATE_FILE")
DAYS_AGO=$(((CURRENT_TIME - LAST_UPDATE) / 86400))

echo ":: [04] Updating Homebrew packages"

if ((CURRENT_TIME - LAST_UPDATE > UPDATE_INTERVAL)); then
    echo "    Last update: ${DAYS_AGO} days ago, checking for updates..."
    brew update
    echo "$CURRENT_TIME" >"$LAST_UPDATE_FILE"

    outdated=$(brew outdated --greedy)
    if [[ -z "$outdated" ]]; then
        echo "    All packages up to date"
    else
        echo "    Upgrading outdated packages..."
        brew upgrade --greedy
        brew cleanup
    fi
else
    echo "    Skipped (last update: ${DAYS_AGO} days ago)"
fi
