<div align="center">

![header](https://capsule-render.vercel.app/api?type=waving&color=0:282a36,100:bd93f9&height=200&section=header&text=~/.dotfiles&fontSize=48&fontColor=f8f8f2&fontAlignY=30&desc=One%20command%20%C2%B7%20Full%20environment%20%C2%B7%20Zero%20hassle&descSize=16&descColor=8be9fd&descAlignY=55&animation=fadeIn)

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
  <a href="https://brew.sh/"><img alt="Homebrew" src="https://img.shields.io/badge/Homebrew-FBB040?style=for-the-badge&logo=homebrew&logoColor=black"></a>
</p>

[English](README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md)

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=22&pause=1000&color=BD93F9&center=true&vCenter=true&width=600&lines=chezmoi+%2B+Nix+%E5%A3%B0%E6%98%8E%E5%BC%8F%E5%BC%80%E5%8F%91%E7%8E%AF%E5%A2%83;%E8%B7%A8%E5%B9%B3%E5%8F%B0+macOS+%2B+Linux+%E6%94%AF%E6%8C%81;Claude+Code+%E8%87%AA%E5%8A%A8%E6%8F%92%E4%BB%B6%E5%90%8C%E6%AD%A5;%E7%8E%B0%E4%BB%A3+Rust+CLI+%E5%B7%A5%E5%85%B7%E9%93%BE)](https://git.io/typing-svg)

</div>

---

## ✨ 亮点

- **跨平台**：同一套配置支持 macOS + Linux（`nix-darwin` + `flakey-profile`）
- **一键引导**：从裸机到完整环境，只需一条 `curl | sh`
- **Claude Code 集成**：50+ 多来源插件，自动同步更新
- **现代 CLI**：Rust 工具链（eza、bat、ripgrep、fd、zoxide）替代传统 Unix 命令
- **安全优先**：`age` 加密 + gopass 辅助密钥引导

---

## 💡 为什么选择这个仓库

- **Profile 全覆盖**：`.chezmoidata/` 驱动 `shared` / `work` / `private` 包，贯穿 Nix、Homebrew、MAS
- **端到端引导**：Nix 安装器自动选择最快的 Determinate 镜像，chezmoi 一次性渲染并应用模板
- **macOS 打磨**：nix-darwin 系统偏好、Homebrew + MAS 集成、应用后更新脚本
- **工作流护栏**：pre-commit（shellcheck、markdownlint、prettier、Nix lint）+ Claude Code hooks
- **DX 自动化**：Justfile 升级/清理、fzf 导航、AI 辅助提交信息
- **CI 一致性**：macOS + Linux 双平台模板渲染与 `nix flake check`
- **Claude Code Hooks**：自动格式化代码、强制使用 uv 替代 pip、阻止直接编辑 main 分支

---

## 🎯 设计理念

搭建一台新的开发机器很繁琐：几十个软件包要装、无数工具要配置、还有多年积累的小调整要记住。本仓库通过**完全声明式配置**解决这个问题——所有软件包、设置、dotfiles 都以代码定义，一条命令即可在任意机器上**完全复现**。

**核心原则：**

- **可复现性** — 任何机器、每一次，都是相同的环境
- **声明式** — 一切定义在代码中，版本控制
- **模块化** — 基于 Profile 的定制：工作/个人/无头服务器
- **AI 增强** — Claude Code 集成，提升开发工作流
- **安全优先** — 加密 secrets，集成 gopass

---

## 📑 目录

- [🚀 快速开始](#quick-start)
- [🧩 架构](#architecture)
- [🤖 Claude Code 集成](#claude-code-integration)
- [⚡ 工具链](#tool-chains)
- [🔧 Shell 函数](#shell-functions)
- [📦 包管理](#package-management)
- [🔄 日常操作](#daily-operations)
- [👤 多 Profile 配置](#multi-profile-configuration)
- [🔐 安全与加密](#security)
- [🙏 致谢](#acknowledgements)

---

> [!WARNING]
> **运行前请先阅读！** 本仓库包含会修改系统配置的脚本。
> 建议先 Fork 本仓库，再按自己的需求进行定制。

---

<a id="quick-start"></a>

## 🚀 快速开始

**方式一：直接运行 init 脚本（推荐）**

```bash
curl -fsLS https://raw.githubusercontent.com/signalridge/dotfiles/main/init.sh | sh
```

**方式二：安装 chezmoi 并 init**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply signalridge
```

**方式三：克隆到本地执行**

```bash
git clone https://github.com/signalridge/dotfiles.git
cd dotfiles && ./init.sh
```

上述命令会自动完成：

1. 安装 Nix（Determinate Systems 安装器）
2. 通过 Nix 安装 `age` 和 `gopass` 用于解密
3. 从 gopass 获取解密密钥（或提示手动设置）
4. 应用所有 dotfiles 和配置
5. 同步 Claude Code 插件

> [!IMPORTANT]
> **首次使用者**：当提示 `useEncryption` 时，请选择 **No**（默认值）。
> 加密设置仅适用于仓库所有者。如需启用加密，请修改：
>
> - `.chezmoiscripts/run_once_before_01_setup-encryption-key.sh`：修改 `KEY_FILE`、`KEY_PUB` 和 gopass 路径
> - `.chezmoi.toml.tmpl`：更新 `[age]` 部分的 `identity` 和 `recipientsFile` 路径

安装完成后，重启终端。macOS 用户运行 `just darwin` 激活 nix-darwin 配置。

---

<a id="architecture"></a>

## 🧩 架构

```
~/.dotfiles/
├── .chezmoidata/           # 模块化数据配置
│   ├── base.yaml           # 核心设置
│   ├── claude.yaml         # Claude Code 插件配置
│   └── versions.yaml       # 工具版本锁定
├── .chezmoiscripts/        # 引导与同步脚本
├── dot_claude/             # Claude Code 配置
│   ├── agents/             # AI 代理定义
│   ├── commands/           # 斜杠命令
│   ├── skills/             # 自动知识技能
│   ├── hooks/              # Git 与代码 Hooks
│   └── context/            # 参考文档
├── nix-config/             # Nix flake 配置
│   └── modules/            # nix-darwin / flakey-profile 模块
└── dot_custom/             # Shell 函数与别名
```

**chezmoi** 跨机器管理 dotfiles，支持模板、加密和平台条件判断。

**nix-darwin**（macOS）提供声明式系统配置，管理系统包、Homebrew 和 macOS 偏好设置。

**flakey-profile**（Linux）使用同一 Nix flake 提供声明式包管理，专注于用户包。

| 组件     | macOS          | Linux          |
| -------- | -------------- | -------------- |
| Dotfiles | chezmoi        | chezmoi        |
| 系统配置 | nix-darwin     | N/A            |
| 用户包   | flakey-profile | flakey-profile |
| GUI 应用 | Homebrew Cask  | N/A            |

---

<a id="claude-code-integration"></a>

## 🤖 Claude Code 集成

本 dotfiles 包含完整的 Claude Code 配置与自动化插件管理。

### 插件系统

插件通过 `.chezmoiexternal.toml.tmpl` 从多个来源自动下载：

| 来源                                                      | 说明                                     |
| --------------------------------------------------------- | ---------------------------------------- |
| [wshobson/agents](https://github.com/wshobson/agents)     | 50+ 社区插件（agents、commands、skills） |
| [anthropics/skills](https://github.com/anthropics/skills) | 官方文档处理（pdf、docx、pptx、xlsx）    |
| [obra/superpowers](https://github.com/obra/superpowers)   | 高级工作流模式                           |

```yaml
# .chezmoidata/claude.yaml
claude:
  wshobsonAgents:
    include:
      - python-development
      - javascript-typescript
      - backend-development
      - tdd-workflows
      - cloud-infrastructure
      # ... 共 19 个插件
  anthropicsSkills:
    include:
      - pdf
      - docx
```

chezmoi external 会自动：

- 在 `chezmoi apply` 时下载已启用的插件
- 将 agents、commands、skills 解压到 `~/.claude/`
- 配置变更时自动更新

### 质量协议

内置质量保证（灵感来自 SuperClaude）：

| 协议                 | 用途                          |
| -------------------- | ----------------------------- |
| **Confidence Check** | 实现前评估（HIGH/MEDIUM/LOW） |
| **Self-Check**       | 实现后验证（附带证据）        |

### Hooks

| Hook                    | 触发时机      | 动作                                 |
| ----------------------- | ------------- | ------------------------------------ |
| `format-code.sh`        | Edit/Write 后 | 自动格式化 Nix、JSON、YAML、Shell 等 |
| `enforce-uv.sh`         | pip 命令时    | 重定向到 `uv`                        |
| `block-main-edits.sh`   | 文件编辑时    | 阻止直接编辑 main 分支               |
| `block-git-rewrites.sh` | git 命令时    | 阻止 force push 和历史重写           |

---

<a id="tool-chains"></a>

## ⚡ 工具链

用现代 Rust 工具替代传统 Unix 命令。

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
| [starship](https://github.com/starship/starship)    | 极简、飞快的提示符     |
| [sheldon](https://github.com/rossmacarthur/sheldon) | 快速 zsh 插件管理器    |
| [atuin](https://github.com/atuinsh/atuin)           | 支持模糊搜索的命令历史 |
| [direnv](https://github.com/direnv/direnv)          | 按目录自动加载环境变量 |
| [fzf](https://github.com/junegunn/fzf)              | 文件/历史等模糊查找器  |

### 开发工具

| 工具                                                | 作用                                    |
| --------------------------------------------------- | --------------------------------------- |
| [mise](https://github.com/jdx/mise)                 | 多语言运行时管理（Node/Python/Go/Rust） |
| [lazygit](https://github.com/jesseduffield/lazygit) | 终端 Git UI                             |
| [yazi](https://github.com/sxyazi/yazi)              | 超快的终端文件管理器                    |
| [tmux](https://github.com/tmux/tmux)                | 终端复用器（支持浮动窗格）              |

---

<a id="shell-functions"></a>

## 🔧 Shell 函数

### 项目跳转

```bash
dev                 # FZF 驱动的项目选择器（基于 ghq）
mkcd <dir>          # 创建目录并 cd 进入
dotcd               # 跳转到 chezmoi 源目录
```

### Git 工作流

```bash
fgc                 # 模糊切换 git 分支（带预览）
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

<a id="package-management"></a>

## 📦 包管理

| 来源           | 平台         | 说明               |
| -------------- | ------------ | ------------------ |
| Nix packages   | macOS, Linux | 可复现、可回滚     |
| Homebrew casks | 仅 macOS     | GUI 应用           |
| Mac App Store  | 仅 macOS     | App Store 独占应用 |

所有软件包清单都在 `.chezmoidata/` 中定义，支持 shared / work-only / private-only 分类。

---

<a id="daily-operations"></a>

## 🔄 日常操作

```bash
# Chezmoi 操作
just apply          # 应用 dotfiles 变更
just diff           # 查看待应用的差异

# Nix 操作
just up             # 更新所有 flake 输入
just switch         # 切换 flakey-profile（重建软件包）
just darwin         # 重建 nix-darwin（macOS）

# 维护
just gc             # 清理 nix store
just full-upgrade   # 完整系统升级
```

---

<a id="multi-profile-configuration"></a>

## 👤 多 Profile 配置

```bash
# 工作机器
chezmoi init --apply --promptBool work=true signalridge

# 个人机器（默认）
chezmoi init --apply signalridge

# 无头服务器（不需要 GUI 配置）
chezmoi init --apply --promptBool headless=true signalridge
```

---

<a id="security"></a>

## 🔐 安全与加密

本仓库使用 `age` 加密私密文件。Chezmoi 使用 `~/.ssh/main`（私钥）和 `~/.ssh/main.pub`（接收者）进行解密。

首次 apply 时，引导脚本会：

1. 安装 Nix
2. 通过 Nix 安装 `age` + `op`
3. 从 gopass 获取密钥（或提示手动设置）

---

<a id="acknowledgements"></a>

## 🙏 致谢

- [chezmoi](https://github.com/twpayne/chezmoi) - Dotfiles 管理器
- [nix-darwin](https://github.com/LnL7/nix-darwin) - 声明式 macOS 配置
- [flakey-profile](https://github.com/lf-/flakey-profile) - 跨平台 Nix profile 管理
- [wshobson/agents](https://github.com/wshobson/agents) - Claude Code 插件 marketplace
- [anthropics/skills](https://github.com/anthropics/skills) - 官方 Claude Code skills
- [obra/superpowers](https://github.com/obra/superpowers) - 高级工作流模式
- [Dracula Theme](https://draculatheme.com/) - 漂亮的深色主题

---

## 📈 统计

![Repobeats](https://repobeats.axiom.co/api/embed/b47788b120b4e3a0f049b72115d88268d5523f64.svg "Repobeats analytics")

---

## 📝 许可证

MIT License
