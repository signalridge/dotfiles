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

This is a personal workstation configuration managed with `chezmoi`. It is a
working configuration rather than a generic starter template, so the sections
below describe the files and behavior that exist in this checkout today.

The main layers are:

- `chezmoi` for templates, target-file merging, and the bootstrap scripts
- Nix for the cross-platform user profile and, on macOS, `nix-darwin`
- Homebrew and the Mac App Store for macOS applications
- `aqua` for pinned CLI releases and third-party registry entries
- `mise` for runtimes and tools that are intentionally managed outside Nix
- Claude Code, Codex CLI, Pi, Cursor Agent CLI, Kimi Code, and Antigravity CLI
  configuration

> This repository contains personal defaults, including permissive AI execution
> modes and private-machine applications. Review the templates and data before
> applying them to another computer.

## Support and Profile Behavior

| Area                | Actual behavior                                                                                                                                                                                                   |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Operating systems   | macOS and Linux are supported by the bootstrap scripts.                                                                                                                                                           |
| Fresh Nix bootstrap | Pinned installer assets exist for `aarch64-darwin`, `aarch64-linux`, and `x86_64-linux`; a fresh `x86_64-darwin` install is rejected by the Nix installer script.                                                 |
| `work`              | Adds work Nix packages and, on macOS, work Homebrew packages; sets `private = false`. The current work set includes MariaDB, PostgreSQL, Redis, AWS/Azure tooling, DBeaver, GCloud CLI, and related applications. |
| `private`           | Derived as `not work`; on macOS, private Homebrew casks and MAS entries are therefore selected when `work = false`. The private Nix package list is currently empty.                                              |
| `headless`          | Excludes selected GUI dotfiles and macOS maintenance scripts (`09`, `17`, and `22`). It is not a universal package switch; on macOS the nix-darwin/Homebrew module is still rendered.                             |
| Mac App Store       | The private MAS list is installed only when `installMasApps = true`.                                                                                                                                              |

## Highlights

- A numbered `chezmoi` pipeline covering Nix, package profiles, CLI tools,
  runtimes, AI integrations, service loaders, and maintenance tasks
- A locked Nix flake plus profile data split into shared and work/private sets
- A shared skill library at `~/.harnesses/skills`, activated per project for
  Claude, Codex, Pi, Cursor, and Kimi Code
- Native provider/model switching for Pi, plus account wrappers for Claude Code
  and Codex CLI
- Pinned Cursor Agent and Azure Functions installers, and a pinned Paperlib
  installer on non-headless macOS
- Pinned Herdr plugins, Claude/Codex lifecycle integration, and orphan-MCP
  cleanup on macOS/Linux
- CI, security scans, regression tests, and scheduled dependency-update PRs

## Source of Truth and Repository Map

The README is deliberately organized around the actual source files:

```text
.
├── .chezmoi.toml.tmpl         # first-run prompts and every derived data value
├── .chezmoiignore             # OS / headless / encryption exclusions
├── .chezmoitemplates/shell/   # shared snippets (age wrapper, nix env sourcing)
├── .chezmoidata/
│   ├── nix.yaml              # Nix user/system package data
│   ├── homebrew.yaml         # taps, formulae, casks, and MAS entries
│   ├── claude.yaml           # Claude providers and accounts
│   ├── pi.yaml               # Pi defaults, packages, and custom providers
│   ├── herdr.yaml            # Herdr plugin revisions
│   ├── antigravity.yaml      # Antigravity CLI settings
│   ├── aerospace.yaml        # AeroSpace floating-window data
│   ├── hammerspoon.yaml      # application-to-IME data
│   └── versions.yaml         # pinned installers, packages, and skill revisions
├── .chezmoiexternal.toml.tmpl # TPM and shared skill archives
├── .chezmoiscripts/           # numbered bootstrap and maintenance scripts
├── init.sh                    # HTTPS-only bootstrap entry point
├── Justfile.tmpl              # rendered to ~/Justfile (see Daily Operations)
├── nix-config/                # flake and nix-darwin/profile modules
├── dot_zshenv, dot_zshrc, …   # zsh entry points (dot_gitconfig is a stub)
├── dot_custom/                # exports, aliases, functions, fzf-tab (~/.custom)
├── dot_claude/                # Claude settings, hooks, context, CI templates
├── dot_codex/                 # Codex config, prompts, and instructions
├── dot_pi/                    # Pi settings, models, agents, MCP, themes, search
├── dot_cursor/                # Cursor CLI settings and MCP
├── dot_kimi-code/             # Kimi safety settings, MCP, and instructions
├── dot_gemini/                # Antigravity CLI settings merge
├── dot_harnesses/             # repo-authored skills and the shared /commit command
├── dot_local/bin/             # account, key, MCP, skill, and status helpers
├── private_dot_config/        # editor, terminal, desktop, tool, service config
├── private_dot_ssh/           # age-encrypted SSH client config
├── private_Library/           # macOS LaunchAgents
├── docs/                      # focused operational guides
├── tests/                     # bootstrap and integration regression tests
└── tools/wezterm-icon/        # Swift helper used by script `22`
```

