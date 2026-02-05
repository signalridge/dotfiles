#!/usr/bin/env bash
# llm-query.sh - Query LLM API with retry logic
# Usage: ./llm-query.sh < prompt.txt > response.txt
#
# Environment variables:
#   LLM_API_KEY   - Required: API key
#   LLM_API_URL   - Optional: API endpoint (default: https://na.wanxiaot.com/v1/chat/completions)
#   LLM_MODEL     - Optional: Model ID (default: gemini-3-pro-preview)
#   MAX_RETRIES   - Optional: Max retry attempts (default: 3)

set -euo pipefail

: "${LLM_API_KEY:?LLM_API_KEY is required}"
: "${LLM_API_URL:=https://na.wanxiaot.com/v1/chat/completions}"
: "${LLM_MODEL:=gemini-3-pro-preview}"
: "${MAX_RETRIES:=3}"

# Debug: show model being used
echo "Using model: $LLM_MODEL" >&2
echo "API URL: $LLM_API_URL" >&2

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
        -H "Authorization: Bearer $LLM_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
          \"model\": \"$LLM_MODEL\",
          \"messages\": [{\"role\": \"user\", \"content\": $escaped_prompt}]
        }" \
        "$LLM_API_URL" 2>&1); then

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
