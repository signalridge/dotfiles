#!/usr/bin/env bash
# update-claude-providers.sh - Update Claude Code provider configs from official docs
# Usage:
#   ./update-claude-providers.sh prompt [provider]  # Generate AI prompt
#   ./update-claude-providers.sh apply              # Apply AI response (reads stdin)
#
# NOTE: This script only updates the 'providers' section (base_url, models).
#       The 'accounts' section is user-configured and should not be auto-updated.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
CLAUDE_YAML="$REPO_ROOT/.chezmoidata/claude.yaml"

# Provider documentation URLs
declare -A PROVIDER_DOCS=(
    ["deepseek"]="https://api-docs.deepseek.com/guides/anthropic_api"
    ["kimi"]="https://github.com/MoonshotAI/kimi-cli/blob/main/docs/en/configuration/providers.md"
    ["glm"]="https://docs.bigmodel.cn/cn/guide/develop/claude"
    ["qwen"]="https://help.aliyun.com/zh/model-studio/claude-code"
    ["minimax"]="https://platform.minimax.io/docs/coding-plan/claude-code"
    ["doubao"]="https://www.volcengine.com/docs/82379/1928261"
)

# Generate prompt for AI
generate_prompt() {
    local provider="${1:-all}"
    local providers=()

    if [[ "$provider" == "all" ]]; then
        providers=("${!PROVIDER_DOCS[@]}")
    else
        providers=("$provider")
    fi

    cat <<'HEADER'
You are a configuration extraction assistant. Extract Claude Code provider configuration from official documentation.

## Task

Extract the following information for each provider:
1. **base_url**: The API endpoint URL (without /v1 suffix)
2. **models**: List of available model IDs

## YAML Structure

The config uses this structure:
```yaml
claude:
  providers:
    provider_name:
      base_url: "https://api.example.com/anthropic"
      models:
        - model-id-1
        - model-id-2
```

## Rules
1. Extract base_url exactly as documented (remove /v1 or /v1/ suffix if present)
2. List ALL available model IDs mentioned in the documentation
3. Order models by capability: most powerful first, fastest/cheapest last
4. Return valid JSON array only

## Output format
```json
[
  {
    "provider": "provider_name",
    "base_url": "https://api.example.com/anthropic",
    "models": ["model-powerful", "model-balanced", "model-fast"]
  }
]
```

Extract configuration for the following providers:

HEADER

    for p in "${providers[@]}"; do
        local url="${PROVIDER_DOCS[$p]:-}"
        if [[ -n "$url" ]]; then
            echo "## $p"
            echo "Documentation: $url"
            # Include fetched content if available (from DOCS_JSON_FILE env var)
            if [[ -n "${DOCS_JSON_FILE:-}" && -f "$DOCS_JSON_FILE" ]]; then
                local content
                content=$(jq -r ".[\"$p\"].content // empty" "$DOCS_JSON_FILE" 2>/dev/null)
                if [[ -n "$content" ]]; then
                    echo ""
                    echo "Page content:"
                    echo '```'
                    echo "$content" | head -2000 || true
                    echo '```'
                fi
            fi
            echo ""
        fi
    done
}

# Apply AI response to claude.yaml
# Only updates providers section (base_url, models), not accounts
apply_response() {
    local response
    response=$(cat)

    # Extract JSON from response (handles markdown code blocks)
    local json
    # Try extracting from code block first
    if echo "$response" | grep -q '```json'; then
        json=$(echo "$response" | sed -n '/```json/,/```/p' | grep -v '```')
    elif echo "$response" | grep -q '```'; then
        json=$(echo "$response" | sed -n '/```/,/```/p' | grep -v '```')
    else
        # Try to extract raw JSON array (handles both compact and multiline)
        json=$(echo "$response" | awk '
            /\[/ { start=1; depth=0 }
            start {
                for(i=1; i<=length($0); i++) {
                    c = substr($0, i, 1)
                    if(c == "[") depth++
                    if(c == "]") depth--
                }
                print
                if(depth == 0 && start) exit
            }
        ')
    fi

    # Validate JSON
    if ! echo "$json" | jq -e '.' >/dev/null 2>&1; then
        echo "Error: Invalid JSON in AI response" >&2
        echo "Response was:" >&2
        echo "$response" >&2
        exit 1
    fi

    # Apply each provider config (only base_url and models)
    echo "$json" | jq -c '.[]' | while read -r item; do
        local provider base_url models
        provider=$(echo "$item" | jq -r '.provider')
        base_url=$(echo "$item" | jq -r '.base_url // empty')
        models=$(echo "$item" | jq -c '.models // []')

        echo "Updating: $provider"

        # Update base_url
        if [[ -n "$base_url" ]]; then
            BASE_URL="$base_url" yq -i ".claude.providers.$provider.base_url = strenv(BASE_URL)" "$CLAUDE_YAML"
            echo "  base_url = $base_url"
        fi

        # Update models array
        if [[ "$models" != "[]" ]]; then
            MODELS="$models" yq -i ".claude.providers.$provider.models = env(MODELS) | .claude.providers.$provider.models |= (. | fromjson)" "$CLAUDE_YAML"
            echo "  models = $models"
        fi
    done

    echo "Updated: $CLAUDE_YAML"
}

# Main
case "${1:-}" in
prompt)
    generate_prompt "${2:-all}"
    ;;
apply)
    apply_response
    ;;
*)
    echo "Usage: $0 prompt [provider|all]" >&2
    echo "       $0 apply < response.json" >&2
    exit 1
    ;;
esac
