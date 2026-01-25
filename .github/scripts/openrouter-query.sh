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
: "${OPENROUTER_MODEL:=mistralai/devstral-2512:free}"
: "${OPENROUTER_REFERER:=https://github.com}"
: "${MAX_RETRIES:=3}"

# Debug: show model being used
echo "Using model: $OPENROUTER_MODEL" >&2

# Read prompt from stdin
prompt=$(cat)
escaped_prompt=$(echo "$prompt" | jq -Rs .)

attempt=0
while ((attempt < MAX_RETRIES)); do
    attempt=$((attempt + 1))

    # Make API request, capture both body and HTTP status
    tmpfile=$(mktemp)
    if http_code=$(curl -s --max-time 120 \
        -w "%{http_code}" \
        -o "$tmpfile" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        -H "Content-Type: application/json" \
        -H "HTTP-Referer: $OPENROUTER_REFERER" \
        -d "{
          \"model\": \"$OPENROUTER_MODEL\",
          \"messages\": [{\"role\": \"user\", \"content\": $escaped_prompt}]
        }" \
        https://openrouter.ai/api/v1/chat/completions 2>&1); then

        body=$(cat "$tmpfile")
        rm -f "$tmpfile"

        # Check HTTP status
        if [[ "$http_code" == "200" ]]; then
            content=$(echo "$body" | jq -r '.choices[0].message.content // empty')
            if [[ -n "$content" ]]; then
                echo "$content"
                exit 0
            fi
            echo "Error: Empty content in response" >&2
            echo "$body" | jq . >&2
            exit 1
        elif [[ "$http_code" == "429" ]]; then
            echo "Rate limited (429), waiting before retry ($attempt/$MAX_RETRIES)..." >&2
            sleep $((attempt * 15))
            continue
        elif [[ "$http_code" =~ ^5 ]]; then
            echo "Server error ($http_code), retrying ($attempt/$MAX_RETRIES)..." >&2
            sleep $((attempt * 5))
            continue
        else
            echo "HTTP error $http_code:" >&2
            echo "$body" | jq . 2>/dev/null || echo "$body" >&2
            exit 1
        fi
    else
        curl_exit=$?
        rm -f "$tmpfile"
        echo "Network error (curl exit $curl_exit), retrying ($attempt/$MAX_RETRIES)..." >&2
        sleep $((attempt * 5))
    fi
done

echo "Error: Failed after $MAX_RETRIES attempts" >&2
exit 1
