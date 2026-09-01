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

## このリポジトリについて

これは `chezmoi` で管理する個人ワークステーション用の設定リポジトリです。
汎用的な starter template ではなく実運用中の構成なので、以下では現在の
checkout に存在するファイルと挙動だけを説明します。

主なレイヤーは次のとおりです。

- `chezmoi`: テンプレート、ターゲットファイルのマージ、bootstrap スクリプト
- Nix: クロスプラットフォームのユーザープロファイル、macOS では `nix-darwin`
- Homebrew と Mac App Store: macOS アプリ
- `aqua`: 固定バージョンの CLI とサードパーティ registry
- `mise`: Nix の外で意図的に管理する runtime とツール
- Claude Code、Codex CLI、Pi、Cursor Agent CLI、Kimi Code、Antigravity CLI の設定

> 個人向けのデフォルト値が含まれます。AI の実行権限は広く、private マシン用
> アプリも含まれるため、別のマシンへ適用する前にテンプレートとデータを確認して
> ください。

## サポート範囲と Profile の挙動

| 範囲                 | 現在の実際の挙動                                                                                                                                                                                          |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OS                   | bootstrap スクリプトは macOS と Linux に対応します。                                                                                                                                                      |
| Nix の新規 bootstrap | 固定 installer は `aarch64-darwin`、`aarch64-linux`、`x86_64-linux` 用に存在します。Nix installer は新規の `x86_64-darwin` を拒否します。                                                                 |
| `work`               | work 用 Nix パッケージと macOS の work Homebrew パッケージを追加し、`private = false` にします。現在の work 集合には MariaDB、PostgreSQL、Redis、AWS/Azure ツール、DBeaver、GCloud CLI などが含まれます。 |
| `private`            | `not work` から導出されるため、macOS では `work = false` のとき private Homebrew cask と MAS 項目が選択されます。現在の private Nix パッケージ一覧は空です。                                              |
| `headless`           | GUI 用 dotfiles と一部の macOS 保守スクリプト（`09`、`17`、`22`）を除外します。汎用的なパッケージ無効化スイッチではなく、macOS では nix-darwin/Homebrew モジュールもレンダーされます。                    |
| Mac App Store        | private の MAS 一覧は `installMasApps = true` の場合だけインストールされます。                                                                                                                            |

## ハイライト

- Nix、パッケージ profile、CLI、runtime、AI 統合、サービス、保守処理を含む
  番号付き `chezmoi` パイプライン
- ロックされた Nix flake と shared/work/private に分かれた profile データ
- `~/.harnesses/skills` の共有 skills ライブラリを、プロジェクト単位で
  Claude、Codex、Pi、Cursor、Kimi Code へ有効化
- Pi のネイティブな provider/model 切替と、Claude Code/Codex CLI の account wrapper
- checksum 検証付きの固定 Cursor Agent/Azure Functions installer、および
  非 headless macOS の固定 Paperlib installer
- 固定 revision の Herdr plugins、Claude/Codex lifecycle integration、
  macOS/Linux の孤立 MCP プロセス掃除
- CI、セキュリティスキャン、回帰テスト、定期的な依存更新 PR

## Source of Truth とリポジトリ構成

README は現在のソースファイルに対応しています。

