#!/bin/bash
# Automated backup using rclone
# Configure rclone remote first: rclone config
# Example: rclone config (create remote named 'backup' for B2/S3/GDrive)

set -euo pipefail

REMOTE="${RCLONE_REMOTE:-backup}"

# Directories to backup (NOTE: .ssh excluded for security - backup keys separately with encryption)
BACKUP_DIRS=(
    "$HOME/Documents"
    "$HOME/Projects"
    "$HOME/.config"
)

# Patterns to exclude from backup
EXCLUDE_PATTERNS=(
    "node_modules/**"
    ".git/**"
    "__pycache__/**"
    "*.pyc"
    ".DS_Store"
    "*.log"
    "venv/**"
    ".venv/**"
    ".ssh/**"
    "*.key"
    "*.pem"
    "id_rsa*"
    "id_ed25519*"
)

backup() {
    local src="$1"
    local dest_name
    dest_name=$(basename "$src")

    if ! command -v rclone >/dev/null 2>&1; then
        echo "Error: rclone is not installed"
        return 1
    fi

    echo "Backing up: $src -> $REMOTE:$dest_name"

    # Build exclude arguments
    local -a exclude_args=()
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        exclude_args+=("--exclude" "$pattern")
    done

    rclone sync "$src" "$REMOTE:$dest_name" \
        "${exclude_args[@]}" \
        --progress \
        --transfers 4 \
        --checkers 8 \
        --fast-list
}

show_help() {
    cat <<'EOF'
Usage: backup.sh [sync|list|status]
  sync   - Sync backup directories to remote
  list   - List remote directories
  status - Show remote storage status

Environment variables:
  RCLONE_REMOTE - Remote name (default: backup)

Configure rclone first: rclone config
EOF
}

case "${1:-sync}" in
sync)
    for dir in "${BACKUP_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            backup "$dir"
        else
            echo "Warning: $dir does not exist, skipping"
        fi
    done
    echo "Backup completed at $(date)"
    ;;
list)
    if ! rclone lsd "$REMOTE:" 2>/dev/null; then
        echo "Error: Cannot list remote. Configure rclone first: rclone config"
        exit 1
    fi
    ;;
status)
    if ! rclone about "$REMOTE:" 2>/dev/null; then
        echo "Error: Cannot get remote status. Configure rclone first: rclone config"
        exit 1
    fi
    ;;
-h | --help | help)
    show_help
    ;;
*)
    echo "Unknown command: $1"
    show_help
    exit 1
    ;;
esac
