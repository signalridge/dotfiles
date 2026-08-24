#!/bin/bash

set -euo pipefail

# Install/update Herdr agent lifecycle integrations. Codex hook configuration is
# kept in ~/.codex/config.toml, so remove the standalone hooks.json that Herdr's
# installer currently creates.

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

# Codex hooks are managed inline in dot_codex/modify_config.toml.tmpl. Herdr also
# writes a legacy hooks.json; remove it only when every command belongs to Herdr.
# Refuse to discard unrelated user hooks or malformed JSON.
codex_hooks="$HOME/.codex/hooks.json"
if [[ -f "$codex_hooks" ]]; then
    if ! command -v jq >/dev/null 2>&1; then
        echo "    Error: jq is required to verify $codex_hooks before removal" >&2
        exit 1
    fi
    expected_command="bash '$HOME/.codex/herdr-agent-state.sh' session"
    if ! jq -e --arg expected "$expected_command" '
        (keys == ["hooks"])
        and (.hooks | type == "object" and length > 0)
        and all(.hooks | to_entries[];
            (.value | type == "array" and length > 0)
            and all(.value[];
                type == "object"
                and (.hooks | type == "array" and length > 0)
                and all(.hooks[];
                    type == "object"
                    and .type == "command"
                    and .timeout == 10
                    and .command == $expected
                )
            )
        )
    ' "$codex_hooks" >/dev/null 2>&1; then
        echo "    Error: preserving $codex_hooks because it contains non-Herdr hooks or invalid JSON" >&2
        exit 1
    fi
    rm -f "$codex_hooks"
fi

install_integration "claude"

# pi: do NOT install Herdr's bundled integration. The repository-owned
# pi-herdr-state package is loaded directly by Pi and remains the only reporter;
# keeping the bundled hook absent prevents duplicate lifecycle updates.
if herdr integration uninstall pi >/dev/null 2>&1; then
    echo "    Integration uninstalled: pi (repository package is authoritative)"
fi