```text
.
├── .chezmoidata/
│   ├── nix.yaml              # Nix ユーザー/システムパッケージデータ
│   ├── homebrew.yaml         # taps、formulae、cask、MAS
│   ├── claude.yaml           # Claude providers/accounts
│   ├── pi.yaml               # Pi のデフォルト、packages、custom providers
│   ├── herdr.yaml            # Herdr plugin revisions
│   ├── antigravity.yaml      # Antigravity CLI 設定
│   ├── aerospace.yaml        # AeroSpace の floating-window データ
│   ├── hammerspoon.yaml      # アプリと入力ソースのデータ
│   └── versions.yaml         # installer、package、skill revisions
├── .chezmoiexternal.toml.tmpl # TPM と共有 skill archive
├── .chezmoiscripts/           # 番号付き bootstrap/保守スクリプト
├── nix-config/                # flake、nix-darwin/profile モジュール
├── dot_claude/                # Claude 設定、hooks、指示
├── dot_codex/                 # Codex 設定、prompts、指示
├── dot_pi/                    # Pi 設定、models、agents、MCP、themes
├── dot_cursor/                # Cursor CLI 設定と MCP
├── dot_kimi-code/             # Kimi の safety 設定と MCP
├── dot_gemini/                # Antigravity CLI のマージ設定
├── dot_harnesses/             # ローカル harness commands と skills
├── dot_local/bin/             # account、key、MCP、skill、status helper
├── private_dot_config/         # shell、tmux、ツール、サービス設定
├── private_Library/           # macOS LaunchAgents
├── docs/                      # 個別の運用ガイド
├── tests/                     # bootstrap/統合回帰テスト
└── tools/                     # 単体ユーティリティ（WezTerm アイコンなど）
```

## Bootstrap フロー: 実際に実行されるもの

ラベルは `00` から `23` までですが、**`19` のスクリプトが二つ**あります。
`run_onchange_*` はレンダーされた source state が変わったときに実行され（週次
トリガーを含むものもあります）、`run_after_*` は apply 後に呼び出されて各自で
条件や頻度を判定します。

