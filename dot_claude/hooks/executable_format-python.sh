#!/bin/bash
# format-python.sh - Best-effort Python formatting after edits.
# Hook type: PostToolUse (Write, Edit, MultiEdit)

set -euo pipefail

# Hook runs in non-interactive shell: ensure stable tool PATH.
[[ -d "$HOME/.nix-profile/bin" ]] && PATH="$HOME/.nix-profile/bin:$PATH"
[[ -d "/opt/homebrew/bin" ]] && PATH="/opt/homebrew/bin:$PATH"
[[ -d "$HOME/.local/share/aquaproj-aqua/bin" ]] && PATH="$PATH:$HOME/.local/share/aquaproj-aqua/bin"
export PATH

run_optional() {
    local tool="$1"
    shift

    if command -v "$tool" >/dev/null 2>&1; then
        "$tool" "$@" >/dev/null 2>&1 || true
        return 0
    fi

    return 1
}

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

# Prefer ruff directly, then uvx fallback.
if run_optional ruff format "$file_path"; then
    run_optional ruff check --fix "$file_path" || true
elif run_optional uvx ruff format "$file_path"; then
    run_optional uvx ruff check --fix "$file_path" || true
fi

exit 0
