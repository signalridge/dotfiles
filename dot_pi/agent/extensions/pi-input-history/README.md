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

1. Press **Ctrl+R** to open the popup — a scrollable list of your recent prompts anchored above the input, fzf/atuin style.
2. Type to fuzzy-filter the list live (subsequence matching, space-separated multi-token).
3. The selected row shows as a full-width highlight bar; matched characters are underlined in your theme's accent color.
4. Navigate and accept:

| Key                         | Action                       |
| --------------------------- | ---------------------------- |
| `↑` / `Ctrl+P` / `Ctrl+R`   | Move to older match          |
| `↓` / `Ctrl+N` / `Ctrl+S`   | Move to newer match          |
| `Enter`                     | Accept selection into editor |
| `Esc` / `Ctrl+G` / `Ctrl+C` | Cancel                       |

## Features

- **fzf/atuin-style popup** — browse a scrollable, live-filtered list of candidates instead of a single-line prompt.
- **Cross-session persistence** — history survives across sessions automatically.
- **Fuzzy subsequence matching** — type partial characters in order, multi-token support with spaces.
- **Character-level highlighting** — matched positions shown with accent color underline on a full-width selection bar.
- **Deduplication** — no duplicate entries across sessions.
- **Current session awareness** — merges live branch history with cached cross-session history.

## Acknowledgments

The Ctrl+R reverse search component is inspired by [pi-readline-search](https://github.com/mrshu/pi-readline-search) by [@mrshu](https://github.com/mrshu).

## License

MIT
