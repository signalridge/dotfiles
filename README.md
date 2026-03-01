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

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=22&pause=1000&color=BD93F9&center=true&vCenter=true&width=600&lines=Declarative+dev+environment+with+chezmoi+%2B+Nix;Cross-platform+macOS+%2B+Linux+support;Automated+plugin+sync+for+Claude+Code;Modern+CLI+toolchain+with+Rust-based+tools)](https://git.io/typing-svg)

</div>

---

## What This Repo Is

A reproducible personal workstation setup built around:

- `chezmoi` for dotfiles, templating, and bootstrap orchestration
- `Nix` for declarative packages (`nix-darwin` on macOS + `flakey-profile` on macOS/Linux)
- `aqua` + `mise` for CLI/runtime pinning outside Nix where practical
- Shared AI tooling for `Claude Code`, `Codex CLI`, and `OpenCode`

This is a real daily-driver setup, not a demo template. The README focuses on what is actually implemented in this repository today.

---

## Highlights

- Unified bootstrap pipeline (`.chezmoiscripts/00..11`) with idempotent post-apply maintenance
- Cross-platform package strategy:
  - Nix user packages on macOS/Linux
  - nix-darwin system config on macOS
  - Homebrew/MAS integration on macOS
- Shared AI skills marketplace sync to `~/.agents/skills` for Claude/Codex/OpenCode
- Multi-provider account switching for managed wrappers, plus native OpenCode provider switching:
  - `claude-manage` / `claude-with`
  - `codex-manage` / `codex-with`
  - OpenCode via native `opencode` (provider keys rendered in config)
- Declarative `OpenCode + oh-my-opencode` global config with native-only (no-Claude-compat) guardrails
- Auto MCP sync for Claude on every `chezmoi apply`
- Automated dependency upkeep via GitHub Actions (versions, flake locks, aqua packages)
- `C1/C2/C3/C4` routing: advisory in `C1`, direct deterministic flow in `C2`, OpenSpec governance for `C3`/`C4`

---

## Why This Repo

- **Profiles everywhere**: `.chezmoidata/` drives `shared` / `work` / `private` packages across Nix, Homebrew, and MAS
- **End-to-end bootstrap**: staged scripts from `00` to `11` keep setup deterministic and composable
- **macOS polish**: nix-darwin system defaults, Homebrew + MAS integration, post-apply maintenance scripts
- **Workflow guardrails**: pre-commit checks + Claude hooks to reduce risky edits and command misuse
- **DX automation**: Justfile routines, fzf navigation helpers, AI-assisted commit flows
- **CI parity**: template rendering and `nix flake check` on macOS + Linux matrix
- **Triple AI stack**: Claude Code, Codex CLI, and OpenCode are managed declaratively in one repo

---

## Motivation

Setting up a new development machine is tedious: dozens of packages to install, many tools to configure, and years of shell/runtime tweaks to remember.

This repository solves that with a declarative baseline and practical bootstrap pipeline, so one repo can recreate a working environment across machines with predictable outcomes.

Core principles:

- **Reproducibility**: same setup logic, same versioned data, repeatable outcomes
- **Declarative first**: package and tool configuration lives in tracked YAML/templates
- **Modular profiles**: work/private/headless behavior is data-driven, not hardcoded forks
- **AI-augmented workflows**: managed prompts, hooks, skills, and provider switching
- **Security layering**: separate mechanisms for dotfile secrets, password store, and key backups

---

## Table of Contents

- [Quick Start](#quick-start)
- [First Run Prompts](#first-run-prompts)
- [Architecture](#architecture)
- [Repository Map](#repository-map)
- [Bootstrap Flow (What Actually Runs)](#bootstrap-flow-what-actually-runs)
- [Daily Operations](#daily-operations)
- [Claude Code Integration](#claude-code-integration)
- [OpenCode Integration](#opencode-integration)
- [AI Tooling (Claude + Codex + OpenCode)](#ai-tooling-claude--codex--opencode)
- [Tool Chains](#tool-chains)
- [Shell Functions](#shell-functions)
- [Package Management](#package-management)
- [Multi-Profile Configuration](#multi-profile-configuration)
- [Security & Secrets](#security--secrets)
- [CI and Automation](#ci-and-automation)
- [Workflow Routing (C1-C4)](#workflow-routing-c1-c4)
- [Additional Docs](#additional-docs)
- [Acknowledgements](#acknowledgements)
- [Stats](#stats)
- [License](#license)

---

## Architecture

This repository combines `chezmoi` templating with Nix-based package management and AI tooling overlays:

- `chezmoi`: source-of-truth orchestration for scripts/templates
- `nix-darwin` (macOS): system-level configuration
- `flakey-profile` (macOS/Linux): user package profile
- `aqua` + `mise`: CLI/runtime tooling layer outside Nix where needed
- `dot_claude` + `dot_codex` + `private_dot_config/opencode`: tool-specific global guidance and configuration

| Component     | macOS          | Linux          |
| ------------- | -------------- | -------------- |
| Dotfiles      | chezmoi        | chezmoi        |
| System Config | nix-darwin     | N/A            |
| User Packages | flakey-profile | flakey-profile |
| GUI Apps      | Homebrew/MAS   | N/A            |

---

## Repository Map

```text
.
├── .chezmoidata/
│   ├── nix.yaml                # Nix package sets (shared/work/private)
│   ├── homebrew.yaml           # Homebrew taps/brews/casks/MAS apps
│   ├── claude.yaml             # Claude provider + account model settings
│   ├── versions.yaml           # Pinned tool/plugin revisions
│   ├── aerospace.yaml          # Aerospace WM data
│   └── hammerspoon.yaml        # Hammerspoon data
├── .chezmoiscripts/            # Bootstrap + maintenance pipeline (00..11)
├── nix-config/
│   ├── flake.nix.tmpl
│   └── modules/
│       ├── system.nix.tmpl     # nix-darwin system config
│       ├── apps.nix.tmpl       # Homebrew + MAS wiring
│       ├── profile.nix.tmpl    # flakey-profile package profile
│       └── host-users.nix
├── dot_local/bin/              # CLI wrappers (Claude/Codex/OpenCode/keys/MCP)
├── dot_claude/                 # Claude global instructions/hooks/templates
├── dot_codex/                  # Codex global instructions/config/prompts
├── private_dot_config/         # Tool configs (tmux, mise, aqua, gopass, ...)
├── docs/                       # Focused guides
└── tests/                      # Bootstrap/script regression tests
```

---

## Bootstrap Flow (What Actually Runs)

The `chezmoi` script chain is staged and numbered:

1. `00` install Nix (Determinate installer with arch/mirror detection)
2. `01` optionally restore encrypted keys-manage files (`useEncryption=true`)
3. `02` macOS: apply nix-darwin system configuration
4. `03` switch flakey-profile package profile
5. `04` bootstrap gopass store (interactive clone)
6. `05` install pinned aqua installer/version
7. `06` install tools from `private_dot_config/aquaproj-aqua/aqua.yaml`
8. `07` install runtimes/tools via `mise`
9. `08` install pinned nix-index database
10. `09` macOS: install/update Paperlib
11. `10` periodic Homebrew update/upgrade (7-day interval)
12. `11` sync Claude MCP servers (add/update only when needed)

---

## Quick Start

> [!WARNING]
> This repository modifies shell, package managers, and system settings.
> Fork and review before running on a machine you care about.

### Option 1: Run `init.sh` directly

```bash
curl -fsSL https://raw.githubusercontent.com/signalridge/dotfiles/main/init.sh | sh
```

### Option 2: Pin to a tag/branch and review first

```bash
REF="<tag-or-branch>"
curl -fsSLo init.sh "https://raw.githubusercontent.com/signalridge/dotfiles/${REF}/init.sh"
shasum -a 256 init.sh || sha256sum init.sh
sh init.sh --ref "${REF}"
```

### Option 3: Clone and run locally (best auditability)

```bash
git clone https://github.com/signalridge/dotfiles.git
cd dotfiles
git checkout <tag-or-commit>
./init.sh
```

### Useful `init.sh` flags

```bash
./init.sh --repo signalridge/dotfiles
./init.sh --ref v1.2.3
./init.sh --depth 1
./init.sh --ssh
```

---

## First Run Prompts

`chezmoi` data prompts include:

- `work` (work machine switch)
- `headless` (container/server without full desktop assumptions)
- `useEncryption` (enable encrypted key restore flow)
- `installMasApps` (macOS App Store apps)
- `claudeProviderAccount` / `codexProviderAccount`

For most first-time users of this repo: keep `useEncryption = false` unless you have your own keys-manage backup repo and key material.

---

## Daily Operations

The generated global Justfile lives at `~/.config/just/.justfile`.

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

### macOS (`nix-darwin`)

```bash
just darwin
just darwin-check
just darwin-build
```

### Tests

```bash
bash tests/run.sh
pre-commit run --all-files
```

---

## Claude Code Integration

### Plugin System

Skills are synced via `.chezmoiexternal.toml.tmpl` from:

- [wshobson/agents](https://github.com/wshobson/agents)
- [anthropics/skills](https://github.com/anthropics/skills)
- [obra/superpowers](https://github.com/obra/superpowers)
- community multilingual Humanizer pack (`humanizer-en`, `stop-slop-en`, `humanizer-zh`, `humanizer-ja`)

They are normalized into `~/.agents/skills` and shared by Claude/Codex/OpenCode.

### Quality Protocols

The managed instruction stack includes explicit quality discipline patterns (for example: pre-implementation confidence checks and evidence-first verification after implementation), primarily delivered via shared skills and project-level guardrails.

### Provider Management

`claude-manage`, `claude-with`, and `claude-token` provide account switching and provider/account-scoped model routing from `.chezmoidata/claude.yaml` + gopass-backed keys.

See: `docs/claude-provider.md`.

### Hooks

Claude hooks in `dot_claude/hooks/` provide workflow guardrails and formatting automation, including:

- `block-git-rewrites.sh`
- `block-main-edits.sh`
- `format-code.sh`
- `format-python.sh`

---

## OpenCode Integration

### Configuration Ownership

OpenCode is managed declaratively through:

- `private_dot_config/opencode/opencode.jsonc.tmpl`
- `private_dot_config/opencode/oh-my-opencode.jsonc`

Rendered targets:

- `~/.config/opencode/opencode.jsonc`
- `~/.config/opencode/oh-my-opencode.jsonc`

OpenCode key rendering uses `provider@private` naming (for example `harui@private`) and resolves provider keys from gopass.

### OpenCode Native Mode

Use native `opencode` directly:

- Key path: `opencode/{provider}/private/api_key`

### Native-Only Policy (No Claude Compatibility Bridge)

`oh-my-opencode` compatibility ingestion is explicitly disabled:

- `claude_code.mcp = false`
- `claude_code.commands = false`
- `claude_code.skills = false`
- `claude_code.agents = false`
- `claude_code.hooks = false`
- `claude_code.plugins = false`
- `disabled_hooks` includes `claude-code-hooks`
- `disabled_agents` includes `sisyphus`
- `sisyphus_agent.disabled = true`
- `sisyphus.tasks.claude_code_compat = false`

This keeps OpenCode runtime behavior independent from `~/.claude/*`.

### OpenSpec Integration in OpenCode

OpenCode plugin order is pinned to:

```json
"plugin": ["oh-my-opencode", "opencode-plugin-openspec"]
```

This preserves oh-my-opencode orchestration while enabling `openspec-plan` agent injection for OpenSpec planning workflow in OpenCode.

### Runtime Confirmation Baseline

OpenCode permissions are pinned to require confirmation (`ask`) for:

- `edit`
- `bash`
- `external_directory`
- `webfetch`
- `websearch`
- `codesearch`
- `lsp`
- `task`
- `skill`

This applies to primary OpenCode flow and the default oh-my-opencode orchestration flow unless an agent overrides those permissions.

See: `docs/opencode-provider.md`.

---

## AI Tooling (Claude + Codex + OpenCode)

### Shared Skill Distribution

`chezmoi external` syncs selected skills from:

- `wshobson/agents`
- `anthropics/skills`
- `obra/superpowers`
- multilingual Humanizer community sources (`humanizer-en`, `stop-slop-en`, `humanizer-zh`, `humanizer-ja`)

They are normalized into `~/.agents/skills` and shared by Claude/Codex/OpenCode.

### Account + Provider Control

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

# OpenCode (native CLI + provider-based key rendering)
opencode run -m harui@private/gpt-5.3-codex "say ok"
```

### Token Helpers

```bash
claude-token --check kimi@private
codex-token --check deepseek@private
gopass show -o opencode/harui/private/api_key >/dev/null
```

### MCP Integration

- Claude MCP entries are reconciled by `.chezmoiscripts/run_after_11_sync-claude-mcp.sh.tmpl`.
- OpenCode MCP/plugin behavior is managed natively via `~/.config/opencode/opencode.jsonc` and `~/.config/opencode/oh-my-opencode.jsonc`.
- Wrapper commands provided in this repo:
  - `~/.local/bin/mcp-context7`
  - `~/.local/bin/mcp-tavily`
  - `~/.local/bin/mcp-postgres`

#### Task -> MCP Routing

| Task type                  | Primary MCP | Fallback                      |
| -------------------------- | ----------- | ----------------------------- |
| Library/framework/API docs | Context7    | Tavily -> built-in web search |
| Web/news/general research  | Tavily      | built-in web search           |
| Symbolic code navigation   | Serena      | repo grep/codesearch + LSP    |

---

## Tool Chains

This setup keeps the original modern CLI stack and shell ergonomics.

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
| [atuin](https://github.com/atuinsh/atuin)           | Shell history with fuzzy search           |
| [direnv](https://github.com/direnv/direnv)          | Per-directory environment variables       |
| [fzf](https://github.com/junegunn/fzf)              | Fuzzy finder for files, history, and more |

### Development Tools

| Tool                                                | Role                                              |
| --------------------------------------------------- | ------------------------------------------------- |
| [mise](https://github.com/jdx/mise)                 | Polyglot runtime manager (Node, Python, Go, Rust) |
| [lazygit](https://github.com/jesseduffield/lazygit) | Terminal UI for git                               |
| [yazi](https://github.com/sxyazi/yazi)              | Fast terminal file manager                        |
| [tmux](https://github.com/tmux/tmux)                | Terminal multiplexer                              |

---

## Shell Functions

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

## Package Management

| Source         | Platform     | Description                 |
| -------------- | ------------ | --------------------------- |
| Nix packages   | macOS, Linux | Reproducible, rollback-able |
| Homebrew casks | macOS only   | GUI applications            |
| Mac App Store  | macOS only   | App Store exclusives        |

Package lists live in `.chezmoidata/` and support `shared` / `work` / `private` segmentation.

---

## Multi-Profile Configuration

```bash
# For work machines
chezmoi init --apply --promptBool work=true signalridge

# For personal machines (default)
chezmoi init --apply signalridge

# For headless servers (no GUI configs)
chezmoi init --apply --promptBool headless=true signalridge
```

---

## Security & Secrets

This repo uses multiple layers with different purposes:

1. `chezmoi` secret decryption via `age` command wrapper and `~/.ssh/main`
2. `gopass` configured with `age` backend for API key/password storage
3. `keys-manage` encrypted backup repo using OpenSSL PBKDF2 (`AES-256-CBC`)
4. Claude hook guardrails to block risky git/history-rewrite flows

See:

- `docs/keys-manage-guide.md`
- `docs/gopass-new-device-setup.md`
- `docs/claude-provider.md`
- `docs/opencode-provider.md`

---

## CI and Automation

### Validation

- `.github/workflows/ci.yml`
  - pre-commit checks
  - template render validation
  - `nix flake check` (macOS + Linux matrix)

- `.github/workflows/tests.yml`
  - manual bootstrap/script test suite (`bash tests/run.sh`)

### Automated Upkeep

- `.github/workflows/scheduler.yml` (twice weekly trigger)
- `.github/workflows/update-versions.yml`
- `.github/workflows/update-flake-lock.yml`
- `.github/workflows/update-aqua-packages.yml`

---

## Workflow Routing (C1-C4)

> [!IMPORTANT]
> This repository routes implementation by `C1/C2/C3/C4` classification before coding.

| Category | Intent                                                                                       | Primary Path                       |
| -------- | -------------------------------------------------------------------------------------------- | ---------------------------------- |
| `C1`     | Advisory/read-only request                                                                   | Analyze and report only            |
| `C2`     | Deterministic change                                                                         | Implement directly                 |
| `C3`     | Governed change (guardrail or high-control)                                                  | OpenSpec standard lifecycle        |
| `C4`     | Discovery-required program (new project / major refactor / high ambiguity with high control) | OpenSpec discovery-first lifecycle |

Boundary and ownership:

- `C1` is advisory only and does not include file changes.
- `C2` deterministic changes do not require OpenSpec.
- OpenSpec governs execution and verification for `C3` and `C4` implementation.
- If category is `C3` or `C4`, switch to governed mode and enter OpenSpec gate before coding.

OpenSpec workflow (`C3`/`C4`):

```bash
openspec new change <change-name>
openspec status --change <change-name>
# then continue with /opsx-* wrappers (if installed) or openspec CLI steps
```

---

## Additional Docs

- `docs/claude-provider.md`
- `docs/opencode-provider.md`
- `docs/keys-manage-guide.md`
- `docs/gopass-new-device-setup.md`
- `docs/tmux.md`

---

## Acknowledgements

- [chezmoi](https://github.com/twpayne/chezmoi) - Dotfiles manager
- [nix-darwin](https://github.com/LnL7/nix-darwin) - Declarative macOS configuration
- [flakey-profile](https://github.com/lf-/flakey-profile) - Cross-platform Nix profile management
- [wshobson/agents](https://github.com/wshobson/agents) - Claude Code plugins marketplace
- [anthropics/skills](https://github.com/anthropics/skills) - Official Claude Code skills
- [obra/superpowers](https://github.com/obra/superpowers) - Advanced workflow patterns
- [Dracula Theme](https://draculatheme.com/) - Theme palette for terminal and fzf styling

---

## Stats

![Alt](https://repobeats.axiom.co/api/embed/81ef9a8c511918fc0eece9bd09bb46ba78eefd0c.svg "Repobeats analytics image")

---

## License

MIT
