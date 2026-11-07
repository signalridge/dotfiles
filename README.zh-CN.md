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

这是用 `chezmoi` 管理的个人工作站配置。它是一套正在使用的配置，而不是通用的
入门模板。各层分工如下：

- `chezmoi`：模板、目标文件合并与 bootstrap 脚本
- Nix：跨平台用户 profile，macOS 上还有 `nix-darwin`
- Homebrew 与 Mac App Store：macOS 应用
- `aqua` 管理固定版本的 CLI，`mise` 管理运行时与其余工具
- Claude Code、Codex CLI、Cursor Agent CLI、Antigravity CLI
  与 DeepSeek Harness 的配置
- 私有网络层：EasyTier mesh、sing-box 客户端、JAIST VPN

> 本仓库包含个人默认值，其中有宽松的 AI 执行模式和私人机器专用的应用。
> 用到其他电脑之前，请先检查模板和数据。

## 支持范围与 Profile 行为

| 范围               | 行为                                                                                                            |
| ------------------ | --------------------------------------------------------------------------------------------------------------- |
| 操作系统           | macOS 与 Linux。                                                                                                |
| 全新 Nix bootstrap | 固定的安装器资源覆盖 `aarch64-darwin`、`aarch64-linux` 和 `x86_64-linux`；全新的 `x86_64-darwin` 安装会被拒绝。 |
| `work`             | 加入 `work` 包集合（Nix，macOS 上还有 Homebrew），并设置 `private = false`；工作机不安装中继/出口工具。         |
| `private`          | 由 `not work` 推导，选择 `private` 包集合。                                                                     |
| `headless`         | 跳过 GUI dotfiles 和 GUI 脚本 `09`、`17`、`21`。它不是包开关：macOS 上 nix-darwin/Homebrew 模块仍会渲染。       |
| Mac App Store      | 仅当 `installMasApps = true` 时安装 MAS 条目。                                                                  |

## 快速开始

> [!WARNING]
> 应用本仓库会修改 shell 文件、包管理器、AI 设置，以及（在 macOS 上）系统和应用
> 设置。请先检查模板和数据。

```bash
curl -fsSL https://raw.githubusercontent.com/signalridge/dotfiles/main/init.sh -o /tmp/init.sh
sh /tmp/init.sh
```

不要使用 `curl … | sh`：首次运行需要交互输入 profile 和身份信息，而当必需数据
缺失且 stdin 不是 TTY 时，模板会明确报错。要固定某个 ref，从该 ref 下载
`init.sh` 并传入 `--ref <ref>`；使用本地克隆时，在目标 checkout 中运行
`./init.sh`。`init.sh` 还支持 `--repo` 和 `--depth`（或
`DOTFILES_REPO`/`DOTFILES_REF`/`DOTFILES_DEPTH`）以及
`DOTFILES_USE_ENCRYPTION=true|false`；详情见 `sh init.sh --help`。bootstrap 只走
HTTPS。

直接调用 chezmoi 时预先选择 profile：

```bash
chezmoi init --apply \
  --promptBool work=false \
  --promptBool useEncryption=false \
  signalridge
```

## 首次运行数据

所有提示项和推导值都在 `.chezmoi.toml.tmpl` 中。

| 数据                                 | 何时请求或使用                                                                   |
| ------------------------------------ | -------------------------------------------------------------------------------- |
| `work`                               | 必需；在 TTY 上提示。用于推导 `private`。                                        |
| `useEncryption`                      | 必需，除非设置了 `DOTFILES_USE_ENCRYPTION`。控制密钥恢复、gopass 和 `~/.ssh/*`。 |
| `hostname`                           | 非工作机上提示；工作机使用系统主机名。                                           |
| `gitUsername`、`gitEmail`            | 缺失时提示；没有身份默认值。                                                     |
| `headless`                           | 在 TTY 上提示；否则使用已存数据或基于 OS 的回退值。                              |
| `installMasApps`、`homeWifiSSIDs`    | macOS TTY 提示（MAS 安装；Hammerspoon 音量监视用的家庭 SSID）。                  |
| `timezone`                           | 自动检测；否则提示，最终回退为 `Etc/UTC`。                                       |
| `keysRepository`、`gopassRepository` | 仅在启用加密时提示。                                                             |
| `easytierExit`                       | 从不提示；在要充当 EasyTier 出口的 Linux 机器上手动设置。                        |

## Bootstrap 流程

`chezmoi init` 之后的一切都由 `.chezmoiscripts/` 中的编号脚本驱动——执行顺序
就是编号：`00` 安装 Nix，`01` 恢复密钥，接着是 nix-darwin、profile、aqua、
gopass 和 mise，之后是 AI 集成、服务和网络栈。`run_onchange_*` 脚本在渲染内容
变化时重新运行；`run_after_*` 脚本每次 apply 都会运行，并自带守卫或执行周期。
按机器区分的条件写在脚本本身和 `.chezmoiignore` 中。

## 日常操作

`~/Justfile` 由 `Justfile.tmpl` 渲染；运行 `just --list` 查看 chezmoi、Nix、
nix-darwin 和 Git 相关 recipe。在源码目录中运行 `pre-commit run --all-files`
进行格式、语法和 secret 检查。

各项声明所在位置：