## Bootstrap Flow: What Actually Runs

The labels go from `00` through `23`, but there are **two independent scripts
labelled `19`**. `run_onchange_*` scripts run when their rendered source state
changes (some also include a weekly trigger); `run_after_*` scripts are invoked
after apply and perform their own guards or cadence checks.

| Label | Script                                                     | Condition and action                                                                                                                                                                                                         |
| ----- | ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `00`  | `run_onchange_before_00_install-nix.sh.tmpl`               | Installs or upgrades pinned Determinate Nix. A fresh install selects a mirror and verifies the downloaded binary checksum.                                                                                                   |
| `01`  | `run_before_01_setup-encryption-key.sh.tmpl`               | Only rendered when `useEncryption = true`; clones/pulls the configured keys-backup repository and restores the keys-manage files needed by chezmoi.                                                                          |
| `02`  | `run_onchange_after_02_init.sh.tmpl`                       | macOS only; applies the rendered `nix-darwin` configuration.                                                                                                                                                                 |
| `03`  | `run_onchange_after_03_set_profiles.sh.tmpl`               | Switches the cross-platform `flakey-profile` user package profile.                                                                                                                                                           |
| `04`  | `run_onchange_after_04_install-aqua.sh.tmpl`               | Installs or updates the pinned `aqua` release with a verified installer.                                                                                                                                                     |
| `05`  | `run_onchange_after_05_aqua-install-tools.sh.tmpl`         | Installs aqua packages in two phases: bootstrap `mise`, expose Go/Rust, then install the full aqua set.                                                                                                                      |
| `06`  | `run_onchange_after_06_setup-gopass.sh.tmpl`               | Only rendered with encryption enabled; verifies or interactively clones the configured gopass store.                                                                                                                         |
| `07`  | `run_onchange_after_07_mise-install.sh.tmpl`               | Installs the configured mise runtimes and tools, using Bun for `npm:` entries.                                                                                                                                               |
| `08`  | `run_onchange_after_08_nix-index-db.sh.tmpl`               | Refreshes the pinned nix-index database when `nix-locate` is installed.                                                                                                                                                      |
| `09`  | `run_onchange_after_09_install-paperlib.sh.tmpl`           | Non-headless macOS only; downloads, checks, verifies, and installs the pinned Paperlib DMG.                                                                                                                                  |
| `10`  | `run_after_10_update_homebrew_packages.sh`                 | On macOS when Homebrew exists, performs an explicit update/repair/upgrade/cleanup check every seven days. nix-darwin itself also has Homebrew `upgrade = true`.                                                              |
| `11`  | `run_after_11_sync-claude-integration-plugins.sh`          | If Claude Code and `jq` exist, adds the official marketplaces and installs Claude Slack plus the Notion workspace plugin.                                                                                                    |
| `12`  | `run_after_12_sync-claude-mcp.sh.tmpl`                     | Reconciles the repository-owned Claude user MCP entries and marks `context7`, `tavily`, and `deepwiki` as always loaded. Other user-added entries are not removed; the legacy name `arxiv-mcp-server` is explicitly removed. |
| `13`  | `run_after_13_sync-codex-connector-plugins.sh`             | Attempts to install `slack@openai-curated`; if the current Codex marketplace does not expose it, the script skips it.                                                                                                        |
| `14`  | `run_after_14_sync-herdr-integrations.sh`                  | Installs/updates Herdr integrations for Claude and Codex. It removes Herdr's bundled Pi integration because the repository-owned `pi-herdr-state` package is authoritative.                                                  |
| `15`  | `run_after_15_cursor-agent.sh.tmpl`                        | macOS/Linux; downloads a pinned, checksum-verified Cursor Agent archive and links `agent` and `cursor-agent` into `~/.local/bin`.                                                                                            |
| `16`  | `run_onchange_after_16_azure-functions-core-tools.sh.tmpl` | Work machines only; installs `func` from Microsoft's pinned Azure CDN archive, not Homebrew or npm.                                                                                                                          |
| `17`  | `run_onchange_after_17_load-launch-agents.sh.tmpl`         | Non-headless macOS only; reloads the managed qmk-hid-host and MCP reaper LaunchAgents and removes the old local Context7 agent.                                                                                              |
| `18`  | `run_onchange_after_18_herdr-plugins.sh.tmpl`              | Installs the seven pinned Herdr plugins from `.chezmoidata/herdr.yaml`.                                                                                                                                                      |
| `19a` | `run_after_19_remove-legacy-pi-sources.sh`                 | Removes legacy Pi extension files, package declarations, installs, and obsolete workflow/statusline state without touching Pi sessions or auth.                                                                              |
| `19b` | `run_onchange_after_19_load-systemd-user-units.sh.tmpl`    | Linux only; enables lingering and the `mcp-reaper.timer` systemd user unit, and disables the old local Context7 unit.                                                                                                        |
| `20`  | `run_after_20_update-pi-extensions.sh.tmpl`                | When Pi is installed, runs `pi update --extensions` once per ISO week/package set. Failures are non-fatal and retried on the next apply.                                                                                     |
| `21`  | `run_onchange_after_21_terminal-profile.sh.tmpl`           | Non-headless macOS only; installs the managed Dracula Terminal.app profile as the default.                                                                                                                                   |
| `22`  | `run_after_22_wezterm-icon.sh`                             | Non-headless macOS only; reapplies the custom WezTerm icon (via `tools/wezterm-icon`) after cask replacement when needed.                                                                                                    |
| `23`  | `run_after_23_mise-up.sh`                                  | Runs `mise up` on a seven-day cadence. A failed upgrade is non-fatal and does not advance the success timestamp.                                                                                                             |

