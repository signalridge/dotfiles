# shellcheck shell=bash
# ===== Utility Functions =====

# Track temp files for robust cleanup on interruption / early returns.
_TEMP_FILES=()

register_temp_file() {
    local path="$1"
    [[ -n "$path" ]] || return 0
    _TEMP_FILES+=("$path")
}

cleanup_registered_temp_files() {
    local path
    for path in "${_TEMP_FILES[@]}"; do
        [[ -n "$path" ]] && rm -f "$path" 2>/dev/null || true
    done
    _TEMP_FILES=()
}

# Log event to history
log_event() {
    local event="$1"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[$timestamp] $event" >>"$HISTORY_LOG"
}

# Canonicalize path for reliable prefix checks.
canonicalize_path() {
    local input_path="$1"

    if command -v realpath &>/dev/null; then
        realpath "$input_path" 2>/dev/null || return 1
        return 0
    fi

    if command -v python3 &>/dev/null; then
        python3 - "$input_path" <<'PY' 2>/dev/null || return 1
import os
import sys
print(os.path.realpath(sys.argv[1]))
PY
        return 0
    fi

    local parent base
    parent=$(dirname "$input_path")
    base=$(basename "$input_path")
    (
        cd "$parent" 2>/dev/null || exit 1
        printf '%s/%s\n' "$(pwd -P)" "$base"
    ) || return 1
}