- Nix 包：`.chezmoidata/nix.yaml` 与 `nix-config/`
- Homebrew 与 MAS：`.chezmoidata/homebrew.yaml`
- aqua CLI：`private_dot_config/aquaproj-aqua/`（工作机跳过 `aqua-private.yaml`）
- mise 运行时与工具：`private_dot_config/mise/config.toml.tmpl`
- 固定的安装器与校验和：`.chezmoidata/versions.yaml`
- shell alias 与函数：`dot_custom/`。其中 `wt-new`/`wt-go`/`wt-ls`/`wt-rm` 会为普通仓库在
  `<repo>/.worktrees/` 下创建 Git worktree；不要在本 chezmoi source 中使用，因为仓库章程
  （`CLAUDE.md`）禁止 worktree 和 branch switching。

## 网络栈

- **EasyTier**：每台 Mac 都以客户端身份加入私有 mesh；Linux 机器只有在其本地数据
  设置了 `easytierExit` 时才作为出口加入（`.chezmoidata/easytier.yaml`，脚本 `23`）。
- **sing-box**：每台机器都有客户端（Mac 上为 TUN，headless Linux 上为用户服务）；
  由 `Egress` 选择器挑选出口（`.chezmoidata/sing-box.yaml`，脚本 `24`）。
- **JAIST VPN**：补丁版 sing-box 中的 OpenConnect 端点，配合
  `openconnect-auto`/`openconnect-login`（脚本 `25`，仅非工作机）。
- **bastion**：手动部署的中继和 STUN 服务器；`bastion-import` 把它的 sing-box
  outbound 存入 gopass。

细节、凭据和手动部署的节点见 [EasyTier mesh](docs/easytier.md)。

## AI Harness

Claude Code、Codex CLI、Cursor Agent CLI、Antigravity CLI 和
aichat 都由 `dot_*` 和 `private_dot_config/` 配置；Claude 和 Codex 共用由
`.chezmoitemplates/agent-instructions.md` 渲染的全局指令。Claude Code 和 Codex
使用原生 OAuth；启动模型在 `.chezmoidata/claude.yaml` 和
`dot_codex/modify_private_config.toml.tmpl` 中设置。MCP 服务器列表
位于 `.chezmoidata/mcp.yaml`。Herdr 负责 agent 状态层。

Skill 安装到 `~/.harnesses/skills/<category>/<skill>/`，来源是固定版本的归档
（`.chezmoiexternal.toml.tmpl`）和 `dot_harnesses/`。默认不全局启用；在项目中运行
`skill-activate`，把选中的 skill 以符号链接放入 `./.claude/skills`、
`./.codex/skills` 和 `./.cursor/skills`
（`--list`、`--active`、`--category <name>`、`--sync`、`--clear`）。

DeepSeek Harness 通过 `dsh-with` 运行，经本地 CLIProxyAPI 使用 OpenAI OAuth。

### AI 执行姿态

受管理的默认值刻意设得很宽松，复用前请务必检查：

- Claude：`bypassPermissions`，配合 Bash deny 规则和 Git 改写 hook
- Codex：`approval_policy = "never"` 与 `sandbox_mode = "danger-full-access"`
- Cursor：`approvalMode = "unrestricted"`
- Antigravity：`toolPermission = "always-proceed"`，无终端沙箱

Claude 的 hook 还会格式化改动的文件。Git 改写 hook
（`dot_claude/hooks/executable_block-git-rewrites.sh`）会阻止部分不可逆操作，并在
可恢复的高风险操作前询问；它并不阻止所有 Git 变更。

## 安全与 Secrets

- chezmoi 使用 `age` 加密（`.chezmoitemplates/shell/age_command_wrapper.sh`），
  身份为 `~/.ssh/main` 与 `~/.ssh/main.pub`。
- API key 和服务凭据存放在 gopass；密钥文件由 `keys-manage` 备份。gopass 的结构写在
  `private_dot_config/gopass/config.tmpl` 中。
- GitHub 访问走 HTTPS + `gh` credential helper，不使用 `insteadOf` 改写。
- 漏洞报告与敏感区域：[SECURITY.md](SECURITY.md)。

## 文档

- [EasyTier mesh](docs/easytier.md)：EasyTier、sing-box、JAIST VPN、bastion 与 NAS
- [WezTerm 图标](tools/wezterm-icon/README.md)
- [安全策略](SECURITY.md)

CI（`.github/workflows/`）运行 pre-commit、Nix flake 检查和安全扫描，每日调度器
会创建依赖更新 PR。

## 致谢

- [chezmoi](https://github.com/twpayne/chezmoi) 与
  [nix-darwin](https://github.com/LnL7/nix-darwin)：配置编排
- [Nix](https://nixos.org/)、[flakey-profile](https://github.com/lf-/flakey-profile)、
  [Homebrew](https://brew.sh/)、[aqua](https://aquaproj.github.io/) 与
  [mise](https://mise.jdx.dev/)：包与工具管理
- [Claude Code](https://www.anthropic.com/claude-code)、[Codex](https://openai.com/index/introducing-codex/)、
  [Cursor](https://cursor.com/) 与 [Herdr](https://github.com/ogulcancelik/herdr)：
  受管理的 AI/agent 工具
- [EasyTier](https://github.com/EasyTier/EasyTier) 与
  [sing-box](https://github.com/SagerNet/sing-box)：网络层
- `.chezmoiexternal.toml.tmpl` 中列出的外部 skill 仓库；它们仍受各自上游许可证约束。
- [Dracula Theme](https://draculatheme.com/)：终端与 fzf 配色

## 许可证

本仓库没有根目录 `LICENSE` 文件。在将其视为可再分发之前，请先添加明确的许可证。
