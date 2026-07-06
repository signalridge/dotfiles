# pi-input-history

**Cross-session prompt history and fuzzy Ctrl+R search for pi.**

[![npm version](https://img.shields.io/npm/v/pi-input-history?style=for-the-badge)](https://www.npmjs.com/package/pi-input-history)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

## Why

Pi's built-in ↑/↓ history only covers the current session and is lost on reload. This extension persists your last 100 prompts across sessions and adds fuzzy **Ctrl+R** search to find any past prompt instantly.

![Ctrl+R reverse search](assets/screenshot.png)

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

### Reverse Search (Ctrl+R)

1. Press **Ctrl+R** to open the search overlay.
2. Type to fuzzy-filter history (subsequence matching, space-separated multi-token).
3. Matched characters are highlighted with your theme's accent color.
4. Navigate and accept:

| Key              | Action                   |
| ---------------- | ------------------------ |
| `Ctrl+R` / `↑`   | Cycle to older match     |
| `Ctrl+S` / `↓`   | Cycle to newer match     |
| `Enter`          | Accept match into editor |
| `Esc` / `Ctrl+G` | Cancel                   |

## Features

- **Cross-session persistence** — history survives across sessions automatically.
- **Fuzzy subsequence matching** — type partial characters in order, multi-token support with spaces.
- **Character-level highlighting** — matched positions shown with accent color underline.
- **Deduplication** — no duplicate entries across sessions.
- **Current session awareness** — merges live branch history with cached cross-session history.

## Acknowledgments

The Ctrl+R reverse search component is inspired by [pi-readline-search](https://github.com/mrshu/pi-readline-search) by [@mrshu](https://github.com/mrshu).

## License

MIT
