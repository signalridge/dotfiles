#!/bin/bash
# TypeScript type checking hook for Claude Code
# Runs incremental type checking on TypeScript files

set -euo pipefail

input=$(cat)

# Extract fields with jq
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

# Only process Write/Edit tools
[[ ! "$tool_name" =~ ^(Write|Edit|MultiEdit)$ ]] && exit 0

# Only process TS/JS files
[[ ! "$file_path" =~ \.(ts|tsx|js|jsx)$ ]] && exit 0

# Change to project directory
cd "${CLAUDE_PROJECT_DIR:-$PWD}"

# Check tsconfig exists
[[ ! -f "tsconfig.json" ]] && exit 0

# Check if file exists
[[ ! -f "$file_path" ]] && exit 0

# Run TypeScript compiler
tsc_output=$(npx tsc --noEmit --pretty false 2>&1) || true
tsc_exit=$?

if [[ $tsc_exit -ne 0 ]]; then
    # Extract errors for current file (limit to 5)
    errors=$(echo "$tsc_output" | grep -F "$file_path" | grep ": error TS" | head -5)

    if [[ -n "$errors" ]]; then
        # Count total errors for this file
        error_count=$(echo "$tsc_output" | grep -F "$file_path" | grep -c ": error TS" || echo "0")

        # Format error message
        error_msg="TypeScript errors in $(basename "$file_path"):\n\n"
        while IFS= read -r line; do
            # Extract error code and message
            if [[ "$line" =~ :\ error\ (TS[0-9]+):\ (.+)$ ]]; then
                error_msg+="- ${BASH_REMATCH[1]}: ${BASH_REMATCH[2]}\n"
            fi
        done <<<"$errors"

        if [[ $error_count -gt 5 ]]; then
            error_msg+="\n... and $((error_count - 5)) more errors"
        fi

        # Escape for JSON
        error_msg=$(echo -e "$error_msg" | jq -Rs '.')

        echo "{\"decision\": \"block\", \"reason\": $error_msg}"
        exit 0
    fi

    # Warn about errors in other files
    other_errors=$(echo "$tsc_output" | grep ": error TS" | grep -v -F "$file_path" | head -3)
    if [[ -n "$other_errors" ]]; then
        echo "[tsc] Note: TypeScript errors exist in other files" >&2
    fi
fi

exit 0
