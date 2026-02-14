#!/bin/bash
# format-python.sh - Best-effort Python formatting after edits.
# Hook type: PostToolUse (Write, Edit, MultiEdit)

set -euo pipefail

find_mise_cmd() {
    local mise_cmd=""
    if [[ -x "$HOME/.nix-profile/bin/mise" ]]; then
        mise_cmd="$HOME/.nix-profile/bin/mise"
    elif command -v mise >/dev/null 2>&1; then
        mise_cmd="$(command -v mise)"
    fi

    # Ignore aqua proxy wrapper for missing commands.
    case "$mise_cmd" in
    */aquaproj-aqua/bin/mise) mise_cmd="" ;;
    esac

    printf '%s\n' "$mise_cmd"
}

MISE_CMD="$(find_mise_cmd)"

find_aqua_cmd() {
    local aqua_cmd=""
    if [[ -x "$HOME/.local/share/aquaproj-aqua/bin/aqua" ]]; then
        aqua_cmd="$HOME/.local/share/aquaproj-aqua/bin/aqua"
    elif command -v aqua >/dev/null 2>&1; then
        aqua_cmd="$(command -v aqua)"
    fi
    printf '%s\n' "$aqua_cmd"
}

AQUA_CMD="$(find_aqua_cmd)"

find_tool_cmd() {
    local tool="$1"
    if command -v "$tool" >/dev/null 2>&1; then
        command -v "$tool"
        return 0
    fi

    local candidate
    for candidate in \
        "$HOME/.nix-profile/bin/$tool" \
        "/opt/homebrew/bin/$tool" \
        "$HOME/.local/share/aquaproj-aqua/bin/$tool"; do
        if [[ -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

run_optional() {
    local tool="$1"
    shift
    local resolved=""

    resolved="$(find_tool_cmd "$tool" || true)"
    if [[ -n "$resolved" ]]; then
        # aqua tool links are proxies and require a usable aqua command.
        if [[ "$resolved" == *"/aquaproj-aqua/bin/"* ]] && [[ "$resolved" != *"/aquaproj-aqua/bin/aqua" ]]; then
            if [[ -n "$AQUA_CMD" ]]; then
                "$AQUA_CMD" exec -- "$tool" "$@" >/dev/null 2>&1 || return 1
                return 0
            fi
            return 1
        fi

        "$resolved" "$@" >/dev/null 2>&1 || true
        return 0
    fi

    if [[ -n "$MISE_CMD" ]]; then
        "$MISE_CMD" exec -- "$tool" "$@" >/dev/null 2>&1 || return 1
        return 0
    fi

    return 1
}

JQ_CMD="$(find_tool_cmd jq || true)"
if [[ -z "$JQ_CMD" ]]; then
    exit 0
fi

input=$(cat 2>/dev/null) || true
[[ -n "$input" ]] || exit 0

tool_name=$(echo "$input" | "$JQ_CMD" -r '.tool_name // ""' 2>/dev/null || echo "")
case "$tool_name" in
Write | Edit | MultiEdit) ;;
*)
    exit 0
    ;;
esac

file_path=$(echo "$input" | "$JQ_CMD" -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null || echo "")
[[ "$file_path" == *.py ]] || exit 0
[[ -f "$file_path" ]] || exit 0

# Prefer ruff directly, then uvx fallback.
if run_optional ruff format "$file_path"; then
    run_optional ruff check --fix "$file_path" || true
elif run_optional uvx ruff format "$file_path"; then
    run_optional uvx ruff check --fix "$file_path" || true
fi

exit 0
