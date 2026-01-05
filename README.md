<div align="center">

![header](https://capsule-render.vercel.app/api?type=waving&color=0:282a36,100:bd93f9&height=200&section=header&text=~/.dotfiles&fontSize=48&fontColor=f8f8f2&fontAlignY=30&desc=One%20command%20%C2%B7%20Full%20environment%20%C2%B7%20Zero%20hassle&descSize=16&descColor=8be9fd&descAlignY=55&animation=fadeIn)

**chezmoi + Nix · Cross-platform dev environment**

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

*A modern, reproducible development environment for macOS and Linux*
</div>

This repository provides a fully declarative system configuration that can bootstrap a new machine in minutes, with all packages, settings, and dotfiles automatically applied. The entire setup is built around Rust-based CLI tools for blazing-fast performance, and supports multi-profile configurations to seamlessly switch between work and personal environments.

---

<a id="table-of-contents"></a>

## 📑 Table of Contents

- [📑 Table of Contents](#table-of-contents)
- [✨ Highlights](#highlights)
- [💡 Why This Repo](#why-this-repo)
- [🎯 Motivation](#motivation)
- [🚀 Quick Start](#quick-start)
- [🔐 Security & Secrets](#security)
- [🧩 Architecture](#architecture)
  - [macOS Configuration](#macos-configuration)
  - [Linux Configuration](#linux-configuration)
  - [How They Work Together](#how-they-work-together)
- [⚡ Tool Chains](#tool-chains)
  - [Modern CLI Replacements](#modern-cli-replacements)
  - [Shell Environment](#shell-environment)
  - [Development Tools](#development-tools)
  - [AI Integration](#ai-integration)
  - [Desktop Applications (macOS only)](#desktop-applications-macos-only)
- [🔧 Shell Functions](#shell-functions)
  - [Project Navigation](#project-navigation)
  - [Git Workflow](#git-workflow)
  - [System Utilities](#system-utilities)
  - [Environment Setup](#environment-setup)
- [📦 Package Management](#package-management)
- [🔄 Daily Operations](#daily-operations)
  - [Cross-Platform Commands](#cross-platform-commands)
  - [macOS-Only Commands](#macos-only-commands)
- [👤 Multi-Profile Configuration](#multi-profile-configuration)
- [⌨️ Keyboard Shortcuts](#keyboard-shortcuts)
- [🌙 Theming](#theming)
- [📈 Stats](#stats)
- [🙏 Acknowledgements](#acknowledgements)
- [📝 License](#license)

---

> [!WARNING]
> **Review before running!** This repository contains scripts that will modify your system configuration.
> Do not blindly execute setup commands without understanding what they do.
> Fork this repository and customize it for your own needs.

---

<a id="highlights"></a>

## ✨ Highlights

- **Cross-platform**: one repo for macOS + Linux (`nix-darwin` + `flakey-profile`)
- **Bootstrap scripts**: installs Nix (Determinate), switches profiles, and keeps Homebrew updated (macOS)
- **Secrets**: `age`-encrypted files with optional 1Password-backed key bootstrap
- **Profiles**: `work` / `private` / `headless` switches via `chezmoi init` prompts
- **Ergonomics**: modern CLI toolchain, consistent theming, and AI helpers

---

<a id="why-this-repo"></a>

## 💡 Why This Repo

- **End-to-end bootstrap**: the Nix installer selects the fastest Determinate mirror, then chezmoi renders and applies templates in one flow
- **Profiles everywhere**: `.chezmoidata.yaml` drives `shared` / `work` / `private` packages across Nix, Homebrew, and MAS
- **macOS polish**: nix-darwin defaults, Homebrew + MAS integration, and post-apply update scripts
- **Security-first secrets**: `age` encryption with 1Password-assisted key bootstrapping and fixed key paths
- **Workflow guardrails**: pre-commit (shellcheck, markdownlint, prettier, Nix format/lint) plus Claude Code hooks for safe git ops and `uv` enforcement
- **DX automation**: Justfile upgrade/cleanup routines, fzf navigation helpers, and AI-assisted commit messages
- **CI parity**: template rendering and `nix flake check` run on macOS + Linux in CI

---

<a id="motivation"></a>

## 🎯 Motivation

Setting up a new development machine is tedious. You need to install dozens of packages, configure countless tools, and remember all those little tweaks you made over the years. This repository solves that problem by:

- **Declarative Configuration** - Every package, setting, and configuration file is defined in code
- **Reproducibility** - Run one command and get the exact same environment on any machine
- **Cross-Platform** - Works on both macOS and Linux with platform-specific optimizations
- **Version Control** - Track changes to your system configuration over time
- **Multi-Profile Support** - Different package sets for work vs personal machines

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
2. Install `age` and `1password-cli` for secrets decryption
3. Fetch encryption key from 1Password (or prompt for manual setup)
4. Apply all dotfiles and configurations

After installation, restart your terminal. For macOS, run `just darwin` to activate nix-darwin configuration.

---

<a id="security"></a>

## 🔐 Security & Secrets

This repo uses `age` encryption for private files (e.g. `private_dot_ssh/encrypted_private_config.tmpl.age`). Chezmoi is configured to decrypt using `~/.ssh/main` (private key) and `~/.ssh/main.pub` (recipient) via `.chezmoi.toml.tmpl`.

On first apply, the bootstrap scripts will:

1. Install Nix (`run_once_before_00_install-nix.sh`)
2. Install `age` + `op` via nix and fetch the key from 1Password (`run_once_before_01_setup-encryption-key.sh`)

If 1Password is unavailable, the script exits with manual setup instructions.

If you fork this repo, update the key path and 1Password item path to match your setup.

---

<a id="architecture"></a>

## 🧩 Architecture

This dotfiles setup combines powerful tools for cross-platform configuration:

**chezmoi** manages dotfiles across machines. It handles templating, secrets, and ensures your configuration files are always in sync. Files prefixed with `dot_` become dotfiles, and `.tmpl` files are processed as Go templates with platform-specific conditionals.

### macOS Configuration

**nix-darwin** provides declarative macOS system configuration. It manages system packages through Nix, Homebrew formulas and casks, and macOS system preferences. The entire system state is defined in Nix expressions and can be rebuilt atomically.

### Linux Configuration

**flakey-profile** provides declarative package management for Linux. It uses the same Nix flake as macOS but without system-level configuration, focusing on user packages that work across any Linux distribution.

### How They Work Together

| Component | macOS | Linux |
|-----------|-------|-------|
| Dotfiles | chezmoi | chezmoi |
| System Config | nix-darwin | N/A |
| User Packages | flakey-profile | flakey-profile |
| GUI Apps | Homebrew Cask | N/A |
| Mac App Store | mas | N/A |

---

<a id="tool-chains"></a>

## ⚡ Tool Chains

This setup replaces traditional Unix tools with modern, Rust-based alternatives that are faster, more user-friendly, and provide better defaults.

### Modern CLI Replacements

| Classic | Modern                                            | Description                           |
| ------- | ------------------------------------------------- | ------------------------------------- |
| `ls`    | [eza](https://github.com/eza-community/eza)       | Git integration, icons, tree views    |
| `cat`   | [bat](https://github.com/sharkdp/bat)             | Syntax highlighting, git integration  |
| `grep`  | [ripgrep](https://github.com/BurntSushi/ripgrep)  | Lightning-fast regex search           |
| `find`  | [fd](https://github.com/sharkdp/fd)               | Intuitive syntax, respects .gitignore |
| `du`    | [dust](https://github.com/bootandy/dust)          | Visual disk usage analyzer            |
| `df`    | [duf](https://github.com/muesli/duf)              | Beautiful disk free table             |
| `cd`    | [zoxide](https://github.com/ajeetdsouza/zoxide)   | Smart directory jumping               |
| `man`   | [tldr](https://github.com/tldr-pages/tlrc)        | Practical command examples            |
| `time`  | [hyperfine](https://github.com/sharkdp/hyperfine) | Command benchmarking                  |

### Shell Environment

The shell prompt is powered by **Starship**, a minimal and fast prompt written in Rust. It's configured with the Dracula color palette and shows contextual information like git status, current directory, and programming language versions.

**Sheldon** manages zsh plugins efficiently. Unlike oh-my-zsh or zinit, Sheldon is written in Rust and provides fast plugin loading with optional deferred execution for non-critical plugins.

**Atuin** revolutionizes shell history. It stores your command history in a SQLite database and provides fuzzy search across your entire history. Press Ctrl+R and instantly find that complex command you ran three months ago.

**Direnv** automatically loads and unloads environment variables when you enter and leave directories. Combined with the helper functions in this repo, you can quickly set up per-project Python virtualenvs, Nix development shells, or mise environments.

| Tool                                                                            | Role                                              |
| ------------------------------------------------------------------------------- | ------------------------------------------------- |
| [starship](https://github.com/starship/starship)                                | Minimal, blazing-fast prompt with git integration |
| [sheldon](https://github.com/rossmacarthur/sheldon)                             | Fast, configurable zsh plugin manager             |
| [atuin](https://github.com/atuinsh/atuin)                                       | Magical shell history with fuzzy search           |
| [direnv](https://github.com/direnv/direnv)                                      | Per-directory environment variables               |
| [fzf](https://github.com/junegunn/fzf)                                          | Fuzzy finder for files, history, and more         |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)         | Fish-like command suggestions                     |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Syntax highlighting for commands                  |

### Development Tools

**mise** (formerly rtx) is a polyglot runtime manager that handles Node.js, Python, Go, Rust, Terraform, and more. It's faster than nvm/pyenv/rbenv and provides a unified interface for all language runtimes.

**lazygit** provides a beautiful terminal UI for git. It makes complex git operations like interactive rebasing, cherry-picking, and conflict resolution much more accessible.

**yazi** is a blazing-fast terminal file manager with image preview support. It's the modern replacement for ranger, written in Rust for maximum performance.

**tmux** configuration includes vim-style keybindings, Dracula theme colors, and popup windows for quick access to lazygit and htop. The prefix key is set to Ctrl+B (default).

| Tool                                                | Role                                              |
| --------------------------------------------------- | ------------------------------------------------- |
| [mise](https://github.com/jdx/mise)                 | Polyglot runtime manager (Node, Python, Go, Rust) |
| [lazygit](https://github.com/jesseduffield/lazygit) | Beautiful terminal UI for git                     |
| [yazi](https://github.com/sxyazi/yazi)              | Blazing fast terminal file manager                |
| [tmux](https://github.com/tmux/tmux)                | Terminal multiplexer with popup windows           |
| [ghq](https://github.com/x-motemen/ghq)             | Remote repository management                      |
| [gh](https://github.com/cli/cli)                    | GitHub CLI for issues, PRs, and more              |

### AI Integration

**Claude Code** is integrated directly into the shell environment. The `aicommit` function generates conventional commit messages from staged changes using AI. The Starship prompt can optionally display Claude API usage stats.

### Desktop Applications (macOS only)

GUI applications are managed through Homebrew casks:

| Category       | Applications                      |
| -------------- | --------------------------------- |
| Terminal       | Ghostty, iTerm2                   |
| Editor         | Neovim, VS Code, Cursor           |
| Browser        | Arc (Dia)                         |
| Window Manager | AeroSpace (i3-like tiling)        |
| Productivity   | Notion, Obsidian, Logseq, Raycast |
| Container      | OrbStack (Docker alternative)     |

---

<a id="shell-functions"></a>

## 🔧 Shell Functions

Beyond aliases, this setup provides powerful shell functions for common workflows.

For machine-specific tweaks you don't want to commit, put them in `~/.custom/local.sh` (it will be sourced automatically if present).

### Project Navigation

The `dev` function combines **ghq** and **fzf** for project management. Type `dev`, and you get a fuzzy-searchable list of all your git repositories with a tree preview. Select one and you're instantly there, with tmux session renamed to match.

```bash
dev                 # FZF-powered project selector (with ghq)
mkcd <dir>          # Create directory and cd into it
dotcd               # Jump to chezmoi source
dotfiles            # Open dotfiles in editor
```

### Git Workflow

`fgc` provides fuzzy branch checkout with log preview. `fgl` lets you browse commits with full diff preview. `fga` shows unstaged files and lets you selectively stage them. These functions make complex git operations feel natural.

```bash
fgc                 # Fuzzy git checkout (branches)
fgl                 # Fuzzy git log viewer
fga                 # Fuzzy git add (select files)
aicommit            # Generate commit message with AI
```

### System Utilities

`fkill` provides safe process killing with confirmation prompts - no more accidentally killing critical processes. `port` quickly shows what's using a specific network port. `backup_dev_env` exports your current Brewfile, VS Code extensions, and mise tools for backup.

```bash
fkill               # Fuzzy process killer (with confirmation)
fenv                # Fuzzy environment variable viewer
port <num>          # Show process using port
backup_dev_env      # Backup dev environment configs
```

### Environment Setup

`create_direnv_venv` sets up a Python virtualenv with direnv integration in one command. `create_direnv_nix` does the same for Nix flake development environments.

```bash
create_direnv_venv  # Create Python venv with direnv
create_direnv_nix   # Create Nix flake with direnv
create_direnv_mise  # Create mise environment with direnv
create_py_project   # Quick Python project setup with uv
```

---

<a id="package-management"></a>

## 📦 Package Management

Packages are managed through multiple sources, each with its strengths:

| Source            | Platform      | Description                 | Examples                    |
| ----------------- | ------------- | --------------------------- | --------------------------- |
| Nix packages      | macOS, Linux  | Reproducible, rollback-able | ripgrep, bat, eza, starship |
| Homebrew formulas | macOS only    | macOS-specific tools        | macos-trash, cliclick       |
| Homebrew casks    | macOS only    | GUI applications            | VS Code, Ghostty, Notion    |
| Mac App Store     | macOS only    | App Store exclusives        | Magnet, WeChat, Office      |

All package lists are defined in `.chezmoidata.yaml` with support for shared, work-only, and private-only packages.

<a id="daily-operations"></a>

## 🔄 Daily Operations

All common operations are available through the Justfile (rendered from `Justfile.tmpl` to `~/Justfile`). If you don't have `just` yet, run `nix run --extra-experimental-features 'nix-command flakes' nixpkgs#just -- <task>`:

### Cross-Platform Commands

```bash
# Chezmoi operations
just apply          # Apply dotfile changes
just diff           # Show pending changes
just re-add         # Re-add modified files

# Nix operations
just up             # Update all flake inputs
just switch         # Switch flakey-profile (rebuild packages)
just gc             # Garbage collect unused nix store entries
just optimize       # Optimize nix store (hard-link duplicates)

# Development
just check          # Run pre-commit checks

# All-in-one
just full-upgrade   # Complete system upgrade
just update-all     # Update flake + chezmoi (+ homebrew on macOS)
```

### macOS-Only Commands

```bash
# Nix-darwin operations
just darwin         # Rebuild and switch configuration
just darwin-debug   # Build with verbose output

# Maintenance
just history        # List all generations of the system profile
just clean          # Clean generations older than 7 days
just clean-all      # Nix gc + brew cleanup
```

---

<a id="multi-profile-configuration"></a>

## 👤 Multi-Profile Configuration

The setup supports different configurations for different machines. In `.chezmoidata.yaml`, packages are organized into three categories:

- **shared** - Installed on all machines
- **work** - Only installed on work machines (Azure CLI, Cursor, etc.)
- **private** - Only installed on personal machines (1Password, gaming, etc.)

`work` is the primary switch: `private` is enabled automatically when `work=false` (default). `headless=true` skips GUI configs like AeroSpace/Karabiner. If prompted for `hostname`, use `hostname -s` (used as the flake output name).

```bash
# For work machines
chezmoi init --apply --promptBool work=true signalridge

# For personal machines (default: work=false -> private=true)
chezmoi init --apply signalridge

# For headless servers (no GUI configs)
chezmoi init --apply --promptBool headless=true signalridge
```

---

<a id="keyboard-shortcuts"></a>

## ⌨️ Keyboard Shortcuts

| Shortcut   | Action                           |
| ---------- | -------------------------------- |
| Alt + Up   | Navigate to parent directory     |
| Alt + Down | Go back in directory history     |
| Ctrl + R   | Search command history (Atuin)   |
| Ctrl + B   | tmux prefix key                  |

---

<a id="theming"></a>

## 🌙 Theming

All tools are configured with the **Dracula** color palette for a consistent, eye-friendly dark theme:

- Starship prompt colors
- tmux status bar
- bat syntax highlighting
- lazygit interface
- yazi file manager

---

<a id="stats"></a>

## 📈 Stats

![Repobeats](https://repobeats.axiom.co/api/embed/b47788b120b4e3a0f049b72115d88268d5523f64.svg "Repobeats analytics")

---

<a id="acknowledgements"></a>

## 🙏 Acknowledgements

This dotfiles setup is built on the shoulders of giants. Special thanks to:

- [chezmoi](https://github.com/twpayne/chezmoi) by [@twpayne](https://github.com/twpayne) - The powerful dotfiles manager
- [nix-darwin](https://github.com/LnL7/nix-darwin) by [@LnL7](https://github.com/LnL7) - Declarative macOS configuration with Nix
- [flakey-profile](https://github.com/lf-/flakey-profile) by [@lf-](https://github.com/lf-) - Cross-platform Nix profile management
- [Nix](https://nixos.org/) by [NixOS](https://github.com/NixOS) - The purely functional package manager
- [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) by [@DeterminateSystems](https://github.com/DeterminateSystems)
- [Sheldon](https://github.com/rossmacarthur/sheldon) by [@rossmacarthur](https://github.com/rossmacarthur) - Fast zsh plugin manager
- [Dracula Theme](https://draculatheme.com/) by [@zenorocha](https://github.com/zenorocha) - The beautiful dark theme

And all the other amazing open-source projects and their contributors that make this setup possible.

---

<a id="license"></a>

## 📝 License

This project is licensed under the MIT License.