## Quick Start

> [!WARNING]
> Applying this repository changes shell files, package managers, AI settings,
> and (on macOS) system/application settings. Review the templates and data first.

### Download and run interactively

```bash
curl -fsSL https://raw.githubusercontent.com/signalridge/dotfiles/main/init.sh -o /tmp/init.sh
sh /tmp/init.sh
```

Do not use `curl … | sh`. The first run needs prompts for work/encryption and
identity data; the templates now fail explicitly when required data is missing
and stdin is not a TTY. Downloading first keeps the terminal attached.

### Pin a ref and review it first

```bash
REF="<tag-or-branch>"
curl -fsSLo /tmp/init.sh "https://raw.githubusercontent.com/signalridge/dotfiles/${REF}/init.sh"
# Review / optionally record the checksum of /tmp/init.sh.
sh /tmp/init.sh --ref "${REF}"
```

### Use a local clone

```bash
git clone https://github.com/signalridge/dotfiles.git
cd dotfiles
./init.sh
```

`init.sh` supports `--repo` (or `DOTFILES_REPO`), `--ref`/`--branch` (or
`DOTFILES_REF`), and `--depth` (or `DOTFILES_DEPTH`) when it is bootstrapping
from a remote repository. When run from a local clone it uses that checkout
directly and these remote-selection options do not change the current checkout;
checkout the desired ref before running it. The bootstrap is HTTPS-only;
`--ssh` is intentionally rejected. `DOTFILES_USE_ENCRYPTION=true|false` can
override the encryption choice, but it does not remove the other first-run
prompts.

To preselect a profile when invoking chezmoi directly, provide the required
prompt values through chezmoi flags or persistent data, for example:

```bash
chezmoi init --apply \
  --promptBool work=false \
  --promptBool useEncryption=false \
  signalridge
```

## First-run Data

These are the actual data paths used by `.chezmoi.toml.tmpl`:

| Data                                            | When it is requested or used                                                                                                            |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `work`                                          | Required unless already in chezmoi data. On a TTY it is prompted; it controls the derived `private` flag.                               |
| `useEncryption`                                 | Required unless already in data or overridden by `DOTFILES_USE_ENCRYPTION`. It controls encrypted key restore and gopass configuration. |
| `hostname`                                      | Prompted only for a non-work machine when no value is stored. Work machines use `.chezmoi.hostname`.                                    |
| `gitUsername`, `gitEmail`                       | Prompted when absent; there is no safe identity default.                                                                                |
| `headless`                                      | Prompted on a TTY; otherwise stored data is used, with an OS-based fallback.                                                            |
| `installMasApps`                                | macOS TTY prompt; defaults to no MAS installation unless enabled.                                                                       |
| `homeWifiSSIDs`                                 | Optional macOS TTY prompt; comma-separated home SSIDs used by the Hammerspoon volume watcher.                                           |
| `timezone`                                      | Auto-detected from the host where possible; otherwise prompted on a TTY or falls back to `Etc/UTC`.                                     |
| `keysRepository`                                | Requested only when encryption is enabled and no value is stored. Required for the keys-manage restore step.                            |
| `gopassRepository`                              | Requested only when encryption is enabled and no value is stored. Required for the gopass setup step.                                   |
| `claudeProviderAccount`, `codexProviderAccount` | **Not prompts.** Defaults are `anthropic` and `openai`; they can be stored in chezmoi data or changed by the account managers.          |

