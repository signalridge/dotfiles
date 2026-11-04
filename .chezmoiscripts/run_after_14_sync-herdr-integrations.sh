#!/bin/bash

set -euo pipefail

# Install/update Herdr agent lifecycle integrations. Codex hook configuration is
# kept in ~/.codex/config.toml, so remove only Herdr's duplicate standalone hooks
# while preserving hooks.json entries installed by other integrations (e.g. Rex).

echo ":: [14] Syncing Herdr agent integrations"

PATH="$HOME/.nix-profile/bin:/opt/homebrew/bin:$HOME/.local/share/aquaproj-aqua/bin:$PATH"

if ! command -v herdr >/dev/null 2>&1; then
    echo "    Skipped (herdr not found)"
    exit 0
fi

install_integration() {
    local name="$1"

    if herdr integration install "$name" >/dev/null 2>&1; then
        echo "    Integration installed/updated: $name"
    else
        echo "    Error: failed to install/update Herdr integration: $name" >&2
        return 1
    fi
}

install_integration "codex"

# Codex hooks are managed inline in dot_codex/modify_private_config.toml.tmpl.
# Herdr also writes a legacy hooks.json, which may contain other integrations.
# Remove only recognized Herdr hooks; refuse to rewrite malformed configuration.
codex_hooks="$HOME/.codex/hooks.json"
if [[ -f "$codex_hooks" ]]; then
    if ! command -v jq >/dev/null 2>&1; then
        echo "    Error: jq is required to verify $codex_hooks before removal" >&2
        exit 1
    fi
    # Use a sibling temporary file so replacement is atomic and failed validation
    # leaves the original untouched. mktemp keeps hook configuration private.
    hooks_tmp="$(mktemp "${codex_hooks}.XXXXXX")"
    trap 'rm -f "$hooks_tmp"' EXIT
    # Herdr emits session, working, and idle lifecycle commands here.
    herdr_command_prefix="bash '$HOME/.codex/herdr-agent-state.sh'"
    if ! jq -s --arg prefix "$herdr_command_prefix" '
        def is_herdr:
            (keys == ["command", "timeout", "type"])
            and .type == "command"
            and .timeout == 10
            and (.command == ($prefix + " session")
              or .command == ($prefix + " working")
              or .command == ($prefix + " idle"));
        if length != 1 then error("expected one JSON document") else .[0] end
        | if (type == "object"
            and (.hooks | type == "object")
            and all(.hooks[];
                type == "array" and all(.[];
                    type == "object"
                    and (.hooks | type == "array" and all(.[]; type == "object"))
                )
            )) then . else error("invalid hooks configuration") end
        | .hooks |= with_entries(
            if any(.value[].hooks[]; is_herdr) then
                .value |= map(
                    if any(.hooks[]; is_herdr) then
                        .hooks |= map(select(is_herdr | not))
                        | select(.hooks | length > 0)
                    else . end
                )
                | select(.value | length > 0)
            else . end
        )
    ' "$codex_hooks" >"$hooks_tmp" 2>/dev/null; then
        echo "    Error: preserving $codex_hooks because it contains invalid JSON or an invalid hooks structure" >&2
        exit 1
    fi
    if jq -e 'keys == ["hooks"] and .hooks == {}' "$hooks_tmp" >/dev/null; then
        rm -f "$codex_hooks"
    elif ! jq -se '.[0] == .[1]' "$codex_hooks" "$hooks_tmp" >/dev/null; then
        mv -f "$hooks_tmp" "$codex_hooks"
    fi
    rm -f "$hooks_tmp"
    trap - EXIT
fi

install_integration "claude"

# pi: Herdr's bundled integration is the only reporter for the herdr:pi
# source. The retired @signalridge/pi-herdr-state package is removed by
# run_after_19_remove-legacy-pi-sources.sh so the two never report together.
install_integration "pi"
