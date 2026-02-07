#!/bin/bash
# navigation-hint.sh (UserPromptSubmit hook)
# Emit a single, low-noise navigation message.
#
# Design goals:
# - Stable across environments: prefer executable `openspec ...` / `just ...` when relevant.
# - Include OpenSpec guidance and "skills" workflows (review/test/commit/pr/context).
# - Avoid /opsx:* as the primary recommendation since it may be routed as a skill in some setups.

set -euo pipefail

# stdin is JSON (may be empty)
input=$(cat 2>/dev/null) || true
[[ -n "$input" ]] || exit 0

# Extract prompt text
prompt=$(echo "$input" | jq -r '.prompt // ""' 2>/dev/null | tr '[:upper:]' '[:lower:]')
[[ -n "$prompt" ]] || exit 0

# Utility: build a single markdown message with sections.
sections=()
add_section() {
    local title="$1"
    local body="$2"
    sections+=("## ${title}
${body}")
}

join_sections() {
    local out=""
    local i
    for i in "${sections[@]}"; do
        if [[ -z "$out" ]]; then
            out="$i"
        else
            out+=$'\n\n'
            out+="$i"
        fi
    done
    printf '%s' "$out"
}

# Common workflows are always safe to suggest.
common_workflows_body=$(
    cat <<'EOF'
- /context: 先理解代码结构 / 找入口 / 定位问题
- /review: 需要审查代码或做安全检查
- /test: 需要跑测试 / TDD
- /commit: 需要提交变更
- /pr:pr-create: 需要创建 PR
EOF
)

# OpenSpec preflight: show the next stable commands and when to use common workflows.
openspec_preflight_body=$(
    cat <<'EOF'
- 如果是 L3/L4（多文件 / 大改动），优先走 OpenSpec 的 CLI（不要依赖 /opsx:* 作为主路径）。
- 如果还没确认 change 状态：先跑 `openspec status --change <change-name> --json`。
- 如果你要先摸清现状：用 /context（不改代码，先定位入口与影响面）。
- 如果涉及安全 / 权限 / 令牌：用 /review 先做 security review。
EOF
)

# OpenSpec guidance: stable CLI + just wrappers.
openspec_guidance_body=$(
    cat <<'EOF'
优先使用稳定的原生命令（在 Claude Code / Codex 都一致）：

- 查看当前 change 的阻塞关系：

  openspec status --change <change-name> --json

- 对所有 status=ready 的 artifact 逐个拉 instructions（合法 id：proposal/specs/design/tasks）：

  openspec instructions <artifact-id> --change <change-name> --json

- 校验：避免 `openspec validate --change` 这类参数漂移，统一走 wrapper：

  just openspec-validate
EOF
)

# OpenSpec + skills mapping (what to use during the workflow).
openspec_workflow_skills_body=$(
    cat <<'EOF'
- Proposal / Design 阶段：
  - /context：读代码 + 找约束（不做实现）
  - /review：如果变更触及 security/auth

- Specs / Tasks 阶段：
  - /review：确认接口 / 风险点 / 回滚路径

- Apply（实现）后：
  - /test：跑测试 / 补测试
  - /commit：通过测试后提交

- Verify / PR：
  - /pr:pr-create：需要开 PR
  - /pr:pr-review：需要审查 PR
EOF
)

# Decide if OpenSpec context is present.
is_openspec=false
case "$prompt" in
*opsx* | *openspec* | *spec-first* | *spec*workflow* | *规范驱动* | *规格驱动* | *l3* | *l4* | *multi-file* | *large*change* | *复杂任务* | *多文件* | *大型重构*)
    is_openspec=true
    ;;
esac

# For OpenSpec contexts, emit a structured message and stop (single message).
if [[ "$is_openspec" == true ]]; then
    add_section "Preflight" "$openspec_preflight_body"
    add_section "OpenSpec" "$openspec_guidance_body"
    add_section "Workflows (skills)" "$openspec_workflow_skills_body"
    add_section "Common workflows" "$common_workflows_body"
    hints=$(join_sections)
    jq -n --arg message "$hints" '{message: $message}'
    exit 0
fi

# Non-OpenSpec: lightweight single-section hints.
case "$prompt" in
*security* | *vulnerability* | *auth* | *password* | *token* | *secret* | *安全* | *漏洞* | *密码*)
    add_section "Suggested" "- /review: security-focused review\n- /context: find entrypoints before changes"
    ;;
*"code review"* | *"review code"* | *"check code"* | *审查* | *检查代码* | *看看这个代码*)
    add_section "Suggested" "- /review"
    ;;
*debug* | *bug* | *error* | *fix* | *issue* | *broken* | *crash* | *报错* | *失败* | *出错* | *崩溃*)
    add_section "Suggested" "- /context\n- /test"
    ;;
*unittest* | *pytest* | *"test "* | *" test"* | *tdd* | *coverage* | *测试*)
    add_section "Suggested" "- /test"
    ;;
*commit* | *message* | *提交*)
    add_section "Suggested" "- /commit"
    ;;
*"pull request"* | *" pr "* | *"create pr"* | *"make pr"* | *创建*pr*)
    add_section "Suggested" "- /pr:pr-create"
    ;;
*context* | *understand* | *explain* | *how*does* | *理解* | *解释* | *怎么工作*)
    add_section "Suggested" "- /context"
    ;;
*)
    exit 0
    ;;
esac

hints=$(join_sections)
[[ -n "$hints" ]] || exit 0
jq -n --arg message "$hints" '{message: $message}'
