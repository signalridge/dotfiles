#!/usr/bin/env bash
# update-claude-providers.sh - Update Claude/Codex provider configs from official docs
# Usage:
#   ./update-claude-providers.sh prompt [provider]  # Generate AI prompt
#   ./update-claude-providers.sh apply              # Apply AI response (reads stdin)
#
# NOTE: This script only updates the 'providers' section (base_url, models).
#       The 'accounts' section is user-configured and should not be auto-updated.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
CLAUDE_YAML="$REPO_ROOT/.chezmoidata/claude.yaml"
CODEX_YAML="$REPO_ROOT/.chezmoidata/codex.yaml"

# Provider documentation URLs (Claude)
declare -A CLAUDE_PROVIDER_DOCS=(
    ["deepseek"]="https://api-docs.deepseek.com/guides/anthropic_api"
    ["kimi"]="https://github.com/MoonshotAI/kimi-cli/blob/main/docs/en/configuration/providers.md"
    ["glm"]="https://docs.bigmodel.cn/cn/guide/develop/claude"
    ["qwen"]="https://help.aliyun.com/zh/model-studio/claude-code"
    ["minimax"]="https://platform.minimax.io/docs/coding-plan/claude-code"
    ["doubao"]="https://www.volcengine.com/docs/82379/1928261"
)

# Provider documentation URLs (Codex)
# Placeholder links: replace with provider-specific Codex docs later.
declare -A CODEX_PROVIDER_DOCS=(
    ["deepseek"]="TODO_CODEX_DOC_DEEPSEEK"
    ["kimi"]="TODO_CODEX_DOC_KIMI"
    ["glm"]="TODO_CODEX_DOC_GLM"
    ["qwen"]="TODO_CODEX_DOC_QWEN"
    ["minimax"]="TODO_CODEX_DOC_MINIMAX"
    ["doubao"]="TODO_CODEX_DOC_DOUBAO"
)

# Generate prompt for AI
generate_prompt() {
    local provider="${1:-all}"
    local providers=()

    if [[ "$provider" == "all" ]]; then
        providers=("${!CLAUDE_PROVIDER_DOCS[@]}")
    else
        providers=("$provider")
    fi

    cat <<'HEADER'
You are a configuration extraction assistant. Extract provider configuration for BOTH Claude Code and Codex CLI from official documentation.

## Task

For each provider, extract two independent configs:
1. **claude**: Anthropic-compatible endpoint + model IDs
2. **codex**: OpenAI-compatible endpoint + model IDs

## Output format

Return valid JSON array only:

```json
[
  {
    "provider": "provider_name",
    "claude": {
      "base_url": "https://...",
      "models": ["..."]
    },
    "codex": {
      "base_url": "https://...",
      "models": ["..."]
    }
  }
]
```

## Rules
1. Keep Claude/Codex values independent (do NOT copy one into another unless docs explicitly match).
2. Remove trailing `/v1` or `/v1/` from base_url if present.
3. List model IDs exactly as documented.
4. If one side is unavailable, set that side to an empty object (`{}`).

Extract configuration for the following providers:

HEADER

    for p in "${providers[@]}"; do
        local claude_url codex_url
        claude_url="${CLAUDE_PROVIDER_DOCS[$p]:-}"
        codex_url="${CODEX_PROVIDER_DOCS[$p]:-}"
        if [[ -n "$claude_url" || -n "$codex_url" ]]; then
            echo "## $p"
            echo "Claude docs: $claude_url"
            echo "Codex docs: $codex_url"

            if [[ -n "${DOCS_JSON_FILE:-}" && -f "$DOCS_JSON_FILE" ]]; then
                local claude_content codex_content
                claude_content=$(jq -r ".[\"$p\"].claude.content // empty" "$DOCS_JSON_FILE" 2>/dev/null)
                codex_content=$(jq -r ".[\"$p\"].codex.content // empty" "$DOCS_JSON_FILE" 2>/dev/null)

                if [[ -n "$claude_content" ]]; then
                    echo ""
                    echo "Claude page content:"
                    echo '```'
                    echo "$claude_content" | head -2000 || true
                    echo '```'
                fi

                if [[ -n "$codex_content" ]]; then
                    echo ""
                    echo "Codex page content:"
                    echo '```'
                    echo "$codex_content" | head -2000 || true
                    echo '```'
                fi
            fi
            echo ""
        fi
    done
}

apply_target() {
    local yaml_file="$1"
    local root_key="$2"
    local provider="$3"
    local base_url="$4"
    local models_json="$5"

    [[ -f "$yaml_file" ]] || return 0

    if ! yq -e ".${root_key}.providers.${provider}" "$yaml_file" >/dev/null 2>&1; then
        return 0
    fi

    if [[ -n "$base_url" ]]; then
        BASE_URL="$base_url" yq -i ".${root_key}.providers.${provider}.base_url = strenv(BASE_URL)" "$yaml_file"
        echo "  ${root_key}.base_url = $base_url"
    fi

    if [[ "$models_json" != "[]" ]]; then
        local tmpfile
        tmpfile=$(mktemp)
        echo "$models_json" | yq -p json -o yaml >"$tmpfile"
        yq -i ".${root_key}.providers.${provider}.models = load(\"$tmpfile\")" "$yaml_file"
        rm -f "$tmpfile"
        echo "  ${root_key}.models = $models_json"
    fi
}

# Apply AI response to claude.yaml / codex.yaml
apply_response() {
    local response
    response=$(cat)

    # Extract JSON from response (handles markdown code blocks)
    local json
    if echo "$response" | grep -q '```json'; then
        json=$(echo "$response" | sed -n '/```json/,/```/p' | grep -v '```')
    elif echo "$response" | grep -q '```'; then
        json=$(echo "$response" | sed -n '/```/,/```/p' | grep -v '```')
    else
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

    if ! echo "$json" | jq -e '.' >/dev/null 2>&1; then
        echo "Error: Invalid JSON in AI response" >&2
        echo "Response was:" >&2
        echo "$response" >&2
        exit 1
    fi

    echo "$json" | jq -c '.[]' | while read -r item; do
        local provider
        provider=$(echo "$item" | jq -r '.provider')

        local claude_base_url claude_models codex_base_url codex_models
        claude_base_url=$(echo "$item" | jq -r '.claude.base_url // empty')
        claude_models=$(echo "$item" | jq -c '.claude.models // []')
        codex_base_url=$(echo "$item" | jq -r '.codex.base_url // empty')
        codex_models=$(echo "$item" | jq -c '.codex.models // []')

        echo "Updating: $provider"
        apply_target "$CLAUDE_YAML" "claude" "$provider" "$claude_base_url" "$claude_models"
        apply_target "$CODEX_YAML" "codex" "$provider" "$codex_base_url" "$codex_models"
    done

    echo "Updated: $CLAUDE_YAML"
    if [[ -f "$CODEX_YAML" ]]; then
        echo "Updated: $CODEX_YAML"
    fi
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
