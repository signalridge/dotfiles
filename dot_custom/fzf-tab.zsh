# Zsh completion configuration (fzf-tab)
# Note: This file uses zsh-specific syntax, excluded from shellcheck

# ─────────────────────────────────────────────────────────────
# fzf-tab: Replace zsh completion menu with fzf
# Docs: https://github.com/Aloxaf/fzf-tab
# ─────────────────────────────────────────────────────────────

# Use tmux popup for completion (requires tmux 3.2+)
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' popup-min-size 80 20

# Keybindings
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'       # Tab accepts selection
zstyle ':fzf-tab:*' accept-line enter               # Enter accepts and runs
zstyle ':fzf-tab:*' continuous-trigger '/'          # / for continuous completion
zstyle ':fzf-tab:*' switch-group '<' '>'            # <> to switch groups

# Display settings
zstyle ':fzf-tab:*' show-group brief                # Show group headers only when needed
zstyle ':completion:*:descriptions' format '[%d]'   # Group descriptions format
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"  # File colors
zstyle ':completion:*' menu no                      # Disable default menu

# ─────────────────────────────────────────────────────────────
# Previews (uses eza, bat from your existing setup)
# ─────────────────────────────────────────────────────────────

# Command previews (when completing command names)
zstyle ':fzf-tab:complete:-command-:*' fzf-preview 'tldr --color always $word 2>/dev/null || whatis $word 2>/dev/null || echo "No info for: $word"'

# Directory previews
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --color=always --icons $realpath 2>/dev/null || ls -la $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza -la --color=always --icons $realpath 2>/dev/null || ls -la $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza --tree --level=2 --color=always --icons $realpath 2>/dev/null || ls -la $realpath'

# File previews (cat, less, vim, nvim, code)
zstyle ':fzf-tab:complete:(cat|less|bat|vim|nvim|code):*' fzf-preview 'bat --color=always --style=numbers --line-range=:100 $realpath 2>/dev/null || head -100 $realpath'

# Process previews (kill, ps)
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview '[[ $group == "[process ID]" ]] && ps -p $word -o pid,user,%cpu,%mem,command'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:4:wrap

# Git previews
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta 2>/dev/null || git diff $word'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --oneline --color=always $word | head -20'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --color=always $word | head -20'
zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'git show --color=always $word | head -100'
zstyle ':completion:*:git-checkout:*' sort false    # Don't sort git branches

# Environment variable preview
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ${(P)word}'

# Homebrew preview (macOS)
zstyle ':fzf-tab:complete:brew-(install|uninstall|search|info):*' fzf-preview 'brew info $word 2>/dev/null | head -20'

# SSH/SCP host preview
zstyle ':fzf-tab:complete:(ssh|scp|rsync):*' fzf-preview 'echo "Host: $word"'

# Docker previews
zstyle ':fzf-tab:complete:docker-container:*' fzf-preview 'docker inspect $word 2>/dev/null | head -50'
zstyle ':fzf-tab:complete:docker-image:*' fzf-preview 'docker image inspect $word 2>/dev/null | head -50'
