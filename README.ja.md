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

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=22&pause=1000&color=BD93F9&center=true&vCenter=true&width=600&lines=chezmoi+%2B+Nix+%E5%AE%A3%E8%A8%80%E7%9A%84%E9%96%8B%E7%99%BA%E7%92%B0%E5%A2%83;%E3%82%AF%E3%83%AD%E3%82%B9%E3%83%97%E3%83%A9%E3%83%83%E3%83%88%E3%83%95%E3%82%A9%E3%83%BC%E3%83%A0+macOS+%2B+Linux;Claude+Code+%E8%87%AA%E5%8B%95%E3%83%97%E3%83%A9%E3%82%B0%E3%82%A4%E3%83%B3%E5%90%8C%E6%9C%9F;%E3%83%A2%E3%83%80%E3%83%B3+Rust+CLI+%E3%83%84%E3%83%BC%E3%83%AB%E3%83%81%E3%82%A7%E3%83%BC%E3%83%B3)](https://git.io/typing-svg)

<p>
  <img src="docs/images/preview.png" alt="デスクトップのプレビュー —— Ghostty ターミナル、AeroSpace タイリング、fastfetch のシステム情報" width="400" />
  <img src="docs/images/herdr-lazyvim-preview.png" alt="Herdr ワークスペースのプレビュー —— Ghostty 上の LazyVim、リポジトリ一覧、agent ステータスのサイドバー" width="400" />
</p>

</div>

---

## このリポジトリについて

これは、再現可能な個人向け開発環境を管理するための dotfiles リポジトリです。中核は次の構成です。

- `chezmoi`: dotfiles 管理、テンプレート展開、ブートストラップのオーケストレーション
- `Nix`: 宣言的パッケージ管理（macOS は `nix-darwin`、macOS/Linux 共通で `flakey-profile`）
- `aqua` + `mise`: 必要に応じて Nix 外で CLI/ランタイムを管理
- `Claude Code` と `Codex CLI`: 共有 AI ツールチェーン

これはデモ用テンプレートではなく、日常運用している実構成です。README では、このリポジトリで現在実装されている内容のみを扱います。

---

## ハイライト

- `.chezmoiscripts/00..20` による統一ブートストラップパイプライン（再実行しても破綻しにくい設計）
- クロスプラットフォームなパッケージ戦略：
  - macOS/Linux 共通の Nix ユーザーパッケージ
  - macOS の `nix-darwin` システム設定
  - macOS の Homebrew / MAS 連携
- Claude/Codex 向け Skills ライブラリを `~/.harnesses/skills` へ自動同期
- Claude/Codex ラッパーの Provider 切替をサポート：
  - `claude-manage` / `claude-with`
  - `codex-manage` / `codex-with`
- `chezmoi apply` のたびにツール連携と Herdr agent 連携を自動同期
- GitHub Actions による依存更新の自動化（versions、flake lock、aqua packages）

---

## なぜこのリポジトリか

- **プロファイル横断管理**: `.chezmoidata/` が `shared` / `work` / `private` を駆動し、Nix・Homebrew・MAS を横断して一元管理
- **エンドツーエンドブートストラップ**: `00..20` の段階実行で、初期化を再現可能かつ段階的に組み合わせられる形で維持
- **macOS 向け最適化**: nix-darwin のシステム既定、Homebrew + MAS 連携、適用後の保守スクリプト
- **ワークフローガードレール**: pre-commit と Claude Hooks で危険な編集やコマンド誤用を抑止
- **DX 自動化**: Justfile ルーチン、fzf ナビゲーション、AI 補助コミットフロー
- **CI 整合性**: テンプレートレンダリングと `nix flake check` を macOS/Linux マトリクスで検証
- **AI 2 系統対応**: Claude Code、Codex CLI を 1 つのリポジトリで宣言的に管理

---

## 設計思想

新しい開発マシンのセットアップは、導入するパッケージも設定項目も多く、過去の調整を再現するだけで手間がかかります。

このリポジトリは、宣言的なベースラインと実用的なブートストラップパイプラインを組み合わせることで、複数マシン間でも予測可能な結果で作業環境を再構築できるようにしています。

コア原則：

- **再現性**: 同じセットアップロジックとバージョン化データから同じ結果を得る
- **宣言的構成を優先**: パッケージ/ツール設定は追跡可能な YAML/テンプレートへ集約
- **モジュラープロファイル**: work/private/headless の挙動をハードコードではなくデータで切替
- **AI 拡張ワークフロー**: prompts、hooks、skills、Provider 切替を一体運用
- **セキュリティの層分離**: dotfile secrets、password store、key backup を用途別に分離管理

---

## 目次

- [クイックスタート](#クイックスタート)
- [初回プロンプト](#初回プロンプト)
- [アーキテクチャ](#アーキテクチャ)
- [リポジトリ構成](#リポジトリ構成)
- [Bootstrap フロー（実際の実行順）](#bootstrap-フロー実際の実行順)
- [日常運用](#日常運用)
- [Claude Code 統合](#claude-code-統合)
- [AI ツールチェーン（Claude + Codex）](#ai-ツールチェーンclaude--codex)
- [ツールチェーン](#ツールチェーン)
- [シェル関数](#シェル関数)
- [パッケージ管理](#パッケージ管理)
- [マルチプロファイル設定](#マルチプロファイル設定)
- [セキュリティとシークレット](#セキュリティとシークレット)
- [CI と自動化](#ci-と自動化)
- [関連ドキュメント](#関連ドキュメント)
- [謝辞](#謝辞)
- [統計](#統計)
- [ライセンス](#ライセンス)

---

## アーキテクチャ

このリポジトリは、`chezmoi` のテンプレート管理を中核に、Nix ベースのパッケージ管理と AI ツール層を重ねた構成です。

- `chezmoi`: スクリプト/テンプレートの唯一の構成ソース（source of truth）
- `nix-darwin`（macOS）: システムレベル構成
- `flakey-profile`（macOS/Linux）: ユーザーパッケージプロファイル
- `aqua` + `mise`: 必要に応じた Nix 外 CLI/ランタイムレイヤー
- `dot_claude` + `dot_codex`: ツール別のグローバル指針と設定

| コンポーネント     | macOS          | Linux          |
| ------------------ | -------------- | -------------- |
| Dotfiles           | chezmoi        | chezmoi        |
| システム設定       | nix-darwin     | N/A            |
| ユーザーパッケージ | flakey-profile | flakey-profile |
| GUI アプリ         | Homebrew/MAS   | N/A            |

---

## リポジトリ構成

```text
.
├── .chezmoidata/
│   ├── nix.yaml                # Nix パッケージ定義（shared/work/private）
│   ├── homebrew.yaml           # Homebrew taps/brews/casks/MAS apps
│   ├── claude.yaml             # Claude Provider と account モデル設定
│   ├── versions.yaml           # ツール/プラグインのピン留め
│   ├── aerospace.yaml          # Aerospace WM データ
│   └── hammerspoon.yaml        # Hammerspoon データ
├── .chezmoiscripts/            # ブートストラップ/保守パイプライン（00..20）
├── nix-config/
│   ├── flake.nix.tmpl
│   └── modules/
│       ├── system.nix.tmpl     # nix-darwin システム設定
│       ├── apps.nix.tmpl       # Homebrew + MAS 連携
│       ├── profile.nix.tmpl    # flakey-profile パッケージ設定
│       └── host-users.nix
├── dot_local/bin/              # CLI ラッパー（Claude/Codex/keys/MCP）
├── dot_claude/                 # Claude グローバル指示、hooks、テンプレート
├── dot_codex/                  # Codex グローバル指示、設定、prompts
├── private_dot_config/         # 各種ツール設定（tmux、mise、aqua、gopass など）
├── docs/                       # 個別ガイド
└── tests/                      # ブートストラップ/スクリプトの回帰テスト
```

---

## Bootstrap フロー（実際の実行順）

`chezmoi` スクリプトは番号順で実行されます。

1. `00` Nix をインストール（Determinate installer + アーキ/ミラー判定）
2. `01` 必要に応じて keys-manage 暗号化ファイルを復元（`useEncryption=true`）
3. `02` macOS: nix-darwin 設定を適用
4. `03` flakey-profile を切り替え
5. `04` ピン留め済みの aqua installer/aqua をインストール
6. `05` `private_dot_config/aquaproj-aqua/aqua.yaml` に基づいてツール（`mise` を含む）を導入
7. `06` gopass ストアを初期化（対話式 clone）
8. `07` aqua が提供する `mise` でランタイム/ツールを導入
9. `08` ピン留め済み nix-index DB を導入
10. `09` macOS: Paperlib をインストール/更新
11. `10` Homebrew 更新（7 日間隔）
12. `11` Claude integration plugins を同期
13. `12` Claude MCP servers を同期
14. `13` Codex connector plugins を同期
15. `14` Claude・Codex・Pi の Herdr integrations を同期
16. `15` Cursor Agent CLI をインストール/更新
17. `16` work profile: Azure Functions Core Tools を導入
18. `17` macOS GUI: 管理対象 LaunchAgents を再読み込み
19. `18` Herdr plugins を同期
20. `19` Linux: systemd user units を再読み込み
21. `20` ISO 暦週/package 集合ごとに Pi extensions を一度同期（失敗時は次回 apply で再試行）

---

## クイックスタート

> [!WARNING]
> このリポジトリはシェル、パッケージマネージャ、システム設定を変更します。
> 本番利用前に Fork して内容を確認してください。

### 方法 1: `init.sh` をダウンロードして対話実行

```bash
curl -fsSL https://raw.githubusercontent.com/signalridge/dotfiles/main/init.sh -o /tmp/init.sh
sh /tmp/init.sh
```

> なぜ `curl … | sh` ではないのか？
> `chezmoi init` は hostname / GitHub ユーザー名 / メールなどを対話的に尋ねます。
> パイプ実行だと stdin が curl に奪われ、prompt が TTY から読み取れずインストールが失敗します（または placeholder 値がそのまま書かれます）。先にダウンロードしてから `sh /tmp/init.sh` を実行すれば TTY が保たれます。

### 方法 2: タグ/ブランチを固定して確認後に実行

```bash
REF="<tag-or-branch>"
curl -fsSLo init.sh "https://raw.githubusercontent.com/signalridge/dotfiles/${REF}/init.sh"
shasum -a 256 init.sh || sha256sum init.sh
sh init.sh --ref "${REF}"
```

### 方法 3: ローカル clone から実行（監査しやすさが最も高い）

```bash
git clone https://github.com/signalridge/dotfiles.git
cd dotfiles
git checkout <tag-or-commit>
./init.sh
```

### `init.sh` の主要オプション

```bash
./init.sh --repo signalridge/dotfiles
./init.sh --ref v1.2.3
./init.sh --depth 1
DOTFILES_USE_ENCRYPTION=false ./init.sh
```

---

## 初回プロンプト

`chezmoi` 初期プロンプトの主な項目：

- `work`（業務マシンかどうか）
- `headless`（GUI を前提にしない環境かどうか）
- `useEncryption`（暗号化キー復元フローを有効化するか）
- `installMasApps`（MAS アプリを導入するか）
- `claudeProviderAccount` / `codexProviderAccount`

このリポジトリを初回利用する場合、keys-manage バックアップと鍵を自分で用意していない限り、`useEncryption = false` を推奨します。

> 初回インストールは対話実行が前提です：身分関連の prompt（`hostname` / `gitUsername` / `gitEmail`）には安全な default がなく、TTY が無いと明示的に fail します。方式 1 の「ダウンロードしてから実行」を使ってください（`curl | sh` は NG）。`~/.config/chezmoi/chezmoi.toml` に既に値が書かれているマシンで再 apply する場合は prompt がスキップされ、その場面では `DOTFILES_USE_ENCRYPTION=true|false` で encryption フラグを環境変数から上書きできます。

---

## 日常運用

グローバル Justfile は `~/.config/just/.justfile` に生成されます。

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

### macOS（`nix-darwin`）

```bash
just darwin
just darwin-check
just darwin-build
```

### テスト

```bash
bash tests/run.sh
pre-commit run --all-files
```

---

## Claude Code 統合

### プラグインシステム

Skills は `.chezmoiexternal.toml.tmpl` 経由で次のソースから同期されます。

- [wshobson/agents](https://github.com/wshobson/agents)、[anthropics/skills](https://github.com/anthropics/skills)、[openai/skills](https://github.com/openai/skills) などの汎用エンジニアリング系 pack
- Hugging Face、Cloudflare、Vercel、Supabase、Expo、Microsoft、および選定したコミュニティ repo の vendor/platform skills
- Go、Rust、Swift、TypeScript/JavaScript、Zig の言語別 suite
- `xurl`、`x-create`、`daily.dev`、Reddit、Remotion、Humanizer 系（`humanizer-en`、`qu-ai-wei`、`humanizer-ja`）などの social/writing/media skills

同期先は `~/.harnesses/skills` の共有ライブラリです。プロジェクトディレクトリで `skill-activate` を実行すると、そのディレクトリの `./.claude/skills`・`./.codex/skills`・`./.pi/skills`・`./.cursor/skills`・`./.kimi-code/skills` の symlink だけを管理します（Cursor CLI は `./.cursor/skills` をネイティブに読み込み、symlink されたスキルフォルダも辿ります。Kimi Code は `./.kimi-code/skills` を自動検出します）。`skill-activate --category typescript` で現在のディレクトリにカテゴリ全体を有効化できます。`skill-activate --sync` は各 harness ディレクトリ間の半端な状態を修復します。ピッカーでは `Ctrl-A` でハイライト中の項目のカテゴリ全体を切り替えます。

### 品質プロトコル

このリポジトリの instructions/skills 構成には、実装前の確認と実装後のエビデンス重視検証を含む品質ルールが組み込まれています。

### Provider 管理

`claude-manage`、`claude-with`、`claude-token` により、アカウント切替、Provider ごとのモデルルーティング、キー参照を管理します。設定ソースは `.chezmoidata/claude.yaml`、API key は gopass で管理されます。

詳細：`docs/claude-provider.md`。

### Hooks

`dot_claude/hooks/` にはワークフローガードと自動整形 Hooks が含まれます。主なもの：

- `block-git-rewrites.sh`
- `format-code.sh`
- `format-python.sh`

---

## AI ツールチェーン（Claude + Codex）

### 共有 Skills 配布

`chezmoi external` が以下から選択した Skills を同期します。

- 汎用エンジニアリング系 pack（`wshobson/agents`、`anthropics/skills`、`openai/skills`）
- vendor/platform skills（Hugging Face、Cloudflare、Vercel、Supabase、Expo、Microsoft、選定したコミュニティ repo）
- Go、Rust、Swift、TypeScript/JavaScript、Zig の言語別 suite
- discovery、strategy、execution、GTM、analytics、AI shipping を扱う `phuryn/pm-skills` のプロダクトマネジメント skills
- `xurl`、`x-create`、`daily.dev`、Reddit、Remotion、Humanizer 系（`humanizer-en`、`qu-ai-wei`、`humanizer-ja`）などの social/writing/media skills

同期先は `~/.harnesses/skills` の共有ライブラリです。プロジェクトディレクトリで `skill-activate` を実行すると、そのディレクトリの `./.claude/skills`・`./.codex/skills`・`./.pi/skills`・`./.cursor/skills`・`./.kimi-code/skills` の symlink だけを管理します（Cursor CLI は `./.cursor/skills` をネイティブに読み込み、symlink されたスキルフォルダも辿ります。Kimi Code は `./.kimi-code/skills` を自動検出します）。`skill-activate --category typescript` で現在のディレクトリにカテゴリ全体を有効化できます。`skill-activate --sync` は各 harness ディレクトリ間の半端な状態を修復します。ピッカーでは `Ctrl-A` でハイライト中の項目のカテゴリ全体を切り替えます。

### Account / Provider 管理

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
```

### Token Helpers

```bash
claude-token --check kimi@private
codex-token --check deepseek@private
```

### ツール連携

- Claude MCP は `.chezmoiscripts/run_after_12_sync-claude-mcp.sh.tmpl` によって自動同期されます。
- Claude の Notion/Slack 連携は `.chezmoiscripts/run_after_11_sync-claude-integration-plugins.sh.tmpl` によって公式 plugin としてインストールされます。
- Codex Slack は `.chezmoiscripts/run_after_13_sync-codex-connector-plugins.sh.tmpl` によって公式 connector plugin としてインストールされ、`slack@openai-curated` として有効化されます。
- Codex、Claude、Pi の Herdr agent lifecycle integration は `.chezmoiscripts/run_after_14_sync-herdr-integrations.sh.tmpl` によってインストールされます。Codex の hook 設定は `hooks.json` ではなく `config.toml` に保持します。
- このリポジトリは次の MCP ラッパーを提供します：
  - `~/.local/bin/mcp-tavily`

#### タスク -> ツールルーティング

| タスク種別                                 | 優先ツール             | フォールバック             |
| ------------------------------------------ | ---------------------- | -------------------------- |
| ライブラリ/フレームワーク/API ドキュメント | Context7               | Tavily -> 内蔵 web search  |
| Web/ニュース/一般調査                      | Tavily                 | 内蔵 web search            |
| シンボリックなコードナビゲーション         | Serena                 | repo grep/codesearch + LSP |
| チームチャット                             | Slack connector/plugin | Slack API または web UI    |
| ノート/ナレッジベース                      | Notion MCP/plugin      | Notion API または web UI   |

---

## ツールチェーン

従来の Unix コマンドにはモダン代替をエイリアスで割り当て、その上に
ドメイン別に整理したパワーユーザー向け CLI 群を重ねています。多くの
CLI は aqua、Nix は flake lock で固定し、一部の mise ランタイムと直接
インストーラは意図的に LTS/latest を追従します。

### ドロップイン置き換え

| 従来   | モダン                                           | 理由                              |
| ------ | ------------------------------------------------ | --------------------------------- |
| `ls`   | [eza](https://github.com/eza-community/eza)      | Git 連携、アイコン、ツリービュー  |
| `cat`  | [bat](https://github.com/sharkdp/bat)            | シンタックスハイライト、Git 連携  |
| `grep` | [ripgrep](https://github.com/BurntSushi/ripgrep) | 高速な正規表現検索                |
| `find` | [fd](https://github.com/sharkdp/fd)              | 直感的な構文、`.gitignore` を尊重 |
| `cd`   | [zoxide](https://github.com/ajeetdsouza/zoxide)  | 使用頻度ベースのディレクトリ移動  |
| `du`   | [dust](https://github.com/bootandy/dust)         | 読みやすいディスク使用量ツリー    |
| `man`  | [tlrc](https://github.com/tldr-pages/tlrc)       | 高速な Rust tldr クライアント     |

### シェルとプロンプト

| ツール                                                  | 役割                            |
| ------------------------------------------------------- | ------------------------------- |
| [starship](https://github.com/starship/starship)        | 軽量で高速なプロンプト          |
| [sheldon](https://github.com/rossmacarthur/sheldon)     | 高速な zsh プラグイン管理       |
| [atuin](https://github.com/atuinsh/atuin)               | あいまい検索付き履歴管理        |
| [direnv](https://github.com/direnv/direnv)              | ディレクトリ単位の環境変数管理  |
| [fzf](https://github.com/junegunn/fzf)                  | ファイル/履歴などのあいまい検索 |
| [carapace](https://github.com/carapace-sh/carapace-bin) | 多くの CLI 向けの補完エンジン   |
| [vivid](https://github.com/sharkdp/vivid)               | `LS_COLORS` テーマ生成          |

### エディタ・ファイル・Git

| ツール                                                                                                          | 役割                                        |
| --------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| [mise](https://github.com/jdx/mise)                                                                             | 多言語ランタイム管理（Node/Python/Go/Rust） |
| [yazi](https://github.com/sxyazi/yazi)                                                                          | 高速ターミナルファイルマネージャ            |
| [tmux](https://github.com/tmux/tmux)                                                                            | ターミナルマルチプレクサ                    |
| [lazygit](https://github.com/jesseduffield/lazygit) / [lazydocker](https://github.com/jesseduffield/lazydocker) | git / Docker のターミナル UI                |
| [jj](https://github.com/jj-vcs/jj)                                                                              | Jujutsu VCS（git 互換）                     |
| [git-cliff](https://github.com/orhun/git-cliff)                                                                 | チェンジログ生成                            |
| [delta](https://github.com/dandavison/delta) / [difftastic](https://github.com/Wilfred/difftastic)              | 構文認識 diff                               |

### ドメイン別 CLI

| 領域                | ツール                                                                                                                                                                                                                                                                                                                         |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| コード/検索         | [ast-grep](https://github.com/ast-grep/ast-grep)、[watchexec](https://github.com/watchexec/watchexec)、[typos](https://github.com/crate-ci/typos)、[ruff](https://github.com/astral-sh/ruff)、[ty](https://github.com/astral-sh/ty)、[prek](https://github.com/j178/prek)                                                      |
| HTTP/API            | [xh](https://github.com/ducaale/xh)、[Posting](https://github.com/darrenburns/posting)、[Slumber](https://github.com/LucasPickering/slumber)、[oha](https://github.com/hatoo/oha)                                                                                                                                              |
| コンテナ/K8s        | [k9s](https://github.com/derailed/k9s)、[kubectl](https://github.com/kubernetes/kubernetes)、[Helm](https://github.com/helm/helm)、[stern](https://github.com/stern/stern)、[kubecolor](https://github.com/kubecolor/kubecolor)、[kubectx](https://github.com/ahmetb/kubectx)、[krew](https://github.com/kubernetes-sigs/krew) |
| Security/SBOM       | [zizmor](https://github.com/zizmorcore/zizmor)、[Gitleaks](https://github.com/gitleaks/gitleaks)、[Trivy](https://github.com/aquasecurity/trivy)、[Syft](https://github.com/anchore/syft)、[Grype](https://github.com/anchore/grype)                                                                                           |
| システム/ネット     | [bottom](https://github.com/ClementTsang/bottom)、[procs](https://github.com/dalance/procs)、[lnav](https://github.com/tstack/lnav)、[hexyl](https://github.com/sharkdp/hexyl)、[doggo](https://github.com/mr-karan/doggo)、[hyperfine](https://github.com/sharkdp/hyperfine)                                                  |
| アーカイブ/メディア | [ouch](https://github.com/ouch-org/ouch)、[gum](https://github.com/charmbracelet/gum)、[vhs](https://github.com/charmbracelet/vhs)                                                                                                                                                                                             |
| AI 使用量           | [ccusage](https://github.com/ryoppippi/ccusage)、`@ccusage/codex`                                                                                                                                                                                                                                                              |

---

## シェル関数

### プロジェクト移動

```bash
dev                 # FZF ベースのプロジェクト選択（ghq）
mkcd <dir>          # ディレクトリを作成して移動
dotcd               # chezmoi ソースへ移動
```

### Git ワークフロー

```bash
fgc                 # あいまい git checkout（ブランチ）
fgl                 # あいまい git log ビューア
fga                 # あいまい git add（ファイル選択）
aicommit            # AI でコミットメッセージ生成
```

### 環境セットアップ

```bash
create_direnv_venv  # Python venv + direnv
create_direnv_nix   # Nix flake + direnv
create_py_project   # uv で Python プロジェクトを作成
```

---

## パッケージ管理

| ソース         | プラットフォーム | 説明                         |
| -------------- | ---------------- | ---------------------------- |
| Nix packages   | macOS, Linux     | 再現性が高くロールバック可能 |
| Homebrew casks | macOS のみ       | GUI アプリ                   |
| Mac App Store  | macOS のみ       | App Store 限定               |

パッケージ一覧は `.chezmoidata/` に定義され、`shared` / `work` / `private` 分離に対応しています。

---

## マルチプロファイル設定

```bash
# 仕事用マシン
chezmoi init --apply --promptBool work=true signalridge

# 個人用マシン（デフォルト）
chezmoi init --apply signalridge

# ヘッドレスサーバー（GUI 設定不要）
chezmoi init --apply --promptBool headless=true signalridge
```

---

## セキュリティとシークレット

このリポジトリは目的別に複数のレイヤーを使い分けています。

1. `chezmoi` secrets の復号：`age` ラッパー + `~/.ssh/main`
2. `gopass` は `age` backend で API key/password を管理
3. `keys-manage` は OpenSSL PBKDF2（`AES-256-CBC`）でバックアップを暗号化
4. Claude Hooks により危険な git/history rewrite 操作をガード

詳細：

- `docs/keys-manage-guide.md`
- `docs/gopass-new-device-setup.md`
- `docs/claude-provider.md`

---

## CI と自動化

### 検証

- `.github/workflows/ci.yml`
  - pre-commit
  - テンプレートレンダリング検証
  - `nix flake check`（macOS + Linux マトリクス）

- `.github/workflows/tests.yml`
  - push、pull request、手動実行でブートストラップ/スクリプトテストを実行（`bash tests/run.sh`）

### 定期メンテナンス

- `.github/workflows/scheduler.yml`（毎日 00:00 UTC に実行）
- `.github/workflows/update-versions.yml`
- `.github/workflows/update-flake-lock.yml`
- `.github/workflows/update-aqua-packages.yml`

---

## 関連ドキュメント

- `docs/claude-provider.md`
- `docs/keys-manage-guide.md`
- `docs/gopass-new-device-setup.md`
- `docs/tmux.md`

---

## 謝辞

- [chezmoi](https://github.com/twpayne/chezmoi) - Dotfiles マネージャ
- [nix-darwin](https://github.com/LnL7/nix-darwin) - 宣言的 macOS 設定
- [flakey-profile](https://github.com/lf-/flakey-profile) - クロスプラットフォーム Nix プロファイル管理
- [wshobson/agents](https://github.com/wshobson/agents) - Claude Code 向けプラグイン集
- [anthropics/skills](https://github.com/anthropics/skills) - 公式 Claude Code スキル集
- [Dracula Theme](https://draculatheme.com/) - ターミナル / fzf テーマのベース

---

## 統計

![Alt](https://repobeats.axiom.co/api/embed/81ef9a8c511918fc0eece9bd09bb46ba78eefd0c.svg "Repobeats analytics image")

---

## ライセンス

MIT