With `useEncryption = false`, the encryption restore/gopass scripts and the
managed `~/.ssh/*` targets are ignored. With encryption enabled, bootstrap may
need a GitHub HTTPS credential: an existing `gh` login, `GH_TOKEN`/`GITHUB_TOKEN`,
or interactive device-code OAuth.

## Daily Operations

Two justfiles are rendered from the same `Justfile.tmpl` source:

- `~/.config/just/.justfile` — the global file. The interactive shell exports
  `JUSTFILE=${XDG_CONFIG_HOME:-$HOME/.config}/just/.justfile`, so `just` uses
  this file from any directory.
- `~/Justfile` — the same recipes **plus** a `test` recipe. Because `JUSTFILE`
  is exported, `just test` does not resolve to it; run the suite directly
  instead (below).

```bash
# Chezmoi
just apply
just diff
just update
just re-add
just edit <file>

# Nix
just up                 # update all flake inputs
just upp nixpkgs        # update one input
just gc                 # defaults to 7 days
just verify
just optimize
just repl
just repair <paths>
just gcroot

# macOS-only recipes
just darwin
just darwin-debug
just darwin-check
just darwin-build
just history
just clean              # defaults to 7 days
```

Run the regression suite and the lint hooks directly:

```bash
bash "$(chezmoi source-path)/tests/run.sh"
pre-commit run --all-files
```

There are also short Git recipes (`st`, `gd`, `gl`, `cm`, `push`, `pull`).

## Package and Tool Management

Package sources are intentionally split; not every list lives in
`.chezmoidata/`.

| Layer             | Source                                                              | What it manages                                                                                                                                                                                                                                 |
| ----------------- | ------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Nix user profile  | `.chezmoidata/nix.yaml` + `nix-config/modules/profile.nix.tmpl`     | Shared packages plus work packages through `flakey-profile`. The current `sysPkgs` list is empty; macOS system settings/fonts/services still live in `nix-darwin`.                                                                              |
| nix-darwin        | `nix-config/modules/*.tmpl`                                         | macOS defaults, fonts, shell/PAM settings, Nix index, Homebrew integration, and system launchd jobs.                                                                                                                                            |
| Homebrew          | `.chezmoidata/homebrew.yaml` + `nix-config/modules/apps.nix.tmpl`   | Taps, formulae, casks, and conditional MAS entries. Homebrew is not a locked/reproducible Nix layer.                                                                                                                                            |
| aqua              | `private_dot_config/aquaproj-aqua/{aqua,registry,aqua-policy}.yaml` | Pinned CLI releases: Claude Code, Codex, Antigravity CLI (`agy`), shell/Kubernetes/security tools, and — from the local `registry.yaml` — Kimi Code, Herdr, Slipway, qmk-hid-host, and doggo. `aqua-policy.yaml` authorizes the local registry. |
| mise              | `private_dot_config/mise/config.toml.tmpl`                          | Node, Bun, Python, Go, Rust, Lua, Terraform, uv, pipx tools, Pi, usage analyzers, browser/media CLIs, `xurl`, and `crosspost`. `npm:` entries use Bun; Node remains installed for runtime compatibility.                                        |
| Direct installers | `.chezmoiscripts/00`, `09`, `15`, and `16`                          | Determinate Nix, Paperlib, Cursor Agent, and work-only Azure Functions Core Tools with repository-pinned versions/checksums.                                                                                                                    |
| Pi extensions     | `.chezmoidata/pi.yaml` + Pi settings                                | Five external packages and twenty `@signalridge` packages, deliberately unpinned and refreshed by Pi's weekly `update --extensions` step.                                                                                                       |

Representative configured tools include `eza`, `bat`, `fd`, `ripgrep`, `fzf`,
`gh`, `ghq`, `just`, `lazygit`, `neovim`, `yazi`, `jj`, `xh`, `slumber`,
`k9s`, `kubectl`, `helm`, `trivy`, `syft`, `grype`, `ruff`, `ty`, `git-cliff`,
`quarto`, `typst`, `aichat`, `agent-browser`, `hyperframes`, and
`impeccable`. The full lists are in the source files above.

