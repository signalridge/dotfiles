# Tmux Keybindings Cheatsheet

> Prefix key: `Ctrl-b`

## Dependencies

- tmux 3.x recommended (popup needs `display-popup`)
- bash 5.2+ (required by tmux2k; macOS: `brew install bash`)
- fzf + fzf-tmux
- sesh (`brew install joshmedeski/sesh/sesh`)
- zoxide, fd (used by sesh directory navigation)
- (Optional, macOS clipboard) `reattach-to-user-namespace` may be needed on some macOS versions

---

## Plugin Stack

| Plugin                          | Description                                                 |
| ------------------------------- | ----------------------------------------------------------- |
| TPM                             | Plugin manager                                              |
| tmux-sensible                   | Sane defaults                                               |
| tmux-yank                       | System clipboard yank integration                           |
| tmux-pain-control               | Pane split + vim-like nav/resize bindings                   |
| tmux-sessionx                   | Internal session management panel                           |
| **tmux-floax**                  | Floating pane manager (`prefix+p/P`)                        |
| sesh (external)                 | Project/session launcher via fzf/zoxide/fd (custom binding) |
| extrakto                        | Extract paths/URLs/hashes from pane via fzf (`prefix+Tab`)  |
| tmux-jump                       | Easymotion-like jump (`prefix+f`)                           |
| tmux-fzf-url                    | fzf picker for URLs (`prefix+u`)                            |
| tmux-open                       | Open highlighted path/URL in copy-mode                      |
| tmux2k                          | Status bar framework                                        |
| tmux-nerd-font-window-name      | Window icons (`#{window_icon}`)                             |
| tmux-better-mouse-mode          | Smoother scroll/select                                      |
| tmux-resurrect + tmux-continuum | Save/restore + auto save/restore                            |
| tmux-notify                     | Notify when a command finishes                              |
| tmux-cowboy                     | Fast kill hung processes                                    |

---

## Basic Operations (Native)

| Keybinding        | Description                                |
| ----------------- | ------------------------------------------ |
| `prefix + r`      | Reload configuration                       |
| `prefix + ?`      | List all keybindings                       |
| `prefix + :`      | Enter command prompt                       |
| `prefix + d`      | Detach current client                      |
| `prefix + Ctrl-b` | Send literal `Ctrl-b` to app (send-prefix) |

---

## Session Management

### Two-layer design: sesh + sessionx

- **sesh (`prefix + T`)**: External entry (project-centric). Best for: jump into work/project → create/attach session.
- **sessionx (`prefix + O`)**: Internal panel (tmux-centric). Best for: preview/rename/delete sessions once you're already in tmux.

| Keybinding         | Description                                 |
| ------------------ | ------------------------------------------- |
| `prefix + T`       | **sesh** picker (fzf popup workflow)        |
| `prefix + O`       | **sessionx** panel (internal session admin) |
| `prefix + Ctrl-n`  | Create new session (prompt for name)        |
| `prefix + Ctrl-x`  | Kill current session (confirm)              |
| `prefix + s`       | Native session list                         |
| `prefix + $`       | Rename current session                      |
| `prefix + (` / `)` | Switch prev/next session                    |

### sesh panel controls (inside `prefix+T` popup)

| Keybinding | Description                |
| ---------- | -------------------------- |
| `Ctrl-a`   | All entries                |
| `Ctrl-t`   | tmux sessions only         |
| `Ctrl-g`   | Configs                    |
| `Ctrl-x`   | Zoxide dirs                |
| `Ctrl-f`   | fd directory search        |
| `Ctrl-d`   | Kill selected tmux session |

---

## Window Management

> `automatic-rename` enabled, window name shows `#{b:pane_current_path}` to avoid "zsh zsh".

| Keybinding         | Description                       |
| ------------------ | --------------------------------- |
| `prefix + c`       | New window (in current pane path) |
| `prefix + ,`       | Rename window                     |
| `prefix + w`       | Window list                       |
| `prefix + n` / `p` | Next / previous window            |
| `prefix + 0-9`     | Switch window by number           |
| `prefix + X`       | Kill window (**no confirm**)      |

> **Note**: Default `prefix + l` (last-window) is **taken over by tmux-pain-control** for "go right pane".

---

## Pane Management — tmux-pain-control

### Splitting

| Keybinding    | Description        |
| ------------- | ------------------ |
| `prefix + \|` | Split (left/right) |
| `prefix + -`  | Split (top/bottom) |

### Navigation (vim-like)

| Keybinding         | Description                  |
| ------------------ | ---------------------------- |
| `prefix + h/j/k/l` | Move between panes (L/D/U/R) |

### Resizing

