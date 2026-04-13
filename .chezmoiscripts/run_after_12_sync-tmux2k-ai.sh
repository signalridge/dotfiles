#!/bin/bash

set -euo pipefail

# Symlink the chezmoi-managed tmux2k ai plugin into the TPM-managed
# tmux2k plugins directory. Idempotent — safe across chezmoi apply reruns.

echo ":: [12] Syncing tmux2k AI plugin"

src="$HOME/.config/tmux/tmux2k-ai.sh"
dst_dir="$HOME/.config/tmux/plugins/tmux2k/plugins"
dst="$dst_dir/ai.sh"

if [[ ! -d "$dst_dir" ]]; then
    echo "    Skipped (tmux2k not installed — run prefix+I in tmux first)"
    exit 0
fi

if [[ ! -f "$src" ]]; then
    echo "    Skipped (source not found: $src)"
    exit 0
fi

ln -sf "$src" "$dst"
echo "    Linked $dst → $src"