## Editor, Terminal, and Desktop

`private_dot_config/` is a larger layer than the package tables suggest; it
holds the rest of the workstation:

| Area                 | Managed configuration                                                                                                                                                                                                      |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Editor               | `nvim/` — a LazyVim setup with a committed `lazy-lock.json`, `neoconf.json`, and local `lua/config` + `lua/plugins` overrides (colorscheme, AI, dotfiles).                                                                 |
| Shell chrome         | `sheldon/plugins.toml` (zsh plugin manager: ohmyzsh libs, `zsh-defer`, autosuggestions, syntax highlighting, `fzf-tab`, `enhancd`, `you-should-use`), `starship.toml`, and `atuin/`.                                       |
| Terminals            | `wezterm/wezterm.lua` plus the bundled `WezTerm.icns`, and `terminal/Dracula.terminal` for Terminal.app (installed by script `21`).                                                                                        |
| Multiplexers         | `tmux/tmux.conf.tmpl` with TPM and seventeen further plugins (tmux2k statusline with a custom AI-agent segment, sessionx, floax, extrakto, resurrect/continuum), plus `herdr/config.toml` for the Herdr workspace manager. |
| macOS desktop        | `aerospace/` (tiling window manager), `hammerspoon/` (IME auto-switch, mic/volume watchers, Spoons), `private_karabiner/`, and `sofle/` (QMK/Vial keyboard layout).                                                        |
| Git and review       | `git/`, `jj/`, `delta/`, `lazygit/`, `git-cliff/`, `gh/`, `gh-dash/`. GitHub access is HTTPS through the `gh` credential helper; there are deliberately **no** `insteadOf` rewrites.                                       |
| Files and inspection | `yazi/`, `bat/`, `bottom/`, `procs/`, `slumber/`, `watchexec/`, `tlrc/`, `lazydocker/`, and the `stern/`, `grype/`, `syft/` policy files.                                                                                  |
| Services and stores  | `systemd/user/` (`mcp-reaper.service` + `.timer` on Linux), `nix/nix.conf`, `gopass/config.tmpl`, `mise/`, `aquaproj-aqua/`, `just/`, `aichat/`, and `letsencrypt/`.                                                       |

`tools/wezterm-icon/` is the standalone Swift helper that script `22` calls to
reapply the custom WezTerm icon after Homebrew replaces the cask.

## Shell Aliases and Functions

Shell files live in `dot_custom/` and are applied to `~/.custom/`
(`exports.sh`, `alias.sh`, `functions.sh`, `utils.sh`, `eval.sh`,
`fzf-tab.zsh`); `~/.zshrc` sources them and returns early for non-interactive
shells. An unmanaged `~/.custom/local.sh` is sourced last for machine-local
overrides. The aliases below are conditional on the target command being
installed:

| Alias                                                 | Target                                                                           |
| ----------------------------------------------------- | -------------------------------------------------------------------------------- |
| `dot`                                                 | `chezmoi`                                                                        |
| `vi`, `vim`, `view`                                   | `nvim`                                                                           |
| `ls`, `cat`, `du`, `df`, `man`                        | `eza`, `bat`, `dust`, `duf`, `tldr`                                              |
| `hf`, `lg`, `lzd`, `top`, `pc`, `dog`, `logv`, `post` | `hyperfine`, `lazygit`, `lazydocker`, `btm`, `procs`, `doggo`, `lnav`, `posting` |
| `ccm`, `ccw`                                          | `claude-manage`, `claude-with`                                                   |
| `cxm`, `cxw`                                          | `codex-manage`, `codex-with`                                                     |
| `k` / `kubectl`                                       | `kubecolor` when installed; otherwise `k` points to `kubectl`                    |

