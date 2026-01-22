#!/bin/bash
# Format and lint hook for JS/TS files

# Read JSON input from stdin
input=$(cat)

# Extract file path and tool name using jq (or python if jq not available)
if command -v jq &>/dev/null; then
    tool_name=$(echo "$input" | jq -r '.tool_name // ""')
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')
else
    # Fallback to python
    tool_name=$(echo "$input" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_name', ''))")
    file_path=$(echo "$input" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_input', {}).get('file_path', ''))")
fi

# Only process edit/write tools
if [[ ! "$tool_name" =~ ^(Write|Edit|MultiEdit)$ ]]; then
    exit 0
fi

# Only process relevant file types
if [[ ! "$file_path" =~ \.(ts|js|jsx|tsx|mjs|cjs)$ ]]; then
    exit 0
fi

# Change to project directory if available
cd "${CLAUDE_PROJECT_DIR:-$(pwd)}" || exit 1

# Check if file exists
if [[ ! -f "$file_path" ]]; then
    exit 0
fi

# Store original file content for comparison
original_content=$(cat "$file_path" 2>/dev/null)

# Run Prettier if available
if command -v npx &>/dev/null && npx prettier --version &>/dev/null 2>&1; then
    echo "[format] Running Prettier..." >&2
    npx prettier --write "$file_path" 2>/dev/null || {
        echo "[format] Warning: Prettier formatting failed" >&2
    }
fi

# Run ESLint if available
if command -v npx &>/dev/null && npx eslint --version &>/dev/null 2>&1; then
    echo "[lint] Running ESLint..." >&2

    # Run ESLint with fix
    eslint_output=$(npx eslint "$file_path" --fix 2>&1)
    eslint_exit_code=$?

    # Check if there are remaining issues
    if [ $eslint_exit_code -ne 0 ]; then
        # Parse ESLint output for errors vs warnings
        error_count=$(echo "$eslint_output" | grep -c "error" || true)
        warning_count=$(echo "$eslint_output" | grep -c "warning" || true)

        if [ $error_count -gt 0 ]; then
            echo "[lint] ESLint found $error_count error(s) that couldn't be auto-fixed:" >&2
            echo "$eslint_output" | grep -A1 -B1 "error" | head -20 >&2

            # For PostToolUse, inform Claude about the errors
            cat <<EOF
{
  "decision": "block",
  "reason": "ESLint found $error_count error(s) in $file_path that need manual fixing. Please review and fix the linting errors."
}
EOF
            exit 0
        elif [ $warning_count -gt 0 ]; then
            echo "[lint] ESLint warnings:" >&2
            echo "$eslint_output" | grep -A1 -B1 "warning" | head -10 >&2
        fi
    fi
fi

# Check if file was modified
new_content=$(cat "$file_path" 2>/dev/null)
if [[ "$original_content" != "$new_content" ]]; then
    echo "[format] File formatted and linted successfully" >&2
fi

# Return success with suppressed output
echo '{"suppressOutput": true}'
exit 0
