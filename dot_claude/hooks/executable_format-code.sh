#!/bin/bash
# format-code.sh - Auto-format various file types after editing
# Supports: Nix, JSON, YAML, Shell, Go, Lua

# Require jq for JSON parsing
if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

# Handle case where stdin is unavailable or empty
input=$(cat 2>/dev/null) || true
if [[ -z "$input" ]]; then
    exit 0
fi

# Extract file path
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null || echo "")

case "$file_path" in
# Nix files
*.nix)
    if command -v nixfmt >/dev/null 2>&1; then
        nixfmt "$file_path" 2>/dev/null || true
    elif command -v alejandra >/dev/null 2>&1; then
        alejandra "$file_path" 2>/dev/null || true
    fi
    ;;

# JSON files
*.json)
    if command -v jq >/dev/null 2>&1; then
        tmp=$(mktemp)
        jq '.' "$file_path" >"$tmp" 2>/dev/null && mv "$tmp" "$file_path" || rm -f "$tmp"
    fi
    ;;

# YAML files
*.yaml | *.yml)
    if command -v yq >/dev/null 2>&1; then
        yq -i '.' "$file_path" 2>/dev/null || true
    fi
    ;;

# Shell scripts
*.sh | *.bash | *.zsh)
    if command -v shfmt >/dev/null 2>&1; then
        shfmt -w "$file_path" 2>/dev/null || true
    fi
    ;;

# Go files
*.go)
    if command -v gofmt >/dev/null 2>&1; then
        gofmt -w "$file_path" 2>/dev/null || true
    fi
    ;;

# Lua files
*.lua)
    if command -v stylua >/dev/null 2>&1; then
        stylua "$file_path" 2>/dev/null || true
    fi
    ;;

# TypeScript/JavaScript (if prettier available)
*.ts | *.tsx | *.js | *.jsx)
    if command -v prettier >/dev/null 2>&1; then
        prettier --write "$file_path" 2>/dev/null || true
    fi
    ;;
esac

# Always succeed
exit 0
