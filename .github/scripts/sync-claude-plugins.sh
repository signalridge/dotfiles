#!/bin/bash
# sync-claude-plugins.sh - Sync Claude Code plugins from upstream repos
# Usage: ./sync-claude-plugins.sh <wshobson-dir> <superpowers-dir> <anthropics-dir>
#
# Strategy: Delete all non-local directories, then sync included plugins
# Local directories are defined in claude.yaml and protected from deletion

set -euo pipefail

WSHOBSON_DIR="${1:?Usage: $0 <wshobson-dir> <superpowers-dir> <anthropics-dir>}"
SUPERPOWERS_DIR="${2:?Usage: $0 <wshobson-dir> <superpowers-dir> <anthropics-dir>}"
ANTHROPICS_DIR="${3:?Usage: $0 <wshobson-dir> <superpowers-dir> <anthropics-dir>}"

REPO_ROOT="$(git rev-parse --show-toplevel)"
DOT_CLAUDE="$REPO_ROOT/dot_claude"
CLAUDE_YAML="$REPO_ROOT/.chezmoidata/claude.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Get included wshobsonAgents plugins from claude.yaml
get_wshobson_include() {
    yq -r '.claude.wshobsonAgents.include[]' "$CLAUDE_YAML" 2>/dev/null || true
}

# Get included anthropicsSkills from claude.yaml
get_anthropics_include() {
    yq -r '.claude.anthropicsSkills.include[]' "$CLAUDE_YAML" 2>/dev/null || true
}

# Get local directories from claude.yaml
get_local_dirs() {
    local type=$1
    yq -r ".claude.localDirectories.${type}[]" "$CLAUDE_YAML" 2>/dev/null || true
}

# Check if directory is local
is_local_dir() {
    local type=$1 name=$2
    get_local_dirs "$type" | grep -qx "$name"
}

# Delete all non-local directories for a type
clean_non_local() {
    local type=$1
    [[ -d "$DOT_CLAUDE/$type" ]] || return 0

    for dir in "$DOT_CLAUDE/$type"/*/; do
        [[ -d "$dir" ]] || continue
        local name
        name=$(basename "$dir")

        # Keep local directories
        is_local_dir "$type" "$name" && continue

        # Delete non-local
        rm -rf "$dir"
        log_warn "Deleted: $type/$name"
    done
}

# Sync single wshobson plugin
sync_plugin() {
    local name=$1
    local src="$WSHOBSON_DIR/plugins/$name"
    [[ -d "$src" ]] || {
        log_warn "Not found: $name"
        return 1
    }

    local synced=0
    for type in agents commands skills; do
        if [[ -d "$src/$type" ]]; then
            mkdir -p "$DOT_CLAUDE/$type/$name"
            cp -r "$src/$type"/* "$DOT_CLAUDE/$type/$name/" 2>/dev/null || true
            ((synced++)) || true
        fi
    done

    if [[ $synced -gt 0 ]]; then
        log_ok "$name"
    else
        log_warn "$name (empty)"
    fi
    return 0
}

# Get superpowers exclude list from claude.yaml
get_superpowers_exclude() {
    local type=$1
    yq -r ".claude.superpowers.exclude.${type}[]" "$CLAUDE_YAML" 2>/dev/null || true
}

# Sync superpowers
sync_superpowers() {
    for type in agents commands skills; do
        if [[ -d "$SUPERPOWERS_DIR/$type" ]]; then
            mkdir -p "$DOT_CLAUDE/$type/superpowers"
            cp -r "$SUPERPOWERS_DIR/$type"/* "$DOT_CLAUDE/$type/superpowers/" 2>/dev/null || true

            # Remove excluded items
            while IFS= read -r exclude; do
                [[ -n "$exclude" ]] || continue
                if [[ -d "$DOT_CLAUDE/$type/superpowers/$exclude" ]]; then
                    rm -rf "$DOT_CLAUDE/$type/superpowers/$exclude"
                    log_warn "Excluded: superpowers/$type/$exclude"
                fi
            done < <(get_superpowers_exclude "$type")
        fi
    done
    log_ok "superpowers"
}

# Sync single anthropics skill
sync_anthropics_skill() {
    local name=$1
    local src="$ANTHROPICS_DIR/skills/$name"
    [[ -d "$src" ]] || {
        log_warn "Not found: anthropics/$name"
        return 1
    }

    mkdir -p "$DOT_CLAUDE/skills/anthropics"
    cp -r "$src" "$DOT_CLAUDE/skills/anthropics/"
    log_ok "anthropics/$name"
    return 0
}

# Main
main() {
    log_info "Syncing Claude plugins..."

    # Validate inputs
    [[ -d "$WSHOBSON_DIR" ]] || {
        log_error "Not found: $WSHOBSON_DIR"
        exit 1
    }
    [[ -d "$SUPERPOWERS_DIR" ]] || {
        log_error "Not found: $SUPERPOWERS_DIR"
        exit 1
    }
    [[ -d "$ANTHROPICS_DIR" ]] || {
        log_error "Not found: $ANTHROPICS_DIR"
        exit 1
    }
    [[ -f "$CLAUDE_YAML" ]] || {
        log_error "Not found: $CLAUDE_YAML"
        exit 1
    }

    # Read included wshobson plugins
    local -a wshobson_include=()
    while IFS= read -r p; do
        [[ -n "$p" ]] && wshobson_include+=("$p")
    done < <(get_wshobson_include)
    log_info "wshobson: ${#wshobson_include[@]} plugins"

    # Read included anthropics skills
    local -a anthropics_include=()
    while IFS= read -r s; do
        [[ -n "$s" ]] && anthropics_include+=("$s")
    done < <(get_anthropics_include)
    log_info "anthropics: ${#anthropics_include[@]} skills"

    # Step 1: Delete all non-local directories
    log_info "Cleaning non-local directories..."
    for type in agents commands skills; do
        clean_non_local "$type"
    done

    # Step 2: Sync wshobson plugins
    log_info "Syncing wshobson plugins..."
    for plugin in "${wshobson_include[@]}"; do
        sync_plugin "$plugin" || true
    done

    # Step 3: Sync superpowers
    log_info "Syncing superpowers..."
    sync_superpowers

    # Step 4: Sync anthropics skills
    log_info "Syncing anthropics skills..."
    for skill in "${anthropics_include[@]}"; do
        sync_anthropics_skill "$skill" || true
    done

    log_info "Done"
}

main "$@"
