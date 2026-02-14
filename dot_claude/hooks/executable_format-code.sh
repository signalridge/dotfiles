#!/bin/bash
# format-code.sh - Best-effort formatter for common source files.
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
[[ -n "$file_path" ]] || exit 0
[[ -f "$file_path" ]] || exit 0

case "$file_path" in
*.nix)
    run_optional nixfmt "$file_path" || run_optional alejandra "$file_path" || true
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
    run_optional yq -i '.' "$file_path" || true
    ;;
*.sh | *.bash | *.zsh)
    run_optional shfmt -w "$file_path" || true
    ;;
*.go)
    run_optional gofmt -w "$file_path" || true
    ;;
*.lua)
    run_optional stylua "$file_path" || true
    ;;
*.ts | *.tsx | *.js | *.jsx)
    run_optional prettier --write "$file_path" || true
    ;;
esac

exit 0
