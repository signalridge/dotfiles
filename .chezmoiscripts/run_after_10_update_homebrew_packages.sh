#!/bin/bash

set -euo pipefail

# Periodic upgrade check (7-day interval)
# New packages are installed by nix-darwin (script 02)

LAST_UPDATE_FILE="$HOME/.cache/brew-last-update"
# Existence means the previous run left something un-upgraded. It shortens the
# interval so the leftovers are retried the next day instead of the next week,
# without paying for a full greedy pass on every single apply.
DEGRADED_FILE="$HOME/.cache/brew-update-degraded"
CURRENT_TIME=$(date +%s)
LAST_UPDATE=0
UPDATE_INTERVAL=$((7 * 86400)) # 7 days
if [[ -f "$DEGRADED_FILE" ]]; then
    UPDATE_INTERVAL=86400 # 1 day
fi

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

repair_missing_cask_apps() {
    local missing_casks

    # Homebrew's receipt still counts a cask as installed after its app is
    # deleted out-of-band. Repair those receipts before the normal upgrade so
    # only the affected casks need --force.
    missing_casks=$(
        "$brew_cmd" info --json=v2 --installed --cask 2>/dev/null |
            "$brew_cmd" ruby -rjson -e '
                missing = {}
                JSON.parse(STDIN.read).fetch("casks", []).each do |cask|
                  cask.fetch("artifacts", []).each do |artifact|
                    next unless artifact["app"].is_a?(Array)
                    target = artifact["target"]
                    next unless target.is_a?(String)
                    missing[cask["token"]] = true unless File.exist?(target)
                  end
                end
                missing.each_key { |token| puts token }
            ' 2>/dev/null || true
    )

    while IFS= read -r cask; do
        [[ -n "$cask" ]] || continue
        echo "    Repairing cask with missing app: $cask"
        if ! "$brew_cmd" reinstall --cask --force "$cask"; then
            echo "    Warning: could not repair $cask" >&2
            brew_step_failed=1
        fi
    done <<<"$missing_casks"
}

brew_step_failed=0

if ((CURRENT_TIME - LAST_UPDATE > UPDATE_INTERVAL)); then
    echo "    Last update: ${DAYS_AGO} days ago, checking for updates..."
    "$brew_cmd" update
    repair_missing_cask_apps

    outdated=$("$brew_cmd" outdated --greedy)
    if [[ -z "$outdated" ]]; then
        echo "    All packages up to date"
    else
        echo "    Upgrading outdated packages..."
        # Deliberately non-fatal. A cask whose artifact is a .pkg is installed
        # by `sudo /usr/sbin/installer`, and that prompt cannot be answered in
        # a non-interactive apply (displaylink 16.2 -> 17.0 hit exactly this).
        # Aborting here would gate every later script on one such cask forever,
        # so record the failure, warn, and let the apply finish.
        "$brew_cmd" upgrade --greedy || brew_step_failed=1
        "$brew_cmd" cleanup || brew_step_failed=1
    fi

    if ((brew_step_failed)); then
        echo "    Warning: some packages could not be upgraded; still outdated:" >&2
        "$brew_cmd" outdated --greedy 2>/dev/null | sed 's/^/          /' >&2 || true
        echo "    Upgrade these by hand - a pkg cask needs an interactive sudo:" >&2
        echo "          brew upgrade --cask <token>" >&2
        : >"$DEGRADED_FILE"
    else
        rm -f "$DEGRADED_FILE"
    fi

    # Always advance the timestamp: the retry cadence is carried by
    # DEGRADED_FILE above, so a stuck package shortens the interval instead of
    # re-running a full greedy upgrade on every apply.
    tmp_update_file="$(mktemp "${LAST_UPDATE_FILE}.XXXXXX")"
    printf '%s\n' "$CURRENT_TIME" >"$tmp_update_file"
    mv "$tmp_update_file" "$LAST_UPDATE_FILE"
else
    echo "    Skipped (last update: ${DAYS_AGO} days ago)"
fi
