#!/bin/bash
# Bundle size checker hook for Claude Code
# Monitors bundle size impact of changes to prevent bloat

set -euo pipefail

# Config
MAX_BUNDLE_KB=500
MAX_INCREASE_KB=50
CACHE_DIR="${TMPDIR:-/tmp}/claude-bundle-cache"
PROJECT_NAME=$(basename "$PWD")
CACHE_FILE="$CACHE_DIR/${PROJECT_NAME}_size"

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // ""')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')
hook_event=$(echo "$input" | jq -r '.hook_event_name // ""')

# Only process JS/TS source files
[[ ! "$file_path" =~ \.(ts|tsx|js|jsx|mjs|cjs)$ ]] && exit 0
[[ "$file_path" =~ \.(test|spec)\. ]] && exit 0
[[ ! "$file_path" =~ (src|lib|components)/ ]] && exit 0

# Change to project directory
cd "${CLAUDE_PROJECT_DIR:-$PWD}"

# Calculate bundle size (JS + CSS + WASM in dist/)
get_bundle_size() {
    local dir="${1:-dist}"
    [[ ! -d "$dir" ]] && echo 0 && return
    # macOS stat uses -f%z, Linux uses -c%s
    if [[ "$(uname)" == "Darwin" ]]; then
        find "$dir" -type f \( -name "*.js" -o -name "*.css" -o -name "*.wasm" \) \
            -exec stat -f%z {} + 2>/dev/null | awk '{s+=$1} END {print s+0}'
    else
        find "$dir" -type f \( -name "*.js" -o -name "*.css" -o -name "*.wasm" \) \
            -exec stat -c%s {} + 2>/dev/null | awk '{s+=$1} END {print s+0}'
    fi
}

# Format size for display
format_size() {
    local bytes=$1
    local kb=$((bytes / 1024))
    if [[ $kb -lt 1024 ]]; then
        echo "${kb}KB"
    else
        local mb=$((kb / 1024))
        local remainder=$((kb % 1024 * 100 / 1024))
        echo "${mb}.${remainder}MB"
    fi
}

# Save baseline size to cache
save_baseline() {
    mkdir -p "$CACHE_DIR"
    echo "$1" >"$CACHE_FILE"
}

# Get baseline size from cache
get_baseline() {
    [[ -f "$CACHE_FILE" ]] && cat "$CACHE_FILE" || echo ""
}

# PreToolUse: capture baseline
if [[ "$hook_event" == "PreToolUse" ]]; then
    baseline=$(get_baseline)
    if [[ -z "$baseline" ]]; then
        echo "[bundle] Measuring baseline bundle size..." >&2
        npm run build &>/dev/null || true
        baseline=$(get_bundle_size)
        save_baseline "$baseline"
    fi
    exit 0
fi

# PostToolUse: check size change
if [[ "$hook_event" == "PostToolUse" && "$tool_name" =~ ^(Write|Edit|MultiEdit)$ ]]; then
    baseline=$(get_baseline)

    echo "[bundle] Checking bundle size impact..." >&2

    # Build
    if ! npm run build &>/dev/null; then
        echo "[bundle] Build failed, skipping size check" >&2
        exit 0
    fi

    new_size=$(get_bundle_size)
    save_baseline "$new_size"

    # Check absolute size
    new_kb=$((new_size / 1024))
    if [[ $new_kb -gt $MAX_BUNDLE_KB ]]; then
        reason="Bundle size ($(format_size $new_size)) exceeds maximum allowed size (${MAX_BUNDLE_KB}KB). Consider code splitting or removing unused dependencies."
        reason=$(echo "$reason" | jq -Rs '.')
        echo "{\"decision\": \"block\", \"reason\": $reason}"
        exit 0
    fi

    # Check increase if we have baseline
    if [[ -n "$baseline" && "$baseline" -gt 0 ]]; then
        increase=$((new_size - baseline))
        increase_kb=$((increase / 1024))

        if [[ $increase_kb -gt $MAX_INCREASE_KB ]]; then
            reason="Bundle size increased by $(format_size $increase) (from $(format_size $baseline) to $(format_size $new_size)). Maximum allowed increase is ${MAX_INCREASE_KB}KB."
            reason=$(echo "$reason" | jq -Rs '.')
            echo "{\"decision\": \"block\", \"reason\": $reason}"
            exit 0
        elif [[ $increase_kb -gt 10 ]]; then
            echo "[bundle] Size increased by $(format_size $increase) to $(format_size $new_size)" >&2
        elif [[ $increase_kb -lt -10 ]]; then
            echo "[bundle] Size decreased by $(format_size $((-increase))) to $(format_size $new_size)" >&2
        fi
    else
        echo "[bundle] Bundle size: $(format_size $new_size)" >&2
    fi
fi

exit 0