| ラベル | スクリプト                                                 | 条件と処理                                                                                                                                                                 |
| ------ | ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `00`   | `run_onchange_before_00_install-nix.sh.tmpl`               | 固定版 Determinate Nix をインストール/更新します。新規時はミラーを選び、installer checksum を検証します。                                                                  |
| `01`   | `run_before_01_setup-encryption-key.sh.tmpl`               | `useEncryption = true` の場合だけレンダーされ、指定された keys-backup リポジトリから keys-manage 管理ファイルを復元します。                                                |
| `02`   | `run_onchange_after_02_init.sh.tmpl`                       | macOS のみ。レンダー済み `nix-darwin` 設定を適用します。                                                                                                                   |
| `03`   | `run_onchange_after_03_set_profiles.sh.tmpl`               | クロスプラットフォームの `flakey-profile` ユーザーパッケージ profile を切り替えます。                                                                                      |
| `04`   | `run_onchange_after_04_install-aqua.sh.tmpl`               | 検証済み installer で固定版 `aqua` をインストール/更新します。                                                                                                             |
| `05`   | `run_onchange_after_05_aqua-install-tools.sh.tmpl`         | 二段階で aqua package を導入します。先に `mise` と Go/Rust を用意し、その後全 aqua 集合を入れます。                                                                        |
| `06`   | `run_onchange_after_06_setup-gopass.sh.tmpl`               | 暗号化有効時だけレンダーされ、gopass store を検証または対話的に clone します。                                                                                             |
| `07`   | `run_onchange_after_07_mise-install.sh.tmpl`               | mise の runtime とツールをインストールします。`npm:` 項目は Bun を使います。                                                                                               |
| `08`   | `run_onchange_after_08_nix-index-db.sh.tmpl`               | `nix-locate` がある場合だけ、固定版 nix-index database を更新します。                                                                                                      |
| `09`   | `run_onchange_after_09_install-paperlib.sh.tmpl`           | 非 headless macOS のみ。固定版 Paperlib DMG をダウンロード、検証、インストールします。                                                                                     |
| `10`   | `run_after_10_update_homebrew_packages.sh`                 | macOS で Homebrew がある場合、7 日ごとに明示的な update/repair/upgrade/cleanup を行います。nix-darwin 側も `upgrade = true` です。                                         |
| `11`   | `run_after_11_sync-claude-integration-plugins.sh`          | Claude Code と `jq` があれば公式 marketplace を登録し、Claude Slack と Notion workspace plugin をインストールします。                                                      |
| `12`   | `run_after_12_sync-claude-mcp.sh.tmpl`                     | 管理対象の Claude user MCP を同期し、`context7`/`tavily`/`deepwiki` を常時ロードにします。他のユーザー項目は削除しませんが、旧名 `arxiv-mcp-server` は明示的に削除します。 |
| `13`   | `run_after_13_sync-codex-connector-plugins.sh`             | `slack@openai-curated` の導入を試みます。現在の marketplace にない場合はスキップします。                                                                                   |
| `14`   | `run_after_14_sync-herdr-integrations.sh`                  | Claude と Codex の Herdr integration をインストール/更新します。Herdr 付属の Pi integration は削除し、リポジトリの `pi-herdr-state` を使います。                           |
| `15`   | `run_after_15_cursor-agent.sh.tmpl`                        | macOS/Linux。checksum 検証済みの固定 Cursor Agent archive を取得し、`~/.local/bin` に `agent` と `cursor-agent` をリンクします。                                           |
| `16`   | `run_onchange_after_16_azure-functions-core-tools.sh.tmpl` | work マシンのみ。Homebrew/npm ではなく Microsoft の固定 Azure CDN archive から `func` を導入します。                                                                       |
| `17`   | `run_onchange_after_17_load-launch-agents.sh.tmpl`         | 非 headless macOS のみ。qmk-hid-host/MCP reaper LaunchAgent を再ロードし、古いローカル Context7 agent を削除します。                                                       |
| `18`   | `run_onchange_after_18_herdr-plugins.sh.tmpl`              | `.chezmoidata/herdr.yaml` にある七つの固定 revision の Herdr plugin を導入します。                                                                                         |
| `19a`  | `run_after_19_remove-legacy-pi-sources.sh`                 | 古い Pi extension ファイル、package 宣言、インストール、不要な workflow/statusline state を削除します。Pi の session/auth は触りません。                                   |
| `19b`  | `run_onchange_after_19_load-systemd-user-units.sh.tmpl`    | Linux のみ。linger と `mcp-reaper.timer` を有効にし、古いローカル Context7 unit を無効にします。                                                                           |
| `20`   | `run_after_20_update-pi-extensions.sh.tmpl`                | Pi があれば ISO 週/package 集合ごとに `pi update --extensions` を一度実行します。失敗は非致命で次回 apply に再試行します。                                                 |
| `21`   | `run_onchange_after_21_terminal-profile.sh.tmpl`           | 非 headless macOS のみ。管理対象 Dracula Terminal.app profile を既定にします。                                                                                             |
| `22`   | `run_after_22_wezterm-icon.sh`                             | macOS のみ。必要な場合、cask 交換後に WezTerm のカスタムアイコンを再適用します。                                                                                           |
| `23`   | `run_after_23_mise-up.sh`                                  | 7 日ごとに `mise up` を実行します。失敗は非致命で、成功時刻は進めません。                                                                                                  |

## クイックスタート

> [!WARNING]
> このリポジトリを適用すると shell、パッケージマネージャ、AI 設定、さらに
> macOS ではシステム/アプリ設定が変更されます。先にテンプレートとデータを確認
> してください。

### ダウンロードして対話的に実行

```bash
curl -fsSL https://raw.githubusercontent.com/signalridge/dotfiles/main/init.sh -o /tmp/init.sh
sh /tmp/init.sh
```

`curl … | sh` は使わないでください。初回は work/encryption と identity の入力が
必要で、必要なデータがなく stdin が TTY でない場合、現在のテンプレートは明示的
に失敗します。先にダウンロードすれば端末入力を維持できます。

### ref を固定して確認

```bash
REF="<tag-or-branch>"
curl -fsSLo /tmp/init.sh "https://raw.githubusercontent.com/signalridge/dotfiles/${REF}/init.sh"
# /tmp/init.sh を確認し、必要なら checksum を記録する。
sh /tmp/init.sh --ref "${REF}"
```

### ローカル clone を使う

```bash
git clone https://github.com/signalridge/dotfiles.git
cd dotfiles
./init.sh
```

