#!/bin/bash
# skill-hint.sh - Smart command suggestions based on prompt analysis
# Supports both English and Chinese keywords
# Source: Optimized based on wshobson/agents and catlog22 patterns

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // ""' 2>/dev/null | tr '[:upper:]' '[:lower:]')

# Exit early if no prompt
if [[ -z "$prompt" ]]; then
    exit 0
fi

hints=""

# Pattern matching with bilingual support (most specific first)
case "$prompt" in
# Security patterns (highest priority)
*security* | *vulnerability* | *auth* | *password* | *token* | *secret* | *安全* | *漏洞* | *密码*)
    hints="Security context detected. Consider: /review:security-scan or code-auditor agent"
    ;;

# Code review patterns
*"code review"* | *"review code"* | *"check code"* | *审查* | *检查代码* | *看看这个代码*)
    hints="/review → comprehensive code review with code-reviewer agent"
    ;;

# Debug patterns
*debug* | *bug* | *error* | *fix* | *issue* | *broken* | *crash* | *报错* | *失败* | *出错* | *崩溃*)
    hints="/debug → systematic debugging (ISOLATE→TRACE→VERIFY) with debugger agent"
    ;;

# Test patterns
*unittest* | *pytest* | *"test "* | *" test"* | *tdd* | *coverage* | *测试*)
    hints="/test → TDD workflow (Red→Green→Refactor) with test-engineer agent"
    ;;

# Refactor patterns
*refactor* | *clean*up* | *improve*code* | *重构* | *优化代码*)
    hints="/refactor → safe refactoring with verification"
    ;;

# Commit patterns
*commit* | *message* | *提交*)
    hints="/commit → context-aware smart commit"
    ;;

# PR patterns
*"pull request"* | *" pr "* | *"create pr"* | *"make pr"* | *创建*pr*)
    hints="/pr:pr-create → create pull request with auto-summary"
    ;;

# Scaffold patterns
*scaffold* | *new*project* | *create*project* | *init*project* | *新项目* | *创建项目*)
    hints="/scaffold → project templates with best practices"
    ;;

# Context/exploration patterns
*context* | *understand* | *explain* | *how*does* | *理解* | *解释* | *怎么工作*)
    hints="/context → codebase structure analysis"
    ;;

# Architecture patterns
*architect* | *design* | *structure* | *架构* | *设计*)
    hints="Consider architecture-auditor agent for design decisions"
    ;;

# Performance patterns
*performance* | *slow* | *optimize* | *性能* | *慢* | *优化*)
    hints="Consider performance-auditor agent for optimization"
    ;;

# Plan patterns
*plan* | *计划* | *规划*)
    hints="/plan:plan-create → create implementation plan for L3+ tasks"
    ;;
esac

if [ -n "$hints" ]; then
    # Output as JSON message
    echo "{\"message\": \"$hints\"}"
fi

exit 0
