#!/bin/bash
# format-python.sh - Best-effort Python formatting after edits.
# Hook type: PostToolUse (Write, Edit, MultiEdit)

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

input=$(cat 2>/dev/null) || true
[[ -n "$input" ]] || exit 0

tool_name=$(echo "$input" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
case "$tool_name" in
Write | Edit | MultiEdit) ;;
*)
    exit 0
    ;;
esac

file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null || echo "")
[[ "$file_path" == *.py ]] || exit 0
[[ -f "$file_path" ]] || exit 0

# Prefer local toolchain first for speed and reproducibility.
if command -v ruff >/dev/null 2>&1; then
    ruff format "$file_path" >/dev/null 2>&1 || true
    ruff check --fix "$file_path" >/dev/null 2>&1 || true
elif command -v uvx >/dev/null 2>&1; then
    uvx ruff format "$file_path" >/dev/null 2>&1 || true
    uvx ruff check --fix "$file_path" >/dev/null 2>&1 || true
fi

exit 0