リモート repository から bootstrap する場合、`init.sh` は `--repo`（または
`DOTFILES_REPO`）、`--ref`/`--branch`（または `DOTFILES_REF`）、`--depth`（または
`DOTFILES_DEPTH`）を受け付けます。ローカル clone から実行すると現在の checkout を
そのまま使い、これらの remote 選択オプションでは checkout は切り替わりません。
先に目的の ref へ切り替えてから実行してください。bootstrap は HTTPS 専用で、
`--ssh` は拒否されます。`DOTFILES_USE_ENCRYPTION=true|false` は暗号化選択を
上書きできますが、その他の初回 prompt は省略しません。

chezmoi を直接呼ぶ場合は、例えば次のように profile を事前選択できます。

```bash
chezmoi init --apply \
  --promptBool work=false \
  --promptBool useEncryption=false \
  signalridge
```

## 初回データ

`.chezmoi.toml.tmpl` が実際に使うデータは次のとおりです。

| データ                                          | 要求/利用されるタイミング                                                                                                      |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `work`                                          | 保存値がなければ必須。TTY で prompt され、派生する `private` を決めます。                                                      |
| `useEncryption`                                 | data にも `DOTFILES_USE_ENCRYPTION` にもなければ必須。暗号化 key 復元と gopass 設定を制御します。                              |
| `hostname`                                      | non-work かつ保存値がない場合だけ prompt。work は `.chezmoi.hostname` を使います。                                             |
| `gitUsername`、`gitEmail`                       | 値がない場合に prompt。安全な identity の既定値はありません。                                                                  |
| `headless`                                      | TTY では prompt、非 TTY では保存値、それもなければ OS ベースの fallback を使います。                                           |
| `installMasApps`                                | macOS の TTY prompt。無効時は MAS をインストールしません。                                                                     |
| `homeWifiSSIDs`                                 | 任意の macOS TTY prompt。Hammerspoon の音量 watcher 用のカンマ区切り SSID です。                                               |
| `timezone`                                      | 可能ならホストから自動検出し、できなければ TTY で prompt、最終的に `Etc/UTC` になります。                                      |
| `keysRepository`                                | 暗号化有効かつ保存値がない場合だけ prompt。keys-manage restore に必要です。                                                    |
| `gopassRepository`                              | 暗号化有効かつ保存値がない場合だけ prompt。gopass setup に必要です。                                                           |
| `claudeProviderAccount`、`codexProviderAccount` | **prompt ではありません**。既定値はそれぞれ `anthropic` と `openai` で、chezmoi data または account manager から変更できます。 |

`useEncryption = false` の場合、暗号化復元/gopass スクリプトと管理対象の
`~/.ssh/*` は ignore されます。暗号化を有効にすると、bootstrap には GitHub
HTTPS credential が必要になる場合があります（既存の `gh` login、
`GH_TOKEN`/`GITHUB_TOKEN`、または対話的 device-code OAuth）。

## 日常運用

対話的 shell は
`JUSTFILE=${XDG_CONFIG_HOME:-$HOME/.config}/just/.justfile`（通常は
`~/.config/just/.justfile`）を export します。この global justfile には次が含まれます。

```bash
# Chezmoi
just apply
just diff
just update
just re-add

# Nix
just up                 # 全 flake input を更新
just upp nixpkgs        # 一つの input を更新
just gc
just verify
just optimize

# macOS only
just darwin
just darwin-check
just darwin-build
```

global justfile には回帰テスト recipe は **ありません**。実際のテストは次で実行
します。

```bash
bash "$(chezmoi source-path)/tests/run.sh"
pre-commit run --all-files
```

その他の生成 recipe には `edit`、`history`、`repl`、`clean`、`repair`、`gcroot`、
Git の短縮コマンド（`st`、`gd`、`gl`、`cm`、`push`、`pull`）があります。一部は
macOS 専用です。`clean` と `gc` の既定期間は 7 日で、引数で変更できます。

## パッケージとツールの管理

パッケージの source は意図的に分かれており、すべての一覧が `.chezmoidata/`
にあるわけではありません。

