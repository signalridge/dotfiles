#!/bin/bash
# navigation-hint.sh (UserPromptSubmit hook)
# Low-noise navigation: post-error reminders only.
#
# Design goals:
# - Silent by default; only emit when user prompt indicates failure/stuck.
# - Output format: 2 lines max (LEVEL RULE_ID: reason + Next: single action).
# - Dedup: /tmp marker to avoid repeating same hint within 10 minutes.
# - Top 3 navigation points max; prefer 1 next action.

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

DEDUP_DIR="${TMPDIR:-/tmp}/claude-hints"
DEDUP_TTL=600 # 10 minutes

mkdir -p "$DEDUP_DIR" 2>/dev/null || true

# stdin is JSON (may be empty)
input=$(cat 2>/dev/null) || true
[[ -n "$input" ]] || exit 0

# Extract prompt text
prompt=$(echo "$input" | jq -r '.prompt // ""' 2>/dev/null | tr '[:upper:]' '[:lower:]')
[[ -n "$prompt" ]] || exit 0

# Utility: emit a 2-line message (LEVEL RULE_ID + Next) then exit.
emit() {
    local level="$1"
    local rule_id="$2"
    local reason="$3"
    local next_action="$4"
    local msg="${level} ${rule_id}: ${reason}
Next: ${next_action}"
    jq -n --arg message "$msg" '{message: $message}'
    exit 0
}

# Utility: check dedup (returns 0 if should skip, 1 if should emit)
should_skip() {
    local rule_id="$1"
    local marker="$DEDUP_DIR/$rule_id"
    if [[ -f "$marker" ]]; then
        # Cross-platform stat: try BSD first, then GNU
        local mtime
        mtime=$(stat -f %m "$marker" 2>/dev/null || stat -c %Y "$marker" 2>/dev/null || echo 0)
        local now
        now=$(date +%s)
        local age=$((now - mtime))
        if [[ $age -lt $DEDUP_TTL ]]; then
            return 0 # skip
        fi
    fi
    touch "$marker" 2>/dev/null || true
    return 1 # emit
}

# --- Post-error reminder rules (only trigger when user indicates failure) ---

# WARN-OPSX-NOT-INSTALLED: user tried /opsx but it failed
if echo "$prompt" | grep -qE '(/opsx|opsx).*(not found|unknown|command not found|没有|找不到|不存在|失败)'; then
    should_skip "opsx-not-installed" && exit 0
    emit "WARN" "OPSX-NOT-INSTALLED" "/opsx command not found or failed." "Use native OpenSpec CLI first (e.g. openspec new change <change-name>), then install wrappers via openspec init --tools claude or openspec update if needed."
fi

# WARN-OPENSPEC-NOT-INIT: openspec command failed due to missing workspace
if echo "$prompt" | grep -qE 'openspec.*(workspace|specs|changes|config).*(not found|missing|不存在|缺失|失败)'; then
    should_skip "openspec-not-init" && exit 0
    emit "WARN" "OPENSPEC-NOT-INIT" "OpenSpec workspace not initialized." "openspec init --tools claude at repo root."
fi

# WARN-NAV-MISSING: user asks "where" / "which file" after a vague answer
if echo "$prompt" | grep -qE '(where|which file|which line|在哪|哪个文件|哪一行|どこ|どのファイル)'; then
    should_skip "nav-missing" && exit 0
    emit "INFO" "NAV-HINT" "Include file:line references for navigability." "Restate with path:line (e.g. src/foo.ts:42)."
fi

# WARN-TEST-FAILED: user mentions test failure
if echo "$prompt" | grep -qE '(test.*fail|tests.*fail|测试.*失败|テスト.*失敗|pytest.*error|jest.*fail)'; then
    should_skip "test-failed" && exit 0
    emit "WARN" "TEST-FAILED" "Tests failed." "/test to re-run and diagnose."
fi

# WARN-BUILD-FAILED: user mentions build/compile failure
if echo "$prompt" | grep -qE '(build.*fail|compile.*fail|编译.*失败|ビルド.*失敗|tsc.*error|cargo.*error)'; then
    should_skip "build-failed" && exit 0
    emit "WARN" "BUILD-FAILED" "Build failed." "Fix errors, then retry build."
fi

# INFO-STUCK: user explicitly says stuck/confused
if echo "$prompt" | grep -qE '(stuck|confused|lost|don.t know|不知道|卡住|困惑|わからない|迷っ)'; then
    should_skip "stuck" && exit 0
    emit "INFO" "STUCK" "Seems stuck." "/context to explore codebase, or ask a specific question."
fi

# Default: silent exit (low noise - no output unless error detected)
exit 0