# Convert a path into a $HOME-relative path (no leading slash).
# This is used for storing entries in backup-list.txt and as metadata keys.
# It intentionally does NOT require the target file to exist.
to_home_rel_path() {
    local input="$1"
    local path="$input"

    # Strip trailing CR (Windows line endings).
    path="${path%$'\r'}"

    # Expand common forms.
    if [[ "$path" == \~/* ]]; then
        path="$HOME/${path#~/}"
    fi

    # Defensive: if someone pasted backup-files/... into the list, accept it.
    if [[ "$path" == "$BACKUP_FILES_DIR/"* ]]; then
        path="${path#"$BACKUP_FILES_DIR"/}"
    fi

    # Absolute -> relative (must be under $HOME).
    if [[ "$path" == /* ]]; then
        if [[ "$path" == "$HOME/"* ]]; then
            path="${path#"$HOME"/}"
        else
            log_error "Only paths under \$HOME are supported: $input"
            return 1
        fi
    fi

    # Normalize leading ./ (can appear in manual edits).
    while [[ "$path" == "./"* ]]; do
        path="${path#./}"
    done

    # Reject empty / traversal.
    if [[ -z "$path" || "$path" == "." || "$path" == ".." ]]; then
        log_error "Invalid path: $input"
        return 1
    fi
    if [[ "$path" == "../"* || "$path" == *"/../"* || "$path" == *"/.." ]]; then
        log_error "Path traversal is not allowed: $input"
        return 1
    fi

    printf '%s\n' "$path"
}

to_home_abs_path() {
    local rel
    rel=$(to_home_rel_path "$1") || return 1
    printf '%s/%s\n' "$HOME" "$rel"
}

iter_backup_list_rel() {
    [[ -f "$BACKUP_LIST" ]] || return 0

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        # Skip accidental menu/UI artifacts if any were written to the file.
        [[ "$line" =~ \[0\;|Add\ Custom|File\ path|Tip: ]] && continue

        local rel
        rel=$(to_home_rel_path "$line") || continue
        printf '%s\n' "$rel"
    done <"$BACKUP_LIST"
}

iter_backup_list_abs() {
    while IFS= read -r rel; do
        [[ -z "$rel" ]] && continue
        printf '%s/%s\n' "$HOME" "$rel"
    done < <(iter_backup_list_rel)
}

backup_list_contains_rel() {
    local needle="$1"
    while IFS= read -r rel; do
        [[ "$rel" == "$needle" ]] && return 0
    done < <(iter_backup_list_rel)
    return 1
}

normalize_backup_list_file() {
    [[ -f "$BACKUP_LIST" ]] || return 0

    local tmp
    tmp=$(mktemp)
    register_temp_file "$tmp"
    iter_backup_list_rel | sort -u >"$tmp"

    if ! cmp -s "$tmp" "$BACKUP_LIST" 2>/dev/null; then
        mv "$tmp" "$BACKUP_LIST"
        return 0
    fi

    rm -f "$tmp"
}

migrate_metadata_keys_to_rel() {
    # Best-effort migration from legacy absolute keys ($HOME/...) to relative keys.
    # This reduces leaking absolute paths/usernames in backup-metadata.json.
    [[ -f "$METADATA_FILE" ]] || return 0
    command -v jq &>/dev/null || return 0

    local rels_json
    rels_json=$(iter_backup_list_rel | jq -Rcs 'split("\n") | map(select(length>0))') || return 0

    local tmp
    tmp=$(mktemp)
    register_temp_file "$tmp"
    if jq --arg home "$HOME" --argjson rels "$rels_json" '
        .files = (.files // {}) |

        # First pass: ensure every rel in backup-list uses a HOME-relative metadata key.
        (reduce $rels[] as $rel (.;
            ($suffix := ("/" + $rel)) |
            ($home_abs := ($home + $suffix)) |

            # Cross-machine support: old metadata keys may include a different home
            # (e.g. /Users/alice/...) but they should still end with "/<rel>".
            ($cand := (
                (.files | keys) |
                map(select(startswith("/") and endswith($suffix))) |
                .[0] // ""
            )) |

            if (.files[$rel] != null) then
                # Relative key already exists: drop any legacy duplicates.
                (if .files[$home_abs] != null then del(.files[$home_abs]) else . end) |
                (if ($cand != "" and $cand != $rel and $cand != $home_abs) then del(.files[$cand]) else . end)
            else
                if (.files[$home_abs] != null) then
                    .files[$rel] = .files[$home_abs] | del(.files[$home_abs])
                elif ($cand != "" and .files[$cand] != null) then
                    .files[$rel] = .files[$cand] | del(.files[$cand])
                else
                    .
                end
            end
        )) |

        # Second pass: migrate any remaining keys under the *current* $HOME to rel.
        (.files |= (reduce (keys[]) as $k (.;
            if ($k | startswith($home + "/")) then
                ($rel := ($k | ltrimstr($home + "/"))) |
                if .[$rel] == null then .[$rel] = .[$k] else . end |
                del(.[$k])
            else
                .
            end
        )))
    ' "$METADATA_FILE" >"$tmp" 2>/dev/null; then
        mv "$tmp" "$METADATA_FILE"
        return 0
    fi

    rm -f "$tmp"
}

# ===== Repo Control Files (backup-list / metadata) =====
#
# Design:
# - Plaintext working copies live locally in the repo but are gitignored:
#     - backup-list.txt
#     - backup-metadata.json
# - Encrypted versions are tracked and synced:
#     - backup-list.txt.enc
#     - backup-metadata.json.enc
#
# This keeps "select/add/remove (no password) -> sync (requires password)" workable,
# while ensuring the remote repo does not store these control files in plaintext.

ensure_gitignore_pattern() {
    local pattern="$1"
    local file="$2"
    grep -qxF "$pattern" "$file" 2>/dev/null || echo "$pattern" >>"$file"
}

ensure_repo_ignores_plain_control_files() {
    local gitignore="$REPO_DIR/.gitignore"
    touch "$gitignore"
    ensure_gitignore_pattern ".keys-manage/" "$gitignore"
    ensure_gitignore_pattern "backup-list.txt" "$gitignore"
    ensure_gitignore_pattern "backup-metadata.json" "$gitignore"
}

ensure_control_state_dir() {
    mkdir -p "$CONTROL_STATE_DIR"
    chmod 700 "$CONTROL_STATE_DIR" 2>/dev/null || true
}

read_control_baseline_hash() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    head -n 1 "$file" 2>/dev/null || true
}

write_control_baseline_hash() {
    local file="$1"
    local hash="$2"
    ensure_control_state_dir
    printf '%s\n' "$hash" >"$file"
    chmod 600 "$file" 2>/dev/null || true
}

control_conflict_policy() {
    local policy="${KEYS_MANAGE_CONTROL_CONFLICT_POLICY:-}"
    case "$policy" in
    local | remote | abort | prompt)
        printf '%s\n' "$policy"
        return 0
        ;;
    "")
        if [[ -t 0 ]]; then
            printf '%s\n' "prompt"
        else
            printf '%s\n' "abort"
        fi
        return 0
        ;;
    *)
        log_warn "Unknown KEYS_MANAGE_CONTROL_CONFLICT_POLICY=$policy (expected: local|remote|abort|prompt)"
        if [[ -t 0 ]]; then
            printf '%s\n' "prompt"
        else
            printf '%s\n' "abort"
        fi
        return 0
        ;;
    esac
}

decrypt_control_file_to_tmp() {
    local enc="$1"
    local password="$2"

    local tmp
    tmp=$(mktemp "${TMPDIR:-/tmp}/keys-control.XXXXXX")
    register_temp_file "$tmp"
    if decrypt_file "$enc" "$tmp" "$password" 2>/dev/null; then
        printf '%s\n' "$tmp"
        return 0
    fi
    rm -f "$tmp"
    return 1
}

validate_metadata_json_file() {
    local file="$1"
    command -v jq &>/dev/null || return 0
    jq empty "$file" 2>/dev/null
}

reconcile_plain_control_file_with_enc() {
    local plain="$1"
    local enc="$2"
    local label="$3"
    local password="$4"
    local validate_json="${5:-false}"

    [[ -f "$enc" ]] || return 0

    local tmp
    tmp=$(decrypt_control_file_to_tmp "$enc" "$password") || {
        log_error "Failed to decrypt $label (wrong password?)"
        return 1
    }

    if [[ "$validate_json" == true ]]; then
        if ! validate_metadata_json_file "$tmp"; then
            rm -f "$tmp"
            log_error "Decrypted $label is not valid JSON (repository may be corrupted)"
            return 1
        fi
    fi

    local baseline_file=""
    case "$label" in
    backup-list) baseline_file="$CONTROL_BASELINE_LIST" ;;
    metadata) baseline_file="$CONTROL_BASELINE_META" ;;
    esac
    local remote_hash=""
    remote_hash=$(calc_checksum "$tmp" 2>/dev/null || true)

    if [[ ! -f "$plain" ]]; then
        mv "$tmp" "$plain"
        chmod 600 "$plain" 2>/dev/null || true
        [[ -n "$baseline_file" && -n "$remote_hash" ]] && write_control_baseline_hash "$baseline_file" "$remote_hash"
        return 0
    fi

    if cmp -s "$tmp" "$plain" 2>/dev/null; then
        rm -f "$tmp"
        [[ -n "$baseline_file" && -n "$remote_hash" ]] && write_control_baseline_hash "$baseline_file" "$remote_hash"
        return 0
    fi

    # If the remote encrypted file hasn't changed since we last synced/unlocked it on this machine,
    # then a mismatch here is expected (local plaintext has pending edits). Avoid prompting.
    if [[ -n "$baseline_file" && -n "$remote_hash" ]]; then
        local baseline_hash
        baseline_hash=$(read_control_baseline_hash "$baseline_file")
        if [[ -n "$baseline_hash" && "$baseline_hash" == "$remote_hash" ]]; then
            rm -f "$tmp"
            return 0
        fi
    fi

    local policy
    policy=$(control_conflict_policy)

    case "$policy" in
    remote)
        log_warn "$label differs; accepting encrypted repo version (discarding local plaintext)"
        if [[ -f "$plain" ]]; then
            ensure_control_state_dir
            local conflict_dir="$CONTROL_STATE_DIR/conflicts"
            mkdir -p "$conflict_dir"
            chmod 700 "$conflict_dir" 2>/dev/null || true
            local ts backup_path
            ts=$(date +%Y%m%d-%H%M%S 2>/dev/null || echo "unknown")
            backup_path="$conflict_dir/$(basename "$plain").local.$ts"
            cp "$plain" "$backup_path" 2>/dev/null || true
            chmod 600 "$backup_path" 2>/dev/null || true
            log_note "Saved local $label to: $backup_path"
        fi
        mv "$tmp" "$plain"
        chmod 600 "$plain" 2>/dev/null || true
        [[ -n "$baseline_file" && -n "$remote_hash" ]] && write_control_baseline_hash "$baseline_file" "$remote_hash"
        return 0
        ;;
    local)
        log_warn "$label differs; keeping local plaintext (will overwrite remote on next sync)"
        rm -f "$tmp"
        return 0
        ;;
    abort)
        log_error "$label differs between local plaintext and encrypted repo state"
        echo "  Local: $plain"
        echo "  Repo:  $enc (encrypted)"
        rm -f "$tmp"
        return 1
        ;;
    prompt | *)
        if [[ ! -t 0 ]]; then
            log_error "$label differs but no TTY available to prompt. Set KEYS_MANAGE_CONTROL_CONFLICT_POLICY=local|remote|abort."
            rm -f "$tmp"
            return 1
        fi

        echo ""
        log_warn "$label differs between local plaintext and encrypted repo state"
        echo "  Local: $plain"
        echo "  Repo:  $enc (encrypted)"
        echo ""
        echo "Choose:"
        echo "  [L] Keep local (overwrite remote on next sync)"
        echo "  [R] Accept remote (discard local changes)"
        echo "  [D] Show diff and abort"
        echo ""
        local choice=""
        read -r -p "Your choice [L/R/D]: " choice || true

        case "$choice" in
        [Rr])
            if [[ -f "$plain" ]]; then
                ensure_control_state_dir
                local conflict_dir="$CONTROL_STATE_DIR/conflicts"
                mkdir -p "$conflict_dir"
                chmod 700 "$conflict_dir" 2>/dev/null || true
                local ts backup_path
                ts=$(date +%Y%m%d-%H%M%S 2>/dev/null || echo "unknown")
                backup_path="$conflict_dir/$(basename "$plain").local.$ts"
                cp "$plain" "$backup_path" 2>/dev/null || true
                chmod 600 "$backup_path" 2>/dev/null || true
                log_note "Saved local $label to: $backup_path"
            fi
            mv "$tmp" "$plain"
            chmod 600 "$plain" 2>/dev/null || true
            [[ -n "$baseline_file" && -n "$remote_hash" ]] && write_control_baseline_hash "$baseline_file" "$remote_hash"
            return 0
            ;;
        [Ll] | "")
            rm -f "$tmp"
            return 0
            ;;
        [Dd])
            if command -v diff &>/dev/null; then
                diff -u "$plain" "$tmp" | sed 's/^/  /' || true
            fi
            rm -f "$tmp"
            return 1
            ;;
        *)
            log_warn "Invalid choice; aborting"
            rm -f "$tmp"
            return 1
            ;;
        esac
        ;;
    esac
}

maybe_update_encrypted_control_file_from_plain() {
    local plain="$1"
    local enc="$2"
    local label="$3"
    local password="$4"
    local validate_json="${5:-false}"

    [[ -f "$plain" ]] || return 0

    if [[ "$validate_json" == true ]]; then
        if ! validate_metadata_json_file "$plain"; then
            log_error "Local $label is not valid JSON: $plain"
            return 1
        fi
    fi

    if [[ -f "$enc" ]]; then
        local tmp
        tmp=$(decrypt_control_file_to_tmp "$enc" "$password") || {
            log_error "Cannot decrypt existing $label (wrong password?)"
            return 1
        }
        if [[ "$validate_json" == true ]]; then
            if ! validate_metadata_json_file "$tmp"; then
                rm -f "$tmp"
                log_error "Encrypted $label decrypts to invalid JSON (repository may be corrupted)"
                return 1
            fi
        fi
        if cmp -s "$tmp" "$plain" 2>/dev/null; then
            rm -f "$tmp"
            return 0
        fi
        rm -f "$tmp"
    fi

    if encrypt_file "$plain" "$enc" "$password"; then
        # Update baseline to the current plaintext content. This avoids false conflicts
        # on the next run when we just regenerated the encrypted control file locally.
        local baseline_file=""
        case "$label" in
        backup-list) baseline_file="$CONTROL_BASELINE_LIST" ;;
        metadata) baseline_file="$CONTROL_BASELINE_META" ;;
        esac
        local plain_hash
        plain_hash=$(calc_checksum "$plain" 2>/dev/null || true)
        [[ -n "$baseline_file" && -n "$plain_hash" ]] && write_control_baseline_hash "$baseline_file" "$plain_hash"
        return 0
    fi
    return 1
}

migrate_plain_control_files_to_gitignored() {
    # Legacy repos tracked backup-list.txt / backup-metadata.json in plaintext.
    # We remove them from the index (keep working copy), and track only .enc files.
    local changed=false

    if git ls-files --error-unmatch "backup-list.txt" &>/dev/null; then
        git rm --cached -f "backup-list.txt" &>/dev/null || true
        changed=true
    fi
    if git ls-files --error-unmatch "backup-metadata.json" &>/dev/null; then
        git rm --cached -f "backup-metadata.json" &>/dev/null || true
        changed=true
    fi

    $changed && return 0
    return 1
}

ensure_control_files_ready() {
    local password="$1"

    ensure_repo_ignores_plain_control_files

    # If repo has encrypted control files, ensure local plaintext exists and matches policy.
    reconcile_plain_control_file_with_enc "$BACKUP_LIST" "$BACKUP_LIST_ENC" "backup-list" "$password" false
    reconcile_plain_control_file_with_enc "$METADATA_FILE" "$METADATA_FILE_ENC" "metadata" "$password" true

    # Ensure local working copies exist (even for brand new repos).
    touch "$BACKUP_LIST"
    chmod 600 "$BACKUP_LIST" 2>/dev/null || true
    [[ -f "$METADATA_FILE" ]] || init_metadata
    chmod 600 "$METADATA_FILE" 2>/dev/null || true
}

ensure_control_files_encrypted_for_commit() {
    local password="$1"

    ensure_control_files_ready "$password" || return 1

    normalize_backup_list_file
    migrate_metadata_keys_to_rel

    maybe_update_encrypted_control_file_from_plain "$BACKUP_LIST" "$BACKUP_LIST_ENC" "backup-list" "$password" false
    maybe_update_encrypted_control_file_from_plain "$METADATA_FILE" "$METADATA_FILE_ENC" "metadata" "$password" true
}

# Convert absolute path to backup path (relative to $HOME)
# Usage: get_backup_path "/Users/user/.ssh/main" -> "backup-files/.ssh/main"
get_backup_path() {
    local file="$1"
    local canonical_file canonical_home
    canonical_file=$(canonicalize_path "$file") || {
        log_error "Invalid path: $file"
        return 1
    }
    canonical_home=$(canonicalize_path "$HOME") || {
        log_error "Cannot resolve HOME path: $HOME"
        return 1
    }

    # Validate file is under canonical $HOME
    if [[ "$canonical_file" != "$canonical_home/"* ]]; then
        log_error "Only files under $HOME can be backed up: $file"
        return 1
    fi

    # Convert absolute path to relative path under $HOME
    local rel_path="${canonical_file#"$canonical_home"/}"
    echo "$BACKUP_FILES_DIR/$rel_path"
}

# Convert backup path to absolute path
# Usage: get_absolute_path "backup-files/.ssh/main" -> "/Users/user/.ssh/main"
get_absolute_path() {
    local backup_path="$1"
    local rel_path="${backup_path#"$BACKUP_FILES_DIR"/}"
    echo "$HOME/$rel_path"
}

# ===== File Discovery & Filtering =====

# Discover key/certificate files from common directories
discover_key_files() {
    # Common directories for keys and certificates
    local key_dirs=(
        "$HOME/.ssh"        # SSH keys
        "$HOME/.gnupg"      # GPG keys
        "$HOME/.config/age" # OpenSSL PBKDF2 encryption keys
    )

    for dir in "${key_dirs[@]}"; do
        [[ ! -d "$dir" ]] && continue

        find "$dir" -type f -print0 2>/dev/null | while IFS= read -r -d $'\0' file; do
            # Skip noisy/host-specific files.
            [[ ! "$file" =~ known_hosts ]] &&
                [[ ! "$file" =~ authorized_keys ]] &&
                [[ ! "$file" =~ \.lock$ ]] &&
                echo "$file"
        done
    done | sort -u
}

# Discover all files under $HOME for fzf fallback when yazi is unavailable.
# This intentionally prunes the biggest/least-useful trees to keep selection usable.
discover_home_files() {
    if command -v fd &>/dev/null; then
        fd -a -t f -H \
            --exclude '.git' \
            --exclude 'node_modules' \
            --exclude '.cache' \
            --exclude '.Trash' \
            --exclude '.local/share/keys-backup' \
            . "$HOME" 2>/dev/null || true
        return 0
    fi

    # Portable fallback (slower than fd).
    find "$HOME" \
        \( -name '.git' -o -name 'node_modules' -o -name '.cache' -o -name '.Trash' -o -path "$REPO_DIR" -o -path "$REPO_DIR/*" \) -prune -o \
        -type f -print 2>/dev/null || true
}

# Get key type from file
detect_key_type() {
    local file="$1"
    [[ ! -f "$file" ]] && {
        echo "unknown"
        return
    }

    local first_line
    first_line=$(head -n1 "$file" 2>/dev/null)

    # Use variables to avoid chezmoi template parsing issues
    local openssh_key="BEGIN OPENSSH PRIVATE""KEY"
    local rsa_key="BEGIN RSA PRIVATE""KEY"
    local ec_key="BEGIN EC PRIVATE""KEY"
    local dsa_key="BEGIN DSA PRIVATE""KEY"

    case "$first_line" in
    *"$openssh_key"*)
        if grep -q "ssh-ed25519" "$file"; then
            echo "Ed25519"
        elif grep -q "ecdsa" "$file"; then
            echo "ECDSA"
        else
            echo "OpenSSH"
        fi
        ;;
    *"$rsa_key"*) echo "RSA" ;;
    *"$ec_key"*) echo "ECDSA" ;;
    *"$dsa_key"*) echo "DSA" ;;
    "Host "*) echo "SSH Config" ;;
    *) echo "unknown" ;;
    esac
}

# ===== Checksum & Change Detection =====

# Detect if file has changed since last backup
detect_changes() {
    local file="$1"
    local password="${2:-}"
    [[ ! -f "$file" ]] && return 0 # Missing file = changed

    # Must be in git repo to detect changes
    cd "$REPO_DIR" 2>/dev/null || return 0

    # Get backup path using new structure
    local backup_file
    backup_file=$(get_backup_path "$file") || return 0

    # Check if file exists in git HEAD
    if ! git cat-file -e "HEAD:$backup_file" 2>/dev/null; then
        return 0 # File not in git = new file
    fi

    # Fast path: Compare with metadata (avoids decryption)
    local current_hash
    current_hash=$(calc_checksum "$file")

    if [[ -f "$METADATA_FILE" ]]; then
        local metadata_hash
        local meta_key
        meta_key=$(to_home_rel_path "$file" 2>/dev/null || true)
        if [[ -n "$meta_key" ]]; then
            metadata_hash=$(jq -r --arg path "$meta_key" '.files[$path].sha256 // empty' "$METADATA_FILE" 2>/dev/null)
        else
            metadata_hash=""
        fi

        # Backward compatibility: legacy metadata keyed by absolute path.
        if [[ -z "$metadata_hash" ]]; then
            metadata_hash=$(jq -r --arg path "$file" '.files[$path].sha256 // empty' "$METADATA_FILE" 2>/dev/null)
        fi

        if [[ -n "$metadata_hash" ]]; then
            # Metadata exists, compare directly (no decryption needed)
            [[ "$current_hash" != "$metadata_hash" ]] && return 0 || return 1
        fi
    fi

    # Slow path (fallback): Decrypt and compare
    # This happens when:
    # - No metadata file exists
    # - File not in metadata (legacy backups)
    local backup_hash
    local temp_encrypted temp_decrypted
    temp_encrypted=$(mktemp "${TMPDIR:-/tmp}/keys-detect.XXXXXX.enc")
    temp_decrypted=$(mktemp "${TMPDIR:-/tmp}/keys-detect.XXXXXX")
    register_temp_file "$temp_encrypted"
    register_temp_file "$temp_decrypted"

    if git show "HEAD:$backup_file" >"$temp_encrypted" 2>/dev/null; then
        if decrypt_file "$temp_encrypted" "$temp_decrypted" "$password" 2>/dev/null; then
            backup_hash=$(calc_checksum "$temp_decrypted")
        else
            # Decryption failed, assume changed
            rm -f "$temp_encrypted" "$temp_decrypted"
            return 0
        fi
    else
        # Cannot get backup file, assume changed
        rm -f "$temp_encrypted" "$temp_decrypted"
        return 0
    fi

    if [[ "$current_hash" != "$backup_hash" ]]; then
        rm -f "$temp_encrypted" "$temp_decrypted"
        return 0
    fi

    rm -f "$temp_encrypted" "$temp_decrypted"
    return 1
}

# Get file status (for display)
get_file_status() {
    local file="$1"
    local backed_up=false

    # Check if in backup list
    if [[ -f "$BACKUP_LIST" ]]; then
        local rel
        rel=$(to_home_rel_path "$file" 2>/dev/null || true)
        if [[ -n "$rel" ]] && backup_list_contains_rel "$rel"; then
            backed_up=true
        fi
    fi

    if [[ "$backed_up" == true ]]; then
        if detect_changes "$file"; then
            echo "${YELLOW}⚠${NC}" # Modified
        else
            echo "${GREEN}✓${NC}" # Up to date
        fi
    else
        if [[ -f "$METADATA_FILE" ]]; then
            local rel
            rel=$(to_home_rel_path "$file" 2>/dev/null || true)
            if [[ -n "$rel" ]] && jq -e --arg path "$rel" '.files[$path] // empty' "$METADATA_FILE" &>/dev/null; then
                echo "${RED}⊗${NC}" # Removed from list
            elif jq -e --arg path "$file" '.files[$path] // empty' "$METADATA_FILE" &>/dev/null; then
                echo "${RED}⊗${NC}" # Removed from list (legacy absolute key)
            else
                echo "${CYAN}⊕${NC}" # New file
            fi
        else
            echo "${CYAN}⊕${NC}" # New file
        fi
    fi
}

# ===== Metadata Management =====

# Initialize metadata file
init_metadata() {
    cat >"$METADATA_FILE" <<EOF
{
  "version": $VERSION,
  "filters": {
    "include_patterns": ["*"],
    "exclude_patterns": ["known_hosts*", "authorized_keys*"],
    "custom_paths": []
  },
  "files": {}
}
EOF
    log_event "Initialized metadata v2"
}

# Update file metadata after backup
update_file_metadata() {
    local file="$1"
    [[ ! -f "$file" ]] && return 1
    [[ ! -f "$METADATA_FILE" ]] && init_metadata

    local key abs_key
    key=$(to_home_rel_path "$file") || return 1
    abs_key="$file"
    if [[ "$abs_key" != /* ]]; then
        abs_key="$HOME/$key"
    fi

    local hash size mtime permissions now count
    hash=$(calc_checksum "$file")
    size=$(get_file_size "$file")
    mtime=$(get_file_mtime "$file")
    # Get file permissions in octal format (e.g., "644", "600")
    permissions=$(stat -f "%Lp" "$file" 2>/dev/null || stat -c "%a" "$file" 2>/dev/null)

    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    count=$(jq -r --arg key "$key" --arg abs "$abs_key" '.files[$key].backup_count // .files[$abs].backup_count // 0' "$METADATA_FILE")
    count=$((count + 1))

    local tmp
    tmp=$(mktemp)
    register_temp_file "$tmp"
    jq \
        --arg key "$key" \
        --arg abs "$abs_key" \
        --arg hash "$hash" \
        --argjson size "$size" \
        --argjson mtime "$mtime" \
        --arg permissions "$permissions" \
        --arg now "$now" \
        --argjson count "$count" \
        '(.files[$key] = {
            "sha256": $hash,
            "size": $size,
            "mtime": $mtime,
            "permissions": $permissions,
            "last_backup": $now,
            "backup_count": $count
        }) | (if $abs != $key then del(.files[$abs]) else . end)' \
        "$METADATA_FILE" >"$tmp"
    mv "$tmp" "$METADATA_FILE"
}

# Remove file metadata from JSON
remove_file_metadata() {
    local file="$1"
    [[ ! -f "$METADATA_FILE" ]] && return 0

    local key abs_key
    key=$(to_home_rel_path "$file" 2>/dev/null || true)
    if [[ -n "$key" ]]; then
        abs_key="$file"
        if [[ "$abs_key" != /* ]]; then
            abs_key="$HOME/$key"
        fi
    else
        # If we can't normalize, treat the input as-is.
        key="$file"
        abs_key="$file"
    fi

    local tmp
    tmp=$(mktemp)
    register_temp_file "$tmp"
    if jq --arg key "$key" --arg abs "$abs_key" 'del(.files[$key]) | del(.files[$abs])' "$METADATA_FILE" >"$tmp" 2>/dev/null; then
        mv "$tmp" "$METADATA_FILE"
        return 0
    else
        rm -f "$tmp"
        return 1
    fi
}

# Get file metadata from JSON
get_file_info() {
    local file="$1"
    local field="$2"
    [[ ! -f "$METADATA_FILE" ]] && return 1

    local key abs_key
    key=$(to_home_rel_path "$file" 2>/dev/null || true)
    abs_key="$file"
    if [[ -n "$key" ]] && [[ "$abs_key" != /* ]]; then
        abs_key="$HOME/$key"
    fi

    local value=""
    if [[ -n "$key" ]]; then
        value=$(jq -r --arg path "$key" --arg field "$field" '.files[$path] | .[$field] // empty' "$METADATA_FILE" 2>/dev/null || true)
    fi
    if [[ -z "$value" ]]; then
        value=$(jq -r --arg path "$abs_key" --arg field "$field" '.files[$path] | .[$field] // empty' "$METADATA_FILE" 2>/dev/null || true)
    fi
    printf '%s\n' "$value"
}

# ===== FZF Builders =====

# Multi-select FZF wrapper
fzf_multi_select() {
    local header="$1"
    local preview="${2:-}"

    local fzf_opts=(
        --height=50%
        --border=rounded
        --ansi
        --multi
        --header="$header"
        --bind='ctrl-a:select-all'
        --bind='ctrl-d:deselect-all'
        --bind='ctrl-/:toggle-preview'
    )

    if [[ -n "$preview" ]]; then
        fzf_opts+=(--preview="$preview" --preview-window='right:50%:wrap:border-left')
    fi

    fzf "${fzf_opts[@]}"
}

# FZF file preview script
# shellcheck disable=SC2034 # Used by fzf preview in backup.sh
FILE_PREVIEW='
    line=$(echo {} | sed "s/^[[:space:]]*//" | sed "s/^[✓⚠⊕⊗○] //")
    file="$line"

    echo -e "\033[1;34m━━━ File Info ━━━\033[0m"
    echo ""
    echo "Path: $file"

    if [[ -f "$file" ]]; then
        # File metadata
        if stat -f%z "$file" &>/dev/null 2>&1; then
            # macOS
            size=$(stat -f%z "$file")
            mtime=$(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file")
            perms=$(stat -f%Sp "$file")
        else
            # Linux
            size=$(stat -c%s "$file")
            mtime=$(stat -c%y "$file" | cut -d. -f1)
            perms=$(stat -c%A "$file")
        fi
        echo "Size: $size bytes"
        echo "Modified: $mtime"
        echo "Permissions: $perms"

        # Key type detection
        keytype=$('"$(declare -f detect_key_type)"'; detect_key_type "$file")
        echo "Type: $keytype"

        # Show backup status if metadata exists
        meta_file="'"$METADATA_FILE"'"
        if [[ -f "$meta_file" ]]; then
            # Prefer HOME-relative metadata keys; fallback to legacy absolute keys.
            meta_key="$file"
            if [[ "$meta_key" == "$HOME/"* ]]; then
                meta_key="${meta_key#"$HOME"/}"
            fi
            last_backup=$(jq -r --arg path "$meta_key" ".files[\$path].last_backup // empty" "$meta_file" 2>/dev/null)
            backup_count=$(jq -r --arg path "$meta_key" ".files[\$path].backup_count // 0" "$meta_file" 2>/dev/null)
            if [[ -z "$last_backup" ]]; then
                last_backup=$(jq -r --arg path "$file" ".files[\$path].last_backup // empty" "$meta_file" 2>/dev/null)
                backup_count=$(jq -r --arg path "$file" ".files[\$path].backup_count // 0" "$meta_file" 2>/dev/null)
            fi
            if [[ -n "$last_backup" ]]; then
                echo ""
                echo -e "\033[1;34m━━━ Backup Info ━━━\033[0m"
                echo "Last backup: $last_backup"
                echo "Backup count: $backup_count"
            fi
        fi

        # Preview first 10 lines
        echo ""
        echo -e "\033[1;34m━━━ Preview ━━━\033[0m"
        head -n 10 "$file" 2>/dev/null || echo "(binary or unreadable)"
    else
        echo ""
        echo -e "\033[0;31m✗ File not found\033[0m"
    fi
'

# Helper function to select custom files using FZF file browser
# Browse filesystem with yazi (file manager)
yazi_select_files() {
    if ! command -v yazi &>/dev/null; then
        log_error "yazi not found. Install with: brew install yazi"
        return 1
    fi

    # Create temp file for yazi output
    local tmpfile
    tmpfile=$(mktemp)
    register_temp_file "$tmpfile"

    # Launch yazi with explicit tty redirection
    # This ensures yazi can access the terminal even when called from within FZF
    yazi --chooser-file="$tmpfile" "$HOME" </dev/tty >/dev/tty 2>&1 || {
        rm -f "$tmpfile"
        echo "" >&2
        log_warn "File selection cancelled"
        return "$RC_BACK"
    }

    # Read selected files
    local selected_files
    selected_files=$(cat "$tmpfile" 2>/dev/null)
    rm -f "$tmpfile"

    if [[ -z "$selected_files" ]]; then
        echo "" >&2
        log_warn "No files selected"
        return "$RC_BACK"
    fi

    # Filter out directories - only allow regular files
    local valid_files=""
    local invalid_items=()
    local outside_home_items=()
    while IFS= read -r path; do
        if [[ "$path" != "$HOME/"* ]]; then
            outside_home_items+=("$path")
        elif [[ -f "$path" ]]; then
            valid_files="${valid_files}${path}"$'\n'
        elif [[ -d "$path" ]]; then
            invalid_items+=("$path")
        fi
    done <<<"$selected_files"

    # Remove trailing newline
    valid_files="${valid_files%$'\n'}"

    # If some directories were selected, show detailed warning
    if [[ ${#invalid_items[@]} -gt 0 ]]; then
        echo "" >&2
        log_warn "Cannot backup directories (only files are supported):"
        for item in "${invalid_items[@]}"; do
            echo "  • $item" >&2
        done
        echo "" >&2
    fi

    if [[ ${#outside_home_items[@]} -gt 0 ]]; then
        echo "" >&2
        log_warn "Cannot backup files outside \$HOME:"
        for item in "${outside_home_items[@]}"; do
            echo "  • $item" >&2
        done
        echo "" >&2
    fi

    # If no valid files but had invalid items, give helpful message
    if [[ -z "$valid_files" ]]; then
        if [[ ${#invalid_items[@]} -gt 0 ]] || [[ ${#outside_home_items[@]} -gt 0 ]]; then
            log_error "No valid files selected"
            echo "Tip: Select regular files under $HOME" >&2
        else
            log_warn "No files selected"
        fi
        return "$RC_BACK"
    fi

    # Return selected files
    echo "$valid_files"
}

# ===== Git Operations =====

# Check git sync status with remote
# Returns: 0=in sync, 1=ahead, 2=behind, 3=diverged, 4=no remote, 5=offline
check_git_sync_status() {
    local ahead behind

    if ! git remote get-url origin &>/dev/null; then
        log_warn "No remote 'origin' configured"
        return 4
    fi

    # Fetch remote without pulling
    local fetch_timeout ssh_cmd
    fetch_timeout="${KEYS_GIT_FETCH_TIMEOUT_SEC:-12}"
    ssh_cmd="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes -o ConnectTimeout=8}"
    run_with_timeout "$fetch_timeout" env GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="$ssh_cmd" \
        git fetch origin --quiet 2>/dev/null || {
        log_warn "Cannot fetch from remote (offline, no access, or timeout after ${fetch_timeout}s)"
        return 5
    }

    # Resolve upstream reference safely.
    local upstream
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)

    if [[ -z "$upstream" ]]; then
        local branch
        branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)
        if [[ -n "$branch" ]] && git rev-parse --verify --quiet "origin/$branch" >/dev/null; then
            upstream="origin/$branch"
        else
            echo "no-upstream"
            return 0
        fi
    fi

    # Get ahead/behind counts
    local counts
    counts=$(git rev-list --left-right --count "HEAD...$upstream" 2>/dev/null || echo "0 0")
    ahead=$(echo "$counts" | awk '{print $1}')
    behind=$(echo "$counts" | awk '{print $2}')

    if [[ $ahead -gt 0 ]] && [[ $behind -gt 0 ]]; then
        echo "diverged:$ahead:$behind"
        return 3
    elif [[ $ahead -gt 0 ]]; then
        echo "ahead:$ahead"
        return 1
    elif [[ $behind -gt 0 ]]; then
        echo "behind:$behind"
        return 2
    else
        echo "in-sync"
        return 0
    fi
}

# Sync repository with remote (pull if needed)
sync_with_remote() {
    local require_online=false
    if [[ "${1:-}" == "--require-online" ]]; then
        require_online=true
        shift || true
    fi

    local status_info=""
    local status_code=0
    status_info=$(check_git_sync_status) || status_code=$?

    case $status_code in
    0) # In sync
        if [[ "$status_info" == "no-upstream" ]]; then
            log_warn "No upstream tracking branch configured; pull check skipped"
        fi
        return 0
        ;;
    1) # Ahead of remote
        local ahead
        ahead=$(echo "$status_info" | cut -d: -f2)
        log_warn "Local repository is $ahead commit(s) ahead of remote"
        echo "  You have unpushed changes. They will be pushed with the next backup."
        return 0
        ;;
    2) # Behind remote
        local behind
        behind=$(echo "$status_info" | cut -d: -f2)
        log_info "Pulling $behind new commit(s) from remote..."
        if safe_git_pull; then
            log_success "Updated from remote"
            return 0
        else
            log_error "Failed to pull from remote"
            echo "  Possible causes:"
            echo "  - Merge conflicts"
            echo "  - Non-fast-forward changes"
            echo ""
            echo "  To fix:"
            echo "  - Run: cd $REPO_DIR && git pull"
            echo "  - Resolve any conflicts manually"
            return 1
        fi
        ;;
    3) # Diverged
        local ahead behind
        ahead=$(echo "$status_info" | cut -d: -f2)
        behind=$(echo "$status_info" | cut -d: -f3)
        log_error "Repository has diverged from remote"
        echo "  Local: $ahead commit(s) ahead"
        echo "  Remote: $behind commit(s) ahead"
        echo ""
        echo "  To fix (choose one):"
        echo "  1. Merge: cd $REPO_DIR && git pull"
        echo "  2. Rebase: cd $REPO_DIR && git pull --rebase"
        return 1
        ;;
    4) # Cannot reach remote
        log_error "No remote 'origin' configured"
        echo "  Configure remote first: cd $REPO_DIR && git remote add origin <repo-url>"
        return 1
        ;;
    5) # Offline / unreachable remote
        if [[ "$require_online" == true ]]; then
            log_error "Cannot reach remote (offline or no access)"
            return 1
        fi
        log_warn "Working offline (cannot reach remote)"
        return 0
        ;;
    *)
        log_error "Unknown git sync state: $status_code"
        return 1
        ;;
    esac
}

# Safe git commit with error handling
safe_git_commit() {
    local commit_msg="$1"
    local commit_output
    commit_output=$(mktemp)
    register_temp_file "$commit_output"

    if git commit -m "$commit_msg" 2>"$commit_output"; then
        rm -f "$commit_output"
        return 0
    fi

    # Commit failed - analyze error
    local error_content
    error_content=$(cat "$commit_output" 2>/dev/null)
    rm -f "$commit_output"

    if echo "$error_content" | grep -q "nothing to commit"; then
        log_warn "Nothing to commit"
        return 1
    else
        log_error "Git commit failed"
        echo ""
        echo "Git error:"
        echo "$error_content" | sed 's/^/  /'
        return 1
    fi
}

# Safe git push with error handling
safe_git_push() {
    local push_output
    push_output=$(mktemp)
    register_temp_file "$push_output"

    echo -n "Pushing to remote... "
    local push_timeout ssh_cmd
    push_timeout="${KEYS_GIT_PUSH_TIMEOUT_SEC:-30}"
    ssh_cmd="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes -o ConnectTimeout=8}"
    if run_with_timeout "$push_timeout" env GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="$ssh_cmd" \
        git push 2>"$push_output"; then
        echo "✓"
        rm -f "$push_output"
        return 0
    fi

    echo "✗"
    echo ""

    # Analyze push error
    local error_content
    error_content=$(cat "$push_output" 2>/dev/null)
    rm -f "$push_output"

    if echo "$error_content" | grep -q "non-fast-forward\|rejected"; then
        log_error "Push rejected (non-fast-forward)"
        echo ""
        echo "  Remote has changes you don't have locally."
        echo ""
        echo "  To fix:"
        echo "  1. Pull first: cd $REPO_DIR && git pull"
        echo "  2. Resolve any conflicts"
        echo "  3. Run backup again"
        return 1
    elif echo "$error_content" | grep -q "Authentication\|Permission denied"; then
        log_error "Authentication failed"
        echo ""
        echo "  Cannot push to remote (permission denied)"
        echo ""
        echo "  To fix:"
        echo "  - Check SSH key: ssh -T git@github.com"
        echo "  - Verify repository access rights"
        return 1
    else
        log_error "Push failed"
        echo ""
        echo "Git error:"
        echo "$error_content" | sed 's/^/  /'
        return 1
    fi
}

# Safe git pull with error handling
safe_git_pull() {
    local pull_output
    pull_output=$(mktemp)
    register_temp_file "$pull_output"

    local pull_timeout ssh_cmd
    pull_timeout="${KEYS_GIT_PULL_TIMEOUT_SEC:-30}"
    ssh_cmd="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes -o ConnectTimeout=8}"
    if run_with_timeout "$pull_timeout" env GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="$ssh_cmd" \
        git pull --quiet --ff-only 2>"$pull_output"; then
        rm -f "$pull_output"
        return 0
    fi

    # Pull failed - analyze error
    local error_content
    error_content=$(cat "$pull_output" 2>/dev/null)
    rm -f "$pull_output"

    if echo "$error_content" | grep -q "no tracking\|no remote"; then
        # No remote configured, not an error
        return 0
    else
        log_warn "Pull failed"
        echo "$error_content" | sed 's/^/  /'
        return 1
    fi
}

# Commit backup changes to git
# Consolidates the common pattern: git add + commit
commit_backup_changes() {
    local message="$1"

    local password
    password=$(get_encryption_password) || {
        log_error "Cannot proceed without password"
        return 1
    }

    ensure_control_files_encrypted_for_commit "$password" || return 1

    # Ensure plaintext control files are not tracked (legacy repo migration).
    migrate_plain_control_files_to_gitignored >/dev/null 2>&1 || true

    git add -A backup-files/ backup-list.txt.enc backup-metadata.json.enc .gitignore 2>/dev/null || true

    if safe_git_commit "$message"; then
        log_success "Changes committed: $message"
        return 0
    else
        log_error "Failed to commit changes"
        return 1
    fi
}

# ===== Directory Management =====

# Ensure local directory exists (without git initialization)
# Used by select/add/remove commands that only need local storage
ensure_local_dir() {
    if [[ -d "$REPO_DIR" ]]; then
        return 0
    fi

    log_info "Creating local backup directory..."
    mkdir -p "$REPO_DIR"

    # Initialize metadata if it doesn't exist
    if [[ ! -f "$METADATA_FILE" ]]; then
        init_metadata
    fi

    log_success "Local directory ready: $REPO_DIR"
    echo ""
    log_note "Run 'keys-manage init' before backing up to initialize git repository"
}

# Ensure repository is initialized and change to repo directory
# Consolidates the common pattern: init_repo_if_needed + cd
require_repo_and_cd() {
    init_repo_if_needed || {
        log_error "Failed to initialize repository"
        return 1
    }

    cd "$REPO_DIR" || {
        log_error "Failed to change directory to $REPO_DIR"
        return 1
    }
}

# ===== OpenSSL Encryption =====

# Cached password for the current session
_CACHED_PASSWORD=""

# Get encryption password from cache, environment, gopass, or prompt
get_encryption_password() {
    # 1. Return cached password if available
    if [[ -n "$_CACHED_PASSWORD" ]]; then
        echo "$_CACHED_PASSWORD"
        return 0
    fi

    # 2. Check environment variable (for CI/CD automation)
    if [[ -n "${KEYS_BACKUP_PASSWORD:-}" ]]; then
        _CACHED_PASSWORD="$KEYS_BACKUP_PASSWORD"
        echo "$_CACHED_PASSWORD"
        return 0
    fi

    # 3. Try to get from gopass
    if command -v gopass &>/dev/null; then
        local gopass_password
        gopass_password=$(gopass show -o keys-manage/password 2>/dev/null)

        if [[ -n "$gopass_password" ]]; then
            _CACHED_PASSWORD="$gopass_password"
            echo "$_CACHED_PASSWORD"
            return 0
        fi
    fi

    # 4. Prompt user (only once per session)
    local password
    read -rsp "Enter backup encryption password: " password
    echo "" >&2

    if [[ -z "$password" ]]; then
        log_error "Password cannot be empty"
        return 1
    fi

    _CACHED_PASSWORD="$password"

    # Ask if user wants to save to gopass
    if command -v gopass &>/dev/null; then
        echo "" >&2
        read -rp "Save password to gopass for future use? (Y/n): " save_choice

        if [[ -z "$save_choice" ]] || [[ "$save_choice" =~ ^[Yy]$ ]]; then
            if echo "$password" | gopass insert -f keys-manage/password 2>/dev/null; then
                log_success "Password saved to gopass (keys-manage/password)" >&2
            else
                log_warn "Failed to save to gopass" >&2
            fi
        fi
    fi

    echo "$_CACHED_PASSWORD"
    return 0
}

# Clear cached password
clear_password_cache() {
    _CACHED_PASSWORD=""
}

# Encrypt file using OpenSSL PBKDF2
# Usage: encrypt_file <source> <destination> [password]
encrypt_file() {
    local source="$1"
    local dest="$2"
    local password="${3:-}"

    [[ ! -f "$source" ]] && {
        log_error "Source file not found: $source"
        return 1
    }

    # Get password if not provided
    if [[ -z "$password" ]]; then
        password=$(get_encryption_password) || {
            log_error "Failed to get encryption password"
            return 1
        }
    fi

    mkdir -p "$(dirname "$dest")"

    # OpenSSL AES-256-CBC with PBKDF2 (100,000 iterations)
    # -salt: Add random salt for security (makes each encryption unique)
    # -pbkdf2 -iter 100000: Use PBKDF2 with 100k iterations (recommended)
    # Note: Random salt means same file encrypts differently each time (this is good!)
    if openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
        -pass fd:3 -in "$source" -out "$dest" 3<<<"$password" 2>/dev/null; then
        chmod 600 "$dest"
        return 0
    else
        log_error "Failed to encrypt file"
        return 1
    fi
}

# Decrypt file using OpenSSL PBKDF2
# Usage: decrypt_file <source> <destination> [password]
# Note: Does NOT modify file permissions - caller is responsible for setting correct permissions
decrypt_file() {
    local source="$1"
    local dest="$2"
    local password="${3:-}"

    [[ ! -f "$source" ]] && {
        log_error "Source file not found: $source"
        return 1
    }

    # Get password if not provided
    if [[ -z "$password" ]]; then
        password=$(get_encryption_password) || {
            log_error "Failed to get encryption password"
            return 1
        }
    fi

    mkdir -p "$(dirname "$dest")"

    # Decrypt using same parameters (permissions unchanged)
    if openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 \
        -pass fd:3 -in "$source" -out "$dest" 3<<<"$password" 2>/dev/null; then
        return 0
    else
        log_error "Failed to decrypt file (wrong password?)"
        return 1
    fi
}

# Initialize repository if needed
init_repo_if_needed() {
    # If git repo already exists, sync with remote and return
    if [[ -d "$REPO_DIR/.git" ]]; then
        cd "$REPO_DIR" || {
            log_error "Failed to change directory to $REPO_DIR"
            return 1
        }
        sync_with_remote || {
            log_error "Cannot sync with remote - please resolve conflicts first"
            return 1
        }
        return 0
    fi

    # If directory exists but no git (created by ensure_local_dir), run init
    if [[ -d "$REPO_DIR" ]] && [[ ! -d "$REPO_DIR/.git" ]]; then
        log_info "Local directory exists, initializing git repository..."
        echo ""
        # Provide instructions to initialize
        log_warn "Please run 'keys-manage init' first to initialize the git repository"
        return 1
    fi

    # Directory doesn't exist at all - this shouldn't happen normally
    # as both ensure_local_dir and init should create it
    echo -e "${BLUE}Cloning keys repository...${NC}"
    git clone "$KEYS_REPO" "$REPO_DIR" || {
        echo -e "${RED}Error:${NC} Failed to clone repository" >&2
        return 1
    }

    cd "$REPO_DIR" || {
        log_error "Failed to change directory to $REPO_DIR"
        return 1
    }
    log_event "Repository initialized"
}

# ===== Backup Operations =====

# Backup single file
backup_file() {
    local file="$1"
    local password="${2:-}"
    [[ ! -f "$file" ]] && return 1

    # Get backup path using new structure
    local backup_file
    backup_file=$(get_backup_path "$file") || return 1

    # Encrypt and store the file
    if ! encrypt_file "$file" "$REPO_DIR/$backup_file" "$password"; then
        log_error "Failed to encrypt: $file"
        return 1
    fi
}

# ===== Verification =====

# Verify file integrity
verify_file() {
    local file="$1"
    local password="${2:-}"
    [[ ! -f "$file" ]] && return 1

    # Get backup path using new structure
    local backup_path
    backup_path=$(get_backup_path "$file") || return 1
    local backup_file="$REPO_DIR/$backup_path"
    [[ ! -f "$backup_file" ]] && return 2

    # Decrypt backup file to temp location for comparison
    local temp_decrypted
    temp_decrypted=$(mktemp "${TMPDIR:-/tmp}/keys-verify.XXXXXX")
    register_temp_file "$temp_decrypted"
    if ! decrypt_file "$backup_file" "$temp_decrypted" "$password" 2>/dev/null; then
        rm -f "$temp_decrypted"
        return 3 # Decryption failed
    fi

    local local_hash backup_hash
    local_hash=$(calc_checksum "$file")
    backup_hash=$(calc_checksum "$temp_decrypted")

    if [[ "$local_hash" == "$backup_hash" ]]; then
        rm -f "$temp_decrypted"
        return 0
    fi

    rm -f "$temp_decrypted"
    return 1
}

# ===== Git Version Helpers =====

# Get commit list with formatting
get_commit_list() {
    cd "$REPO_DIR" || {
        log_error "Failed to change directory to $REPO_DIR"
        return 1
    }
    git log --oneline --format="%C(yellow)%h%C(reset) %C(green)%ad%C(reset) %s" \
        --date=relative -- backup-files/ backup-list.txt.enc backup-metadata.json.enc
}

# FZF commit picker
fzf_pick_commit() {
    local header="${1:-Select version to restore}"

    get_commit_list | fzf --ansi \
        --height=80% \
        --border=rounded \
        --header="$header" \
        --preview='git -C "'"$REPO_DIR"'" show --color=always {1} -- backup-files/' \
        --preview-window='right:60%:wrap' \
        --bind='enter:accept' | awk '{print $1}'
}

# ===== Commands =====

# ===== Help =====

show_help() {
    cat <<EOF
Usage: keys-manage [command] [options]

When run without a command, displays interactive menu.

Backup Commands:
  init              Initialize encrypted backup repository
  select            Interactive file selection (shows all, toggle with Tab)
  add               Add files to backup list (local changes)
  remove            Remove files from backup list (local changes)
  sync              Sync all changes (auto re-encrypt modified files + git push/pull)
  backup            Alias for 'sync'
  verify            Verify backup integrity (compare checksums, read-only)
  history           Show sync event log (detailed operations)

Restore Commands:
  restore [commit]  Restore files (FZF version picker if no commit)
  versions          Browse backup versions with FZF
  validate          Validate repository integrity

Common Commands:
  menu              Open interactive menu (same as no command)
  status            Show backup and restore status
  password          Manage encryption password (gopass integration)

Options:
  -p, --password PWD  Encryption password (OpenSSL)
  --dry-run          Preview without changes
  --no-backup        Skip safety snapshot before overwriting local files (restore only; not recommended)

Examples:
  # Interactive menu (default)
  keys-manage

  # Backup workflow
  keys-manage init             # First time: initialize repository
  keys-manage select           # Interactive: add/remove files
  # OR (interactive add/remove)
  keys-manage add
  keys-manage remove
  keys-manage sync             # Sync all changes (auto re-encrypt + git push/pull)
  keys-manage verify           # Verify backup integrity (read-only)

  # Restore workflow
  keys-manage versions         # Browse all versions
  keys-manage restore          # Restore with FZF version picker
  keys-manage restore HEAD~1   # Restore specific version

  # Status and maintenance
  keys-manage menu             # Open interactive menu
  keys-manage status           # Check sync status
  keys-manage history          # View backup log
  keys-manage validate         # Validate repository

Supported Directories:
  - ~/.ssh               SSH keys
  - ~/.gnupg             GPG keys
  - ~/.config/age        OpenSSL PBKDF2 encryption keys
  - Custom paths under \$HOME via yazi picker

Status Indicators:
  ${GREEN}✓${NC}  Up to date (backed up, no changes)
  ${YELLOW}⚠${NC}  Modified (backed up but changed since)
  ${CYAN}⊕${NC}  New file (not in backup list)
  ${RED}⊗${NC}  Removed (was backed up, now excluded)

EOF
}
