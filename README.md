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

## What This Repository Is

A personal workstation configuration managed with `chezmoi`. It is a working
setup, not a starter template. The layers are:

- `chezmoi` for templates, target-file merging and the bootstrap scripts
- Nix for the cross-platform user profile and, on macOS, `nix-darwin`
- Homebrew and the Mac App Store for macOS applications
- `aqua` for pinned CLI releases, `mise` for runtimes and the remaining tools
- configuration for Claude Code, Codex CLI, Cursor Agent CLI, Antigravity CLI
  and DeepSeek Harness
- a private network layer: EasyTier mesh, sing-box client, JAIST VPN

> This repository contains personal defaults, including permissive AI execution
> modes and private-machine applications. Review the templates and data before
> applying them to another computer.

## Support and Profile Behavior

| Area                | Behavior                                                                                                                                       |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Operating systems   | macOS and Linux.                                                                                                                               |
| Fresh Nix bootstrap | Pinned installer assets for `aarch64-darwin`, `aarch64-linux` and `x86_64-linux`; a fresh `x86_64-darwin` install is rejected.                 |
| `work`              | Adds the `work` package sets (Nix, and Homebrew on macOS) and sets `private = false`; work machines get no relay/exit tools.                   |
| `private`           | Derived as `not work`; selects the `private` package sets.                                                                                     |
| `headless`          | Skips GUI dotfiles and the GUI scripts `09`, `17` and `21`. It is not a package switch: on macOS the nix-darwin/Homebrew module still renders. |
| Mac App Store       | MAS entries are installed only when `installMasApps = true`.                                                                                   |

## Quick Start

> [!WARNING]
> Applying this repository changes shell files, package managers, AI settings,
> and (on macOS) system/application settings. Review the templates and data first.

```bash
curl -fsSL https://raw.githubusercontent.com/signalridge/dotfiles/main/init.sh -o /tmp/init.sh
sh /tmp/init.sh
```

Do not use `curl … | sh`: the first run prompts for profile and identity data,
and the templates fail explicitly when required data is missing and stdin is not
a TTY. To pin a ref, download `init.sh` from that ref and pass `--ref <ref>`; from
a local clone, run `./init.sh` in the checkout you want. `init.sh` also takes
`--repo` and `--depth` (or `DOTFILES_REPO`/`DOTFILES_REF`/`DOTFILES_DEPTH`) and
`DOTFILES_USE_ENCRYPTION=true|false`; run `sh init.sh --help` for details. The
bootstrap is HTTPS-only.

To preselect a profile when invoking chezmoi directly:

```bash
chezmoi init --apply \
  --promptBool work=false \
  --promptBool useEncryption=false \
  signalridge
```

## First-run Data

All prompts and derived values live in `.chezmoi.toml.tmpl`.

| Data                                 | When it is requested or used                                                                |
| ------------------------------------ | ------------------------------------------------------------------------------------------- |
| `work`                               | Required; prompted on a TTY. Derives `private`.                                             |
| `useEncryption`                      | Required unless `DOTFILES_USE_ENCRYPTION` is set. Gates key restore, gopass and `~/.ssh/*`. |
| `hostname`                           | Prompted on non-work machines; work machines use the system hostname.                       |
| `gitUsername`, `gitEmail`            | Prompted when absent; there is no identity default.                                         |
| `headless`                           | Prompted on a TTY; otherwise stored data or an OS-based fallback.                           |
| `installMasApps`, `homeWifiSSIDs`    | macOS TTY prompts (MAS installs; home SSIDs for the Hammerspoon volume watcher).            |
| `timezone`                           | Auto-detected; otherwise prompted, falling back to `Etc/UTC`.                               |
| `keysRepository`, `gopassRepository` | Prompted only with encryption enabled.                                                      |
| `easytierExit`                       | Never prompted; set by hand on a Linux machine that should act as an EasyTier exit.         |

## Bootstrap Flow

Everything after `chezmoi init` is driven by numbered scripts in
`.chezmoiscripts/` — run order is the number: `00` installs Nix, `01` restores
keys, then nix-darwin, profiles, aqua, gopass and mise, followed by AI
integrations, services and the network stack. `run_onchange_*` scripts rerun when
their rendered content changes; `run_after_*` scripts run on every apply and keep
their own guards or cadence. Per-machine conditions are in the scripts and in
`.chezmoiignore`.

## Daily Operations

`~/Justfile` is rendered from `Justfile.tmpl`; run `just --list` for the chezmoi,
Nix, nix-darwin and Git recipes. Run `pre-commit run --all-files` in the source
for formatting, syntax and secret checks.

Where things are declared:

