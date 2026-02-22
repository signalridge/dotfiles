## Why

当前 Claude / Codex / OpenCode 工作流缺少显式 `git worktree` gate，导致多任务并行时容易出现以下问题：

- 同一工作区混入多个任务上下文，AI 会话和 branch 边界不清晰
- 新任务经常直接在主工作区开始，回滚和审计成本上升
- `doctor` 诊断只能检查账号/配置，无法检查 workspace 隔离健康度

需要把 `worktree` 从“建议”提升为“可检查、可执行、可验证”的统一工作流能力。

## What Changes

- 引入项目级 `worktree` 约定：统一使用 `.worktrees/<branch>`，并在仓库中显式忽略。
- 增加 shell 工作流函数：`wt-new`、`wt-go`、`wt-ls`、`wt-rm`、`wt-prune`。
- 在 shell prompt 中增加 `worktree` 可视化标识（基于 `starship` 自定义模块），让非主工作区状态一眼可见。
- 增加跨工具共享 `worktree` 命令文档（不做 OpenCode-only 命令），通过现有 command projection 机制供 Claude/Codex/OpenCode 一致消费。
- 将 requirement 按层分离：repo baseline、shell interface、tool integration、cross-tool projection，避免主 spec 与 command delta spec 语义重叠。
- 保持 `manage doctor` 与账号管理职责解耦，`worktree` 不作为 doctor 必需诊断项。
- 在 Claude/Codex/OpenCode 的 AGENTS 模板加入统一 `Worktree Gate (L2+)` 策略。
- 增加测试断言，确保上述约束长期可回归验证。

## Capabilities

### New Capabilities

- `worktree-first-ai-workflow`: 定义并落实三工具统一的 `worktree` 优先开发流程、诊断与守卫。

### Modified Capabilities

- `shared-ai-commands`: 扩展共享命令集合，引入跨工具统一的 `worktree` 工作流命令说明。

## Impact

- `.gitignore`
- `dot_custom/functions.sh`
- `private_dot_config/starship.toml`
- `dot_agents/commands/core/*`
- `dot_claude/CLAUDE.md.tmpl`
- `dot_codex/AGENTS.md.tmpl`
- `private_dot_config/opencode/AGENTS.md.tmpl`
- `tests/test_opencode_config_rendering.sh`
- `openspec/changes/worktree-first-ai-workflow/*`
