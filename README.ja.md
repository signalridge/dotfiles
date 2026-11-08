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

`chezmoi` で管理している個人用ワークステーションの設定です。汎用のスターター
テンプレートではなく、実際に使っている構成です。レイヤーは次のとおりです。

- `chezmoi`：テンプレート、ターゲットファイルのマージ、bootstrap スクリプト
- Nix：クロスプラットフォームのユーザー profile、macOS では `nix-darwin`
- Homebrew と Mac App Store：macOS アプリケーション
- `aqua` でバージョン固定の CLI を、`mise` でランタイムと残りのツールを管理
- Claude Code、Codex CLI、Cursor Agent CLI、Antigravity CLI の設定
- プライベートネットワーク層：EasyTier mesh、sing-box クライアント、JAIST VPN

> このリポジトリには、緩い AI 実行モードや個人マシン向けのアプリケーションを含む
> 個人的なデフォルト値が入っています。別のコンピューターに適用する前に、
> テンプレートとデータを確認してください。

## サポート範囲と Profile の挙動

| 項目               | 挙動                                                                                                                                                           |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OS                 | macOS と Linux。                                                                                                                                               |
| 新規 Nix bootstrap | 固定インストーラーは `aarch64-darwin`、`aarch64-linux`、`x86_64-linux` に対応。新規の `x86_64-darwin` インストールは拒否されます。                             |
| `work`             | `work` パッケージセット（Nix、macOS では Homebrew も）を追加し、`private = false` に設定。仕事用マシンには中継/出口ツールを入れません。                        |
| `private`          | `not work` から導出され、`private` パッケージセットを選択します。                                                                                              |
| `headless`         | GUI の dotfiles と GUI スクリプト `09`、`17`、`21` をスキップ。パッケージのスイッチではなく、macOS では nix-darwin/Homebrew モジュールは引き続き描画されます。 |
| Mac App Store      | `installMasApps = true` のときだけ MAS のエントリをインストールします。                                                                                        |

## クイックスタート

> [!WARNING]
> このリポジトリを適用すると、shell ファイル、パッケージマネージャー、AI 設定、
> （macOS では）システムとアプリケーションの設定が変更されます。先にテンプレートと
> データを確認してください。

```bash
curl -fsSL https://raw.githubusercontent.com/signalridge/dotfiles/main/init.sh -o /tmp/init.sh
sh /tmp/init.sh
```

`curl … | sh` は使わないでください。初回実行では profile と身元情報の入力を
求められ、必須データがなく stdin が TTY でない場合、テンプレートは明示的に失敗
します。ref を固定するには、その ref の `init.sh` をダウンロードして
`--ref <ref>` を渡します。ローカルクローンでは、目的の checkout で `./init.sh` を
実行します。`init.sh` は `--repo` と `--depth`（または
`DOTFILES_REPO`/`DOTFILES_REF`/`DOTFILES_DEPTH`）、
`DOTFILES_USE_ENCRYPTION=true|false` にも対応します。詳細は `sh init.sh --help`
を参照してください。bootstrap は HTTPS のみです。

chezmoi を直接呼び出すときに profile を事前に選ぶ例：

```bash
chezmoi init --apply \
  --promptBool work=false \
  --promptBool useEncryption=false \
  signalridge
```

## 初回データ

すべてのプロンプトと導出値は `.chezmoi.toml.tmpl` にあります。

| データ                               | 要求・使用されるタイミング                                                      |
| ------------------------------------ | ------------------------------------------------------------------------------- |
| `work`                               | 必須。TTY でプロンプト表示。`private` の導出に使用。                            |
| `useEncryption`                      | `DOTFILES_USE_ENCRYPTION` がなければ必須。鍵の復元、gopass、`~/.ssh/*` を制御。 |
| `hostname`                           | 仕事用以外のマシンでプロンプト表示。仕事用マシンはシステムのホスト名を使用。    |
| `gitUsername`、`gitEmail`            | 未設定ならプロンプト表示。身元のデフォルト値はありません。                      |
| `headless`                           | TTY でプロンプト表示。それ以外は保存済みデータか OS ベースのフォールバック。    |
| `installMasApps`                     | macOS の TTY プロンプト（Mac App Store のインストール）。                       |
| `timezone`                           | 自動検出。できなければプロンプト表示し、最終的に `Etc/UTC` にフォールバック。   |
| `keysRepository`、`gopassRepository` | 暗号化が有効なときだけプロンプト表示。                                          |
| `easytierExit`                       | プロンプトなし。EasyTier の出口にする Linux マシンで手動設定します。            |

## Bootstrap フロー

`chezmoi init` 以降の処理はすべて `.chezmoiscripts/` の番号付きスクリプトが
担い、実行順は番号どおりです。`00` が Nix をインストールし、`01` が鍵を復元、
続いて nix-darwin、profile、aqua、gopass、mise、その後に AI 連携、サービス、
ネットワークスタックが続きます。`run_onchange_*` は描画内容が変わったときに再実行
され、`run_after_*` は apply のたびに実行され、それぞれ独自のガードや実行間隔を
持ちます。マシンごとの条件はスクリプト自体と `.chezmoiignore` にあります。

## 日常運用

`~/Justfile` は `Justfile.tmpl` から描画されます。`just --list` で chezmoi、Nix、
nix-darwin、Git のレシピを確認できます。ソースディレクトリで
`pre-commit run --all-files` を実行すると、フォーマット・構文・secret の
チェックが走ります。

各定義の置き場所：