- Nix packages: `.chezmoidata/nix.yaml` and `nix-config/`
- Homebrew and MAS: `.chezmoidata/homebrew.yaml`
- aqua CLIs: `private_dot_config/aquaproj-aqua/` (`aqua-private.yaml` is skipped on work machines)
- mise runtimes and tools: `private_dot_config/mise/config.toml.tmpl`
- pinned installers and checksums: `.chezmoidata/versions.yaml`
- shell aliases and functions: `dot_custom/`. Its `wt-new`/`wt-go`/`wt-ls`/`wt-rm`
  helpers create Git worktrees under `<repo>/.worktrees/` for ordinary
  repositories; never use them inside this chezmoi source tree, whose
  constitution (`CLAUDE.md`) forbids worktrees and branch switching.

## Network Stack

- **EasyTier**: every Mac joins the private mesh as a client; a Linux machine
  joins as an exit only when its local data sets `easytierExit`
  (`.chezmoidata/easytier.yaml`, script `23`).
- **sing-box**: client on every machine (TUN on Macs, user service on headless
  Linux); its `Egress` selector picks an exit (`.chezmoidata/sing-box.yaml`, script `24`).
- **JAIST VPN**: an OpenConnect endpoint in the patched sing-box with
  `openconnect-auto`/`openconnect-login` (script `25`, non-work machines).
- **bastion**: a hand-deployed relay and STUN server; `bastion-import` stores its
  sing-box outbounds in gopass.

Details, credentials and the hand-deployed nodes: [EasyTier mesh](docs/easytier.md).

## AI Harnesses

Claude Code, Codex CLI, Cursor Agent CLI, Antigravity CLI and aichat are
configured from `dot_*` and `private_dot_config/`; Claude and Codex share
global instructions rendered from `.chezmoitemplates/agent-instructions.md`.
Claude Code and Codex use native OAuth; startup models are set in
`.chezmoidata/claude.yaml` and `dot_codex/modify_private_config.toml.tmpl`.
The MCP server list lives in
`.chezmoidata/mcp.yaml`. Herdr provides the agent status layer.

Skills land in `~/.harnesses/skills/<category>/<skill>/`, from pinned archives
(`.chezmoiexternal.toml.tmpl`) and `dot_harnesses/`. Nothing is activated
globally; run `skill-activate` in a project to symlink a selection into
`./.claude/skills`, `./.codex/skills` and `./.cursor/skills` (`--list`, `--active`, `--category <name>`, `--sync`, `--clear`).

DeepSeek Harness runs through `dsh-with`, which uses OpenAI OAuth via a local
CLIProxyAPI.

### AI execution posture

The managed defaults are intentionally permissive and should be reviewed
before reuse:

- Claude: `bypassPermissions` with Bash deny rules and a Git rewrite hook
- Codex: `approval_policy = "never"` and `sandbox_mode = "danger-full-access"`
- Cursor: `approvalMode = "unrestricted"`
- Antigravity: `toolPermission = "always-proceed"`, no terminal sandbox

Claude hooks also format changed files. The Git rewrite hook
(`dot_claude/hooks/executable_block-git-rewrites.sh`) blocks some irreversible
operations and asks before recoverable risky ones; it does not block every Git
mutation.

## Security and Secrets

- chezmoi encrypts with `age` (`.chezmoitemplates/shell/age_command_wrapper.sh`),
  using `~/.ssh/main` and `~/.ssh/main.pub`.
- API keys and service credentials live in gopass; key files are backed up with
  `keys-manage`; the gopass layout is listed in `private_dot_config/gopass/config.tmpl`.
- GitHub access is HTTPS through the `gh` credential helper, with no `insteadOf`
  rewrites.
- Vulnerability reporting and sensitive areas: [SECURITY.md](SECURITY.md).

## Documentation

- [EasyTier mesh](docs/easytier.md): EasyTier, sing-box, JAIST VPN, bastion and NAS
- [WezTerm icon](tools/wezterm-icon/README.md)
- [Security policy](SECURITY.md)

CI (`.github/workflows/`) runs pre-commit, Nix flake checks and security scans,
and a daily scheduler opens dependency-update PRs.

## Acknowledgements

- [chezmoi](https://github.com/twpayne/chezmoi) and
  [nix-darwin](https://github.com/LnL7/nix-darwin) for configuration
  orchestration
- [Nix](https://nixos.org/), [flakey-profile](https://github.com/lf-/flakey-profile),
  [Homebrew](https://brew.sh/), [aqua](https://aquaproj.github.io/), and
  [mise](https://mise.jdx.dev/) for package/tool management
- [Claude Code](https://www.anthropic.com/claude-code), [Codex](https://openai.com/index/introducing-codex/),
  [Cursor](https://cursor.com/), and [Herdr](https://github.com/ogulcancelik/herdr)
  for the managed AI/agent tools
- [EasyTier](https://github.com/EasyTier/EasyTier) and
  [sing-box](https://github.com/SagerNet/sing-box) for the network layer
- The external skill repositories listed in `.chezmoiexternal.toml.tmpl`; they
  remain governed by their respective upstream licenses.
- [Dracula Theme](https://draculatheme.com/) for the terminal and fzf palette

## License

This repository has no root `LICENSE` file. Add an explicit license before
treating it as redistributable.