`la` and `ll` always exist; `lla` and `lt` are defined only when eza is
installed (they use eza's `--git`/`--tree` flags). `cp`, `mv`, and `mkdir` are
interactive/safe aliases (`-i`/`-v`, plus `mkdir -p`). `ripgrep`, `fd`, and
`zoxide` are installed/integrated, but **`grep`, `find`, and `cd` are not
aliased** to them.

Under zsh there is also a set of global aliases that expand anywhere on the
command line — `L` (`| less`), `G` (`| grep`), `H`, `T`, `W`, `S`, `U`,
`J` (`| jq`), `CP` (`| pbcopy`), `F` (`$(fzf)`), and `N`/`N1`/`N2` for output
redirection — plus `galias` to list them and `yy` to copy the previous command
to the clipboard. `take` is a second name for `mkcd`.

Common functions:

```bash
dev [query]                 # ghq + fzf repository picker
mkcd <dir>                  # create a directory and enter it
dotcd                       # jump to the chezmoi source
fgc / fgl / fga              # fuzzy branch, log, and staged-file helpers
aicommit [--dry-run] ...    # AI conventional-commit message from staged diff
create_direnv_venv          # write a Python .envrc and allow it
create_direnv_nix           # write `use flake` to .envrc (does not create a flake)
create_direnv_mise          # write `use mise` to .envrc
create_py_project [name]    # uv init plus a direnv Python layout
```

Additional helpers cover `ccnew`/`ccdone`, `wt-new`/`wt-go`/`wt-ls`/`wt-rm`,
`gh_latest`, `gh_clone`, `fkill`, `fenv`, `mcp-ps`, and `mcp-reap`. The
`wt-*` and `cc*` helpers use Git worktrees for ordinary repositories; do not
use them inside this chezmoi source tree, whose constitution forbids worktrees
and branch switching. `AICOMMIT_PROVIDER` accepts `claude`, `codex`, or `auto`
and defaults to `claude` in the managed shell exports.

## AI Harnesses and Provider Management

### Managed harnesses

| Harness          | Managed files and behavior                                                                                                                                                                                                                                                                                                                       |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Claude Code      | `~/.claude/settings.json`, `CLAUDE.md`, the four `context/*.md` files, `hooks/`, `statusline-command.sh`, the `templates/*.yml` CI starters, and the official integration plugins.                                                                                                                                                               |
| Codex CLI        | `~/.codex/config.toml`, `AGENTS.md`, the project-document fallback list, lifecycle hooks, MCP, and the Slack plugin configuration.                                                                                                                                                                                                               |
| Pi               | `~/.pi/agent/settings.json`, `models.json`, `subagents.json`, `workflows/settings.json`, `mcp.json`, `keybindings.json`, `APPEND_SYSTEM.md`, six `agents/*.md` definitions, four themes, the `pi-permission-system` config, and `~/.pi/web-search.json`. Pi uses its native `/model` and `/login`; there is no Pi account wrapper or `pi-token`. |
| Cursor Agent CLI | Pinned `agent`/`cursor-agent` binary plus `~/.cursor/cli-config.json` and `~/.cursor/mcp.json`.                                                                                                                                                                                                                                                  |
| Kimi Code        | `~/.kimi-code/config.toml` safety defaults, `~/.kimi-code/mcp.json`, and `~/.kimi-code/AGENTS.md`; no account wrapper is provided.                                                                                                                                                                                                               |
| Antigravity CLI  | A deep merge into `~/.gemini/antigravity-cli/settings.json`; runtime-owned `model`, `permissions`, and `trustedWorkspaces` are preserved.                                                                                                                                                                                                        |
| aichat           | `~/.config/aichat/config.yaml`, with Kimi Moonshot and Doubao entries when their `pi/...` gopass keys exist.                                                                                                                                                                                                                                     |

Claude's `~/.claude/skills`, `~/.codex/skills`, `~/.pi/agent/skills`,
`~/.cursor/skills`, and `~/.kimi-code/skills` are kept as real directories by
`dot_claude/run_after_ensure-skill-dirs.sh`; nothing is activated there by
default.

### Claude and Codex accounts

Claude providers in `.chezmoidata/claude.yaml` are currently `anthropic`,
`deepseek`, `kimi`, `glm`, `qwen`, `minimax`, and `doubao`. Configured accounts
are `anthropic`, `opus`, `haiku`, `deepseek@private`, `doubao@private`, and
`kimi@private`. Native Anthropic accounts use OAuth; third-party Claude keys
are read from gopass paths of the form:

```text
claude/<provider>/<account-label>/api_key
```

Codex keeps native OpenAI OAuth as `openai` and renders third-party provider
blocks for DeepSeek, Doubao, GLM, Kimi, MiniMax, and Qwen. Codex API keys use:

```text
codex/<provider>/<account-label>/api_key
```

Use `claude-manage`/`codex-manage` for persistent account changes and
`claude-with`/`codex-with` for a one-session launch. The token helpers only
read/check keys or print merged account configuration; they do not switch the
account.

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

### Pi policy

The managed Pi startup default is machine-scoped: private machines start on
`openai-codex/gpt-6-astra` at `high`, work machines on
`openai-codex/gpt-5.6-luna` at `max`. Both also get the
`signalridge-ridgeline` theme, quiet startup, Bun-backed package installation,
and native compaction/retry settings.

`subagents.json` defines exactly three named tiers: `low`, `medium`, and
`high`. They are one ladder — `luna/xhigh`, `luna/max`, `astra/high`,
`astra/xhigh` — which work machines enter one rung below private ones, so a
rung costs the same on either. The startup default above is deliberately the
`medium` rung of whichever machine it is, and the regression suite asserts
that. Workflow settings map workflow strengths `low`/`medium`/`high` directly
to those same tier names; the old separate workflow model vocabulary is not
part of this configuration.

Pi custom provider keys, where needed, are service-scoped under `pi/` (for
example `pi/opencode/api_key`, `pi/deepseek/api_key`, and `pi/kimi/api_key`).
Providers backed by a missing gopass key are skipped while rendering
`models.json`; providers backed by an environment variable remain as `$VAR`
references and can fail only when called without that variable. The aichat
Moonshot platform key is separate at `pi/moonshot/api_key`; it is not the Kimi
Code subscription key.

### Shared skills

`.chezmoiexternal.toml.tmpl` downloads a hardcoded, pinned selection of skill
archives into the shared library:

```text
~/.harnesses/skills/<category>/<skill>/
```

Sources include wshobson/agents, anthropics/skills, OpenAI, Hugging Face,
Sentry, Trail of Bits, Cloudflare, Vercel, Supabase, Expo, Microsoft, Baoyu,
phuryn/pm-skills, Reddit/daily.dev/X publishing skills, UI/UX and diagram
skills, and Go/Rust/Swift/TypeScript suites. These are shared library entries,
not a blanket Claude marketplace installation. The global `ai-research-skills`
CLI is managed separately by mise's pipx/uvx backend; it does not install host
skills or commands.

Three skills are authored in this repository rather than downloaded, and land
in the same library: `dev/toolbelt` (the local CLI inventory referenced from the
global agent instructions), `media/remotion`, and `social/oss-x-post` (which
bundles the gated `social-post` and `reddit-submit` publish helpers). The shared
`/commit` command lives at `~/.harnesses/commands/core/commit.md` and is
symlinked into `~/.claude/commands/core` and `~/.codex/prompts/core-commit.md`.

Run `skill-activate` from a project directory to create flat symlinks for the
same selected skills in all five directories:

```text
./.claude/skills  ./.codex/skills  ./.pi/skills
./.cursor/skills  ./.kimi-code/skills
```

Useful modes are `--active`, `--list`, `--category <name>`, `--sync`, and
`--clear`. Skills are not activated globally by default.

### Plugins, MCP, and Herdr

The official plugin/connectors are separate from the shared skill library:

- Claude attempts to install `slack@claude-plugins-official` and
  `notion-workspace-plugin@notion-plugin-marketplace`.
- Codex attempts to add `slack@openai-curated` and skips it when unavailable in
  the current marketplace.
- Herdr installs seven pinned plugins from `.chezmoidata/herdr.yaml` and
  installs its Claude/Codex lifecycle integrations. The bundled Pi integration
  is explicitly removed; `pi-herdr-state` is the repository-owned reporter.

MCP declarations are intentionally not identical in every harness:

| Harness         | Managed MCP entries                                                                                                                   |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| Claude          | `context7`, `markitdown`, `arxiv`, `tavily`, `gitmcp`, `deepwiki`; `context7`/`tavily`/`deepwiki` are always loaded.                  |
| Codex           | Notion plus the same six entries above.                                                                                               |
| Pi              | `context7`, `deepwiki`, `gitmcp` as lazy direct tools; `markitdown` and `arxiv` as lazy proxy tools. Pi does not declare Tavily here. |
| Cursor and Kimi | `context7`, `tavily`, `deepwiki`, `gitmcp`, `markitdown`, and `arxiv`.                                                                |

Pi reaches Tavily through a different path: the managed `~/.pi/web-search.json`
configures the `pi-web-access` extension with an Exa/Tavily routing pair, reads
the Tavily key from gopass at call time, and disables browser-cookie reuse.

`~/.local/bin/mcp-tavily` reads `tavily/api_key` from gopass at runtime and
launches the pinned `tavily-mcp@0.2.16` through `bunx`. When the corresponding
non-headless macOS or systemd-user setup is active, the LaunchAgent or user
timer runs `mcp-reaper` to log and kill orphaned local MCP processes without
touching processes owned by a live session.

### AI execution posture

The managed defaults are intentionally permissive and should be reviewed
before reuse:

- Claude: `bypassPermissions` with explicit deny rules and a Git rewrite hook
- Codex: `approval_policy = "never"` and `sandbox_mode = "danger-full-access"`
- Cursor: `approvalMode = "unrestricted"`
- Kimi Code: `default_permission_mode = "yolo"`
- Antigravity: `toolPermission = "always-proceed"`, no terminal sandbox
- Pi: the permission package allows normal operations but denies Git worktree /
  branch-switch commands in its managed policy

Claude hooks also format changed files and maintain tmux/Herdr state. The Git
rewrite hook blocks some irreversible operations and asks for confirmation for
recoverable risky operations; it does not block every Git mutation.

## Security and Secrets

There are separate mechanisms for separate secret classes:

1. Chezmoi uses the `age` backend through
   `.chezmoitemplates/shell/age_command_wrapper.sh`, with `~/.ssh/main` and
   `~/.ssh/main.pub` as the managed identity/recipient pair.
2. Gopass uses the age backend at `~/.local/share/gopass/stores/root` and is
   configured only in the encryption-enabled profile.
3. `keys-manage` stores key backups in
   `~/.local/share/keys-backup`. Individual files and the encrypted control
   files use OpenSSL AES-256-CBC with PBKDF2 (100,000 iterations); the backup
   password can come from a TTY, `KEYS_BACKUP_PASSWORD`, `--password-file`, or
   `gopass`, but `-p/--password` is deliberately rejected to avoid secrets in
   process arguments.
4. GitHub repository access for bootstrap/key backup uses HTTPS and the `gh`
   credential helper. Legacy GitHub SSH URLs are normalized to HTTPS.
5. Claude's Git hook guard blocks some dangerous history operations and asks
   before others; see the hook and `SECURITY.md` for the exact rules.

Related security material:

- [SECURITY.md](SECURITY.md)
- [keys-manage guide](docs/keys-manage-guide.md)
- [gopass new-device guide](docs/gopass-new-device-setup.md)
- [Claude provider guide](docs/claude-provider.md)

## CI and Automation

- `.github/workflows/ci.yml`: on pushes/PRs to `main` and manual runs; runs
  pre-commit linting and renders/checks the Nix flake on a macOS/Linux matrix.
- `.github/workflows/tests.yml`: runs `bash tests/run.sh` on pushes, PRs, and
  manual runs.
- `.github/workflows/security.yml`: runs Zizmor, Trivy filesystem, and Gitleaks
  scans on pushes, PRs, and manual runs.
- `.github/workflows/pr-title.yml`: validates semantic PR titles and allows
  `wip` PRs.
- `.github/workflows/scheduler.yml`: runs daily at `00:00 UTC` and dispatches
  the three maintenance workflows.
- `update-versions.yml`, `update-flake-lock.yml`, and
  `update-aqua-packages.yml`: manual-dispatch workflows, normally triggered by
  the scheduler, that open dependency-update PRs.
- Dependabot separately checks GitHub Actions dependencies on a daily Tokyo-time
  cron with a three-day cooldown.

## Additional Documentation

- [Claude provider tools](docs/claude-provider.md)
- [Keys manager](docs/keys-manage-guide.md)
- [Gopass new-device setup](docs/gopass-new-device-setup.md)
- [Tmux keybindings](docs/tmux.md)
- [Social publishing](docs/social-publishing.md)
- [Security policy](SECURITY.md)

## Acknowledgements

- [chezmoi](https://github.com/twpayne/chezmoi) and
  [nix-darwin](https://github.com/LnL7/nix-darwin) for configuration
  orchestration
- [Nix](https://nixos.org/), [flakey-profile](https://github.com/lf-/flakey-profile),
  [Homebrew](https://brew.sh/), [aqua](https://aquaproj.github.io/), and
  [mise](https://mise.jdx.dev/) for package/tool management
- [Claude Code](https://www.anthropic.com/claude-code), [Codex](https://openai.com/index/introducing-codex/),
  [Pi](https://github.com/earendil-works/pi), [Cursor](https://cursor.com/),
  [Kimi Code](https://www.kimi.com/code), and [Herdr](https://github.com/ogulcancelik/herdr)
  for the managed AI/agent tools
- The external skill repositories listed in `.chezmoiexternal.toml.tmpl`; they
  remain governed by their respective upstream licenses.
- [Dracula Theme](https://draculatheme.com/) for the terminal and fzf palette

## License Status

This checkout does not currently contain a root `LICENSE` file. Do not infer a
license from the old README badge; add an explicit license file and declaration
before treating this repository as redistributable.
