#!/bin/bash
# Bash command validator for Claude Code
# Validates bash commands before execution to encourage best practices

set -euo pipefail

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // ""')
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Only process Bash tool
[[ "$tool_name" != "Bash" || -z "$command" ]] && exit 0

issues=()
warnings=()

# Security checks
if [[ "$command" =~ rm[[:space:]]+-rf[[:space:]]+/[^[:space:]] ]]; then
    issues+=("Dangerous rm -rf command detected. Double-check the path!")
fi

if [[ "$command" =~ curl.*\|[[:space:]]*bash ]]; then
    issues+=("Piping curl to bash is dangerous. Download and review scripts first")
fi

if [[ "$command" =~ chmod[[:space:]]+777 ]]; then
    issues+=("chmod 777 is insecure. Use more restrictive permissions")
fi

# Dangerous commands that need confirmation
if [[ "$command" =~ rm[[:space:]]+-rf ]]; then
    issues+=("Potentially dangerous command: rm -rf")
fi

if [[ "$command" =~ git[[:space:]]+reset[[:space:]]+--hard ]]; then
    issues+=("Potentially dangerous command: git reset --hard")
fi

if [[ "$command" =~ git[[:space:]]+clean[[:space:]]+-fd ]]; then
    issues+=("Potentially dangerous command: git clean -fd")
fi

if [[ "$command" =~ sudo[[:space:]] ]]; then
    issues+=("Potentially dangerous command: sudo")
fi

# Best practice warnings
if [[ "$command" =~ \bgrep\b ]] && [[ ! "$command" =~ \| ]]; then
    warnings+=("Consider using 'rg' (ripgrep) instead of 'grep' for better performance")
fi

if [[ "$command" =~ \bfind\b.*-name ]]; then
    warnings+=("Consider using 'fd' or 'rg --files -g' instead of 'find -name'")
fi

if [[ "$command" =~ cat[[:space:]].*\|[[:space:]]*grep ]]; then
    warnings+=("Use 'rg pattern file' instead of 'cat file | grep pattern'")
fi

if [[ "$command" =~ cd[[:space:]]+.*\&\& ]]; then
    warnings+=("Consider using absolute paths or subshells instead of 'cd &&' patterns")
fi

# If there are security issues, ask for confirmation
if [[ ${#issues[@]} -gt 0 ]]; then
    echo "[validator] Security/safety issues detected:" >&2
    for issue in "${issues[@]}"; do
        echo "  - $issue" >&2
    done

    # Build reason string
    reason="Command has potential issues:"
    for issue in "${issues[@]}"; do
        reason+="\n- $issue"
    done
    reason=$(echo -e "$reason" | jq -Rs '.')

    echo "{\"decision\": \"ask\", \"reason\": $reason}"
    exit 0
fi

# Show warnings but don't block
if [[ ${#warnings[@]} -gt 0 ]]; then
    echo "[validator] Suggestions for better practices:" >&2
    for warning in "${warnings[@]}"; do
        echo "  - $warning" >&2
    done
fi

# Allow the command
exit 0
