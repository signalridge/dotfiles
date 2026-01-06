<div align="center">

![header](https://capsule-render.vercel.app/api?type=waving&color=0:282a36,100:bd93f9&height=200&section=header&text=~/.dotfiles&fontSize=48&fontColor=f8f8f2&fontAlignY=30&desc=One%20command%20%C2%B7%20Full%20environment%20%C2%B7%20Zero%20hassle&descSize=16&descColor=8be9fd&descAlignY=55&animation=fadeIn)

**chezmoi + Nix · 跨平台开发环境 (macOS / Linux)**

[English](README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md)

<p>
  <a href="https://github.com/signalridge/dotfiles/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/signalridge/dotfiles/ci.yml?style=for-the-badge&logo=github&label=CI"></a>&nbsp;
  <a href="https://opensource.org/licenses/MIT"><img alt="License" src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge"></a>&nbsp;
  <img alt="macOS" src="https://img.shields.io/badge/macOS-Sonoma+-000000?style=for-the-badge&logo=apple&logoColor=white">&nbsp;
  <img alt="Linux" src="https://img.shields.io/badge/Linux-supported-FCC624?style=for-the-badge&logo=linux&logoColor=black">
</p>

<p>
  <a href="https://github.com/twpayne/chezmoi"><img alt="chezmoi" src="https://img.shields.io/badge/chezmoi-4B91E2?style=for-the-badge&logo=chezmoi&logoColor=white"></a>&nbsp;
  <a href="https://github.com/LnL7/nix-darwin"><img alt="nix-darwin" src="https://img.shields.io/badge/nix--darwin-5277C3?style=for-the-badge&logo=nixos&logoColor=white"></a>&nbsp;
  <a href="https://www.zsh.org/"><img alt="zsh" src="https://img.shields.io/badge/zsh-F15A24?style=for-the-badge&logo=zsh&logoColor=white"></a>&nbsp;
  <a href="https://brew.sh/"><img alt="Homebrew" src="https://img.shields.io/badge/Homebrew-FBB040?style=for-the-badge&logo=homebrew&logoColor=black"></a>
</p>

*基于 Nix 与 chezmoi 的现代、可复现开发环境，同时支持 macOS 与 Linux*
</div>

本仓库提供一套完全声明式的系统配置：能在几分钟内把一台全新的机器引导到可用状态，并自动应用所有软件包、系统设置与 dotfiles。整套方案围绕 Rust 编写的 CLI 工具构建，追求极致性能，并支持多 Profile 配置，便于在工作与个人环境之间无缝切换。

---

## 📑 目录

- [亮点](#highlights)
- [项目优势](#project-advantages)
- [动机](#motivation)
- [快速开始](#quick-start)
- [安全与加密](#security)
- [架构](#architecture)
- [工具链](#tool-chains)
- [Shell 函数](#shell-functions)
- [包管理](#package-management)
- [日常操作](#daily-operations)
- [多 Profile 配置](#multi-profile-configuration)
- [键盘快捷键](#keyboard-shortcuts)
- [主题](#theming)
- [统计](#stats)
- [致谢](#acknowledgements)
- [许可证](#license)

---

> [!WARNING]
> **运行前请先阅读！** 本仓库包含会修改系统配置的脚本。
> 在不了解其作用前，不要盲目执行安装/初始化命令。
> 建议先 Fork 本仓库，再按自己的需求进行定制。

---

<a id="highlights"></a>

## ✨ 亮点

- **跨平台**：同一套配置支持 macOS + Linux（`nix-darwin` + `flakey-profile`）
- **自动引导**：首次 `apply` 会安装 Nix（Determinate）、切换 Nix profile，并在 macOS 上维护 Homebrew
- **私密文件**：使用 `age` 加密（可选通过 1Password 自动获取密钥）
- **多 Profile**：`work` / `private` / `headless` 通过 `chezmoi init` 的交互提示（prompts）控制
- **效率工具链**：现代 CLI、统一主题、以及 AI 辅助工具

---

<a id="project-advantages"></a>

## 💡 项目优势

- **一体化引导**：Nix 安装器自动测速选择 Determinate 镜像，chezmoi 统一渲染并应用模板
- **Profile 全覆盖**：`.chezmoidata.yaml` 驱动 `shared/work/private` 软件包，贯穿 Nix、Homebrew、MAS
- **macOS 体验打磨**：nix-darwin 系统偏好设置 + Homebrew/MAS 集成 + 应用后自动更新脚本
- **安全优先的私密管理**：`age` 加密并结合 1Password 导入密钥，路径固定便于审计
- **工作流护栏**：pre-commit（shellcheck/markdownlint/prettier/Nix 格式化与 lint）+ Claude Code hooks 阻止危险 git 操作并强制 `uv`
- **效率自动化**：Justfile 升级/清理、fzf 导航增强、AI 生成提交信息
- **CI 一致性**：CI 在 macOS + Linux 上渲染模板并执行 `nix flake check`

---

<a id="motivation"></a>

## 🎯 动机

搭建一台新的开发机器很繁琐：你需要安装几十个软件包、配置无数工具，并记住这些年积累下来的各种小调整。本仓库通过以下方式解决这个问题：

- **声明式配置** - 所有软件包、设置与配置文件都以代码方式定义
- **可复现** - 一条命令即可在任意机器上获得完全一致的环境
- **跨平台** - 同时支持 macOS 与 Linux，并针对各平台进行优化
- **版本控制** - 持续追踪系统配置的变更历史
- **多 Profile 支持** - 为工作/个人机器提供不同的软件包集合

---

<a id="quick-start"></a>

## 🚀 快速开始

**方式一：直接从 GitHub 运行 init 脚本（推荐）**

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

上述任一命令都会自动完成：

1. 安装 Nix（Determinate Systems 安装器）
2. 通过 Nix 安装 `age` 和 `1password-cli` 用于解密
3. 从 1Password 获取解密密钥（或提示手动设置）
4. 应用所有 dotfiles 和配置

> [!IMPORTANT]
> **首次使用者**：当提示 `useEncryption` 时，请选择 **No**（默认值）。
> 加密设置仅适用于仓库所有者。如需启用加密，请修改：
>
> - `.chezmoiscripts/run_once_before_01_setup-encryption-key.sh`：修改 `KEY_FILE`、`KEY_PUB` 和 1Password 路径（`op://Personal/main/...`）
> - `.chezmoi.toml.tmpl`：更新 `[age]` 部分的 `identity` 和 `recipientsFile` 路径

安装完成后，重启终端。macOS 用户运行 `just darwin` 激活 nix-darwin 配置。

---

<a id="security"></a>

## 🔐 私密信息与加密

本仓库使用 `age` 加密管理私密文件（例如 `private_dot_ssh/encrypted_private_config.tmpl.age`）。`chezmoi` 会根据 `.chezmoi.toml.tmpl` 使用 `~/.ssh/main`（私钥）和 `~/.ssh/main.pub`（接收者/recipient）进行解密。

首次 apply 时，引导脚本会：

1. 安装 Nix（`run_once_before_00_install-nix.sh`）
2. 通过 Nix 安装 `age` + `op` 并尝试从 1Password 获取密钥（`run_once_before_01_setup-encryption-key.sh`）

如果 1Password 不可用，脚本会退出并提示手动设置步骤。

如果你 fork 了本仓库，请按你的环境修改密钥路径与 1Password 条目路径。

---

<a id="architecture"></a>

## 🧩 架构

这套 dotfiles 方案将多款强大的工具组合在一起，实现跨平台配置：

**chezmoi** 用于跨机器管理 dotfiles，支持模板与私密信息（secrets），并确保配置文件始终保持同步。以 `dot_` 前缀命名的文件会生成对应的点文件（dotfile），`.tmpl` 文件会作为 Go 模板处理，支持平台条件判断。

### macOS 配置

**nix-darwin** 提供声明式的 macOS 系统配置：通过 Nix 与 Homebrew（formula/cask）管理系统软件包，并设置 macOS 系统偏好。整个系统状态由 Nix 表达式描述，可原子化地构建与切换。

### Linux 配置

**flakey-profile** 为 Linux 提供声明式的包管理。它使用与 macOS 相同的 Nix flake，但不涉及系统级配置，专注于用户软件包，可在任何 Linux 发行版上使用。

### 协同工作方式

| 组件 | macOS | Linux |
| ---- | ----- | ----- |
| Dotfiles | chezmoi | chezmoi |
| 系统配置 | nix-darwin | N/A |
| 用户软件包 | flakey-profile | flakey-profile |
| GUI 应用 | Homebrew Cask | N/A |
| Mac App Store | mas | N/A |

---

<a id="tool-chains"></a>

## ⚡ 工具链

该配置用现代、Rust 编写的替代品取代传统 Unix 工具：更快、更易用，并提供更合理的默认值。

### 现代 CLI 替代方案

| 传统   | 现代                                              | 说明                                 |
| ------ | ------------------------------------------------- | ------------------------------------ |
| `ls`   | [eza](https://github.com/eza-community/eza)       | git 集成、图标、树形视图             |
| `cat`  | [bat](https://github.com/sharkdp/bat)             | 语法高亮、git 集成                   |
| `grep` | [ripgrep](https://github.com/BurntSushi/ripgrep)  | 极速正则搜索                         |
| `find` | [fd](https://github.com/sharkdp/fd)               | 更直观的语法，遵循 `.gitignore`      |
| `du`   | [dust](https://github.com/bootandy/dust)          | 可视化磁盘占用分析                   |
| `df`   | [duf](https://github.com/muesli/duf)              | 美观的磁盘剩余空间表格               |
| `cd`   | [zoxide](https://github.com/ajeetdsouza/zoxide)   | 智能目录跳转                         |
| `man`  | [tldr](https://github.com/tldr-pages/tlrc)        | 更实用的命令示例                     |
| `time` | [hyperfine](https://github.com/sharkdp/hyperfine) | 命令基准测试                         |

### Shell 环境

Shell 提示符由 **Starship** 驱动：Rust 编写、轻量且快速。使用 Dracula 配色，并展示 git 状态、当前目录与编程语言版本等上下文信息。

**Sheldon** 用于高效管理 zsh 插件。相比 oh-my-zsh 或 zinit，Sheldon 由 Rust 编写，加载速度更快，并支持对非关键插件进行可选的延迟加载。

**Atuin** 彻底升级了 shell 历史：将命令记录存入 SQLite，并支持全局模糊搜索。按下 Ctrl+R，就能立刻找回三个月前那条复杂命令。

**Direnv** 会在进入/离开目录时自动加载/卸载环境变量。配合本仓库提供的辅助函数，可以快速为项目创建 Python virtualenv、Nix flake 开发环境，或 mise 环境。

| 工具                                                                            | 作用                           |
| ------------------------------------------------------------------------------- | ------------------------------ |
| [starship](https://github.com/starship/starship)                                | 极简、飞快的提示符（含 git 信息） |
| [sheldon](https://github.com/rossmacarthur/sheldon)                             | 快速、可配置的 zsh 插件管理器  |
| [atuin](https://github.com/atuinsh/atuin)                                       | 支持模糊搜索的增强命令历史     |
| [direnv](https://github.com/direnv/direnv)                                      | 按目录自动加载环境变量         |
| [fzf](https://github.com/junegunn/fzf)                                          | 文件/历史等模糊查找器          |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)         | Fish 风格命令建议              |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | 命令语法高亮                   |

### 开发工具

**mise**（前身 rtx）是多语言运行时管理器，可管理 Node.js、Python、Go、Rust、Terraform 等。相比 nvm/pyenv/rbenv 更快，并提供统一的接口。

**lazygit** 提供漂亮的终端 git UI，让交互式 rebase、cherry-pick 与冲突处理等复杂操作更易上手。

**yazi** 是超快的终端文件管理器，支持图片预览，是 ranger 的现代替代品，使用 Rust 编写以追求性能。

本仓库的 **tmux** 配置包含 vim 风格按键、Dracula 主题色，以及用于快速打开 lazygit/htop 的弹窗窗口。前缀键为 Ctrl+B（默认）。

| 工具                                                | 作用                                   |
| --------------------------------------------------- | -------------------------------------- |
| [mise](https://github.com/jdx/mise)                 | 多语言运行时管理器（Node/Python/Go/Rust） |
| [lazygit](https://github.com/jesseduffield/lazygit) | 终端 git UI                            |
| [yazi](https://github.com/sxyazi/yazi)              | 超快的终端文件管理器                   |
| [tmux](https://github.com/tmux/tmux)                | 终端复用器（支持弹窗窗口）             |
| [ghq](https://github.com/x-motemen/ghq)             | 远程仓库管理                           |
| [gh](https://github.com/cli/cli)                    | GitHub CLI（Issue、PR 等）             |

### AI 集成

**Claude Code** 已直接集成到 shell 环境中。`aicommit` 函数可根据已暂存的变更，通过 AI 生成 Conventional Commits 风格的提交信息。Starship 提示符也可选择显示 Claude API 使用统计。

### 桌面应用（仅 macOS）

GUI 应用通过 Homebrew cask 管理：

| 分类     | 应用                              |
| -------- | --------------------------------- |
| 终端     | Ghostty, iTerm2                   |
| 编辑器   | Neovim, VS Code, Cursor           |
| 浏览器   | Arc (Dia)                         |
| 窗口管理 | AeroSpace（i3 风格平铺）           |
| 生产力   | Notion, Obsidian, Logseq, Raycast |
| 容器     | OrbStack（Docker 替代）           |

---

<a id="shell-functions"></a>

## 🔧 Shell 函数

除了 alias，这套配置还提供了一些面向常用工作流的 shell 函数。

如果有不想提交到仓库的本机改动，可以写到 `~/.custom/local.sh`（存在时会被自动 `source`）。

### 项目跳转

`dev` 函数把 **ghq** 与 **fzf** 组合起来做项目管理：输入 `dev` 后，会出现一个可模糊搜索的仓库列表（带目录树预览）；选中后立刻进入项目目录，同时把 tmux 会话重命名为项目名。

```bash
dev                 # FZF 驱动的项目选择器（基于 ghq）
mkcd <dir>          # 创建目录并 cd 进入
dotcd               # 跳转到 chezmoi 源目录
dotfiles            # 用编辑器打开 dotfiles
```

### Git 工作流

`fgc` 提供带日志预览的模糊分支切换；`fgl` 用于浏览提交记录并预览完整 diff；`fga` 列出未暂存文件并支持选择性暂存。这些函数让复杂的 git 操作变得更自然。

```bash
fgc                 # 模糊切换 git 分支（带预览）
fgl                 # 模糊浏览 git log
fga                 # 模糊 git add（选择文件）
aicommit            # 使用 AI 生成提交信息
```

### 系统工具

`fkill` 提供带确认提示的安全进程终止，不用再担心误杀关键进程；`port` 可以快速查看某个端口被哪个进程占用；`backup_dev_env` 用于导出当前 Brewfile、VS Code 扩展与 mise 工具清单，便于备份。

```bash
fkill               # 模糊选择并结束进程（带确认）
fenv                # 模糊查看环境变量
port <num>          # 查看占用端口的进程
backup_dev_env      # 备份开发环境配置
```

### 环境初始化

`create_direnv_venv` 一条命令创建 Python virtualenv 并与 direnv 集成；`create_direnv_nix` 则用于创建 Nix flake 开发环境并接入 direnv。

```bash
create_direnv_venv  # 创建 Python venv + direnv
create_direnv_nix   # 创建 Nix flake + direnv
create_direnv_mise  # 创建 mise 环境 + direnv
create_py_project   # 使用 uv 快速初始化 Python 项目
```

---

<a id="package-management"></a>

## 📦 包管理

软件包来自多个来源，各有所长：

| 来源              | 平台          | 说明                   | 示例                             |
| ----------------- | ------------- | ---------------------- | -------------------------------- |
| Nix packages      | macOS, Linux  | 可复现、可回滚         | ripgrep, bat, eza, starship      |
| Homebrew formulas | 仅 macOS      | macOS 特定工具         | macos-trash, cliclick            |
| Homebrew cask     | 仅 macOS      | GUI 应用               | VS Code, Ghostty, Notion         |
| Mac App Store     | 仅 macOS      | App Store 独占应用     | Magnet, WeChat, Office           |

所有软件包清单都在 `.chezmoidata.yaml` 中定义，并支持 shared / work-only / private-only 的分类管理。

---

<a id="daily-operations"></a>

## 🔄 日常操作

所有常用操作都通过 Justfile 统一入口（由 `Justfile.tmpl` 渲染到 `~/Justfile`）。若本机还没有 `just`，可用 `nix run --extra-experimental-features 'nix-command flakes' nixpkgs#just -- <task>` 直接运行：

### 跨平台命令

```bash
# Chezmoi 操作
just apply          # 应用 dotfiles 变更
just diff           # 查看待应用的差异
just re-add         # 重新添加被修改的文件

# Nix 操作
just up             # 更新所有 flake 输入
just switch         # 切换 flakey-profile（重建软件包）
just gc             # 清理未使用的 nix store
just optimize       # 优化 nix store（硬链接去重）

# 开发
just check          # 运行 pre-commit 检查

# 一键合集
just full-upgrade   # 完整系统升级
just update-all     # 更新 flake + chezmoi（macOS 还包括 homebrew）
```

### 仅 macOS 命令

```bash
# Nix-darwin 操作
just darwin         # 重建并切换配置
just darwin-debug   # 以详细输出构建

# 维护
just history        # 列出所有系统 profile generation
just clean          # 清理 7 天前的 generation
just clean-all      # nix gc + brew cleanup
```

---

<a id="multi-profile-configuration"></a>

## 👤 多 Profile 配置

该配置支持为不同机器准备不同的方案。在 `.chezmoidata.yaml` 中，软件包分为三类：

- **shared** - 所有机器都安装
- **work** - 仅工作机器安装（Azure CLI、Cursor 等）
- **private** - 仅个人机器安装（1Password、游戏相关等）

`work` 是主要开关：当 `work=false`（默认）时会自动启用 `private=true`。`headless=true` 会跳过 AeroSpace/Karabiner 等 GUI 配置。若提示输入 `hostname`，请填写 `hostname -s` 的输出（会作为 flake 的名字使用）。

```bash
# 工作机器
chezmoi init --apply --promptBool work=true signalridge

# 个人机器（默认：work=false -> private=true）
chezmoi init --apply signalridge

# 无头服务器（不需要 GUI 配置）
chezmoi init --apply --promptBool headless=true signalridge
```

---

<a id="keyboard-shortcuts"></a>

## ⌨️ 键盘快捷键

| 快捷键     | 动作                     |
| ---------- | ------------------------ |
| Alt + Up   | 返回上级目录             |
| Alt + Down | 回到目录历史             |
| Ctrl + R   | 搜索命令历史（Atuin）    |
| Ctrl + B   | tmux 前缀键              |

---

<a id="theming"></a>

## 🌙 主题

所有工具都统一使用 **Dracula** 配色，保证一致且护眼的深色主题体验：

- Starship 提示符配色
- tmux 状态栏
- bat 语法高亮
- lazygit 界面
- yazi 文件管理器

---

<a id="stats"></a>

## 📈 统计

![Repobeats](https://repobeats.axiom.co/api/embed/b47788b120b4e3a0f049b72115d88268d5523f64.svg "Repobeats analytics")

---

<a id="acknowledgements"></a>

## 🙏 致谢

这套 dotfiles 站在巨人的肩膀上。特别感谢：

- [chezmoi](https://github.com/twpayne/chezmoi) by [@twpayne](https://github.com/twpayne) - 强大的 dotfiles 管理器
- [nix-darwin](https://github.com/LnL7/nix-darwin) by [@LnL7](https://github.com/LnL7) - 基于 Nix 的声明式 macOS 配置
- [flakey-profile](https://github.com/lf-/flakey-profile) by [@lf-](https://github.com/lf-) - 跨平台 Nix profile 管理
- [Nix](https://nixos.org/) by [NixOS](https://github.com/NixOS) - 纯函数式包管理器
- [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) by [@DeterminateSystems](https://github.com/DeterminateSystems)
- [Sheldon](https://github.com/rossmacarthur/sheldon) by [@rossmacarthur](https://github.com/rossmacarthur) - 快速的 zsh 插件管理器
- [Dracula Theme](https://draculatheme.com/) by [@zenorocha](https://github.com/zenorocha) - 漂亮的深色主题

以及其他所有让这套配置成为可能的开源项目与贡献者。

---

<a id="license"></a>

## 📝 许可证

本项目基于 MIT License 发布。
