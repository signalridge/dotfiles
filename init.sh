#!/bin/sh

set -eu # -e: exit on error, -u: error on unset variables

# Dependencies:
#   - sh, mkdir, command, pwd
# Optional:
#   - chezmoi (installed automatically if missing)
#   - curl or wget (to install chezmoi)

usage() {
    cat >&2 <<'EOF'
Usage: init.sh [options] [-- <chezmoi init flags>]

Options:
  --repo <repo>     Repo to init from (default: signalridge)
                   Examples: signalridge, signalridge/dotfiles, git@github.com:signalridge/dotfiles.git
  --ref <ref>       Branch or tag to checkout (maps to: chezmoi init --branch)
  --depth <n>       Shallow clone depth (maps to: chezmoi init --depth)
  --ssh             Use SSH when guessing repo URL (maps to: chezmoi init --ssh)
  -h, --help        Show this help

Environment:
  DOTFILES_REPO / DOTFILES_REF / DOTFILES_DEPTH / DOTFILES_SSH

Examples:
  ./init.sh
  ./init.sh --ref <tag-or-branch>
  curl -fsLS https://raw.githubusercontent.com/signalridge/dotfiles/<tag-or-branch>/init.sh | sh -s -- --ref <tag-or-branch>
EOF
}

repo="${DOTFILES_REPO:-signalridge}"
ref="${DOTFILES_REF:-}"
depth="${DOTFILES_DEPTH:-}"
ssh="${DOTFILES_SSH:-}"

while [ $# -gt 0 ]; do
    case "$1" in
    -h | --help)
        usage
        exit 0
        ;;
    --repo)
        shift
        repo="${1:-}"
        [ -n "$repo" ] || {
            echo "error: --repo requires a value" >&2
            exit 2
        }
        ;;
    --ref | --branch)
        shift
        ref="${1:-}"
        [ -n "$ref" ] || {
            echo "error: --ref requires a value" >&2
            exit 2
        }
        ;;
    --depth)
        shift
        depth="${1:-}"
        [ -n "$depth" ] || {
            echo "error: --depth requires a value" >&2
            exit 2
        }
        ;;
    --ssh)
        ssh=1
        ;;
    --)
        shift
        break
        ;;
    -*)
        echo "error: unknown option: $1" >&2
        usage
        exit 2
        ;;
    *)
        echo "error: unexpected argument: $1" >&2
        usage
        exit 2
        ;;
    esac
    shift
done

if ! command -v chezmoi >/dev/null 2>&1; then
    bin_dir="$HOME/bin"
    chezmoi="$bin_dir/chezmoi"
    mkdir -p "$bin_dir"
    if command -v curl >/dev/null 2>&1; then
        sh -c "$(curl -fsLS --proto '=https' --tlsv1.2 https://get.chezmoi.io)" -- -b "$bin_dir"
    elif command -v wget >/dev/null 2>&1; then
        sh -c "$(wget -qO- https://get.chezmoi.io)" -- -b "$bin_dir"
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
    exec "$chezmoi" init --apply --source "$script_dir" "$@"
else
    # Piped from curl/wget - clone from GitHub instead
    if [ -n "$ssh" ]; then
        set -- --ssh "$@"
    fi
    if [ -n "$depth" ]; then
        set -- --depth "$depth" "$@"
    fi
    if [ -n "$ref" ]; then
        set -- --branch "$ref" "$@"
    fi

    exec "$chezmoi" init --apply "$@" "$repo"
fi
