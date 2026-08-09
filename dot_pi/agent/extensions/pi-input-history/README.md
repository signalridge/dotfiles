# pi-input-history

**Cross-session prompt history and an fzf/atuin-style fuzzy Ctrl+R popup for pi.**

[![npm version](https://img.shields.io/npm/v/pi-input-history?style=for-the-badge)](https://www.npmjs.com/package/pi-input-history)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

## Why

Pi's built-in ↑/↓ history only covers the current session and is lost on reload. This extension persists your last 100 prompts across sessions and adds an fzf/atuin-style **Ctrl+R** popup — a scrollable, live-filtered list of past prompts — so you can find any of them instantly.

![Ctrl+R fuzzy popup](assets/screenshot.png)

## Install

```bash
pi install npm:pi-input-history
```

Or from git:

```bash
pi install git:github.com/ouzhenkun/pi-input-history
```

## Usage

### Persistent History

On session start, your last 100 prompts across all sessions are loaded into the editor. Use **↑/↓** arrows to browse them as usual.

### Fuzzy Popup (Ctrl+R)

1. Press **Ctrl+R** to open the popup — a large centred two-pane dialog, `fzf --preview` style. The left pane lists your recent prompts newest-first, each row carrying its position and age; the right pane shows the **full text** of the highlighted entry, which one-line summaries cannot convey for long prompts.
2. Type to fuzzy-filter the list live (subsequence matching, space-separated multi-token).
3. The selected row shows as a full-width highlight bar; matched characters are underlined in your theme's accent color.
4. Navigate and accept:

| Key                         | Action                       |
| --------------------------- | ---------------------------- |
| `↑` / `Ctrl+P` / `Ctrl+S`   | Move up the list (newer)     |
| `↓` / `Ctrl+N` / `Ctrl+R`   | Move down the list (older)   |
| `Ctrl+D` / `Ctrl+U`         | Scroll the preview pane      |
| `Enter`                     | Accept selection into editor |
| `Esc` / `Ctrl+G` / `Ctrl+C` | Cancel                       |

Arrow and Emacs bindings follow the list (`Ctrl+P`/`Ctrl+N` = previous/next line); `Ctrl+R`/`Ctrl+S` keep their shell meaning, so pressing **Ctrl+R** again walks further back in history. Below 76 columns the preview pane is dropped and the list takes the full width.

## Features

- **fzf-style two-pane popup** — a live-filtered list plus a preview pane showing the highlighted prompt in full, instead of a single-line prompt.
- **Cross-session persistence** — history survives across sessions automatically.
- **Fuzzy subsequence matching** — type partial characters in order, multi-token support with spaces.
- **Character-level highlighting** — matched positions shown with accent color underline on a full-width selection bar.
- **Deduplication** — no duplicate entries across sessions.
- **Current session awareness** — merges live branch history with cached cross-session history.

## Acknowledgments

The Ctrl+R reverse search component is inspired by [pi-readline-search](https://github.com/mrshu/pi-readline-search) by [@mrshu](https://github.com/mrshu).

## License

MIT
