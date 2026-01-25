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

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=22&pause=1000&color=BD93F9&center=true&vCenter=true&width=600&lines=chezmoi+%2B+Nix+%E5%AE%A3%E8%A8%80%E7%9A%84%E9%96%8B%E7%99%BA%E7%92%B0%E5%A2%83;%E3%82%AF%E3%83%AD%E3%82%B9%E3%83%97%E3%83%A9%E3%83%83%E3%83%88%E3%83%95%E3%82%A9%E3%83%BC%E3%83%A0+macOS+%2B+Linux;Claude+Code+%E8%87%AA%E5%8B%95%E3%83%97%E3%83%A9%E3%82%B0%E3%82%A4%E3%83%B3%E5%90%8C%E6%9C%9F;%E3%83%A2%E3%83%80%E3%83%B3+Rust+CLI+%E3%83%84%E3%83%BC%E3%83%AB%E3%83%81%E3%82%A7%E3%83%BC%E3%83%B3)](https://git.io/typing-svg)

</div>

---

## ✨ ハイライト

- **クロスプラットフォーム**：macOS + Linux を 1 つの構成で管理（`nix-darwin` + `flakey-profile`）
- **ワンコマンドブートストラップ**：ベアメタルから完全環境まで `curl | sh` 一発で
- **Claude Code 統合**：50 以上のマルチソースプラグイン、自動同期更新
- **モダン CLI**：Rust ツールチェーン（eza、bat、ripgrep、fd、zoxide）で Unix クラシックを置き換え
- **セキュリティ優先**：`age` 暗号化 + gopass アシスト付きキーブートストラップ

---

## 💡 なぜこのリポジトリか

- **プロファイルを横断**：`.chezmoidata/` が `shared` / `work` / `private` パッケージを Nix・Homebrew・MAS で統一管理
- **エンドツーエンドブートストラップ**：Nix インストーラが最速の Determinate ミラーを自動選択、chezmoi が一括でテンプレートを適用
- **macOS チューニング**：nix-darwin のシステム設定、Homebrew + MAS 統合、適用後の更新スクリプト
- **ワークフローガードレール**：pre-commit（shellcheck、markdownlint、prettier、Nix lint）+ Claude Code hooks
- **DX 自動化**：Justfile のアップグレード/クリーンアップ、fzf ナビゲーション、AI アシストコミットメッセージ
- **CI 一貫性**：macOS + Linux でテンプレートレンダリングと `nix flake check` を実行
- **Claude Code Hooks**：コード自動フォーマット、pip の代わりに uv を強制、main ブランチへの直接編集をブロック

---

## 🎯 設計思想

新しい開発マシンのセットアップは面倒です：数十のパッケージをインストールし、無数のツールを設定し、長年の調整を思い出す必要があります。このリポジトリは**完全に宣言的な設定**でこの問題を解決します——すべてのパッケージ、設定、dotfiles がコードで定義され、1 コマンドで任意のマシンに**完全再現**できます。

**コア原則：**

- **再現性** — どのマシンでも、毎回同じ環境
- **宣言的** — すべてコードで定義、バージョン管理
- **モジュラー** — プロファイルベースのカスタマイズ：仕事/個人/ヘッドレス
- **AI 拡張** — Claude Code 統合で開発ワークフローを強化
- **セキュリティ優先** — 暗号化されたシークレット、gopass 統合

---

## 📑 目次

- [🚀 クイックスタート](#quick-start)
- [🧩 アーキテクチャ](#architecture)
- [🤖 Claude Code 統合](#claude-code-integration)
- [⚡ ツールチェーン](#tool-chains)
- [🔧 シェル関数](#shell-functions)
- [📦 パッケージ管理](#package-management)
- [🔄 日常操作](#daily-operations)
- [👤 マルチプロファイル設定](#multi-profile-configuration)
- [🔐 セキュリティとシークレット](#security)
- [🙏 謝辞](#acknowledgements)

---

> [!WARNING]
> **実行前に必ず確認してください！** このリポジトリにはシステム設定を変更するスクリプトが含まれます。
> まず Fork して、自分の環境に合わせてカスタマイズしてください。

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

上記コマンドで自動的に：

1. Nix をインストール（Determinate Systems インストーラ）
2. Nix 経由で `age` と `gopass` をインストール（復号用）
3. gopass から復号鍵を取得（または手動セットアップを案内）
4. すべての dotfiles と設定を適用
5. Claude Code プラグインを同期

> [!IMPORTANT]
> **初めて使う方へ**：`useEncryption` を聞かれたら **No**（デフォルト）を選択してください。
> 暗号化設定はリポジトリ所有者専用です。暗号化が必要な場合は以下を修正してください：
>
> - `.chezmoiscripts/run_once_before_01_setup-encryption-key.sh`：`KEY_FILE`、`KEY_PUB`、gopass パスを変更
> - `.chezmoi.toml.tmpl`：`[age]` セクションの `identity` と `recipientsFile` パスを更新

インストール後、ターミナルを再起動してください。macOS では `just darwin` で nix-darwin 設定を有効化します。

---

<a id="architecture"></a>

## 🧩 アーキテクチャ

```
~/.dotfiles/
├── .chezmoidata/           # モジュラーデータ設定
│   ├── base.yaml           # コア設定
│   ├── claude.yaml         # Claude Code プラグイン設定
│   └── versions.yaml       # ツールバージョン固定
├── .chezmoiscripts/        # ブートストラップ・同期スクリプト
├── dot_claude/             # Claude Code 設定
│   ├── agents/             # AI エージェント定義
│   ├── commands/           # スラッシュコマンド
│   ├── skills/             # 自動知識スキル
│   ├── hooks/              # Git・コード Hooks
│   └── context/            # リファレンスドキュメント
├── nix-config/             # Nix flake 設定
│   └── modules/            # nix-darwin / flakey-profile モジュール
└── dot_custom/             # シェル関数・エイリアス
```

**chezmoi** は複数マシン間で dotfiles を管理し、テンプレート、暗号化、プラットフォーム条件分岐をサポートします。

**nix-darwin**（macOS）は Nix による宣言的システム設定を提供し、システムパッケージ、Homebrew、macOS 設定を管理します。

**flakey-profile**（Linux）は同じ Nix flake を使って宣言的パッケージ管理を提供し、ユーザーパッケージに焦点を当てます。

| コンポーネント     | macOS          | Linux          |
| ------------------ | -------------- | -------------- |
| Dotfiles           | chezmoi        | chezmoi        |
| システム設定       | nix-darwin     | N/A            |
| ユーザーパッケージ | flakey-profile | flakey-profile |
| GUI アプリ         | Homebrew Cask  | N/A            |

---

<a id="claude-code-integration"></a>

## 🤖 Claude Code 統合

この dotfiles には、自動化されたプラグイン管理を備えた包括的な Claude Code セットアップが含まれています。

### プラグインシステム

プラグインは `.chezmoiexternal.toml.tmpl` を通じて複数のソースから自動ダウンロードされます：

| ソース                                                    | 説明                                                   |
| --------------------------------------------------------- | ------------------------------------------------------ |
| [wshobson/agents](https://github.com/wshobson/agents)     | 50+ コミュニティプラグイン（agents、commands、skills） |
| [anthropics/skills](https://github.com/anthropics/skills) | 公式ドキュメント処理（pdf、docx、pptx、xlsx）          |
| [obra/superpowers](https://github.com/obra/superpowers)   | 高度なワークフローパターン                             |

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
      # ... 全19プラグイン
  anthropicsSkills:
    include:
      - pdf
      - docx
```

chezmoi external が自動的に：

- `chezmoi apply` 時に有効なプラグインをダウンロード
- agents、commands、skills を `~/.claude/` に展開
- 設定変更時に自動更新

### 品質プロトコル

SuperClaude にインスパイアされた組み込み品質保証：

| プロトコル           | 目的                          |
| -------------------- | ----------------------------- |
| **Confidence Check** | 実装前評価（HIGH/MEDIUM/LOW） |
| **Self-Check**       | 実装後検証（エビデンス付き）  |

### Hooks

| Hook                    | トリガー       | アクション                                    |
| ----------------------- | -------------- | --------------------------------------------- |
| `format-code.sh`        | Edit/Write 後  | Nix、JSON、YAML、Shell などを自動フォーマット |
| `enforce-uv.sh`         | pip コマンド時 | `uv` へリダイレクト                           |
| `block-main-edits.sh`   | ファイル編集時 | main ブランチへの直接編集をブロック           |
| `block-git-rewrites.sh` | git コマンド時 | force push と履歴書き換えをブロック           |

---

<a id="tool-chains"></a>

## ⚡ ツールチェーン

従来の Unix ツールをモダンな Rust 製代替ツールに置き換えます。

### モダン CLI 置き換え

| 従来   | モダン                                           | 説明                              |
| ------ | ------------------------------------------------ | --------------------------------- |
| `ls`   | [eza](https://github.com/eza-community/eza)      | Git 連携、アイコン、ツリービュー  |
| `cat`  | [bat](https://github.com/sharkdp/bat)            | シンタックスハイライト、Git 連携  |
| `grep` | [ripgrep](https://github.com/BurntSushi/ripgrep) | 超高速な正規表現検索              |
| `find` | [fd](https://github.com/sharkdp/fd)              | 直感的な構文、`.gitignore` を尊重 |
| `cd`   | [zoxide](https://github.com/ajeetdsouza/zoxide)  | スマートなディレクトリジャンプ    |

### シェル環境

| ツール                                              | 役割                             |
| --------------------------------------------------- | -------------------------------- |
| [starship](https://github.com/starship/starship)    | 最小・高速なプロンプト           |
| [sheldon](https://github.com/rossmacarthur/sheldon) | 高速 zsh プラグインマネージャ    |
| [atuin](https://github.com/atuinsh/atuin)           | あいまい検索付きシェル履歴       |
| [direnv](https://github.com/direnv/direnv)          | ディレクトリ単位の環境変数管理   |
| [fzf](https://github.com/junegunn/fzf)              | ファイル・履歴などのあいまい検索 |

### 開発ツール

| ツール                                              | 役割                                             |
| --------------------------------------------------- | ------------------------------------------------ |
| [mise](https://github.com/jdx/mise)                 | 多言語ランタイム管理（Node/Python/Go/Rust）      |
| [lazygit](https://github.com/jesseduffield/lazygit) | 美しい Git TUI                                   |
| [yazi](https://github.com/sxyazi/yazi)              | 超高速ターミナルファイルマネージャ               |
| [tmux](https://github.com/tmux/tmux)                | フローティングペイン対応ターミナルマルチプレクサ |

---

<a id="shell-functions"></a>

## 🔧 シェル関数

### プロジェクト移動

```bash
dev                 # FZF ベースのプロジェクト選択（ghq）
mkcd <dir>          # ディレクトリ作成して cd
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

<a id="package-management"></a>

## 📦 パッケージ管理

| ソース         | プラットフォーム | 説明                         |
| -------------- | ---------------- | ---------------------------- |
| Nix packages   | macOS, Linux     | 再現性が高くロールバック可能 |
| Homebrew casks | macOS のみ       | GUI アプリ                   |
| Mac App Store  | macOS のみ       | App Store 限定               |

パッケージ一覧は `.chezmoidata/` に定義され、shared / work-only / private-only の分類に対応しています。

---

<a id="daily-operations"></a>

## 🔄 日常操作

```bash
# Chezmoi 操作
just apply          # dotfiles 変更を適用
just diff           # 未適用差分を表示

# Nix 操作
just up             # flake 入力をすべて更新
just switch         # flakey-profile を切り替え（パッケージ再ビルド）
just darwin         # nix-darwin を再ビルド（macOS）

# メンテナンス
just gc             # nix store をクリーンアップ
just full-upgrade   # 完全アップグレード
```

---

<a id="multi-profile-configuration"></a>

## 👤 マルチプロファイル設定

```bash
# 仕事用マシン
chezmoi init --apply --promptBool work=true signalridge

# 個人用マシン（デフォルト）
chezmoi init --apply signalridge

# ヘッドレスサーバー（GUI 設定不要）
chezmoi init --apply --promptBool headless=true signalridge
```

---

<a id="security"></a>

## 🔐 セキュリティとシークレット

このリポジトリは `age` でプライベートファイルを暗号化します。Chezmoi は `~/.ssh/main`（秘密鍵）と `~/.ssh/main.pub`（受信者）で復号します。

初回 `apply` 時、ブートストラップスクリプトが：

1. Nix をインストール
2. Nix 経由で `age` + `op` をインストール
3. gopass から鍵を取得（または手動セットアップを案内）

---

<a id="acknowledgements"></a>

## 🙏 謝辞

- [chezmoi](https://github.com/twpayne/chezmoi) - Dotfiles マネージャ
- [nix-darwin](https://github.com/LnL7/nix-darwin) - 宣言的 macOS 設定
- [flakey-profile](https://github.com/lf-/flakey-profile) - クロスプラットフォーム Nix プロファイル管理
- [wshobson/agents](https://github.com/wshobson/agents) - Claude Code プラグイン marketplace
- [anthropics/skills](https://github.com/anthropics/skills) - 公式 Claude Code skills
- [obra/superpowers](https://github.com/obra/superpowers) - 高度なワークフローパターン
- [Dracula Theme](https://draculatheme.com/) - 美しいダークテーマ

---

## 📈 統計

![Repobeats](https://repobeats.axiom.co/api/embed/b47788b120b4e3a0f049b72115d88268d5523f64.svg "Repobeats analytics")

---

## 📝 ライセンス

MIT License
