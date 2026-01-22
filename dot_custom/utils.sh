# shellcheck shell=bash
# ─────────────────────────────────────────────────────────────
# Utility Functions Library
# Common helper functions for shell scripts and interactive use
# ─────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────
# Colored Output
# ─────────────────────────────────────────────────────────────
print_success() { printf "\033[32m✔ %s\033[0m\n" "$1"; }
print_error() { printf "\033[31m✖ %s\033[0m\n" "$1"; }
print_warning() { printf "\033[33m! %s\033[0m\n" "$1"; }
print_info() { printf "\033[34mℹ %s\033[0m\n" "$1"; }
print_step() { printf "\033[35m→ %s\033[0m\n" "$1"; }

# ─────────────────────────────────────────────────────────────
# Command Utilities
# ─────────────────────────────────────────────────────────────
# Check if command exists
cmd_exists() { command -v "$1" &>/dev/null; }

# Get current OS
get_os() {
    case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    *) echo "unknown" ;;
    esac
}

# Check if running on macOS
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

# Check if running on Linux
is_linux() { [[ "$(uname -s)" == "Linux" ]]; }

# Check if inside git repository
is_git_repo() { git rev-parse --is-inside-work-tree &>/dev/null; }

# ─────────────────────────────────────────────────────────────
# File Utilities
# ─────────────────────────────────────────────────────────────
# delete-files - Delete files matching pattern recursively
# Usage: delete-files [pattern]  (default: *.DS_Store)
delete-files() {
    local pattern="${1:-*.DS_Store}"
    print_info "Searching for files matching: $pattern"
    local files
    files=$(find . -type f -name "$pattern" 2>/dev/null)
    if [[ -z "$files" ]]; then
        print_success "No files found matching: $pattern"
        return 0
    fi
    echo "$files"
    echo ""
    printf "Delete these files? [y/N] "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        find . -type f -name "$pattern" -delete 2>/dev/null
        print_success "Deleted files matching: $pattern"
    else
        print_warning "Cancelled"
    fi
}

# ─────────────────────────────────────────────────────────────
# Batch Rename with zmv (zsh only)
# ─────────────────────────────────────────────────────────────
if [[ -n "$ZSH_VERSION" ]]; then
    autoload -Uz zmv
    # Usage: zmv '*.txt' '*.md'
    alias zmv='noglob zmv -W'
    # Dry-run version
    alias zmvn='noglob zmv -W -n'
fi

# ─────────────────────────────────────────────────────────────
# Network Utilities
# ─────────────────────────────────────────────────────────────
# nw - Network monitoring with sniffnet
nw() {
    if ! cmd_exists sniffnet; then
        print_error "sniffnet is not installed. Install via: nix profile install nixpkgs#sniffnet"
        return 1
    fi
    sudo sniffnet "$@"
}

# myip - Get public IP address
myip() {
    curl -s https://api.ipify.org && echo ""
}

# localip - Get local IP address
localip() {
    if is_macos; then
        ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null
    else
        hostname -I | awk '{print $1}'
    fi
}

# ─────────────────────────────────────────────────────────────
# Text Processing
# ─────────────────────────────────────────────────────────────
# trim - Remove leading/trailing whitespace
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

# urlencode - URL encode a string
# Usage: urlencode "hello world" or echo "hello world" | urlencode
urlencode() {
    if [[ -n "$1" ]]; then
        python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$1"
    else
        python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.stdin.read().strip()))"
    fi
}

# urldecode - URL decode a string
# Usage: urldecode "hello%20world" or echo "hello%20world" | urldecode
urldecode() {
    if [[ -n "$1" ]]; then
        python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" "$1"
    else
        python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.stdin.read().strip()))"
    fi
}
