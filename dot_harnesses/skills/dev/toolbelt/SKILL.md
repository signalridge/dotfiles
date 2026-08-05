---
name: toolbelt
description: Inventory of the CLI tools actually installed on this machine (aqua/mise/nix) and which one to reach for per task — search, structural rewrite, structured data, diff, HTTP, profiling, VCS, k8s, security, docs, media. Use when picking a command-line tool, when a POSIX default (grep/find/sed/curl/wc) feels clumsy, when checking whether a tool exists before installing anything, or when a command is missing and a replacement is needed. Triggers - "what tools do I have", "is X installed", "better than grep", "instead of sed", "structural search", "AST rewrite", "有哪些工具", "装了什么", "用什么命令", "替代 grep".
---

# Local toolbelt

Everything below is installed and on `PATH`. Managed by aqua (`~/.config/aquaproj-aqua/aqua.yaml`),
mise (`~/.config/mise/config.toml`), or nix (`.chezmoidata/nix.yaml`). If something here is
missing, that is a bug in the dotfiles — report it rather than installing by hand.

## Rule of thumb

Reach for the modern tool first. The POSIX defaults still exist and still work, but they
are slower, harder to script correctly, and their output is worse to parse.

| Instead of                       | Use               | Why                                               |
| -------------------------------- | ----------------- | ------------------------------------------------- |
| `grep -r`                        | `rg`              | gitignore-aware, parallel, `--json` output        |
| pattern-matching code with regex | `ast-grep` / `sg` | matches syntax, not text — survives formatting    |
| `find`                           | `fd`              | sane defaults, no `-print0 \| xargs` dance        |
| `sed -i`                         | `sd`              | literal strings by default, no escaping minefield |
| `wc -l` over sources             | `tokei`           | per-language, skips comments/blanks               |
| `curl`                           | `xh`              | JSON by default, readable flags                   |
| `diff -u`                        | `difft`           | syntax-aware — ignores pure reformatting          |
| `du -sh` / `df -h`               | `dust` / `duf`    | sorted tree / aligned table                       |
| `ps aux \| grep`                 | `procs`           | searchable, tree view, no self-match              |
| `man`                            | `tldr` (`tlrc`)   | examples first                                    |

## Search & navigation

- `rg` — text search. `--json` for machine output, `-t py` type filter, `-C` context.
- `rga` — same, but also greps inside PDF/docx/zip/sqlite.
- `ast-grep` / `sg` — structural search **and rewrite**. `sg run -p 'foo($A)' -r 'bar($A)'`.
  Debug a non-matching pattern with `--debug-query=ast`.
- `fd` — file search. `-e ext`, `-H` hidden, `-x cmd` per-result exec.
- `fzf` — fuzzy filter. Interactive; in scripts use `--filter=<query>` (non-interactive).
- `tre` — tree listing, gitignore-aware.
- `eza` — `ls` replacement (`--git`, `--tree`).
- `zoxide` — frecency `cd`. `zoxide query <term>` resolves a path non-interactively.

## Structured data

- `jq` — JSON.
- `yq` — YAML (and JSON/XML/TOML/props via `-p`/`-o`).
- `dasel` — one query syntax across JSON/YAML/TOML/XML/CSV.
- `hexyl` — hex viewer.
- `sd` — find & replace. `sd 'old' 'new' file`; `-s` for literal, `-p` dry-run preview.

## Diff, VCS, code review

- `difft` (difftastic) — syntax-aware diff; the one to use when a diff is mostly noise.
- `delta` — git pager with syntax highlighting + side-by-side.
- `git-cliff` — changelog from conventional commits.
- `jj` — Jujutsu VCS (git-compatible backend).
- `gh` / `glab` — GitHub / GitLab. `gh api` + `--jq` is the scriptable path.
- `ghq` — clone into a structured `~/ghq/<host>/<owner>/<repo>` tree.
- `onefetch` — repo summary (languages, churn, contributors).
- `tokei` — LOC by language.
- `act` — run GitHub Actions locally.

## HTTP & network

- `xh` — HTTP client. `xh POST url key=val`, `--json`, `-d` download.
- `oha` — load testing / benchmarking HTTP.
- `doggo` — DNS lookup with clean output.
- `rclone` — cloud storage sync.
- `aria2c` — multi-connection downloader.
- `wget`, `openssl`, `mosh` — as usual.

## Build, run, orchestrate

- `just` — task runner (`Justfile`). Prefer over ad-hoc shell scripts.
- `watchexec` — rerun a command on file change. `-e py -r cmd`.
- `pueue` — background job queue with logs; survives terminal exit.
- `direnv` — per-directory env.
- `hyperfine` — statistical benchmarking (warmup, multiple runs, comparison).
- `mise` / `aqua` — toolchain + binary version management.
- `treefmt` — one-shot multi-language formatter (config in `treefmt.toml`).
- `prek` — fast pre-commit runner (`prek run --files ...`).

## Quality & lint

`ruff` + `ty` (Python), `shellcheck` + `shfmt` (shell), `actionlint` + `zizmor` (GH Actions),
`golangci-lint` (Go), `selene` + `stylua` (Lua), `statix` + `nixfmt` (Nix), `tflint` (Terraform),
`typos` (spelling), `prettier` (JS/TS/JSON/YAML/MD).

## Security & supply chain

- `gitleaks` — secret scanning.
- `trivy` — vulnerabilities in images/fs/repos.
- `syft` — SBOM generation; `grype` — scan an SBOM.
- `age` — file encryption (chezmoi's backend).
- `gopass` — password store.

## Kubernetes & infra

`kubectl` (+ `kubecolor`), `kubectx`, `krew`, `helm`, `stern` (multi-pod log tail),
`k9s` (TUI), `lazydocker` (TUI), `terraform`, `tflint`.

## Docs, media, presentation

- `glow` — render markdown. Use `-s dark` and note it pages by default.
- `quarto`, `typst` — document/PDF authoring.
- `mmdc` (mermaid-cli) — render mermaid to SVG/PNG.
- `magick` (ImageMagick), `ffmpeg`, `gs` (Ghostscript), `poppler` — image/video/PDF processing.
- `vhs` — script a terminal session to GIF/MP4; `asciinema` — record a real one.
- `markitdown` — any document to markdown (also available as MCP).
- `ouch` — compress/decompress anything (`ouch d file.tar.zst`); `7zz`, `zstd`.

## Observability

`btm` (bottom, TUI), `procs`, `dust`, `duf`, `lnav` (log navigator), `sniffnet` (network, TUI),
`fastfetch`.

## Interactive TUIs — do NOT invoke from an agent shell

These take over the terminal and will hang a non-interactive call:

`yazi`, `k9s`, `lazygit`, `lazydocker`, `btm`, `jnv`, `nvim`, `atuin`, `sesh`, `slumber`,
`posting`, `gum` (without a piped subcommand), `sniffnet`.

`bat` and `glow` page by default — pass `--paging=never` (bat) or redirect, or just use
`cat` / read the file directly.

## AI agent tooling

`claude`, `codex`, `kimi`, `pi`, `aichat`, `agent-browser` (browser automation for agents),
`impeccable` (frontend UI anti-pattern detector, project-scoped), `hyperframes` (HTML→MP4),
`ccusage` (token usage analysis), `herdr` (terminal/session manager).
