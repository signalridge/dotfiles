#!/bin/bash
# update-claude-providers.sh - Update Claude Code provider configs from official docs
# Usage:
#   ./update-claude-providers.sh prompt [provider]  # Generate Gemini prompt
#   ./update-claude-providers.sh apply              # Apply AI response (reads stdin)

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
CLAUDE_YAML="$REPO_ROOT/.chezmoidata/claude.yaml"

# Provider documentation URLs
declare -A PROVIDER_DOCS=(
    ["deepseek"]="https://api-docs.deepseek.com/guides/anthropic_api"
    ["kimi"]="https://platform.moonshot.cn/docs/guide/agent-support"
    ["glm"]="https://docs.bigmodel.cn/cn/guide/develop/claude"
    ["qwen"]="https://help.aliyun.com/zh/model-studio/claude-code"
    ["minimax"]="https://platform.minimax.io/docs/coding-plan/claude-code"
    ["doubao"]="https://www.volcengine.com/docs/82379/1928261"
)

# Generate prompt for Gemini
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

## Claude Code Environment Variables

Official env vars (from https://code.claude.com/docs/en/settings):

| Env Variable | YAML Field | Description |
|--------------|------------|-------------|
| ANTHROPIC_BASE_URL | base_url | API endpoint URL (required for third-party) |
| ANTHROPIC_MODEL | model | Default model ID |
| ANTHROPIC_SMALL_FAST_MODEL | small_model | Smaller/faster model for background tasks |
| ANTHROPIC_DEFAULT_HAIKU_MODEL | haiku_model | Model for Haiku tier |
| ANTHROPIC_DEFAULT_SONNET_MODEL | sonnet_model | Model for Sonnet tier |
| ANTHROPIC_DEFAULT_OPUS_MODEL | opus_model | Model for Opus tier |
| CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC | disable_nonessential_traffic | Disable telemetry (boolean) |

Provider-recommended (not official, but some providers suggest):

| Env Variable | YAML Field | Description |
|--------------|------------|-------------|
| API_TIMEOUT_MS | timeout_ms | API timeout in milliseconds (e.g. 600000 = 10min) |

## Model Tier Hierarchy (IMPORTANT)

Claude Code uses three model tiers that map to different capability levels:

| Tier | Purpose | Should map to |
|------|---------|---------------|
| haiku_model | Fast, cheap, simple tasks (syntax check, file search) | Provider's FASTEST/CHEAPEST model (e.g., flash, turbo, lite) |
| sonnet_model | Balanced, general coding tasks | Provider's BALANCED model (e.g., plus, standard, chat) |
| opus_model | Complex reasoning, difficult tasks | Provider's MOST POWERFUL model (e.g., max, pro, reasoner) |

## Rules
1. Extract values for the YAML fields listed above from each provider's documentation
2. Use exact model IDs and URLs as shown in the documentation
3. For small_model: use the provider's fast/cheap model (same as haiku tier)
4. For haiku_model/sonnet_model/opus_model: Map to appropriate tier based on model capabilities:
   - If provider has multiple models, map them to tiers by capability
   - If provider only has ONE model, use that model for ALL tiers
   - NEVER use the most powerful model for haiku (it should be fast/cheap)
5. For timeout_ms: include if documentation mentions timeout configuration
6. Set disable_nonessential_traffic to true if documentation recommends disabling telemetry
7. Return valid JSON array only
8. Only include fields that are explicitly mentioned or can be reasonably inferred from documentation

## Output format
```json
[
  {
    "provider": "provider_name",
    "config": {
      "base_url": "...",
      "model": "...",
      "small_model": "...",
      "timeout_ms": "600000",
      "haiku_model": "...",
      "sonnet_model": "...",
      "opus_model": "...",
      "disable_nonessential_traffic": true
    }
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
                    # Devstral has 256K context, no need to truncate aggressively
                    echo "$content" | head -2000 || true
                    echo '```'
                fi
            fi
            echo ""
        fi
    done
}

# Apply AI response to claude.yaml
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
        # Use awk to properly match balanced brackets
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

    # Apply each provider config
    echo "$json" | jq -c '.[]' | while read -r item; do
        local provider config
        provider=$(echo "$item" | jq -r '.provider')
        config=$(echo "$item" | jq -c '.config')

        echo "Updating: $provider"

        # Dynamically iterate over ALL fields in the config
        echo "$config" | jq -r 'to_entries[] | "\(.key)\t\(.value)"' | while IFS=$'\t' read -r field value; do
            if [[ -n "$value" && "$value" != "null" ]]; then
                # Handle boolean vs string values
                if [[ "$value" == "true" || "$value" == "false" ]]; then
                    yq -i ".claude.providers.$provider.$field = $value" "$CLAUDE_YAML"
                else
                    # Use strenv() to avoid explicit double quotes
                    VALUE="$value" yq -i ".claude.providers.$provider.$field = strenv(VALUE)" "$CLAUDE_YAML"
                fi
                echo "  $field = $value"
            fi
        done
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
