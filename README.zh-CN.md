<div align="center">

![header](https://capsule-render.vercel.app/api?type=waving&color=0:282a36,100:bd93f9&height=200&section=header&text=~/.dotfiles&fontSize=48&fontColor=f8f8f2&fontAlignY=30&desc=Chezmoi%20%C2%B7%20Nix%20%C2%B7%20AI%20tooling&descSize=16&descColor=8be9fd&descAlignY=55&animation=fadeIn)

<p>
  <a href="https://github.com/signalridge/dotfiles/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/signalridge/dotfiles/ci.yml?style=for-the-badge&logo=github&label=CI"></a>&nbsp;
  <a href="https://opensource.org/licenses/MIT"><img alt="License" src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge"></a>&nbsp;
  <img alt="macOS" src="https://img.shields.io/badge/macOS-Sonoma+-000000?style=for-the-badge&logo=apple&logoColor=white">&nbsp;
  <img alt="Linux" src="https://img.shields.io/badge/Linux-supported-FCC624?style=for-the-badge&logo=linux&logoColor=black">
</p>

<p>
  <a href="https://github.com/twpayne/chezmoi"><img alt="chezmoi" src="https://img.shields.io/badge/chezmoi-4B91E2?style=for-the-badge&logo=chezmoi&logoColor=white"></a>&nbsp;
  <a href="https://github.com/LnL7/nix-darwin"><img alt="nix-darwin" src="https://img.shields.io/badge/nix--darwin-5277C3?style=for-the-badge&logo=nixos&logoColor=white"></a>&nbsp;
  <a href="https://www.anthropic.com/claude-code"><img alt="Claude Code" src="https://img.shields.io/badge/Claude_Code-191919?style=for-the-badge&logo=anthropic&logoColor=white"></a>&nbsp;
  <a href="https://openai.com/index/introducing-codex/"><img alt="Codex CLI" src="https://img.shields.io/badge/Codex_CLI-111111?style=for-the-badge&logo=openai&logoColor=white"></a>&nbsp;
  <a href="https://brew.sh/"><img alt="Homebrew" src="https://img.shields.io/badge/Homebrew-FBB040?style=for-the-badge&logo=homebrew&logoColor=black"></a>
</p>

[English](README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md)

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=22&pause=1000&color=BD93F9&center=true&vCenter=true&width=600&lines=chezmoi+%2B+Nix+%E5%A3%B0%E6%98%8E%E5%BC%8F%E5%BC%80%E5%8F%91%E7%8E%AF%E5%A2%83;%E8%B7%A8%E5%B9%B3%E5%8F%B0+macOS+%2B+Linux+%E6%94%AF%E6%8C%81;Claude+Code+%E8%87%AA%E5%8A%A8%E6%8F%92%E4%BB%B6%E5%90%8C%E6%AD%A5;%E7%8E%B0%E4%BB%A3+Rust+CLI+%E5%B7%A5%E5%85%B7%E9%93%BE)](https://git.io/typing-svg)

</div>

---

## 这个仓库是什么

这是一个可复现的个人开发环境仓库，核心由以下组件组成：

- `chezmoi`：管理 dotfiles、模板和 bootstrap 编排
- `Nix`：声明式包管理（macOS 用 `nix-darwin`，macOS/Linux 都用 `flakey-profile`）
- `aqua` + `mise`：补充 Nix 之外的 CLI 与 runtime 版本固定
- `Claude Code` + `Codex CLI` + `OpenCode`：共享 AI 工具链

这不是展示型模板，而是日常真实使用的配置。本文档只描述仓库当前已经实现的能力。

---

## 亮点

- 统一 bootstrap 流程（`.chezmoiscripts/00..11`），并带有幂等维护步骤
- 跨平台包管理策略：
  - macOS/Linux 共用 Nix user packages
  - macOS 使用 `nix-darwin` 管理系统配置
  - macOS 集成 Homebrew / MAS
- 共享 AI skills 自动同步到 `~/.agents/skills`（Claude、Codex、OpenCode 共用）
- Claude/Codex wrapper 的 provider 切换，加上 OpenCode 原生 account 选择：
  - `claude-manage` / `claude-with`
  - `codex-manage` / `codex-with`
  - OpenCode 使用 `opencode` + `opencodeProviderAccount`
- 声明式管理 `OpenCode + oh-my-opencode` 全局配置，并启用 native-only（禁用 Claude compatibility）护栏
- 每次 `chezmoi apply` 自动对齐 Claude MCP 配置
- GitHub Actions 自动维护依赖版本（versions、flake lock、aqua packages）
- OpenSpec 管理中大型改动生命周期（`openspec/changes`、`openspec/specs`、`opsx-*`）

---

## 为什么选择这个仓库

- **Profile 全覆盖**：`.chezmoidata/` 统一驱动 `shared` / `work` / `private`，覆盖 Nix、Homebrew、MAS
- **端到端引导**：`00..11` 阶段脚本把安装、配置、工具同步串成稳定流水线
- **macOS 打磨**：nix-darwin 系统项、Homebrew / MAS 联动、应用后维护脚本
- **工作流护栏**：pre-commit + Claude hooks 组合，降低危险操作概率
- **DX 自动化**：Justfile、fzf 导航、AI 辅助提交流程
- **CI 一致性**：模板渲染与 `nix flake check` 在 macOS/Linux 双平台验证
- **三 AI 栈**：Claude Code、Codex CLI 与 OpenCode 在一套配置里协同维护

---

## 设计理念

新机器初始化成本高，且容易“装得出来但用不顺”。本仓库目标不是最小示例，而是让真实开发环境可重复落地。

核心原则：

- **可复现**：同一套配置数据，多机器结果一致
- **声明式优先**：包、工具、配置都落在可追踪文件中
- **模块化 Profile**：work/private/headless 用数据切换，不靠分叉脚本
- **AI 增强工作流**：prompts、skills、hooks、provider 管理统一纳管
- **分层安全**：dotfiles secrets、password store、key backup 各自独立机制

---

## 目录

- [快速开始](#快速开始)
- [首次运行会询问什么](#首次运行会询问什么)
- [架构](#架构)
- [仓库结构](#仓库结构)
- [Bootstrap 流程（实际执行顺序）](#bootstrap-流程实际执行顺序)
- [日常操作](#日常操作)
- [Claude Code 集成](#claude-code-集成)
- [OpenCode 集成](#opencode-集成)
- [AI 工具链（Claude + Codex + OpenCode）](#ai-工具链claude--codex--opencode)
- [工具链](#工具链)
- [Shell 函数](#shell-函数)
- [包管理](#包管理)
- [多 Profile 配置](#多-profile-配置)
- [安全与加密](#安全与加密)
- [CI 与自动化](#ci-与自动化)
- [变更管理（OpenSpec）](#变更管理openspec)
- [更多文档](#更多文档)
- [致谢](#致谢)
- [统计](#统计)
- [许可证](#许可证)

---

## 架构

仓库整体架构由 `chezmoi` + Nix 主干 + AI 工具层构成：

- `chezmoi`：模板与脚本编排中枢
- `nix-darwin`（macOS）：系统层声明式配置
- `flakey-profile`（macOS/Linux）：用户包 Profile
- `aqua` + `mise`：Nix 外 CLI/runtime 管理层
- `dot_claude` + `dot_codex` + `private_dot_config/opencode`：AI 工具全局策略与配置

| 组件     | macOS          | Linux          |
| -------- | -------------- | -------------- |
| Dotfiles | chezmoi        | chezmoi        |
| 系统配置 | nix-darwin     | N/A            |
| 用户包   | flakey-profile | flakey-profile |
| GUI 应用 | Homebrew/MAS   | N/A            |

---

## 仓库结构

```text
.
├── .chezmoidata/
│   ├── nix.yaml                # Nix 包集合（shared/work/private）
│   ├── homebrew.yaml           # Homebrew taps/brews/casks/MAS apps
│   ├── claude.yaml             # Claude provider 与 account 模型配置
│   ├── versions.yaml           # 工具与插件版本固定
│   ├── aerospace.yaml          # Aerospace WM 数据
│   └── hammerspoon.yaml        # Hammerspoon 数据
├── .chezmoiscripts/            # Bootstrap 与维护脚本链（00..11）
├── nix-config/
│   ├── flake.nix.tmpl
│   └── modules/
│       ├── system.nix.tmpl     # nix-darwin 系统配置
│       ├── apps.nix.tmpl       # Homebrew + MAS 连接层
│       ├── profile.nix.tmpl    # flakey-profile 包配置
│       └── host-users.nix
├── dot_local/bin/              # CLI 封装脚本（Claude/Codex/OpenCode/keys/MCP）
├── dot_claude/                 # Claude 全局指令、hooks、模板
├── dot_codex/                  # Codex 全局指令、配置、prompts
├── private_dot_config/         # 工具配置（tmux、mise、aqua、gopass 等）
├── docs/                       # 专项文档
└── tests/                      # bootstrap/脚本回归测试
```

---

## Bootstrap 流程（实际执行顺序）

`chezmoi` 脚本按编号阶段执行：

1. `00` 安装 Nix（Determinate installer + 架构/镜像检测）
2. `01` 可选恢复 keys-manage 加密文件（`useEncryption=true`）
3. `02` macOS：应用 nix-darwin 系统配置
4. `03` 切换 flakey-profile 包配置
5. `04` 初始化 gopass store（交互式 clone）
6. `05` 安装固定版本的 aqua installer/aqua
7. `06` 根据 `private_dot_config/aquaproj-aqua/aqua.yaml` 安装工具
8. `07` 通过 `mise` 安装 runtime 与工具
9. `08` 下载固定版本 nix-index 数据库
10. `09` macOS：安装/更新 Paperlib
11. `10` 周期性 Homebrew 更新（7 天间隔）
12. `11` 同步 Claude MCP servers（仅缺失/不一致时更新）

---

## 快速开始

> [!WARNING]
> 本仓库会修改 shell、包管理器和系统配置。
> 建议先 Fork 并审阅，再用于生产机器。

### 方式 1：直接运行 `init.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/signalridge/dotfiles/main/init.sh | sh
```

### 方式 2：固定 tag/branch 并先审阅

```bash
REF="<tag-or-branch>"
curl -fsSLo init.sh "https://raw.githubusercontent.com/signalridge/dotfiles/${REF}/init.sh"
shasum -a 256 init.sh || sha256sum init.sh
sh init.sh --ref "${REF}"
```

### 方式 3：本地 clone 后执行（审计性最佳）

```bash
git clone https://github.com/signalridge/dotfiles.git
cd dotfiles
git checkout <tag-or-commit>
./init.sh
```

### `init.sh` 常用参数

```bash
./init.sh --repo signalridge/dotfiles
./init.sh --ref v1.2.3
./init.sh --depth 1
./init.sh --ssh
```

---

## 首次运行会询问什么

`chezmoi` 交互项包含：

- `work`（是否工作机）
- `headless`（是否无 GUI 场景）
- `useEncryption`（是否启用加密密钥恢复流）
- `installMasApps`（是否安装 MAS 应用）
- `claudeProviderAccount` / `codexProviderAccount` / `opencodeProviderAccount`

对大多数首次使用者：除非你已经有自己的 keys-manage 备份仓库与密钥材料，否则建议保持 `useEncryption = false`。

---

## 日常操作

全局 Justfile 会生成到 `~/.config/just/.justfile`。

### Chezmoi

```bash
just apply
just diff
just update
just re-add
```

### Nix

```bash
just up
just upp nixpkgs
just gc
just verify
just optimize
```

### macOS（`nix-darwin`）

```bash
just darwin
just darwin-check
just darwin-build
```

### 测试

```bash
bash tests/run.sh
pre-commit run --all-files
```

---

## Claude Code 集成

### 插件系统

skills 由 `.chezmoiexternal.toml.tmpl` 从以下来源同步：

- [wshobson/agents](https://github.com/wshobson/agents)
- [anthropics/skills](https://github.com/anthropics/skills)
- [obra/superpowers](https://github.com/obra/superpowers)

同步后统一落到 `~/.agents/skills`，可被 Claude/Codex/OpenCode 共用。

### 质量协议

当前指令与 skills 体系内置了质量约束（例如实现前置信度检查、实现后基于证据的自检），并配合项目 guardrails 约束高风险变更。

### Provider 管理

`claude-manage`、`claude-with`、`claude-token` 共同实现 account 切换、provider 路由与模型映射；配置源来自 `.chezmoidata/claude.yaml`，密钥通过 gopass 管理。

详见：`docs/claude-provider.md`。

### Hooks

`dot_claude/hooks/` 提供了流程护栏与格式化自动化，核心包括：

- `block-git-rewrites.sh`
- `block-main-edits.sh`
- `format-code.sh`
- `format-python.sh`

---

## OpenCode 集成

### 配置归属边界

OpenCode 配置由以下模板声明式管理：

- `private_dot_config/opencode/opencode.jsonc.tmpl`
- `private_dot_config/opencode/oh-my-opencode.jsonc.tmpl`

渲染到：

- `~/.config/opencode/opencode.jsonc`
- `~/.config/opencode/oh-my-opencode.jsonc`

默认 provider/account 由 `~/.config/chezmoi/chezmoi.toml` 的 `opencodeProviderAccount` 驱动。

### OpenCode 原生模式

请直接使用原生 `opencode`：

- 默认选择器：`~/.config/chezmoi/chezmoi.toml` 中的 `opencodeProviderAccount`
- 第三方 key 路径：`opencode/{provider}/{account}/api_key`

### Native-only 策略（禁用 Claude compatibility bridge）

`oh-my-opencode` 中与 Claude compatibility 相关入口被显式关闭：

- `claude_code.mcp = false`
- `claude_code.commands = false`
- `claude_code.skills = false`
- `claude_code.agents = false`
- `claude_code.hooks = false`
- `claude_code.plugins = false`
- `disabled_hooks` 包含 `claude-code-hooks`
- `sisyphus.tasks.claude_code_compat = false`

这保证 OpenCode 工作流不依赖 `~/.claude/*`。

### OpenCode 内的 OpenSpec 集成

OpenCode plugin 顺序固定为：

```json
"plugin": ["oh-my-opencode", "opencode-plugin-openspec"]
```

这样既保留 `oh-my-opencode` orchestration，又能在 OpenCode 内启用 `openspec-plan` agent 做 OpenSpec 规划。

### 运行时确认策略

默认将敏感操作设为 `ask`：

- `edit`
- `bash`
- `external_directory`
- `webfetch`
- `websearch`
- `codesearch`
- `lsp`
- `task`
- `skill`

该策略同时覆盖 OpenCode 主流程和默认 `oh-my-opencode` orchestration 流程（除非某个 agent 显式覆盖）。

详见：`docs/opencode-provider.md`。

---

## AI 工具链（Claude + Codex + OpenCode）

### 共享 Skills 分发

`chezmoi external` 会同步这些来源的精选 skills：

- `wshobson/agents`
- `anthropics/skills`
- `obra/superpowers`

最终统一到 `~/.agents/skills`，由 Claude、Codex、OpenCode 共同使用。

### Account 与 Provider 管理

```bash
# Claude
claude-manage
claude-manage list
claude-manage switch anthropic
claude-with kimi@private -- --resume

# Codex
codex-manage
codex-manage list
codex-manage switch openai
codex-with deepseek@private "explain this file"

# OpenCode（原生 CLI + data 驱动默认 account/provider）
opencode run -m harui/gpt-5.3-codex "say ok"
```

### Token Helpers

```bash
claude-token --check kimi@private
codex-token --check deepseek@private
gopass show -o opencode/harui/private/api_key >/dev/null
```

### MCP 集成

- Claude MCP 由 `.chezmoiscripts/run_after_11_sync-claude-mcp.sh.tmpl` 自动对齐。
- OpenCode 的 MCP/plugin 行为由 `~/.config/opencode/opencode.jsonc` 与 `~/.config/opencode/oh-my-opencode.jsonc` 原生管理。
- 仓库提供 MCP wrapper：
  - `~/.local/bin/mcp-tavily`
  - `~/.local/bin/mcp-postgres`

---

## 工具链

当前仓库仍保留你原有的现代 CLI 与 shell 体验栈。

### 现代 CLI 替代

| 传统   | 现代                                             | 说明                        |
| ------ | ------------------------------------------------ | --------------------------- |
| `ls`   | [eza](https://github.com/eza-community/eza)      | Git 集成、图标、树形视图    |
| `cat`  | [bat](https://github.com/sharkdp/bat)            | 语法高亮、Git 集成          |
| `grep` | [ripgrep](https://github.com/BurntSushi/ripgrep) | 极速正则搜索                |
| `find` | [fd](https://github.com/sharkdp/fd)              | 直观语法，遵循 `.gitignore` |
| `cd`   | [zoxide](https://github.com/ajeetdsouza/zoxide)  | 智能目录跳转                |

### Shell 环境

| 工具                                                | 作用                   |
| --------------------------------------------------- | ---------------------- |
| [starship](https://github.com/starship/starship)    | 极简、快速的提示符     |
| [sheldon](https://github.com/rossmacarthur/sheldon) | zsh 插件管理器         |
| [atuin](https://github.com/atuinsh/atuin)           | 支持模糊搜索的命令历史 |
| [direnv](https://github.com/direnv/direnv)          | 按目录自动加载环境变量 |
| [fzf](https://github.com/junegunn/fzf)              | 文件/历史等模糊查找器  |

### 开发工具

| 工具                                                | 作用                                       |
| --------------------------------------------------- | ------------------------------------------ |
| [mise](https://github.com/jdx/mise)                 | 多语言 runtime 管理（Node/Python/Go/Rust） |
| [lazygit](https://github.com/jesseduffield/lazygit) | 终端 Git UI                                |
| [yazi](https://github.com/sxyazi/yazi)              | 高性能终端文件管理器                       |
| [tmux](https://github.com/tmux/tmux)                | 终端复用器                                 |

---

## Shell 函数

### 项目跳转

```bash
dev                 # FZF 驱动的项目选择器（基于 ghq）
mkcd <dir>          # 创建目录并 cd 进入
dotcd               # 跳转到 chezmoi 源目录
```

### Git 工作流

```bash
fgc                 # 模糊切换 git 分支
fgl                 # 模糊浏览 git log
fga                 # 模糊 git add（选择文件）
aicommit            # 使用 AI 生成提交信息
```

### 环境初始化

```bash
create_direnv_venv  # 创建 Python venv + direnv
create_direnv_nix   # 创建 Nix flake + direnv
create_py_project   # 使用 uv 快速初始化 Python 项目
```

---

## 包管理

| 来源           | 平台         | 说明               |
| -------------- | ------------ | ------------------ |
| Nix packages   | macOS, Linux | 可复现、可回滚     |
| Homebrew casks | 仅 macOS     | GUI 应用           |
| Mac App Store  | 仅 macOS     | App Store 独占应用 |

包清单统一定义在 `.chezmoidata/`，并按 `shared` / `work` / `private` 分层。

---

## 多 Profile 配置

```bash
# 工作机器
chezmoi init --apply --promptBool work=true signalridge

# 个人机器（默认）
chezmoi init --apply signalridge

# 无头服务器（不需要 GUI 配置）
chezmoi init --apply --promptBool headless=true signalridge
```

---

## 安全与加密

这个仓库是多层安全模型，不同层负责不同目标：

1. `chezmoi` secrets 解密：`age` wrapper + `~/.ssh/main`
2. `gopass` 使用 `age` backend 存储 API keys / passwords
3. `keys-manage` 使用 OpenSSL PBKDF2（`AES-256-CBC`）做备份仓库加密
4. Claude hooks 作为操作护栏，阻止高风险 git/history rewrite 行为

详见：

- `docs/keys-manage-guide.md`
- `docs/gopass-new-device-setup.md`
- `docs/claude-provider.md`
- `docs/opencode-provider.md`

---

## CI 与自动化

### 校验流水线

- `.github/workflows/ci.yml`
  - pre-commit 校验
  - 模板渲染校验
  - `nix flake check`（macOS + Linux 矩阵）

- `.github/workflows/tests.yml`
  - 手动触发 bootstrap/脚本测试（`bash tests/run.sh`）

### 自动维护

- `.github/workflows/scheduler.yml`（每周两次触发）
- `.github/workflows/update-versions.yml`
- `.github/workflows/update-flake-lock.yml`
- `.github/workflows/update-aqua-packages.yml`

---

## 变更管理（OpenSpec）

> [!IMPORTANT]
> 在本仓库中，OpenSpec 是中大型改动的事实来源（source of truth）。

- 变更产物位于 `openspec/changes/<change-name>/`（`proposal.md`、`design.md`、`tasks.md`、delta specs）。
- 主规范位于 `openspec/specs/<capability>/spec.md`。
- 完成后的变更归档到 `openspec/changes/archive/`。
- 如已安装 `opsx-*` 包装命令，可按同一 OpenSpec 生命周期执行。

典型流程：

```bash
openspec new change <change-name>
openspec status --change <change-name>
# 然后使用 opsx-* 或 openspec instructions/apply/verify/archive
```

---

## 更多文档

- `docs/claude-provider.md`
- `docs/opencode-provider.md`
- `docs/keys-manage-guide.md`
- `docs/gopass-new-device-setup.md`
- `docs/tmux.md`

---

## 致谢

- [chezmoi](https://github.com/twpayne/chezmoi) - Dotfiles 管理器
- [nix-darwin](https://github.com/LnL7/nix-darwin) - 声明式 macOS 配置
- [flakey-profile](https://github.com/lf-/flakey-profile) - 跨平台 Nix profile 管理
- [wshobson/agents](https://github.com/wshobson/agents) - Claude Code 插件 marketplace
- [anthropics/skills](https://github.com/anthropics/skills) - 官方 Claude Code skills
- [obra/superpowers](https://github.com/obra/superpowers) - 高级工作流模式
- [Dracula Theme](https://draculatheme.com/) - 终端与 fzf 主题灵感来源

---

## 统计

![Alt](https://repobeats.axiom.co/api/embed/81ef9a8c511918fc0eece9bd09bb46ba78eefd0c.svg "Repobeats analytics image")

---

## 许可证

MIT
