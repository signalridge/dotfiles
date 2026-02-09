#!/bin/bash
# format-code.sh - Best-effort formatter for common source files.
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
[[ -n "$file_path" ]] || exit 0
[[ -f "$file_path" ]] || exit 0

case "$file_path" in
*.nix)
    if command -v nixfmt >/dev/null 2>&1; then
        nixfmt "$file_path" >/dev/null 2>&1 || true
    elif command -v alejandra >/dev/null 2>&1; then
        alejandra "$file_path" >/dev/null 2>&1 || true
    fi
    ;;
*.json)
    tmp_file="$(mktemp)"
    if jq '.' "$file_path" >"$tmp_file" 2>/dev/null; then
        mv "$tmp_file" "$file_path"
    else
        rm -f "$tmp_file"
    fi
    ;;
*.yaml | *.yml)
    if command -v yq >/dev/null 2>&1; then
        yq -i '.' "$file_path" >/dev/null 2>&1 || true
    fi
    ;;
*.sh | *.bash | *.zsh)
    if command -v shfmt >/dev/null 2>&1; then
        shfmt -w "$file_path" >/dev/null 2>&1 || true
    fi
    ;;
*.go)
    if command -v gofmt >/dev/null 2>&1; then
        gofmt -w "$file_path" >/dev/null 2>&1 || true
    fi
    ;;
*.lua)
    if command -v stylua >/dev/null 2>&1; then
        stylua "$file_path" >/dev/null 2>&1 || true
    fi
    ;;
*.ts | *.tsx | *.js | *.jsx)
    if command -v prettier >/dev/null 2>&1; then
        prettier --write "$file_path" >/dev/null 2>&1 || true
    fi
    ;;
esac

exit 0