| レイヤー                 | Source                                                            | 管理内容                                                                                                                                                                   |
| ------------------------ | ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Nix ユーザープロファイル | `.chezmoidata/nix.yaml` + `nix-config/modules/profile.nix.tmpl`   | `flakey-profile` で shared と work のパッケージを管理します。現在の `sysPkgs` は空ですが、macOS のシステム設定/フォント/サービスは `nix-darwin` にあります。               |
| nix-darwin               | `nix-config/modules/*.tmpl`                                       | macOS defaults、フォント、shell/PAM、Nix index、Homebrew、system launchd jobs。                                                                                            |
| Homebrew                 | `.chezmoidata/homebrew.yaml` + `nix-config/modules/apps.nix.tmpl` | tap、formula、cask、条件付き MAS。ロックされた再現可能な Nix レイヤーではありません。                                                                                      |
| aqua                     | `private_dot_config/aquaproj-aqua/aqua.yaml` と `registry.yaml`   | Claude/Codex、shell、Kubernetes/security、Kimi Code、Herdr、Slipway、qmk-hid-host など固定版 CLI。                                                                         |
| mise                     | `private_dot_config/mise/config.toml.tmpl`                        | Node、Bun、Python、Go、Rust、Lua、Terraform、uv、pipx、Pi、使用量分析、browser/media CLI、`xurl`、`crosspost`。`npm:` は Bun を使いますが Node は runtime のため残します。 |
| 直接 installer           | `.chezmoiscripts/00`、`09`、`15`、`16`                            | Determinate Nix、Paperlib、Cursor Agent、work-only Azure Functions Core Tools。版と checksum は repository のデータで固定します。                                          |
| Pi extensions            | `.chezmoidata/pi.yaml` + Pi settings                              | 外部 package 5 個と `@signalridge` package 20 個。意図的に pin せず、Pi の週次 `update --extensions` で更新します。                                                        |

代表的なツールは `eza`、`bat`、`fd`、`ripgrep`、`fzf`、`gh`、`ghq`、`just`、
`lazygit`、`neovim`、`yazi`、`jj`、`xh`、`slumber`、`k9s`、`kubectl`、`helm`、
`trivy`、`syft`、`grype`、`ruff`、`ty`、`git-cliff`、`quarto`、`typst`、
`aichat`、`agent-browser`、`hyperframes`、`impeccable` です。完全な一覧は上記の
実際の source file を参照してください。

## Shell alias と関数

Shell 設定は対話的な zsh セッションでのみ読み込まれます。以下の alias は対象
コマンドが存在する場合だけ作成されます。

| Alias                                                 | 対象                                                                             |
| ----------------------------------------------------- | -------------------------------------------------------------------------------- |
| `dot`                                                 | `chezmoi`                                                                        |
| `vi`、`vim`、`view`                                   | `nvim`                                                                           |
| `ls`、`cat`、`du`、`df`、`man`                        | `eza`、`bat`、`dust`、`duf`、`tldr`                                              |
| `hf`、`lg`、`lzd`、`top`、`pc`、`dog`、`logv`、`post` | `hyperfine`、`lazygit`、`lazydocker`、`btm`、`procs`、`doggo`、`lnav`、`posting` |
| `ccm`、`ccw`                                          | `claude-manage`、`claude-with`                                                   |
| `cxm`、`cxw`                                          | `codex-manage`、`codex-with`                                                     |
| `k` / `kubectl`                                       | `kubecolor` があればそれ、なければ `k` は `kubectl`                              |

`la`、`ll`、`lla`、`lt` は eza/listing helper です。`cp`、`mv`、`mkdir` は
interactive/safe alias（`-i`/`-v` と `mkdir -p`）です。`ripgrep`、`fd`、`zoxide`
は導入・統合されますが、**`grep`、`find`、`cd` がそれらへ alias されるわけでは
ありません**。

代表的な関数：

