#!/bin/bash
# openrouter-query.sh - Query OpenRouter API with retry logic
# Usage: ./openrouter-query.sh < prompt.txt > response.txt
#
# Environment variables:
#   OPENROUTER_API_KEY - Required: API key for OpenRouter
#   OPENROUTER_MODEL   - Optional: Model ID (default: deepseek/deepseek-chat-v3-0324:free)
#   OPENROUTER_REFERER - Optional: HTTP Referer header
#   MAX_RETRIES        - Optional: Max retry attempts (default: 3)

set -euo pipefail

: "${OPENROUTER_API_KEY:?OPENROUTER_API_KEY is required}"
: "${OPENROUTER_MODEL:=deepseek/deepseek-chat-v3-0324:free}"
: "${OPENROUTER_REFERER:=https://github.com}"
: "${MAX_RETRIES:=3}"

# Read prompt from stdin
prompt=$(cat)
escaped_prompt=$(echo "$prompt" | jq -Rs .)

attempt=0
while ((attempt < MAX_RETRIES)); do
    attempt=$((attempt + 1))

    # Make API request with timeout and fail on HTTP errors
    if response=$(curl -sf --max-time 120 https://openrouter.ai/api/v1/chat/completions \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        -H "Content-Type: application/json" \
        -H "HTTP-Referer: $OPENROUTER_REFERER" \
        -d "{
          \"model\": \"$OPENROUTER_MODEL\",
          \"messages\": [{\"role\": \"user\", \"content\": $escaped_prompt}]
        }" 2>/dev/null); then

        # Extract content from response
        content=$(echo "$response" | jq -r '.choices[0].message.content // empty')

        if [[ -n "$content" ]]; then
            echo "$content"
            exit 0
        fi

        # Check for rate limit error
        error=$(echo "$response" | jq -r '.error.message // empty')
        if [[ "$error" == *"rate"* || "$error" == *"limit"* ]]; then
            echo "Rate limited, waiting before retry ($attempt/$MAX_RETRIES)..." >&2
            sleep $((attempt * 10))
            continue
        fi

        echo "Error: Empty content in response" >&2
        echo "$response" | jq . >&2
        exit 1
    else
        echo "Network error, retrying ($attempt/$MAX_RETRIES)..." >&2
        sleep $((attempt * 5))
    fi
done

echo "Error: Failed after $MAX_RETRIES attempts" >&2
exit 1