- Nix パッケージ：`.chezmoidata/nix.yaml` と `nix-config/`
- Homebrew と MAS：`.chezmoidata/homebrew.yaml`
- aqua の CLI：`private_dot_config/aquaproj-aqua/`（仕事用マシンでは `aqua-private.yaml` をスキップ）
- mise のランタイムとツール：`private_dot_config/mise/config.toml.tmpl`
- 固定したインストーラーとチェックサム：`.chezmoidata/versions.yaml`
- shell の alias と関数：`dot_custom/`。`wt-new`/`wt-go`/`wt-ls`/`wt-rm` は通常の repository
  では `<repo>/.worktrees/` に Git worktree を作りますが、この chezmoi source 内では
  使わないでください。constitution（`CLAUDE.md`）が worktree と branch switching を禁止しています。

## ネットワークスタック

- **EasyTier**：すべての Mac がクライアントとしてプライベート mesh に参加します。
  Linux マシンはローカルデータで `easytierExit` を設定したときだけ出口として参加
  します（`.chezmoidata/easytier.yaml`、スクリプト `23`）。
- **sing-box**：すべてのマシンにクライアントがあり（Mac では TUN、headless Linux
  ではユーザーサービス）、`Egress` セレクターで出口を選びます
  （`.chezmoidata/sing-box.yaml`、スクリプト `24`）。
- **JAIST VPN**：パッチ版 sing-box の OpenConnect エンドポイントと
  `openconnect-auto`/`openconnect-login`（スクリプト `25`、仕事用以外のマシンのみ）。
- **bastion**：手動でデプロイした中継兼 STUN サーバー。`bastion-import` がその
  sing-box outbound を gopass に保存します。

## AI Harness

Claude Code、Codex CLI、Cursor Agent CLI、Antigravity CLI
は `dot_*` と `private_dot_config/` で設定します。Claude と Codex は
`.chezmoitemplates/agent-instructions.md` から描画される共通のグローバル指示を
使います。Claude Code と Codex はネイティブ OAuth を使い、起動時のモデルは
`.chezmoidata/claude.yaml` と `dot_codex/modify_private_config.toml.tmpl` で
設定します。MCP サーバーの一覧は
`.chezmoidata/mcp.yaml` にあります。エージェントの状態表示は Herdr が担います。

Skill は `~/.harnesses/skills/<category>/<skill>/` に置かれ、ソースはバージョン
固定のアーカイブ（`.chezmoiexternal.toml.tmpl`）と `dot_harnesses/` です。
グローバルには何も有効化されません。プロジェクトで `skill-activate` を実行すると、
選んだ skill が `./.claude/skills`、`./.codex/skills`、`./.cursor/skills` に
シンボリックリンクされます
（`--list`、`--active`、`--category <name>`、`--sync`、`--clear`）。

### AI 実行ポリシー

管理しているデフォルト値は意図的に緩く設定しているため、再利用する前に確認して
ください。

- Claude：`bypassPermissions`、Bash の deny ルールと Git 書き換え hook を併用
- Codex：`approval_policy = "never"` と `sandbox_mode = "danger-full-access"`
- Cursor：`approvalMode = "unrestricted"`
- Antigravity：`toolPermission = "always-proceed"`、ターミナルサンドボックスなし

Claude の hook は変更したファイルのフォーマットも行います。Git 書き換え hook
（`dot_claude/hooks/executable_block-git-rewrites.sh`）は一部の不可逆な操作を
ブロックし、復旧可能な危険操作の前には確認を求めますが、すべての Git 変更を
ブロックするわけではありません。

## セキュリティと Secrets

- chezmoi は `age` で暗号化します（`.chezmoitemplates/shell/age_command_wrapper.sh`）。
  鍵は `~/.ssh/main` と `~/.ssh/main.pub` です。
- API キーとサービスの認証情報は gopass に、鍵ファイルのバックアップは
  `keys-manage` にあります。gopass の構成は `private_dot_config/gopass/config.tmpl` に記載。
- GitHub へのアクセスは HTTPS + `gh` credential helper で、`insteadOf` による
  書き換えは使いません。
- 脆弱性の報告と注意すべき領域：[SECURITY.md](SECURITY.md)。

## ドキュメント

- [WezTerm アイコン](tools/wezterm-icon/README.md)
- [セキュリティポリシー](SECURITY.md)

CI（`.github/workflows/`）は pre-commit、Nix flake のチェック、セキュリティスキャンを
実行し、日次のスケジューラーが依存関係更新の PR を作成します。

## 謝辞

- [chezmoi](https://github.com/twpayne/chezmoi) と
  [nix-darwin](https://github.com/LnL7/nix-darwin)：設定のオーケストレーション
- [Nix](https://nixos.org/)、[flakey-profile](https://github.com/lf-/flakey-profile)、
  [Homebrew](https://brew.sh/)、[aqua](https://aquaproj.github.io/)、
  [mise](https://mise.jdx.dev/)：パッケージとツールの管理
- [Claude Code](https://www.anthropic.com/claude-code)、[Codex](https://openai.com/index/introducing-codex/)、
  [Cursor](https://cursor.com/)、[Herdr](https://github.com/ogulcancelik/herdr)：
  管理対象の AI/エージェントツール
- [EasyTier](https://github.com/EasyTier/EasyTier) と
  [sing-box](https://github.com/SagerNet/sing-box)：ネットワーク層
- `.chezmoiexternal.toml.tmpl` に列挙した外部 skill リポジトリ。それぞれの上流の
  ライセンスに従います。
- [Dracula Theme](https://draculatheme.com/)：ターミナルと fzf の配色

## ライセンス

このリポジトリにはルートの `LICENSE` ファイルがありません。再配布可能なものとして
扱う前に、明示的なライセンスを追加してください。
