#!/bin/bash
# format-python.sh - Auto-format Python files after editing

input=$(cat)

# Extract file path
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null || echo "")

# Only process Python files
if [[ "$file_path" == *.py ]]; then
  # Format with ruff if available
  if command -v uvx >/dev/null 2>&1; then
    uvx ruff format "$file_path" 2>/dev/null || true
    uvx ruff check --fix "$file_path" 2>/dev/null || true
  elif command -v ruff >/dev/null 2>&1; then
    ruff format "$file_path" 2>/dev/null || true
    ruff check --fix "$file_path" 2>/dev/null || true
  fi
fi

# Always succeed
exit 0
