#!/bin/bash
# Update Claude plugin metadata from wshobson/agents
# - Scans plugins and preserves existing keywords
# - Generates prompt for AI to fill missing keywords
# - Applies AI-generated keywords back to plugins.json
set -euo pipefail

REPO_DIR="${REPO_DIR:-/tmp/wshobson-agents}"
MARKETPLACE="$REPO_DIR/.claude-plugin/marketplace.json"
OUTPUT="${OUTPUT:-/tmp/plugins.json}"

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

# Generate prompt for missing keywords (output to stdout for GitHub Actions)
generate_prompt() {
    local missing_count
    missing_count=$(jq '[.[] | select(.keywords == [])] | length' "$OUTPUT")

    if [[ "$missing_count" -eq 0 ]]; then
        echo "No plugins missing keywords" >&2
        return 0
    fi

    echo "Plugins missing keywords: $missing_count" >&2

    # Generate prompt
    cat <<'PROMPT'
Generate keywords for each plugin. Return ONLY a valid JSON object where keys are plugin names and values are arrays of 5-8 lowercase keywords.

Example output:
{"plugin-name": ["keyword1", "keyword2", "keyword3", "keyword4", "keyword5"]}

Plugins:
PROMPT

    jq -r '.[] | select(.keywords == []) | "- \(.name): \(.description)"' "$OUTPUT"
}

# Apply AI-generated keywords from JSON response
apply_keywords() {
    local ai_response="$1"

    # Try to extract JSON from response (handle markdown code blocks)
    local json_data
    json_data=$(echo "$ai_response" | sed -n '/^{/,/^}/p' | head -1)
    if [[ -z "$json_data" ]]; then
        # Try extracting from code block
        json_data=$(echo "$ai_response" | sed -n '/```json/,/```/p' | sed '1d;$d')
    fi
    if [[ -z "$json_data" ]]; then
        json_data=$(echo "$ai_response" | grep -o '{.*}' | head -1)
    fi

    if ! echo "$json_data" | jq -e 'type == "object"' &>/dev/null; then
        echo "Error: Could not parse AI response as JSON object" >&2
        echo "Response was: $ai_response" >&2
        return 1
    fi

    # Apply each plugin's keywords
    for name in $(echo "$json_data" | jq -r 'keys[]'); do
        local kw
        kw=$(echo "$json_data" | jq -c --arg n "$name" '.[$n]')
        if echo "$kw" | jq -e 'type=="array" and length > 0' &>/dev/null; then
            jq --arg n "$name" --argjson k "$kw" \
                'map(if .name == $n then .keywords = $k else . end)' "$OUTPUT" >"${OUTPUT}.tmp"
            mv "${OUTPUT}.tmp" "$OUTPUT"
            echo "Applied keywords for: $name"
        fi
    done
}

# Main command dispatcher
case "${1:-scan}" in
scan)
    # Scan plugins from marketplace.json
    scan_plugins >"$OUTPUT"
    echo "Output: $OUTPUT ($(jq length "$OUTPUT") plugins)" >&2
    ;;
prompt)
    # Output the AI prompt (for use in GitHub Actions)
    generate_prompt
    ;;
apply)
    # Apply AI response (pass response as $2 or via stdin)
    if [[ -n "${2:-}" ]]; then
        apply_keywords "$2"
    else
        apply_keywords "$(cat)"
    fi
    ;;
*)
    echo "Usage: $0 {scan|prompt|apply}" >&2
    exit 1
    ;;
esac
