<div align="center">

![header](https://capsule-render.vercel.app/api?type=waving&color=0:282a36,100:bd93f9&height=200&section=header&text=~/.dotfiles&fontSize=48&fontColor=f8f8f2&fontAlignY=30&desc=Chezmoi%20%C2%B7%20Nix%20%C2%B7%20AI%20tooling&descSize=16&descColor=8be9fd&descAlignY=55&animation=fadeIn)

<p>
  <a href="https://github.com/signalridge/dotfiles/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/signalridge/dotfiles/ci.yml?style=for-the-badge&logo=github&label=CI"></a>&nbsp;
  <img alt="macOS" src="https://img.shields.io/badge/macOS-supported-000000?style=for-the-badge&logo=apple&logoColor=white">&nbsp;
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

</div>

---

## 这个仓库是什么

这是一个使用 `chezmoi` 管理的个人工作站配置仓库。它是正在使用的真实
配置，而不是通用 starter template；下面只描述当前 checkout 中实际存在的
文件和行为。

主要层次：

- `chezmoi`：模板、目标文件合并和 bootstrap 脚本
- Nix：跨平台用户 profile；macOS 额外使用 `nix-darwin`
- Homebrew 与 Mac App Store：macOS 应用
- `aqua`：固定版本的 CLI 与第三方 registry 条目
- `mise`：有意放在 Nix 之外管理的 runtime 和工具
- Claude Code、Codex CLI、Pi、Cursor Agent CLI、Kimi Code 与 Antigravity CLI
  的配置

> 这里包含个人默认值，包括宽松的 AI 执行模式和私人机器应用。应用到其他
> 电脑前请先审阅模板和数据。

## 支持范围与 Profile 行为

| 范围               | 当前实际行为                                                                                                                                                          |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 操作系统           | bootstrap 脚本支持 macOS 和 Linux。                                                                                                                                   |
| 全新 Nix bootstrap | 固定 installer 资产覆盖 `aarch64-darwin`、`aarch64-linux`、`x86_64-linux`；Nix installer 脚本会拒绝全新的 `x86_64-darwin` 安装。                                      |
| `work`             | 添加 work Nix 包，并在 macOS 上添加 work Homebrew 包；设置 `private = false`。当前 work 集合包括 MariaDB、PostgreSQL、Redis、AWS/Azure 工具、DBeaver、GCloud CLI 等。 |
| `private`          | 由 `not work` 推导；因此 macOS 上 `work = false` 时会选择 private Homebrew cask 和 MAS 条目。当前 private Nix 包列表为空。                                            |
| `headless`         | 排除部分 GUI dotfiles 和 macOS 维护脚本（`09`、`17`、`22`）。它不是通用的包开关；macOS 上仍会渲染 nix-darwin/Homebrew 模块。                                          |
| Mac App Store      | private MAS 列表只有在 `installMasApps = true` 时才会安装。                                                                                                           |

## 亮点

- 覆盖 Nix、包 profile、CLI 工具、runtime、AI 集成、服务加载和维护任务的
  编号式 `chezmoi` 流程
- 锁定的 Nix flake，以及 shared/work/private 分层的 profile 数据
- 位于 `~/.harnesses/skills` 的共享 skills 库，可按项目激活到 Claude、
  Codex、Pi、Cursor 和 Kimi Code
- Pi 原生 provider/model 切换，以及 Claude Code/Codex CLI account wrapper
- 固定版本、带 checksum 校验的 Cursor Agent 与 Azure Functions installer，
  以及非 headless macOS 上的 Paperlib installer
- 固定 revision 的 Herdr plugins、Claude/Codex lifecycle integration，以及
  macOS/Linux 的孤儿 MCP 清理
- CI、安全扫描、回归测试和定期依赖更新 PR

## Source of Truth 与仓库结构

README 按当前实际源文件组织：

```text
.
├── .chezmoidata/
│   ├── nix.yaml              # Nix 用户/系统包数据
│   ├── homebrew.yaml         # taps、formulae、cask、MAS 条目
│   ├── claude.yaml           # Claude providers 与 accounts
│   ├── pi.yaml               # Pi 默认值、packages、custom providers
│   ├── herdr.yaml            # Herdr plugin revisions
│   ├── antigravity.yaml      # Antigravity CLI 设置
│   ├── aerospace.yaml        # AeroSpace 浮动窗口数据
│   ├── hammerspoon.yaml      # 应用到输入法的数据
│   └── versions.yaml         # installer、package 和 skill revisions
├── .chezmoiexternal.toml.tmpl # TPM 与共享 skills archive
├── .chezmoiscripts/           # 编号式 bootstrap/维护脚本
├── nix-config/                # flake、nix-darwin/profile 模块
├── dot_claude/                # Claude 设置、hooks、指令
├── dot_codex/                 # Codex 配置、prompts、指令
├── dot_pi/                    # Pi 设置、models、agents、MCP、themes
├── dot_cursor/                # Cursor CLI 设置与 MCP
├── dot_kimi-code/             # Kimi safety 设置与 MCP
├── dot_gemini/                # Antigravity CLI 合并配置
├── dot_harnesses/             # 本地 harness commands 与 skills
├── dot_local/bin/             # account、key、MCP、skill、status helpers
├── private_dot_config/        # shell、tmux、工具和服务配置
├── private_Library/           # macOS LaunchAgents
├── docs/                      # 专项运维指南
├── tests/                     # bootstrap 与集成回归测试
└── tools/                     # 独立工具（包括 WezTerm 图标）
```

## Bootstrap 流程：实际执行内容

标签从 `00` 到 `23`，但实际有 **两个独立的 `19` 脚本**。`run_onchange_*`
脚本在渲染后的源状态变化时执行（部分还包含每周触发器）；`run_after_*`
脚本会在 apply 后调用，再由脚本自行判断条件或执行周期限制。

| 标签  | 脚本                                                       | 条件与行为                                                                                                                                                   |
| ----- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `00`  | `run_onchange_before_00_install-nix.sh.tmpl`               | 安装或升级固定版本的 Determinate Nix；全新安装会选择镜像并校验 installer checksum。                                                                          |
| `01`  | `run_before_01_setup-encryption-key.sh.tmpl`               | 仅在 `useEncryption = true` 时渲染；clone/pull 配置的 keys-backup 仓库，并恢复 keys-manage 管理的文件。                                                      |
| `02`  | `run_onchange_after_02_init.sh.tmpl`                       | 仅 macOS；应用渲染后的 `nix-darwin` 配置。                                                                                                                   |
| `03`  | `run_onchange_after_03_set_profiles.sh.tmpl`               | 切换跨平台的 `flakey-profile` 用户包 profile。                                                                                                               |
| `04`  | `run_onchange_after_04_install-aqua.sh.tmpl`               | 使用校验过的 installer 安装或更新固定版本的 `aqua`。                                                                                                         |
| `05`  | `run_onchange_after_05_aqua-install-tools.sh.tmpl`         | 两阶段安装 aqua 包：先 bootstrap `mise`，注入 Go/Rust，再安装完整 aqua 集合。                                                                                |
| `06`  | `run_onchange_after_06_setup-gopass.sh.tmpl`               | 仅在启用加密时渲染；验证或交互式 clone 配置的 gopass store。                                                                                                 |
| `07`  | `run_onchange_after_07_mise-install.sh.tmpl`               | 安装 mise 配置的 runtime 与工具；`npm:` 条目使用 Bun。                                                                                                       |
| `08`  | `run_onchange_after_08_nix-index-db.sh.tmpl`               | 仅当 `nix-locate` 已安装时刷新固定版本的 nix-index 数据库。                                                                                                  |
| `09`  | `run_onchange_after_09_install-paperlib.sh.tmpl`           | 仅非 headless macOS；下载、校验、验证并安装固定版本的 Paperlib DMG。                                                                                         |
| `10`  | `run_after_10_update_homebrew_packages.sh`                 | macOS 且存在 Homebrew 时，每 7 天执行显式 update/repair/upgrade/cleanup；nix-darwin 自身也设置了 Homebrew `upgrade = true`。                                 |
| `11`  | `run_after_11_sync-claude-integration-plugins.sh`          | Claude Code 和 `jq` 存在时添加官方 marketplaces，并安装 Claude Slack 与 Notion workspace plugin。                                                            |
| `12`  | `run_after_12_sync-claude-mcp.sh.tmpl`                     | 对齐仓库拥有的 Claude user MCP 条目，并将 `context7`、`tavily`、`deepwiki` 设为 always loaded；不会删除其他用户条目，但会明确删除旧名称 `arxiv-mcp-server`。 |
| `13`  | `run_after_13_sync-codex-connector-plugins.sh`             | 尝试安装 `slack@openai-curated`；当前 Codex marketplace 不提供时跳过。                                                                                       |
| `14`  | `run_after_14_sync-herdr-integrations.sh`                  | 安装/更新 Claude 与 Codex 的 Herdr integration；删除 Herdr 自带的 Pi integration，因为仓库自己的 `pi-herdr-state` 才是权威实现。                             |
| `15`  | `run_after_15_cursor-agent.sh.tmpl`                        | macOS/Linux；下载带 checksum 校验的固定版本 Cursor Agent，并在 `~/.local/bin` 创建 `agent`、`cursor-agent` 链接。                                            |
| `16`  | `run_onchange_after_16_azure-functions-core-tools.sh.tmpl` | 仅 work 机器；从 Microsoft 固定的 Azure CDN archive 安装 `func`，不用 Homebrew 或 npm。                                                                      |
| `17`  | `run_onchange_after_17_load-launch-agents.sh.tmpl`         | 仅非 headless macOS；重载 qmk-hid-host 和 MCP reaper LaunchAgent，并移除旧的本地 Context7 agent。                                                            |
| `18`  | `run_onchange_after_18_herdr-plugins.sh.tmpl`              | 从 `.chezmoidata/herdr.yaml` 安装七个固定 revision 的 Herdr plugin。                                                                                         |
| `19a` | `run_after_19_remove-legacy-pi-sources.sh`                 | 删除旧 Pi extension 文件、package 声明、安装目录及过时 workflow/statusline 状态，不触碰 Pi session 或 auth。                                                 |
| `19b` | `run_onchange_after_19_load-systemd-user-units.sh.tmpl`    | 仅 Linux；启用 linger 和 `mcp-reaper.timer` systemd user unit，并禁用旧的本地 Context7 unit。                                                                |
| `20`  | `run_after_20_update-pi-extensions.sh.tmpl`                | Pi 已安装时，每个 ISO 周/package 集合运行一次 `pi update --extensions`；失败不阻断 apply，并在下次 apply 重试。                                              |
| `21`  | `run_onchange_after_21_terminal-profile.sh.tmpl`           | 仅非 headless macOS；安装托管的 Dracula Terminal.app profile 并设为默认。                                                                                    |
| `22`  | `run_after_22_wezterm-icon.sh`                             | 仅 macOS；需要时在 cask 替换 WezTerm 后重新应用自定义图标。                                                                                                  |
| `23`  | `run_after_23_mise-up.sh`                                  | 每 7 天运行 `mise up`；失败不致命，也不会推进成功时间戳。                                                                                                    |

## 快速开始

> [!WARNING]
> 应用本仓库会修改 shell 文件、包管理器、AI 设置，以及 macOS 上的系统/应用
> 设置。请先审阅模板和数据。

### 下载后交互式运行

```bash
curl -fsSL https://raw.githubusercontent.com/signalridge/dotfiles/main/init.sh -o /tmp/init.sh
sh /tmp/init.sh
```

不要使用 `curl … | sh`。首次运行需要询问 work/encryption 和身份数据；当前
模板在缺少必要数据且 stdin 不是 TTY 时会明确失败，不会写入占位值。先下载
可以保留终端输入。

### 固定 ref 并先审阅

```bash
REF="<tag-or-branch>"
curl -fsSLo /tmp/init.sh "https://raw.githubusercontent.com/signalridge/dotfiles/${REF}/init.sh"
# 审阅 / 可选地记录 /tmp/init.sh 的 checksum。
sh /tmp/init.sh --ref "${REF}"
```

### 使用本地 clone

```bash
git clone https://github.com/signalridge/dotfiles.git
cd dotfiles
./init.sh
```

在从远程仓库 bootstrap 时，`init.sh` 支持 `--repo`（或 `DOTFILES_REPO`）、
`--ref`/`--branch`（或 `DOTFILES_REF`）和 `--depth`（或 `DOTFILES_DEPTH`）。从
本地 clone 运行时，它直接使用当前 checkout；这些远程选择参数不会切换当前
checkout，请先切换到目标 ref 再运行。bootstrap 仅支持 HTTPS，`--ssh` 会被拒绝。
`DOTFILES_USE_ENCRYPTION=true|false` 可以覆盖加密选择，但不会取消其他首次运行
prompt。

直接调用 chezmoi 时，可通过 flag 或持久化 data 预先选择 profile，例如：

```bash
chezmoi init --apply \
  --promptBool work=false \
  --promptBool useEncryption=false \
  signalridge
```

## 首次运行数据

`.chezmoi.toml.tmpl` 实际使用以下数据：

| 数据                                            | 请求或使用时机                                                                                        |
| ----------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `work`                                          | 没有存储值时必需；TTY 下会询问，并据此推导 `private`。                                                |
| `useEncryption`                                 | 没有 data 或 `DOTFILES_USE_ENCRYPTION` 覆盖时必需；控制加密 key 恢复和 gopass 配置。                  |
| `hostname`                                      | 仅非 work 且没有存储值时询问；work 机器使用 `.chezmoi.hostname`。                                     |
| `gitUsername`、`gitEmail`                       | 缺失时询问，没有安全的身份默认值。                                                                    |
| `headless`                                      | TTY 下询问；非 TTY 使用存储值，否则使用基于 OS 的 fallback。                                          |
| `installMasApps`                                | macOS TTY prompt；未启用时默认不安装 MAS。                                                            |
| `homeWifiSSIDs`                                 | 可选的 macOS TTY prompt；逗号分隔的家庭 SSID，供 Hammerspoon 音量 watcher 使用。                      |
| `timezone`                                      | 尽可能从主机自动检测；否则 TTY 下询问，最终 fallback 到 `Etc/UTC`。                                   |
| `keysRepository`                                | 仅启用加密且没有存储值时询问；供 keys-manage restore 使用。                                           |
| `gopassRepository`                              | 仅启用加密且没有存储值时询问；供 gopass setup 使用。                                                  |
| `claudeProviderAccount`、`codexProviderAccount` | **不是 prompt**；默认分别为 `anthropic` 和 `openai`，可写入 chezmoi data，或由 account manager 修改。 |

当 `useEncryption = false` 时，加密恢复/gopass 脚本和托管的 `~/.ssh/*` 目标会被
忽略。启用加密后，bootstrap 可能需要 GitHub HTTPS 凭据：已有的 `gh` 登录、
`GH_TOKEN`/`GITHUB_TOKEN`，或交互式 device-code OAuth。

## 日常操作

交互式 shell 会导出
`JUSTFILE=${XDG_CONFIG_HOME:-$HOME/.config}/just/.justfile`（通常为
`~/.config/just/.justfile`）。这个全局 justfile 包含：

```bash
# Chezmoi
just apply
just diff
just update
just re-add

# Nix
just up                 # 更新全部 flake inputs
just upp nixpkgs        # 更新单个 input
just gc
just verify
just optimize

# 仅 macOS
just darwin
just darwin-check
just darwin-build
```

全局 justfile **不包含**回归测试 recipe。实际测试请运行：

```bash
bash "$(chezmoi source-path)/tests/run.sh"
pre-commit run --all-files
```

其他生成的 recipe 还有 `edit`、`history`、`repl`、`clean`、`repair`、`gcroot`
以及 Git 简写（`st`、`gd`、`gl`、`cm`、`push`、`pull`）；其中部分仅 macOS
可用。`clean` 和 `gc` 默认保留 7 天，也可以传参覆盖。

## 包与工具管理

包源是有意分层的，并不是所有清单都位于 `.chezmoidata/`。

| 层               | 源文件                                                            | 管理内容                                                                                                                                                              |
| ---------------- | ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Nix 用户 profile | `.chezmoidata/nix.yaml` + `nix-config/modules/profile.nix.tmpl`   | 通过 `flakey-profile` 管理 shared 包和 work 包；当前 `sysPkgs` 清单为空，macOS 系统设置/字体/服务仍由 `nix-darwin` 管理。                                             |
| nix-darwin       | `nix-config/modules/*.tmpl`                                       | macOS defaults、字体、shell/PAM 设置、Nix index、Homebrew 集成和系统 launchd jobs。                                                                                   |
| Homebrew         | `.chezmoidata/homebrew.yaml` + `nix-config/modules/apps.nix.tmpl` | taps、formulae、cask 和条件式 MAS 条目；不是锁定且可复现的 Nix 层。                                                                                                   |
| aqua             | `private_dot_config/aquaproj-aqua/aqua.yaml` 与 `registry.yaml`   | 固定版本 CLI，包括 Claude/Codex、shell 工具、Kubernetes/security 工具、Kimi Code、Herdr、Slipway 和 qmk-hid-host。                                                    |
| mise             | `private_dot_config/mise/config.toml.tmpl`                        | Node、Bun、Python、Go、Rust、Lua、Terraform、uv、pipx 工具、Pi、用量分析器、浏览器/媒体 CLI、`xurl` 和 `crosspost`。`npm:` 条目使用 Bun，但 Node 仍保留用于 runtime。 |
| 直接 installer   | `.chezmoiscripts/00`、`09`、`15`、`16`                            | Determinate Nix、Paperlib、Cursor Agent 和 work-only Azure Functions Core Tools，版本/checksum 均来自仓库数据。                                                       |
| Pi extensions    | `.chezmoidata/pi.yaml` + Pi settings                              | 五个外部 package 和二十个 `@signalridge` package；有意不 pin，由 Pi 每周的 `update --extensions` 刷新。                                                               |

代表性工具包括 `eza`、`bat`、`fd`、`ripgrep`、`fzf`、`gh`、`ghq`、`just`、
`lazygit`、`neovim`、`yazi`、`jj`、`xh`、`slumber`、`k9s`、`kubectl`、`helm`、
`trivy`、`syft`、`grype`、`ruff`、`ty`、`git-cliff`、`quarto`、`typst`、
`aichat`、`agent-browser`、`hyperframes` 和 `impeccable`。完整清单以实际源文件
为准。

## Shell Alias 与函数

Shell 配置只在交互式 zsh 中加载。下列 alias 只有在目标命令存在时才会创建：

| Alias                                                 | 目标                                                                             |
| ----------------------------------------------------- | -------------------------------------------------------------------------------- |
| `dot`                                                 | `chezmoi`                                                                        |
| `vi`、`vim`、`view`                                   | `nvim`                                                                           |
| `ls`、`cat`、`du`、`df`、`man`                        | `eza`、`bat`、`dust`、`duf`、`tldr`                                              |
| `hf`、`lg`、`lzd`、`top`、`pc`、`dog`、`logv`、`post` | `hyperfine`、`lazygit`、`lazydocker`、`btm`、`procs`、`doggo`、`lnav`、`posting` |
| `ccm`、`ccw`                                          | `claude-manage`、`claude-with`                                                   |
| `cxm`、`cxw`                                          | `codex-manage`、`codex-with`                                                     |
| `k` / `kubectl`                                       | 安装了 `kubecolor` 时使用它；否则 `k` 指向 `kubectl`                             |

`la`、`ll`、`lla`、`lt` 是 eza/listing helpers；`cp`、`mv`、`mkdir` 是带
交互/安全选项的 alias（`-i`/`-v`，以及 `mkdir -p`）。`ripgrep`、`fd`、
`zoxide` 会安装并集成，但 **`grep`、`find`、`cd` 并没有被 alias 替换**。

常用函数：

```bash
dev [query]                 # ghq + fzf 仓库选择器
mkcd <dir>                  # 创建目录并进入
dotcd                       # 跳转到 chezmoi source
fgc / fgl / fga              # 模糊分支、log、暂存文件辅助工具
aicommit [--dry-run] ...    # 根据 staged diff 生成 AI conventional commit
create_direnv_venv          # 写入 Python .envrc 并 allow
create_direnv_nix           # 向 .envrc 写入 use flake（不会创建 flake）
create_direnv_mise          # 向 .envrc 写入 use mise
create_py_project [name]    # uv init + direnv Python layout
```

其他函数包括 `ccnew`/`ccdone`、`wt-new`/`wt-go`/`wt-ls`/`wt-rm`、`gh_latest`、
`gh_clone`、`fkill`、`fenv`、`mcp-ps` 和 `mcp-reap`。`wt-*`、`cc*` 会为普通
仓库使用 Git worktree；不要在本 chezmoi source 中使用，因为仓库章程禁止
worktree 和 branch switching。`AICOMMIT_PROVIDER` 可取 `claude`、`codex`、
`auto`，托管 shell exports 的默认值是 `claude`。

## AI Harness 与 Provider 管理

### 托管的 harness

| Harness          | 托管文件与行为                                                                                                                                                                       |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Claude Code      | `~/.claude/settings.json`、全局指令、hooks、statusline 和官方 integration plugins。                                                                                                  |
| Codex CLI        | `~/.codex/config.toml`、project-document fallback 列表、lifecycle hooks、MCP 和 Slack plugin 配置。                                                                                  |
| Pi               | `~/.pi/agent/settings.json`、`models.json`、`subagents.json`、workflow settings、themes、keybindings 和 MCP。Pi 使用原生 `/model`、`/login`；没有 Pi account wrapper 或 `pi-token`。 |
| Cursor Agent CLI | 固定版本的 `agent`/`cursor-agent` binary，以及 `~/.cursor/cli-config.json`、`~/.cursor/mcp.json`。                                                                                   |
| Kimi Code        | `~/.kimi-code/config.toml` safety defaults 和 `~/.kimi-code/mcp.json`；没有 account wrapper。                                                                                        |
| Antigravity CLI  | 合并到 `~/.gemini/antigravity-cli/settings.json`；保留 runtime 管理的 model/trust 设置。                                                                                             |
| aichat           | `~/.config/aichat/config.yaml`；当对应 `pi/...` gopass key 存在时写入 Kimi Moonshot 和 Doubao。                                                                                      |

### Claude 与 Codex accounts

`.chezmoidata/claude.yaml` 当前的 Claude providers 是 `anthropic`、`deepseek`、
`kimi`、`glm`、`qwen`、`minimax`、`doubao`。已配置 accounts 是 `anthropic`、
`opus`、`haiku`、`deepseek@private`、`doubao@private`、`kimi@private`。
原生 Anthropic account 使用 OAuth；第三方 Claude key 使用以下形式的 gopass
路径：

```text
claude/<provider>/<account-label>/api_key
```

Codex 保留 `openai` 原生 OAuth，并渲染 DeepSeek、Doubao、GLM、Kimi、MiniMax、
Qwen 的第三方 provider block。Codex API key 使用：

```text
codex/<provider>/<account-label>/api_key
```

持久切换使用 `claude-manage`/`codex-manage`；单次启动路由使用
`claude-with`/`codex-with`。token helper 只读取/检查 key 或输出合并后的 account
配置，不负责切换 account。

```bash
claude-manage list
claude-manage switch kimi@private
claude-with kimi@private -- --resume
claude-token --check kimi@private

codex-manage list
codex-manage switch openai
codex-with deepseek@private "explain this file"
codex-token --check deepseek@private
```

### Pi 策略

Pi 托管的启动默认值是 `openai-codex/gpt-5.6-luna`、
`signalridge-ridgeline` theme、quiet startup、Bun-backed package 安装，以及
原生 compaction/retry 设置。父 session 的 effort 按机器区分：private 使用
`max`，work 使用 `xhigh`。

`subagents.json` 只定义三个命名 tier：`low`、`medium`、`high`。它们的
model/effort 也按机器区分；workflow settings 将 workflow strength
`low`/`medium`/`high` 直接映射到同名 tier。旧的独立 workflow model vocabulary
不属于当前配置。

Pi 所需的 custom provider key 按 service 放在 `pi/` 下（例如
`pi/opencode/api_key`、`pi/deepseek/api_key`、`pi/kimi/api_key`）。使用缺失 gopass
key 的 provider 在渲染 `models.json` 时会被跳过；使用环境变量的 provider 会保留
`$VAR` 引用，调用时如果变量未设置才会失败。aichat 使用的 Moonshot 平台 key
单独位于 `pi/moonshot/api_key`，它不是 Kimi Code subscription key。

### 共享 Skills

`.chezmoiexternal.toml.tmpl` 将硬编码且固定 revision 的 skills archive 下载到：

```text
~/.harnesses/skills/<category>/<skill>/
```

来源包括 wshobson/agents、anthropics/skills、OpenAI、Hugging Face、Sentry、
Trail of Bits、Cloudflare、Vercel、Supabase、Expo、Microsoft、Baoyu、
phuryn/pm-skills、Reddit/daily.dev/X publishing skills、UI/UX/diagram skills，
以及 Go/Rust/Swift/TypeScript 套件。这些是共享 library 条目，不是统一安装 Claude
marketplace。全局 `ai-research-skills` CLI 由 mise 的 pipx/uvx backend 单独管理；
不会安装 host skills 或 commands。

在项目目录运行 `skill-activate`，会将同一批选中的 skills 以 flat symlink 写入：

```text
./.claude/skills  ./.codex/skills  ./.pi/skills
./.cursor/skills  ./.kimi-code/skills
```

可用模式包括 `--active`、`--list`、`--category <name>`、`--sync`、`--clear`。
默认不会全局激活 skills。

### Plugins、MCP 与 Herdr

官方 plugin/connector 与共享 skills 库是两套机制：

- Claude 尝试安装 `slack@claude-plugins-official` 和
  `notion-workspace-plugin@notion-plugin-marketplace`。
- Codex 尝试添加 `slack@openai-curated`；当前 marketplace 不提供时跳过。
- Herdr 从 `.chezmoidata/herdr.yaml` 安装七个固定 plugin，并安装 Claude/Codex
  lifecycle integration。Herdr 自带的 Pi integration 会被明确删除，仓库自己的
  `pi-herdr-state` 才是 reporter。

各 harness 的 MCP 声明并不完全相同：

| Harness        | 托管的 MCP 条目                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------- |
| Claude         | `context7`、`markitdown`、`arxiv`、`tavily`、`gitmcp`、`deepwiki`；`context7`/`tavily`/`deepwiki` always loaded。     |
| Codex          | Notion 加上上面的六个条目。                                                                                           |
| Pi             | `context7`、`deepwiki`、`gitmcp` 是 lazy direct tools；`markitdown`、`arxiv` 是 lazy proxy tools。这里不声明 Tavily。 |
| Cursor 与 Kimi | `context7`、`tavily`、`deepwiki`、`gitmcp`、`markitdown`、`arxiv`。                                                   |

`~/.local/bin/mcp-tavily` 运行时从 gopass 读取 `tavily/api_key`，再通过
`bunx` 启动固定版本的 `tavily-mcp@0.2.16`。当对应的非 headless macOS 或
systemd-user 配置启用时，LaunchAgent 或 user timer 会运行 `mcp-reaper`，记录并
杀掉孤儿本地 MCP 进程，不触碰仍属于活动 session 的进程。

### AI 执行权限姿态

托管默认值有意偏宽松，复用前必须审阅：

- Claude：`bypassPermissions`，同时有显式 deny 规则和 Git rewrite hook
- Codex：`approval_policy = "never"`、`sandbox_mode = "danger-full-access"`
- Cursor：`approvalMode = "unrestricted"`
- Kimi Code：`default_permission_mode = "yolo"`
- Antigravity：`toolPermission = "always-proceed"`，不启用 terminal sandbox
- Pi：permission package 允许普通操作，但托管策略拒绝 Git worktree/branch-switch
  命令

Claude hooks 还负责格式化变更文件以及维护 tmux/Herdr 状态。Git rewrite hook
只会阻止部分不可逆操作，并对可恢复的高风险操作要求确认；它不会阻止所有 Git
修改。

## 安全与 Secrets

不同类型的 secret 使用不同机制：

1. Chezmoi 通过 `.chezmoitemplates/shell/age_command_wrapper.sh` 使用 `age`
   backend，`~/.ssh/main` 和 `~/.ssh/main.pub` 是托管的 identity/recipient 对。
2. Gopass 使用 age backend，store 在 `~/.local/share/gopass/stores/root`；只在
   启用加密的 profile 中配置。
3. `keys-manage` 将 key backup 放在 `~/.local/share/keys-backup`。单个文件和
   加密 control file 使用 OpenSSL AES-256-CBC + PBKDF2（100,000 iterations）；
   password 可来自 TTY、`KEYS_BACKUP_PASSWORD`、`--password-file` 或 gopass，但
   为避免 secret 出现在 process arguments 中，`-p/--password` 会被拒绝。
4. bootstrap/key backup 的 GitHub 访问使用 HTTPS 和 `gh` credential helper；旧的
   GitHub SSH URL 会自动规范化为 HTTPS。
5. Claude Git hook 会阻止部分危险 history 操作，并在另一些操作前询问；精确规则
   见 hook 和 `SECURITY.md`。

相关安全材料：

- [SECURITY.md](SECURITY.md)
- [keys-manage 指南](docs/keys-manage-guide.md)
- [gopass 新设备指南](docs/gopass-new-device-setup.md)
- [Claude provider 指南](docs/claude-provider.md)

## CI 与自动化

- `.github/workflows/ci.yml`：在 `main` 的 push/PR 和手动运行时执行 pre-commit
  lint，并在 macOS/Linux 矩阵渲染和检查 Nix flake。
- `.github/workflows/tests.yml`：在 push、PR 和手动运行时执行
  `bash tests/run.sh`。
- `.github/workflows/security.yml`：在 push、PR 和手动运行时运行 Zizmor、Trivy
  filesystem 和 Gitleaks 扫描。
- `.github/workflows/pr-title.yml`：校验 semantic PR title，并允许 `wip` PR。
- `.github/workflows/scheduler.yml`：每天 `00:00 UTC` 运行，dispatch 三个维护
  workflow。
- `update-versions.yml`、`update-flake-lock.yml`、`update-aqua-packages.yml`：
  `workflow_dispatch` workflow，通常由 scheduler 触发并创建依赖更新 PR。
- Dependabot 另以东京时区每日 cron 检查 GitHub Actions 依赖，并有三天 cooldown。

## 更多文档

- [Claude provider tools](docs/claude-provider.md)
- [Keys manager](docs/keys-manage-guide.md)
- [Gopass 新设备设置](docs/gopass-new-device-setup.md)
- [Tmux keybindings](docs/tmux.md)
- [Social publishing](docs/social-publishing.md)
- [Security policy](SECURITY.md)

## 致谢

- [chezmoi](https://github.com/twpayne/chezmoi) 与
  [nix-darwin](https://github.com/LnL7/nix-darwin)：配置编排
- [Nix](https://nixos.org/)、[flakey-profile](https://github.com/lf-/flakey-profile)、
  [Homebrew](https://brew.sh/)、[aqua](https://aquaproj.github.io/) 和
  [mise](https://mise.jdx.dev/)：包与工具管理
- [Claude Code](https://www.anthropic.com/claude-code)、[Codex](https://openai.com/index/introducing-codex/)、
  [Pi](https://github.com/earendil-works/pi)、[Cursor](https://cursor.com/)、
  [Kimi Code](https://www.kimi.com/code) 与 [Herdr](https://github.com/ogulcancelik/herdr)：
  托管的 AI/agent 工具
- `.chezmoiexternal.toml.tmpl` 中列出的 external skill 仓库；它们分别遵循各自
  upstream license。
- [Dracula Theme](https://draculatheme.com/)：terminal 与 fzf 配色

## 许可证状态

当前 checkout 没有根目录 `LICENSE` 文件。不要从旧 README badge 推断许可证；在
将仓库作为可再分发内容使用前，应补充明确的 license 文件和声明。
