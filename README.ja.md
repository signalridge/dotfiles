<div align="center">

![header](https://capsule-render.vercel.app/api?type=waving&color=0:282a36,100:bd93f9&height=200&section=header&text=~/.dotfiles&fontSize=48&fontColor=f8f8f2&fontAlignY=30&desc=One%20command%20%C2%B7%20Full%20environment%20%C2%B7%20Zero%20hassle&descSize=16&descColor=8be9fd&descAlignY=55&animation=fadeIn)

**chezmoi + Nix · クロスプラットフォーム開発環境 (macOS / Linux)**

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

*Nix と chezmoi で構築する、モダンで再現性の高い開発環境（macOS / Linux 対応）*
</div>

このリポジトリは、システム構成を完全に宣言的に管理し、新しいマシンを数分で立ち上げられるようにします。パッケージ、設定、dotfiles を自動で適用し、Rust 製の高速 CLI ツール群を中心に設計されています。さらに、仕事用/個人用など複数プロファイルの切り替えにも対応しています。

---

## 📑 目次

- [ハイライト](#highlights)
- [このリポジトリの強み](#project-advantages)
- [目的](#motivation)
- [クイックスタート](#quick-start)
- [セキュリティとシークレット](#security)
- [アーキテクチャ](#architecture)
- [ツールチェーン](#tool-chains)
- [シェル関数](#shell-functions)
- [パッケージ管理](#package-management)
- [日常操作](#daily-operations)
- [マルチプロファイル設定](#multi-profile-configuration)
- [キーボードショートカット](#keyboard-shortcuts)
- [テーマ](#theming)
- [統計](#stats)
- [謝辞](#acknowledgements)
- [ライセンス](#license)

---

> [!WARNING]
> **実行前に必ず確認してください！** このリポジトリにはシステム設定を変更するスクリプトが含まれます。
> 何をするか理解しないまま、セットアップコマンドを実行しないでください。
> まず Fork して、自分の環境に合わせてカスタマイズすることを推奨します。

---

<a id="highlights"></a>

## ✨ ハイライト

- **クロスプラットフォーム**：macOS + Linux を 1 つの構成で管理（`nix-darwin` + `flakey-profile`）
- **ブートストラップ**：初回 `apply` で Nix（Determinate）を導入し、プロファイル切り替えや Homebrew 更新（macOS）まで自動化
- **シークレット**：`age` 暗号化ファイル（必要に応じて 1Password で鍵を自動取得）
- **プロファイル**：`work` / `private` / `headless` を `chezmoi init` の対話プロンプトで切り替え
- **快適さ**：モダン CLI、統一テーマ、AI ヘルパーを同梱

---

<a id="project-advantages"></a>

## 💡 このリポジトリの強み

- **エンドツーエンドのブートストラップ**：Determinate Nix の高速ミラーを自動選択し、chezmoi がテンプレートを一括適用
- **プロファイルを横断**：`.chezmoidata.yaml` の `shared/work/private` を Nix/Homebrew/MAS で共通利用
- **macOS チューニング**：nix-darwin の defaults、Homebrew/MAS 統合、適用後の更新スクリプト
- **セキュアなシークレット**：`age` 暗号化と 1Password 連携で鍵を導入し、固定パスで管理
- **ワークフローのガードレール**：pre-commit（shellcheck/markdownlint/prettier/Nix フォーマット・lint）+ Claude Code hooks で危険な git 操作を抑止し `uv` を強制
- **DX 自動化**：Justfile の更新/クリーンアップ、fzf ナビ、AI コミットメッセージ
- **CI の一貫性**：macOS + Linux でテンプレートをレンダリングし `nix flake check` を実行

---

<a id="motivation"></a>

## 🎯 目的

新しい開発マシンのセットアップは面倒です。数十個のパッケージをインストールし、無数のツールを設定し、長年積み上げた細かな調整を思い出す必要があります。このリポジトリは次の点でそれを解決します：

- **宣言的な設定** - すべてのパッケージ/設定/構成ファイルをコードとして定義
- **再現性** - 1 コマンドで、どのマシンでも同じ環境を構築
- **クロスプラットフォーム** - macOS と Linux の両方に対応し、各プラットフォームに最適化
- **バージョン管理** - システム設定の変更を履歴として追跡
- **マルチプロファイル対応** - 仕事用/個人用でパッケージセットを切り替え

---

<a id="quick-start"></a>

## 🚀 クイックスタート

**方法 1: GitHub から init スクリプトを直接実行（推奨）**

```bash
curl -fsLS https://raw.githubusercontent.com/signalridge/dotfiles/main/init.sh | sh
```

**方法 2: chezmoi をインストールして init**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply signalridge
```

**方法 3: クローンしてローカルで実行**

```bash
git clone https://github.com/signalridge/dotfiles.git
cd dotfiles && ./init.sh
```

上記いずれかのコマンドで自動的に：

1. Nix をインストール（Determinate Systems インストーラ）
2. Nix 経由で `age` と `1password-cli` をインストール（復号用）
3. 1Password から復号鍵を取得（または手動セットアップを案内）
4. すべての dotfiles と設定を適用

インストール後、ターミナルを再起動してください。macOS では `just darwin` で nix-darwin 設定を有効化します。

---

<a id="security"></a>

## 🔐 セキュリティとシークレット

このリポジトリは `age` でシークレットを暗号化します（例：`private_dot_ssh/encrypted_private_config.tmpl.age`）。`.chezmoi.toml.tmpl` で `~/.ssh/main`（秘密鍵）と `~/.ssh/main.pub`（受信者）を使って復号するよう設定しています。

初回 `apply` 時、ブートストラップスクリプトが：

1. Nix をインストール（`run_once_before_00_install-nix.sh`）
2. Nix 経由で `age` + `op` をインストールし、1Password から鍵を取得（`run_once_before_01_setup-encryption-key.sh`）

1Password が利用できない場合は、手動セットアップ手順を表示して終了します。

fork して使う場合は、鍵パスと 1Password のアイテムパスを自分の環境に合わせて変更してください。

---

<a id="architecture"></a>

## 🧩 アーキテクチャ

この dotfiles セットアップは、クロスプラットフォーム構成のために複数の強力なツールを組み合わせています：

**chezmoi** は複数マシン間で dotfiles を管理します。テンプレートやシークレットに対応し、設定ファイルを常に同期できます。`dot_` プレフィックスのファイルは dotfile として配置され、`.tmpl` は Go テンプレートとして処理され、プラットフォーム別の条件分岐もサポートします。

### macOS 構成

**nix-darwin** は macOS を宣言的に構成します。Nix と Homebrew（formula/cask）でシステムパッケージを管理し、macOS のシステム設定も含めて Nix 式で記述できます。システム状態は原子的にビルド/切り替え可能です。

### Linux 構成

**flakey-profile** は Linux 向けの宣言的パッケージ管理を提供します。macOS と同じ Nix flake を使用しますが、システムレベルの設定は行わず、ユーザーパッケージに焦点を当てています。あらゆる Linux ディストリビューションで動作します。

### 連携方法

| コンポーネント | macOS | Linux |
| -------------- | ----- | ----- |
| Dotfiles | chezmoi | chezmoi |
| システム設定 | nix-darwin | N/A |
| ユーザーパッケージ | flakey-profile | flakey-profile |
| GUI アプリ | Homebrew Cask | N/A |
| Mac App Store | mas | N/A |

---

<a id="tool-chains"></a>

## ⚡ ツールチェーン

従来の Unix ツールを、より高速で使いやすい Rust 製のモダンな代替に置き換えます。

### モダン CLI 置き換え

| 従来   | モダン                                           | 説明                                       |
| ------ | ------------------------------------------------ | ------------------------------------------ |
| `ls`   | [eza](https://github.com/eza-community/eza)      | git 連携、アイコン、ツリービュー           |
| `cat`  | [bat](https://github.com/sharkdp/bat)            | シンタックスハイライト、git 連携           |
| `grep` | [ripgrep](https://github.com/BurntSushi/ripgrep) | 超高速な正規表現検索                       |
| `find` | [fd](https://github.com/sharkdp/fd)              | 直感的な構文、`.gitignore` を尊重           |
| `du`   | [dust](https://github.com/bootandy/dust)         | 視覚的なディスク使用量アナライザ           |
| `df`   | [duf](https://github.com/muesli/duf)             | 見やすいディスク空き容量テーブル           |
| `cd`   | [zoxide](https://github.com/ajeetdsouza/zoxide)  | スマートなディレクトリジャンプ             |
| `man`  | [tldr](https://github.com/tldr-pages/tlrc)       | 実用的なコマンド例                         |
| `time` | [hyperfine](https://github.com/sharkdp/hyperfine) | コマンドベンチマーク                        |

### シェル環境

プロンプトは Rust 製の **Starship** を使用します。Dracula カラーパレットで統一し、git 状態、カレントディレクトリ、言語バージョンなどのコンテキスト情報を表示します。

**Sheldon** は zsh プラグインを効率よく管理します。oh-my-zsh や zinit と比べて高速で、重要度の低いプラグインを遅延読み込みすることもできます。

**Atuin** はシェル履歴を進化させます。履歴を SQLite に保存し、全履歴を横断したあいまい検索が可能です。Ctrl+R で、数か月前の複雑なコマンドもすぐ見つかります。

**Direnv** はディレクトリの出入りに合わせて環境変数を自動でロード/アンロードします。このリポジトリのヘルパー関数と組み合わせることで、プロジェクトごとの Python venv、Nix flake 開発環境、mise 環境を素早く用意できます。

| ツール                                                                            | 役割                                             |
| ------------------------------------------------------------------------------- | ------------------------------------------------ |
| [starship](https://github.com/starship/starship)                                | 最小・高速なプロンプト（git 連携）                |
| [sheldon](https://github.com/rossmacarthur/sheldon)                             | 高速で柔軟な zsh プラグインマネージャ             |
| [atuin](https://github.com/atuinsh/atuin)                                       | あいまい検索付きの強力なシェル履歴                |
| [direnv](https://github.com/direnv/direnv)                                      | ディレクトリ単位の環境変数管理                    |
| [fzf](https://github.com/junegunn/fzf)                                          | ファイル/履歴などのあいまい検索                   |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)         | Fish ライクなコマンド提案                        |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | コマンドのシンタックスハイライト                  |

### 開発ツール

**mise**（旧 rtx）は多言語ランタイムマネージャです。Node.js、Python、Go、Rust、Terraform などを扱え、nvm/pyenv/rbenv より高速で統一的な操作感を提供します。

**lazygit** は美しい TUI で git 操作を支援します。インタラクティブ rebase、cherry-pick、コンフリクト解消などの複雑な作業も扱いやすくなります。

**yazi** は画像プレビューにも対応した超高速ターミナルファイルマネージャで、ranger のモダンな代替です（Rust 製）。

この **tmux** 設定は vim 風キーバインド、Dracula テーマ、lazygit/htop を素早く開くポップアップなどを備えます。プレフィックスキーは Ctrl+B（デフォルト）です。

| ツール                                                | 役割                                              |
| --------------------------------------------------- | ------------------------------------------------- |
| [mise](https://github.com/jdx/mise)                 | 多言語ランタイム管理（Node/Python/Go/Rust）        |
| [lazygit](https://github.com/jesseduffield/lazygit) | 美しい git TUI                                    |
| [yazi](https://github.com/sxyazi/yazi)              | 超高速ターミナルファイルマネージャ                |
| [tmux](https://github.com/tmux/tmux)                | ポップアップ対応のターミナルマルチプレクサ        |
| [ghq](https://github.com/x-motemen/ghq)             | リモートリポジトリ管理                            |
| [gh](https://github.com/cli/cli)                    | GitHub CLI（Issue/PR など）                       |

### AI 統合

**Claude Code** をシェル環境に統合しています。`aicommit` 関数は、ステージ済みの差分から Conventional Commits 形式のコミットメッセージを AI 生成します。Starship プロンプトで Claude API の使用状況を表示することもできます。

### デスクトップアプリ（macOS のみ）

GUI アプリは Homebrew cask で管理します：

| カテゴリ         | アプリ                              |
| ---------------- | ----------------------------------- |
| ターミナル       | Ghostty, iTerm2                     |
| エディタ         | Neovim, VS Code, Cursor             |
| ブラウザ         | Arc (Dia)                           |
| ウィンドウ管理   | AeroSpace（i3 ライクなタイル配置）   |
| 生産性           | Notion, Obsidian, Logseq, Raycast   |
| コンテナ         | OrbStack（Docker 代替）             |

---

<a id="shell-functions"></a>

## 🔧 シェル関数

エイリアスに加えて、よく使うワークフロー向けのシェル関数を用意しています。

コミットしたくないマシン固有の設定は `~/.custom/local.sh` に書けます（存在すれば自動で `source` されます）。

### プロジェクト移動

`dev` 関数は **ghq** と **fzf** を組み合わせたプロジェクトセレクタです。`dev` を実行すると、ツリープレビュー付きのリポジトリ一覧をあいまい検索でき、選択するとそのまま移動します。tmux セッション名もプロジェクト名に合わせて変更されます。

```bash
dev                 # FZF ベースのプロジェクト選択（ghq）
mkcd <dir>          # ディレクトリ作成して cd
dotcd               # chezmoi ソースへ移動
dotfiles            # dotfiles をエディタで開く
```

### Git ワークフロー

`fgc` はログプレビュー付きのあいまいブランチ切り替え、`fgl` はコミット閲覧（diff プレビュー）、`fga` は未ステージファイルの選択的ステージングを提供します。複雑な git 操作が自然になります。

```bash
fgc                 # あいまい git checkout（ブランチ）
fgl                 # あいまい git log ビューア
fga                 # あいまい git add（ファイル選択）
aicommit            # AI でコミットメッセージ生成
```

### システムユーティリティ

`fkill` は確認付きで安全にプロセスを終了できます（重要プロセスの誤 kill を防止）。`port` は指定ポートを使用しているプロセスを表示します。`backup_dev_env` は Brewfile、VS Code 拡張、mise ツールをエクスポートしてバックアップします。

```bash
fkill               # あいまいプロセス kill（確認あり）
fenv                # 環境変数ビューア（あいまい検索）
port <num>          # ポート使用プロセスを表示
backup_dev_env      # 開発環境設定をバックアップ
```

### 環境セットアップ

`create_direnv_venv` は Python venv を作成し、direnv と連携します。`create_direnv_nix` は Nix flake 開発環境を作り、direnv と組み合わせます。

```bash
create_direnv_venv  # Python venv + direnv
create_direnv_nix   # Nix flake + direnv
create_direnv_mise  # mise 環境 + direnv
create_py_project   # uv で Python プロジェクトを作成
```

---

<a id="package-management"></a>

## 📦 パッケージ管理

複数のソースを用途に応じて使い分けます：

| ソース            | プラットフォーム | 説明                         | 例                               |
| ----------------- | ---------------- | ---------------------------- | -------------------------------- |
| Nix packages      | macOS, Linux     | 再現性が高く、ロールバック可能 | ripgrep, bat, eza, starship      |
| Homebrew formulas | macOS のみ       | macOS 向けツール              | macos-trash, cliclick            |
| Homebrew casks    | macOS のみ       | GUI アプリ                    | VS Code, Ghostty, Notion         |
| Mac App Store     | macOS のみ       | App Store 限定                | Magnet, WeChat, Office           |

パッケージ一覧は `.chezmoidata.yaml` に定義され、shared / work-only / private-only の分類にも対応しています。

---

<a id="daily-operations"></a>

## 🔄 日常操作

よく使う操作は Justfile から実行できます（`Justfile.tmpl` から `~/Justfile` にレンダリングされます）。まだ `just` がない場合は `nix run --extra-experimental-features 'nix-command flakes' nixpkgs#just -- <task>` で実行できます：

### クロスプラットフォームコマンド

```bash
# Chezmoi 操作
just apply          # dotfiles 変更を適用
just diff           # 未適用差分を表示
just re-add         # 変更されたファイルを再追加

# Nix 操作
just up             # flake 入力をすべて更新
just switch         # flakey-profile を切り替え（パッケージ再ビルド）
just gc             # 未使用の nix store を削除
just optimize       # nix store 最適化（重複ハードリンク）

# 開発
just check          # pre-commit を実行

# オールインワン
just full-upgrade   # 完全アップグレード
just update-all     # flake + chezmoi を更新（macOS は homebrew も）
```

### macOS 専用コマンド

```bash
# Nix-darwin 操作
just darwin         # 設定を再ビルドして切り替え
just darwin-debug   # 詳細出力でビルド

# メンテナンス
just history        # システム profile の generation 一覧
just clean          # 7 日以上前の generation を削除
just clean-all      # nix gc + brew cleanup
```

---

<a id="multi-profile-configuration"></a>

## 👤 マルチプロファイル設定

マシンごとに異なる構成を使えます。`.chezmoidata.yaml` ではパッケージを 3 つに分類しています：

- **shared** - すべてのマシンにインストール
- **work** - 仕事用マシンのみ（Azure CLI、Cursor など）
- **private** - 個人用マシンのみ（1Password、ゲーム関連など）

`work` が主スイッチです。`work=false`（デフォルト）のとき `private=true` が自動で有効になります。`headless=true` の場合は AeroSpace/Karabiner など GUI 設定がスキップされます。`hostname` を聞かれたら `hostname -s` の値を入れてください（flake の名前に使います）。

```bash
# 仕事用マシン
chezmoi init --apply --promptBool work=true signalridge

# 個人用マシン（デフォルト：work=false -> private=true）
chezmoi init --apply signalridge

# ヘッドレスサーバー（GUI 設定不要）
chezmoi init --apply --promptBool headless=true signalridge
```

---

<a id="keyboard-shortcuts"></a>

## ⌨️ キーボードショートカット

| ショートカット | 動作                               |
| -------------- | ---------------------------------- |
| Alt + Up       | 親ディレクトリへ移動               |
| Alt + Down     | ディレクトリ履歴を戻る             |
| Ctrl + R       | コマンド履歴検索（Atuin）          |
| Ctrl + B       | tmux プレフィックスキー            |

---

<a id="theming"></a>

## 🌙 テーマ

すべてのツールを **Dracula** カラーパレットで統一し、見やすいダークテーマにしています：

- Starship プロンプト
- tmux ステータスバー
- bat のシンタックスハイライト
- lazygit の UI
- yazi ファイルマネージャ

---

<a id="stats"></a>

## 📈 統計

![Repobeats](https://repobeats.axiom.co/api/embed/b47788b120b4e3a0f049b72115d88268d5523f64.svg "Repobeats analytics")

---

<a id="acknowledgements"></a>

## 🙏 謝辞

この dotfiles は多くの素晴らしい OSS の上に成り立っています。特に以下に感謝します：

- [chezmoi](https://github.com/twpayne/chezmoi) by [@twpayne](https://github.com/twpayne) - 強力な dotfiles マネージャ
- [nix-darwin](https://github.com/LnL7/nix-darwin) by [@LnL7](https://github.com/LnL7) - Nix による宣言的 macOS 設定
- [flakey-profile](https://github.com/lf-/flakey-profile) by [@lf-](https://github.com/lf-) - クロスプラットフォーム Nix プロファイル管理
- [Nix](https://nixos.org/) by [NixOS](https://github.com/NixOS) - 純粋関数型パッケージマネージャ
- [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) by [@DeterminateSystems](https://github.com/DeterminateSystems)
- [Sheldon](https://github.com/rossmacarthur/sheldon) by [@rossmacarthur](https://github.com/rossmacarthur) - 高速な zsh プラグインマネージャ
- [Dracula Theme](https://draculatheme.com/) by [@zenorocha](https://github.com/zenorocha) - 美しいダークテーマ

そして、このセットアップを支えてくれるすべての OSS と貢献者の皆さまに感謝します。

---

<a id="license"></a>

## 📝 ライセンス

このプロジェクトは MIT License で提供されています。
