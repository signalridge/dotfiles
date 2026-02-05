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

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=22&pause=1000&color=BD93F9&center=true&vCenter=true&width=600&lines=Declarative+dev+environment+with+chezmoi+%2B+Nix;Cross-platform+macOS+%2B+Linux+support;Automated+plugin+sync+for+Claude+Code;Modern+CLI+toolchain+with+Rust-based+tools)](https://git.io/typing-svg)

</div>

---

## ✨ Highlights

- **Cross-platform**: One repo for macOS + Linux (`nix-darwin` + `flakey-profile`)
- **One-command bootstrap**: From bare metal to full environment with a single `curl | sh`
- **Claude Code integration**: 50+ plugins from multiple sources with automated sync
- **Modern CLI**: Rust-based tools (eza, bat, ripgrep, fd, zoxide) replacing Unix classics
- **Security-first**: `age` encryption with gopass-assisted key bootstrapping

---

## 💡 Why This Repo

- **Profiles everywhere**: `.chezmoidata/` drives `shared` / `work` / `private` packages across Nix, Homebrew, and MAS
- **End-to-end bootstrap**: Nix installer auto-selects fastest Determinate mirror, chezmoi renders and applies templates in one flow
- **macOS polish**: nix-darwin system defaults, Homebrew + MAS integration, post-apply update scripts
- **Workflow guardrails**: pre-commit (shellcheck, markdownlint, prettier, Nix lint) + Claude Code hooks
- **DX automation**: Justfile routines, fzf navigation helpers, AI-assisted commit messages
- **CI parity**: Template rendering and `nix flake check` run on macOS + Linux
- **Claude Code hooks**: Auto-format code, enforce uv over pip, block main branch edits

---

## 🎯 Motivation

Setting up a new development machine is tedious: dozens of packages to install, countless tools to configure, and years of tweaks to remember. This repository solves that with **fully declarative configuration** - every package, setting, and dotfile defined in code, **reproducible** across any machine with one command.

**Core principles:**

- **Reproducibility** — Same environment on any machine, every time
- **Declarative** — Everything defined in code, version controlled
- **Modular** — Profile-based customization for work/personal/headless
- **AI-augmented** — Claude Code integration for development workflows
- **Security-first** — Encrypted secrets with gopass integration

---

## 📑 Table of Contents

- [🚀 Quick Start](#quick-start)
- [🧩 Architecture](#architecture)
- [🤖 Claude Code Integration](#claude-code-integration)
- [⚡ Tool Chains](#tool-chains)
- [🔧 Shell Functions](#shell-functions)
- [📦 Package Management](#package-management)
- [🔄 Daily Operations](#daily-operations)
- [👤 Multi-Profile Configuration](#multi-profile-configuration)
- [🔐 Security & Secrets](#security)
- [🙏 Acknowledgements](#acknowledgements)

---

> [!WARNING]
> **Review before running!** This repository contains scripts that will modify your system configuration.
> Fork this repository and customize it for your own needs.

---

<a id="quick-start"></a>

## 🚀 Quick Start

**Option 1: Run init script directly from GitHub (recommended)**

```bash
curl -fsLS https://raw.githubusercontent.com/signalridge/dotfiles/main/init.sh | sh
```

**Option 2: Install chezmoi and init**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply signalridge
```

**Option 3: Clone and run locally**

```bash
git clone https://github.com/signalridge/dotfiles.git
cd dotfiles && ./init.sh
```

This will automatically:

1. Install Nix (Determinate Systems installer)
2. (If `useEncryption` enabled) Restore `~/.ssh/main` and other keys-manage managed files (prompts for decryption password)
3. Apply all dotfiles and configurations
4. Sync Claude Code plugins from marketplace

> [!IMPORTANT]
> **First-time users**: When prompted for `useEncryption`, answer **No** (default).
> The encryption setup is specific to the repo owner. If you need encryption, modify:
>
> - `.chezmoiscripts/run_before_01_setup-encryption-key.sh.tmpl`: Restore/ensure encryption keys from a `keys-manage` encrypted backup repo
> - `.chezmoi.toml.tmpl`: Update `keysRepository`, and update `identity` / `recipientsFile` paths in `[age]` section

After installation, restart your terminal. For macOS, run `just darwin` to activate nix-darwin configuration.

---

<a id="architecture"></a>

## 🧩 Architecture

```
~/.dotfiles/
├── .chezmoidata/           # Modular data configuration
│   ├── base.yaml           # Core settings
│   ├── claude.yaml         # Claude Code plugin configuration
│   └── versions.yaml       # Pinned tool versions
├── .chezmoiscripts/        # Bootstrap & sync scripts
├── dot_claude/             # Claude Code configuration
│   ├── agents/             # AI agent definitions
│   ├── commands/           # Slash commands
│   ├── skills/             # Auto-knowledge skills
│   ├── hooks/              # Git & code hooks
│   └── context/            # Reference documentation
├── nix-config/             # Nix flake configuration
│   └── modules/            # nix-darwin / flakey-profile modules
└── dot_custom/             # Shell functions & aliases
```

**chezmoi** manages dotfiles across machines with templating, secrets, and platform-specific conditionals.

**nix-darwin** (macOS) provides declarative system configuration through Nix, managing system packages, Homebrew, and macOS preferences.

**flakey-profile** (Linux) provides declarative package management using the same Nix flake, focused on user packages.

| Component     | macOS          | Linux          |
| ------------- | -------------- | -------------- |
| Dotfiles      | chezmoi        | chezmoi        |
| System Config | nix-darwin     | N/A            |
| User Packages | flakey-profile | flakey-profile |
| GUI Apps      | Homebrew Cask  | N/A            |

---

<a id="claude-code-integration"></a>

## 🤖 Claude Code Integration

This dotfiles includes a comprehensive Claude Code setup with automated plugin management.

### Plugin System

Plugins are automatically downloaded via `.chezmoiexternal.toml.tmpl` from multiple sources:

| Source                                                    | Description                                          |
| --------------------------------------------------------- | ---------------------------------------------------- |
| [wshobson/agents](https://github.com/wshobson/agents)     | 50+ community plugins (agents, commands, skills)     |
| [anthropics/skills](https://github.com/anthropics/skills) | Official document processing (pdf, docx, pptx, xlsx) |
| [obra/superpowers](https://github.com/obra/superpowers)   | Advanced workflow patterns                           |

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
      # ... 19 plugins enabled
  anthropicsSkills:
    include:
      - pdf
      - docx
```

chezmoi external automatically:

- Downloads enabled plugins on `chezmoi apply`
- Extracts agents, commands, and skills into `~/.claude/`
- Updates when plugin configuration changes

### Quality Protocols

Built-in quality assurance inspired by SuperClaude:

| Protocol             | Purpose                                         |
| -------------------- | ----------------------------------------------- |
| **Confidence Check** | Pre-implementation assessment (HIGH/MEDIUM/LOW) |
| **Self-Check**       | Post-implementation verification with evidence  |

### Provider Management

Switch between Claude providers (Anthropic, DeepSeek, Kimi, etc.) with FZF-powered tools:

```bash
claude-with                    # FZF picker → launch with selected provider
claude-with deepseek@work      # Launch with specific provider/account
claude-provider                # FZF manager for default provider & API keys
claude-provider add-key kimi   # Add API key to gopass
```

See [doc/claude-provider.md](doc/claude-provider.md) for full documentation.

### Hooks

| Hook                    | Trigger          | Action                                      |
| ----------------------- | ---------------- | ------------------------------------------- |
| `format-code.sh`        | After Edit/Write | Auto-format Nix, JSON, YAML, Shell, Go, Lua |
| `enforce-uv.sh`         | On pip commands  | Redirect to `uv` for Python                 |
| `block-main-edits.sh`   | On file edit     | Prevent direct edits to main branch         |
| `block-git-rewrites.sh` | On git commands  | Block force push and history rewrites       |

---

<a id="tool-chains"></a>

## ⚡ Tool Chains

This setup replaces traditional Unix tools with modern, Rust-based alternatives.

### Modern CLI Replacements

| Classic | Modern                                           | Description                           |
| ------- | ------------------------------------------------ | ------------------------------------- |
| `ls`    | [eza](https://github.com/eza-community/eza)      | Git integration, icons, tree views    |
| `cat`   | [bat](https://github.com/sharkdp/bat)            | Syntax highlighting, git integration  |
| `grep`  | [ripgrep](https://github.com/BurntSushi/ripgrep) | Lightning-fast regex search           |
| `find`  | [fd](https://github.com/sharkdp/fd)              | Intuitive syntax, respects .gitignore |
| `cd`    | [zoxide](https://github.com/ajeetdsouza/zoxide)  | Smart directory jumping               |

### Shell Environment

| Tool                                                | Role                                      |
| --------------------------------------------------- | ----------------------------------------- |
| [starship](https://github.com/starship/starship)    | Minimal, blazing-fast prompt              |
| [sheldon](https://github.com/rossmacarthur/sheldon) | Fast zsh plugin manager                   |
| [atuin](https://github.com/atuinsh/atuin)           | Magical shell history with fuzzy search   |
| [direnv](https://github.com/direnv/direnv)          | Per-directory environment variables       |
| [fzf](https://github.com/junegunn/fzf)              | Fuzzy finder for files, history, and more |

### Development Tools

| Tool                                                | Role                                              |
| --------------------------------------------------- | ------------------------------------------------- |
| [mise](https://github.com/jdx/mise)                 | Polyglot runtime manager (Node, Python, Go, Rust) |
| [lazygit](https://github.com/jesseduffield/lazygit) | Beautiful terminal UI for git                     |
| [yazi](https://github.com/sxyazi/yazi)              | Blazing fast terminal file manager                |
| [tmux](https://github.com/tmux/tmux)                | Terminal multiplexer with floating panes          |

---

<a id="shell-functions"></a>

## 🔧 Shell Functions

### Project Navigation

```bash
dev                 # FZF-powered project selector (with ghq)
mkcd <dir>          # Create directory and cd into it
dotcd               # Jump to chezmoi source
```

### Git Workflow

```bash
fgc                 # Fuzzy git checkout (branches)
fgl                 # Fuzzy git log viewer
fga                 # Fuzzy git add (select files)
aicommit            # Generate commit message with AI
```

### Environment Setup

```bash
create_direnv_venv  # Create Python venv with direnv
create_direnv_nix   # Create Nix flake with direnv
create_py_project   # Quick Python project setup with uv
```

---

<a id="package-management"></a>

## 📦 Package Management

| Source         | Platform     | Description                 |
| -------------- | ------------ | --------------------------- |
| Nix packages   | macOS, Linux | Reproducible, rollback-able |
| Homebrew casks | macOS only   | GUI applications            |
| Mac App Store  | macOS only   | App Store exclusives        |

All package lists are defined in `.chezmoidata/` with support for shared, work-only, and private-only packages.

---

<a id="daily-operations"></a>

## 🔄 Daily Operations

```bash
# Chezmoi operations
just apply          # Apply dotfile changes
just diff           # Show pending changes

# Nix operations
just up             # Update all flake inputs
just switch         # Switch flakey-profile (rebuild packages)
just darwin         # Rebuild nix-darwin (macOS)

# Maintenance
just gc             # Garbage collect nix store
just full-upgrade   # Complete system upgrade
```

---

<a id="multi-profile-configuration"></a>

## 👤 Multi-Profile Configuration

```bash
# For work machines
chezmoi init --apply --promptBool work=true signalridge

# For personal machines (default)
chezmoi init --apply signalridge

# For headless servers (no GUI configs)
chezmoi init --apply --promptBool headless=true signalridge
```

---

<a id="security"></a>

## 🔐 Security & Secrets

This repo uses `age` encryption for private files. Chezmoi decrypts using `~/.ssh/main` (private key) and `~/.ssh/main.pub` (recipient).

On first apply, bootstrap scripts will:

1. Install Nix
2. Install `age` + `gopass` via nix
3. Fetch the key from gopass (or prompt for manual setup)

---

<a id="acknowledgements"></a>

## 🙏 Acknowledgements

- [chezmoi](https://github.com/twpayne/chezmoi) - Dotfiles manager
- [nix-darwin](https://github.com/LnL7/nix-darwin) - Declarative macOS configuration
- [flakey-profile](https://github.com/lf-/flakey-profile) - Cross-platform Nix profile management
- [wshobson/agents](https://github.com/wshobson/agents) - Claude Code plugins marketplace
- [anthropics/skills](https://github.com/anthropics/skills) - Official Claude Code skills
- [obra/superpowers](https://github.com/obra/superpowers) - Advanced workflow patterns
- [Dracula Theme](https://draculatheme.com/) - Beautiful dark theme

---

## 📈 Stats

![Alt](https://repobeats.axiom.co/api/embed/81ef9a8c511918fc0eece9bd09bb46ba78eefd0c.svg "Repobeats analytics image")

---

## 📝 License

MIT License