| Keybinding         | Description  |
| ------------------ | ------------ |
| `prefix + H/J/K/L` | Resize panes |

### Others

| Keybinding         | Description                                     |
| ------------------ | ----------------------------------------------- |
| `prefix + x`       | Kill pane (**no confirm**)                      |
| `prefix + z`       | Zoom pane (toggle maximize)                     |
| `prefix + S`       | Toggle synchronize panes (shows ON/OFF message) |
| `prefix + !`       | Move pane to new window                         |
| `prefix + q`       | Show pane numbers                               |
| `prefix + o`       | Cycle to next pane                              |
| `prefix + {` / `}` | Swap with prev/next pane                        |
| `prefix + Space`   | Cycle through layouts                           |

---

## Copy Mode (vi-style) + Clipboard (tmux-yank)

### Enter / Select

| Keybinding   | Description                   |
| ------------ | ----------------------------- |
| `prefix + a` | Enter copy-mode (custom bind) |
| `prefix + [` | Enter copy-mode (native)      |
| `v`          | Begin selection               |
| `V`          | Select line                   |
| `Escape`     | Cancel / exit                 |
| `/` / `?`    | Search forward / backward     |
| `n` / `N`    | Next / previous match         |

### Yank Behavior (important)

| Context     | Keybinding   | What it does                                       |
| ----------- | ------------ | -------------------------------------------------- |
| Normal mode | `prefix + y` | Copy from command line (works in shells/REPLs)     |
| Normal mode | `prefix + Y` | Copy current pane's **CWD**                        |
| Copy mode   | `y`          | Copy selection to system clipboard                 |
| Copy mode   | `Y`          | **Put selection** (copy + paste into command line) |

> `set-clipboard on` is enabled, consistent with tmux-yank recommendations.

### tmux-open (inside copy-mode)

| Keybinding | Description                     |
| ---------- | ------------------------------- |
| `o`        | Open selection with default app |
| `Ctrl-o`   | Open with `$EDITOR`             |
| `Shift-s`  | Search selection with Google    |

---

## Quick Extract / Jump / URL Open

| Keybinding     | Plugin       | Description                                 |
| -------------- | ------------ | ------------------------------------------- |
| `prefix + Tab` | extrakto     | Extract paths/URLs/hashes from pane via fzf |
| `prefix + f`   | tmux-jump    | Jump to any character (easymotion-like)     |
| `prefix + u`   | tmux-fzf-url | fzf picker to select URL(s) and open        |

---

## Floating Panes (tmux-floax)

> floax provides persistent floating panes that can be toggled, resized, and embedded back into the workspace.

| Keybinding   | Description                                 |
| ------------ | ------------------------------------------- |
| `prefix + p` | Toggle floating pane (open/close)           |
| `prefix + P` | Open floax menu (resize, fullscreen, embed) |
| `prefix + g` | Popup lazygit (90%x90%)                     |

### Floax Menu Options (inside floating pane)

| Key | Description                            |
| --- | -------------------------------------- |
| `-` | Shrink pane size                       |
| `+` | Grow pane size                         |
| `f` | Toggle fullscreen                      |
| `r` | Reset to default size                  |
| `e` | Embed floating pane to workspace below |

---

## Monitoring & Logging

### tmux-notify

| Keybinding   | Description                                |
| ------------ | ------------------------------------------ |
| `prefix + m` | Monitor pane, notify when command finishes |
| `prefix + M` | Cancel monitoring                          |

---

## Session Persistence — tmux-resurrect / tmux-continuum

- Continuum auto-saves every **15 min** and restores on start
- Resurrect provides manual save/restore keys

| Keybinding        | Description              |
| ----------------- | ------------------------ |
| `prefix + Ctrl-s` | Save tmux environment    |
| `prefix + Ctrl-r` | Restore tmux environment |

---

## Other Tools

| Keybinding   | Description                                          |
| ------------ | ---------------------------------------------------- |
| `prefix + *` | tmux-cowboy: kill hanging process (use with caution) |

---

## TPM Plugin Management

| Keybinding         | Description                  |
| ------------------ | ---------------------------- |
| `prefix + I`       | Install plugins              |
| `prefix + U`       | Update plugins               |
| `prefix + Alt + u` | Remove plugins not in config |

---

## Status Bar Modules (tmux2k)

Left: `session` | `git` | `cpu` | `ram`

Right: `battery` | `network` | `time`

---

## Important Reminders

1. **`prefix + l` is NOT last-window anymore** — tmux-pain-control uses it for "go right pane"
2. **`prefix + x/X` kills without confirmation** — different from tmux default behavior
3. **Mouse support enabled** — scroll wheel (3 lines), drag to select auto-copies to clipboard
