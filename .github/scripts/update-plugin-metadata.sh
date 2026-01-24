#!/bin/bash
# Update Claude plugin metadata from wshobson/agents
# - Scans directories for commands/agents/skills file paths
# - Preserves existing keywords from local config
# - Uses Claude API to generate missing keywords
set -euo pipefail

REPO_DIR="${1:-/tmp/wshobson-agents}"
MARKETPLACE="$REPO_DIR/.claude-plugin/marketplace.json"
OUTPUT="${2:-/tmp/plugins.json}"
EXISTING_YAML="${3:-}" # Optional: existing claude.yaml to preserve keywords

# Scan plugins and generate plugins.json (name, description, keywords)
scan_plugins() {
    jq -c '.plugins[]' "$MARKETPLACE" | while read -r plugin; do
        name=$(echo "$plugin" | jq -r '.name')
        desc=$(echo "$plugin" | jq -r '.description // ""')
        keywords=$(echo "$plugin" | jq -c '.keywords // []')
        jq -n --arg name "$name" --arg desc "$desc" --argjson kw "$keywords" \
            '{name:$name, description:$desc, keywords:$kw}'
    done | jq -s '.'
}

# Generate keywords for plugins missing them using Claude API
generate_keywords() {
    [[ -z "${ANTHROPIC_API_KEY:-}" ]] && return 0

    local missing
    missing=$(jq -r '.[] | select(.keywords == []) | .name' "$OUTPUT")
    [[ -z "$missing" ]] && return 0

    local desc readme response kw
    for name in $missing; do
        desc=$(jq -r --arg n "$name" '.[] | select(.name == $n) | .description // ""' "$OUTPUT")
        readme=$(head -50 "$REPO_DIR/plugins/$name/README.md" 2>/dev/null | tr '\n' ' ' | cut -c1-500 || echo "")

        response=$(curl -s https://api.anthropic.com/v1/messages \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -H "content-type: application/json" \
            -d "$(jq -n --arg d "$desc" --arg r "$readme" --arg n "$name" '{
                model: "claude-haiku-4-20250514",
                max_tokens: 100,
                messages: [{role: "user", content: "Generate 5-8 lowercase keywords for this plugin. Return ONLY a JSON array.\n\nPlugin: \($n)\nDescription: \($d)\nREADME: \($r)"}]
            }')")

        kw=$(echo "$response" | jq -r '.content[0].text' | grep -o '\[.*\]' | head -1)
        if [[ -n "$kw" ]] && echo "$kw" | jq -e '.' &>/dev/null; then
            jq --arg n "$name" --argjson k "$kw" 'map(if .name == $n then .keywords = $k else . end)' "$OUTPUT" >"${OUTPUT}.tmp"
            mv "${OUTPUT}.tmp" "$OUTPUT"
            echo "Generated keywords for: $name"
        fi
        sleep 0.3
    done
}

# Preserve existing keywords if new scan has empty keywords
preserve_existing_keywords() {
    [[ -z "$EXISTING_YAML" || ! -f "$EXISTING_YAML" ]] && return 0

    local existing_plugins
    existing_plugins=$(yq -o=json '.claude.wshobson.registry' "$EXISTING_YAML")

    # For each plugin with empty keywords, check if existing has keywords
    jq -r '.[] | select(.keywords == []) | .name' "$OUTPUT" | while read -r name; do
        local existing_kw
        existing_kw=$(echo "$existing_plugins" | jq -c --arg n "$name" '.[] | select(.name == $n) | .keywords // []')
        if [[ -n "$existing_kw" && "$existing_kw" != "[]" ]]; then
            jq --arg n "$name" --argjson k "$existing_kw" \
                'map(if .name == $n then .keywords = $k else . end)' "$OUTPUT" >"${OUTPUT}.tmp"
            mv "${OUTPUT}.tmp" "$OUTPUT"
            echo "Preserved keywords for: $name"
        fi
    done
}

# Main
scan_plugins >"$OUTPUT"
preserve_existing_keywords
generate_keywords
echo "Output: $OUTPUT ($(jq length "$OUTPUT") plugins)"
