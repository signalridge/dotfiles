#!/bin/bash

set -euo pipefail

# Sync Claude Code plugin bundles that provide official external integrations.

echo ":: [11] Syncing Claude Code integration plugins"

PATH="$HOME/.nix-profile/bin:/opt/homebrew/bin:$HOME/.local/share/aquaproj-aqua/bin:$PATH"
claude_cmd="$(command -v claude 2>/dev/null || true)"

if [[ -z "$claude_cmd" ]]; then
    echo "    Skipped (claude not found)"
    exit 0
fi

if ! command -v jq &>/dev/null; then
    echo "    Skipped (jq not found)"
    exit 0
fi

MARKETPLACES_JSON="$HOME/.claude/plugins/known_marketplaces.json"
INSTALLED_PLUGINS_JSON="$HOME/.claude/plugins/installed_plugins.json"

ensure_marketplace() {
    local name="$1"
    local source="$2"

    if [[ -f "$MARKETPLACES_JSON" ]] && jq -e --arg n "$name" '.[$n]' "$MARKETPLACES_JSON" >/dev/null 2>&1; then
        echo "    Marketplace exists: $name"
        return 0
    fi

    "$claude_cmd" plugin marketplace add "$source"
}

ensure_plugin() {
    local plugin="$1"

    if [[ -f "$INSTALLED_PLUGINS_JSON" ]] && jq -e --arg p "$plugin" '.plugins[$p] | length > 0' "$INSTALLED_PLUGINS_JSON" >/dev/null 2>&1; then
        echo "    Plugin exists: $plugin"
        return 0
    fi

    "$claude_cmd" plugin install "$plugin"
}

ensure_marketplace "claude-plugins-official" "anthropics/claude-plugins-official"
ensure_marketplace "notion-plugin-marketplace" "makenotion/claude-code-notion-plugin"

ensure_plugin "slack@claude-plugins-official"
ensure_plugin "notion-workspace-plugin@notion-plugin-marketplace"