```bash
dev [query]                 # ghq + fzf リポジトリ picker
mkcd <dir>                  # ディレクトリを作って移動
dotcd                       # chezmoi source へ移動
fgc / fgl / fga              # branch、log、staged file の fuzzy helper
aicommit [--dry-run] ...    # staged diff から AI conventional commit
create_direnv_venv          # Python .envrc を書いて allow
create_direnv_nix           # .envrc に use flake（flake 自体は作らない）
create_direnv_mise          # .envrc に use mise
create_py_project [name]    # uv init + direnv の Python layout
```

ほかに `ccnew`/`ccdone`、`wt-new`/`wt-go`/`wt-ls`/`wt-rm`、`gh_latest`、`gh_clone`、
`fkill`、`fenv`、`mcp-ps`、`mcp-reap` があります。`wt-*` と `cc*` は通常の
repository では Git worktree を使いますが、この chezmoi source 内では worktree
と branch switching が禁止されています。`AICOMMIT_PROVIDER` は `claude`、
`codex`、`auto` を受け付け、管理 shell exports の既定値は `claude` です。

## AI Harness と Provider 管理

### 管理対象 harness

| Harness          | 管理ファイルと挙動                                                                                                                                                                            |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Claude Code      | `~/.claude/settings.json`、global instructions、hooks、statusline、official integration plugins。                                                                                             |
| Codex CLI        | `~/.codex/config.toml`、project-document fallback、lifecycle hooks、MCP、Slack plugin 設定。                                                                                                  |
| Pi               | `~/.pi/agent/settings.json`、`models.json`、`subagents.json`、workflow settings、themes、keybindings、MCP。Pi は `/model` と `/login` を使い、Pi account wrapper や `pi-token` はありません。 |
| Cursor Agent CLI | 固定版 `agent`/`cursor-agent` binary と `~/.cursor/cli-config.json`、`~/.cursor/mcp.json`。                                                                                                   |
| Kimi Code        | `~/.kimi-code/config.toml` の safety defaults と `~/.kimi-code/mcp.json`。account wrapper はありません。                                                                                      |
| Antigravity CLI  | `~/.gemini/antigravity-cli/settings.json` への deep merge。runtime が管理する model/trust 設定は保持します。                                                                                  |
| aichat           | `~/.config/aichat/config.yaml`。対応する `pi/...` gopass key があれば Kimi Moonshot と Doubao を書き出します。                                                                                |

### Claude/Codex account

`.chezmoidata/claude.yaml` の Claude provider は現在 `anthropic`、`deepseek`、
`kimi`、`glm`、`qwen`、`minimax`、`doubao` です。設定済み account は
`anthropic`、`opus`、`haiku`、`deepseek@private`、`doubao@private`、
`kimi@private` です。Native Anthropic は OAuth、サードパーティ Claude key は
次の形式の gopass path から読みます。

```text
claude/<provider>/<account-label>/api_key
```

Codex は `openai` の native OAuth を残し、DeepSeek、Doubao、GLM、Kimi、MiniMax、
Qwen の third-party provider block をレンダーします。Codex API key は次です。

```text
codex/<provider>/<account-label>/api_key
```

永続的な切替は `claude-manage`/`codex-manage`、一回だけの起動は
`claude-with`/`codex-with` を使います。token helper は key の取得/確認や account
設定の出力だけを行い、account の切替はしません。

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

### Pi のポリシー

管理対象 Pi の起動既定値は `openai-codex/gpt-5.6-luna`、
`signalridge-ridgeline` theme、quiet startup、Bun ベースの package install、
native compaction/retry 設定です。親セッションの effort は machine-scoped で、
private は `max`、work は `xhigh` です。

`subagents.json` は `low`、`medium`、`high` の三つの tier だけを定義します。
model/effort も machine-scoped で、workflow settings は workflow strength
`low`/`medium`/`high` を同名 tier へ直接対応付けます。旧来の別 workflow model
vocabulary は現在の設定にはありません。

