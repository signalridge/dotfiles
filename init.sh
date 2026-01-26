#!/bin/sh

set -eu # -e: exit on error, -u: error on unset variables

if [ ! "$(command -v chezmoi)" ]; then
    bin_dir="$HOME/bin"
    chezmoi="$bin_dir/chezmoi"
    if [ "$(command -v curl)" ]; then
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$bin_dir"
    elif [ "$(command -v wget)" ]; then
        sh -c "$(wget -qO- get.chezmoi.io)" -- -b "$bin_dir"
    else
        echo "To install chezmoi, you must have curl or wget installed." >&2
        exit 1
    fi
else
    chezmoi=chezmoi
fi

# POSIX way to get script's dir: https://stackoverflow.com/a/29834779/12156188
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"

# Check if script_dir looks valid (has .chezmoiroot or is a chezmoi source dir)
# When piped from curl, $0 is "sh" and script_dir becomes /usr/bin which is wrong
if [ -f "$script_dir/.chezmoiroot" ] || [ -f "$script_dir/.chezmoi.toml.tmpl" ]; then
    # exec: replace current process with chezmoi init using local source
    exec "$chezmoi" init --apply "--source=$script_dir"
else
    # Piped from curl/wget - clone from GitHub instead
    exec "$chezmoi" init --apply signalridge
fi
