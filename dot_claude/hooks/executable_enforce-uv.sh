#!/bin/bash
# enforce-uv.sh - Enforce using uv instead of pip for Python package management
# Source: Personal workflow preference for modern Python tooling

main() {
    local input
    input=$(cat 2>/dev/null) || true

    # Validate input
    if [ -z "$input" ]; then
        echo '{"decision": "approve"}'
        exit 0
    fi

    local tool_name
    local command
    tool_name=$(echo "$input" | jq -r '.tool_name' 2>/dev/null || echo "")
    command=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

    if [[ "$tool_name" == "Bash" ]]; then
        case "$command" in
        pip\ install* | pip3\ install*)
            local packages
            packages=$(echo "$command" | sed -E 's/pip[0-9]? install//' | sed 's/--[^ ]*//g' | xargs)
            cat <<-EOF
{
  "decision": "block",
  "reason": "Use uv instead of pip:

uv add $packages

Or for one-time use:
uvx <package>"
}
EOF
            exit 0
            ;;
        pip\ uninstall* | pip3\ uninstall*)
            local packages
            packages=$(echo "$command" | sed -E 's/pip[0-9]? uninstall//' | sed 's/-y//g' | xargs)
            cat <<-EOF
{
  "decision": "block",
  "reason": "Use uv instead:

uv remove $packages"
}
EOF
            exit 0
            ;;
        python\ -m\ pip* | python3\ -m\ pip*)
            cat <<-EOF
{
  "decision": "block",
  "reason": "Use uv instead of pip:

uv add <package>   # add dependency
uv remove <pkg>    # remove dependency
uv run <script>    # run with venv"
}
EOF
            exit 0
            ;;
        esac
    fi

    echo '{"decision": "approve"}'
}

main