Pi の custom provider key は必要に応じて service 単位で `pi/` 以下に置きます
（例：`pi/opencode/api_key`、`pi/deepseek/api_key`、`pi/kimi/api_key`）。gopass key が
ない provider は `models.json` のレンダー時にスキップされます。環境変数型の
provider は `$VAR` 参照を残すため、変数なしで呼び出した時点で失敗する可能性が
あります。aichat の Moonshot platform key は別の `pi/moonshot/api_key` で、Kimi
Code subscription key とは異なります。

### 共有 Skills

`.chezmoiexternal.toml.tmpl` は固定 revision の skill archive を共有 library に
ダウンロードします。

```text
~/.harnesses/skills/<category>/<skill>/
```

source には wshobson/agents、anthropics/skills、OpenAI、Hugging Face、Sentry、Trail
of Bits、Cloudflare、Vercel、Supabase、Expo、Microsoft、Baoyu、phuryn/pm-skills、
Reddit/daily.dev/X publishing、UI/UX/diagram skill、Go/Rust/Swift/TypeScript suite
などがあります。これは共有 library であり、Claude marketplace を一括インストール
する仕組みではありません。global `ai-research-skills` CLI は mise の pipx/uvx
backend で別に管理され、host skills/commands はインストールしません。

プロジェクトディレクトリで `skill-activate` を実行すると、選択した skill を次の
五つのディレクトリへ flat symlink として作成します。

```text
./.claude/skills  ./.codex/skills  ./.pi/skills
./.cursor/skills  ./.kimi-code/skills
```

利用できるモードは `--active`、`--list`、`--category <name>`、`--sync`、`--clear`
です。既定では global に有効化されません。

### Plugins、MCP、Herdr

Official plugin/connector と共有 skill library は別の仕組みです。

- Claude は `slack@claude-plugins-official` と
  `notion-workspace-plugin@notion-plugin-marketplace` の導入を試みます。
- Codex は `slack@openai-curated` の追加を試み、現在の marketplace にない場合は
  スキップします。
- Herdr は `.chezmoidata/herdr.yaml` の七つの固定 plugin と Claude/Codex lifecycle
  integration を導入します。付属 Pi integration は明示的に削除し、
  `pi-herdr-state` を使います。

MCP 宣言は harness ごとに同じではありません。

| Harness     | 管理される MCP                                                                                                                       |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Claude      | `context7`、`markitdown`、`arxiv`、`tavily`、`gitmcp`、`deepwiki`。`context7`/`tavily`/`deepwiki` は常時ロード。                     |
| Codex       | Notion と上記六つ。                                                                                                                  |
| Pi          | `context7`、`deepwiki`、`gitmcp` は lazy direct tools、`markitdown` と `arxiv` は lazy proxy tools。ここでは Tavily を宣言しません。 |
| Cursor/Kimi | `context7`、`tavily`、`deepwiki`、`gitmcp`、`markitdown`、`arxiv`。                                                                  |

`~/.local/bin/mcp-tavily` は実行時に gopass の `tavily/api_key` を読み、`bunx` で
固定版 `tavily-mcp@0.2.16` を起動します。対応する non-headless macOS または
systemd-user 設定が有効な場合、LaunchAgent または user timer が `mcp-reaper` を
実行し、live session のプロセスには触れず、孤立したローカル MCP プロセスを記録・
終了します。

### AI の実行権限

管理対象の既定値は意図的に permissive なので、再利用前に確認してください。

- Claude: `bypassPermissions`、明示的な deny rule と Git rewrite hook
- Codex: `approval_policy = "never"`、`sandbox_mode = "danger-full-access"`
- Cursor: `approvalMode = "unrestricted"`
- Kimi Code: `default_permission_mode = "yolo"`
- Antigravity: `toolPermission = "always-proceed"`、terminal sandbox 無効
- Pi: permission package は通常操作を許可しますが、管理ポリシーは Git worktree/
  branch-switch コマンドを拒否します

Claude hooks は変更ファイルの整形と tmux/Herdr state の更新も行います。Git rewrite
hook は一部の不可逆操作を block し、復旧可能な危険操作では確認を求めますが、すべて
の Git 変更を拒否するわけではありません。

## セキュリティと Secrets

secret の種類ごとに別の仕組みを使います。

1. Chezmoi は `.chezmoitemplates/shell/age_command_wrapper.sh` 経由で `age` backend
   を使い、`~/.ssh/main` と `~/.ssh/main.pub` を identity/recipient ペアにします。
2. Gopass は age backend を使い、store は `~/.local/share/gopass/stores/root`。
   暗号化有効 profile でのみ設定されます。
3. `keys-manage` は `~/.local/share/keys-backup` に key backup を保存します。個々の
   ファイルと control file は OpenSSL AES-256-CBC + PBKDF2（100,000 iterations）で
   暗号化されます。password は TTY、`KEYS_BACKUP_PASSWORD`、`--password-file`、
   gopass から取得できますが、process arguments への漏洩を避けるため `-p/--password`
   は拒否されます。
4. bootstrap/key backup の GitHub access は HTTPS と `gh` credential helper を使い、
   古い GitHub SSH URL は HTTPS に正規化されます。
5. Claude の Git hook guard は一部の危険な history 操作を block し、別の操作では
   確認を求めます。詳細は hook と `SECURITY.md` を参照してください。

関連するセキュリティ資料：

- [SECURITY.md](SECURITY.md)
- [keys-manage guide](docs/keys-manage-guide.md)
- [gopass new-device guide](docs/gopass-new-device-setup.md)
- [Claude provider guide](docs/claude-provider.md)

## CI と自動化

- `.github/workflows/ci.yml`: `main` への push/PR と手動実行で pre-commit lint を行い、
  macOS/Linux matrix で Nix flake をレンダー・チェックします。
- `.github/workflows/tests.yml`: push、PR、手動実行で `bash tests/run.sh` を実行します。
- `.github/workflows/security.yml`: push、PR、手動実行で Zizmor、Trivy filesystem、
  Gitleaks scan を実行します。
- `.github/workflows/pr-title.yml`: semantic PR title を検証し、`wip` PR を許可します。
- `.github/workflows/scheduler.yml`: 毎日 `00:00 UTC` に実行し、三つの保守 workflow を
  dispatch します。
- `update-versions.yml`、`update-flake-lock.yml`、`update-aqua-packages.yml`: 通常は
  scheduler から起動され、依存更新 PR を作る `workflow_dispatch` workflow です。
- Dependabot は東京時間の daily cron でも GitHub Actions dependency を確認し、3 日の
  cooldown を使います。

## 関連ドキュメント

- [Claude provider tools](docs/claude-provider.md)
- [Keys manager](docs/keys-manage-guide.md)
- [Gopass new-device setup](docs/gopass-new-device-setup.md)
- [Tmux keybindings](docs/tmux.md)
- [Social publishing](docs/social-publishing.md)
- [Security policy](SECURITY.md)

## 謝辞

- [chezmoi](https://github.com/twpayne/chezmoi) と
  [nix-darwin](https://github.com/LnL7/nix-darwin): 設定オーケストレーション
- [Nix](https://nixos.org/)、[flakey-profile](https://github.com/lf-/flakey-profile)、
  [Homebrew](https://brew.sh/)、[aqua](https://aquaproj.github.io/)、
  [mise](https://mise.jdx.dev/): package/tool 管理
- [Claude Code](https://www.anthropic.com/claude-code)、[Codex](https://openai.com/index/introducing-codex/)、
  [Pi](https://github.com/earendil-works/pi)、[Cursor](https://cursor.com/)、
  [Kimi Code](https://www.kimi.com/code)、[Herdr](https://github.com/ogulcancelik/herdr):
  管理対象の AI/agent ツール
- `.chezmoiexternal.toml.tmpl` にある external skill repository。各 upstream の
  license に従います。
- [Dracula Theme](https://draculatheme.com/): terminal と fzf の配色

## ライセンスの状態

現在の checkout にはルートの `LICENSE` ファイルがありません。古い README badge
からライセンスを推測しないでください。再配布可能なものとして扱う前に、明示的な
license file と宣言を追加してください。
