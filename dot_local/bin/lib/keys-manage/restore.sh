# shellcheck shell=bash
# ===== Restore Commands (from keys-restore) =====

# Command: restore - Restore files from backup
cmd_restore() {
    local dry_run=false
    local no_backup=false
    local commit_arg=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --commit | -c)
            if [[ $# -lt 2 ]] || [[ "$2" == -* ]]; then
                log_error "Missing value for --commit"
                return 1
            fi
            commit_arg="$2"
            shift 2
            ;;
        --dry-run)
            dry_run=true
            shift
            ;;
        --no-backup)
            no_backup=true
            shift
            ;;
        *)
            # First positional argument is commit
            if [[ -z "$commit_arg" ]]; then
                commit_arg="$1"
            else
                log_error "Unexpected argument: $1"
                return 1
            fi
            shift
            ;;
        esac
    done

    require_cmd git fzf jq openssl || return 1

    [[ ! -d "$REPO_DIR/.git" ]] && {
        log_error "Repository not initialized"
        echo "Run 'keys-manage init' first"
        return 1
    }

    cd "$REPO_DIR" || {
        log_error "Failed to change directory to $REPO_DIR"
        return 1
    }

    # Restore should see latest backups when remote exists, so sync first.
    # (Uses time-limited fetch/pull so it doesn't hang forever.)
    if git remote get-url origin &>/dev/null; then
        log_info "Syncing backup history with remote..."
        if ! sync_with_remote; then
            log_error "Cannot continue restore until repository sync issues are resolved"
            return 1
        fi
    else
        log_warn "No remote configured; using local backup history only"
    fi

    if [[ -n "$commit_arg" ]] && ! git rev-parse --verify "$commit_arg^{commit}" &>/dev/null; then
        log_error "Invalid commit: $commit_arg"
        return 1
    fi

    local restorable_files
    if [[ -n "$commit_arg" ]]; then
        restorable_files=$(git ls-tree -r --name-only "$commit_arg" backup-files/ 2>/dev/null |
            sed 's|^backup-files/||' || true)
    else
        restorable_files=$(git ls-tree -r --name-only HEAD backup-files/ 2>/dev/null |
            sed 's|^backup-files/||' || true)
    fi
    if [[ -z "$restorable_files" ]]; then
        if [[ -n "$commit_arg" ]]; then
            log_error "No backup files found in commit: $commit_arg"
        else
            log_error "No backup files found in repository"
        fi
        return 1
    fi

    log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_section "Interactive Restore - Per-file version selection"
    log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local selected_file=""
    local backup_path=""
    local target_path=""
    local selected_commit=""
    local commit_info=""

    while true; do
        # Step 1: Select ONE file to restore
        if [[ -z "$selected_file" ]]; then
            log_section "Step 1: Select file to restore"
            echo ""

            if ! selected_file=$({
                printf '%s\n' "$restorable_files"
                echo -e "${YELLOW}Back${NC}"
            } | fzf --ansi \
                --height=70% \
                --border=rounded \
                --header="Select file to restore (ESC: exit)" \
                --preview='
                    file="{}"
                    if [[ "$file" == "Back" ]]; then
                        echo "Return to main menu"
                        exit 0
                    fi
                    echo "File: $file"
                    echo ""
                    echo "Commit history (only commits affecting this file):"
                    echo ""
                    git log --oneline -10 -- "backup-files/$file"
                ' \
                --preview-window='right:50%:wrap'); then
                return "$RC_EXIT"
            fi

            if [[ "$selected_file" == "Back" ]]; then
                return "$RC_BACK"
            fi

            backup_path="backup-files/$selected_file"
            target_path=$(get_absolute_path "$BACKUP_FILES_DIR/$selected_file")
            selected_commit=""
        fi

        echo ""
        echo "Selected: $selected_file"
        echo ""

        # Step 2: Select version (commit) for this specific file
        if [[ -z "$selected_commit" ]]; then
            log_section "Step 2: Select version for: $selected_file"
            echo ""
            echo "Showing only commits that modified this file:"
            echo ""

            if [[ -n "$commit_arg" ]]; then
                selected_commit="$commit_arg"
                if ! git rev-parse --verify "$selected_commit^{commit}" &>/dev/null; then
                    log_error "Invalid commit: $selected_commit"
                    return 1
                fi
                echo "Using specified commit: $(git log -1 --format='%h - %s (%ar)' "$selected_commit")"
            else
                local selected_line
                if ! selected_line=$({
                    git log --oneline -- "$backup_path"
                    echo -e "${YELLOW}Back${NC}"
                } | fzf --ansi \
                    --height=60% \
                    --border=rounded \
                    --header="Select version to restore for: $selected_file (Back: reselect file, ESC: exit)" \
                    --preview='
                        line="{}"
                        if [[ "$line" == "Back" ]]; then
                            echo "Back to file selection"
                            exit 0
                        fi
                        echo "Commit details:"
                        echo ""
                        git show --stat {1} -- "'"$backup_path"'"
                        echo ""
                        echo "Changes in this file:"
                        git show {1} -- "'"$backup_path"'" | head -50
                    ' \
                    --preview-window='right:60%:wrap'); then
                    return "$RC_EXIT"
                fi

                if [[ "$selected_line" == "Back" ]]; then
                    selected_file=""
                    backup_path=""
                    target_path=""
                    selected_commit=""
                    continue
                fi

                selected_commit=$(echo "$selected_line" | awk '{print $1}')
            fi
        fi

        # Validate commit
        if ! git rev-parse --verify "$selected_commit^{commit}" &>/dev/null; then
            log_error "Invalid commit: $selected_commit"
            if [[ -n "$commit_arg" ]]; then
                return 1
            fi
            selected_commit=""
            continue
        fi

        # Check if file exists in selected commit
        if ! git cat-file -e "$selected_commit:$backup_path" 2>/dev/null; then
            log_error "File not found in commit $selected_commit: $selected_file"
            if [[ -n "$commit_arg" ]]; then
                selected_file=""
                backup_path=""
                target_path=""
                selected_commit=""
                continue
            fi
            selected_commit=""
            continue
        fi

        commit_info=$(git log -1 --format='%h - %s (%ar)' "$selected_commit")
        echo ""
        echo "✓ Selected version: $commit_info"
        echo ""

        # Step 3: Show summary and confirm
        log_section "Step 3: Confirm restore"
        echo ""

        log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_section "Restore Summary"
        log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        echo "File to restore:"
        echo "  • $selected_file"
        echo "    From: $commit_info"
        echo "    To:   $target_path"
        echo ""

        if [[ "$dry_run" == true ]]; then
            echo ""
            log_warn "Dry run mode - file will not be restored"
            return 0
        fi

        local confirm
        if [[ -n "$commit_arg" ]]; then
            read -r -p "Proceed with restore? [y]es/[f]ile/[n]o: " confirm
        else
            read -r -p "Proceed with restore? [y]es/[b]ack version/[f]ile/[n]o: " confirm
        fi

        case "$confirm" in
        [Yy])
            break
            ;;
        [Bb])
            if [[ -n "$commit_arg" ]]; then
                log_warn "Cannot reselect commit when --commit is provided"
            else
                selected_commit=""
            fi
            continue
            ;;
        [Ff])
            selected_file=""
            backup_path=""
            target_path=""
            selected_commit=""
            continue
            ;;
        [Nn] | "")
            echo "Restore cancelled"
            return 0
            ;;
        *)
            log_warn "Invalid choice: $confirm"
            continue
            ;;
        esac
    done

    local selected_commit_full latest_file_commit
    selected_commit_full=$(git rev-parse "$selected_commit^{commit}")
    latest_file_commit=$(git log -n 1 --format='%H' -- "$backup_path" 2>/dev/null || true)
    local create_restore_commit=true
    if [[ -n "$latest_file_commit" ]] && [[ "$selected_commit_full" == "$latest_file_commit" ]]; then
        create_restore_commit=false
    fi

    # Backup current state
    local backup_dir
    backup_dir="${RESTORE_SNAPSHOT_DIR}/$(date +%Y%m%d-%H%M%S)"

    if [[ "$no_backup" != true ]]; then
        echo ""
        echo "[1/4] Backing up current state..."
        mkdir -p "$backup_dir"

        if [[ -f "$target_path" ]]; then
            # Preserve directory structure in backup
            local backup_subdir
            backup_subdir=$(dirname "$backup_dir/$selected_file")
            mkdir -p "$backup_subdir"
            cp "$target_path" "$backup_subdir/"
            [[ -f "$target_path.pub" ]] && cp "$target_path.pub" "$backup_subdir/"
            log_success "Backed up current file to: $backup_dir"
        else
            echo "No existing file to backup"
        fi
    else
        echo ""
        log_warn "⚠ Skipping current state backup (--no-backup) (no rollback snapshot will be created)"
    fi

    # Restore file
    echo ""
    echo "[2/4] Restoring file..."

    local password
    password=$(get_encryption_password) || {
        log_error "Failed to get encryption password"
        return 1
    }

    local temp_encrypted
    temp_encrypted=$(mktemp "${TMPDIR:-/tmp}/keys-restore.XXXXXX.enc")
    register_temp_file "$temp_encrypted"
    local filename
    filename=$(basename "$target_path")

    # Extract encrypted file from selected commit
    if ! git show "$selected_commit:$backup_path" >"$temp_encrypted" 2>/dev/null; then
        echo "  ${STATUS_ERROR} Not found in commit $(git rev-parse --short "$selected_commit"): $filename"
        rm -f "$temp_encrypted"
        return 1
    fi

    # Decrypt and restore
    mkdir -p "$(dirname "$target_path")"
    if decrypt_file "$temp_encrypted" "$target_path" "$password" 2>/dev/null; then
        # Restore original permissions from metadata
        local original_perms
        original_perms=$(get_file_info "$target_path" "permissions" || true)

        if [[ -n "$original_perms" ]]; then
            # Use original permissions from metadata
            chmod "$original_perms" "$target_path"
        else
            # Fallback: default to 600 for private files
            chmod 600 "$target_path"
        fi

        local commit_short
        commit_short=$(git rev-parse --short "$selected_commit")
        echo "  ${STATUS_OK} Restored: $filename (from $commit_short)"
    else
        echo "  ${STATUS_ERROR} Decryption failed: $filename"
        rm -f "$temp_encrypted"
        return 1
    fi

    echo ""
    if [[ "$create_restore_commit" == true ]]; then
        # Re-encrypt restored file into backup repo and create a new latest commit.
        echo "[3/4] Writing restored version as latest backup commit..."

        # Ensure control files are unlocked locally before updating metadata/list.
        ensure_control_files_ready "$password" || return 1

        if ! backup_file "$target_path" "$password"; then
            log_error "Failed to update backup repository for restored file"
            return 1
        fi

        update_file_metadata "$target_path"

        # Keep backup list in sync (idempotent).
        if ! grep -qxF "$selected_file" "$BACKUP_LIST"; then
            echo "$selected_file" >>"$BACKUP_LIST"
            normalize_backup_list_file
        fi

        local selected_commit_short restore_commit_msg
        selected_commit_short=$(git rev-parse --short "$selected_commit")
        restore_commit_msg="Restore $selected_file from $selected_commit_short"

        ensure_control_files_encrypted_for_commit "$password" || return 1
        migrate_plain_control_files_to_gitignored >/dev/null 2>&1 || true
        git add -A backup-files/ backup-list.txt.enc backup-metadata.json.enc .gitignore 2>/dev/null || true
        if safe_git_commit "$restore_commit_msg"; then
            log_success "Created latest restore commit"
            log_note "Run 'keys-manage sync' to publish restore commit to remote"
        else
            log_warn "No repository content change to commit"
        fi
    else
        echo "[3/4] Selected version is already latest for this file"
        log_info "Skipped backup commit; restored local file only"
    fi

    rm -f "$temp_encrypted"
    echo ""
    echo "[4/4] Complete"

    echo ""
    log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "✅ Restore Complete${NC}"
    log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Successfully restored: $selected_file"
    echo "From commit: $commit_info"

    if [[ "$no_backup" != true ]]; then
        echo ""
        log_info "Rollback available:"
        echo "  Current state saved to: $backup_dir"
        echo "  To rollback: cp -R \"$backup_dir\"/. \"$HOME\"/"
    fi

    echo ""
    log_event "Restored: $selected_file from $(git rev-parse --short "$selected_commit")"
}

# Command: versions - Show available versions with FZF
cmd_versions() {
    require_cmd fzf || return 1

    [[ ! -d "$REPO_DIR/.git" ]] && {
        log_error "Repository not initialized"
        return 1
    }

    cd "$REPO_DIR" || {
        log_error "Failed to change directory to $REPO_DIR"
        return 1
    }

    log_section "Select backup version to view"
    echo ""

    local selected
    selected=$(fzf_pick_commit "Select backup version") || {
        log_warn "Selection cancelled"
        return 0
    }

    if [[ -n "$selected" ]]; then
        echo ""
        log_section "Selected commit: $selected"
        echo ""
        git show --stat "$selected" -- backup-files/
        echo ""
        echo "To restore: keys-manage restore --commit $selected"
        echo "To preview: keys-manage restore --dry-run --commit $selected"
    fi
}

# Command: validate - Validate backup integrity
cmd_validate() {
    require_cmd git jq || return 1

    [[ ! -d "$REPO_DIR/.git" ]] && {
        log_error "Repository not initialized"
        return 1
    }

    cd "$REPO_DIR" || {
        log_error "Failed to change directory to $REPO_DIR"
        return 1
    }

    log_section "Validating backup repository..."
    echo ""

    # Check git repository
    local fsck_output
    local fsck_status=0
    fsck_output=$(git fsck 2>&1) || fsck_status=$?
    if [[ $fsck_status -ne 0 ]] || echo "$fsck_output" | grep -q "error:"; then
        log_fail "Git repository has errors"
        if echo "$fsck_output" | grep -q "error:"; then
            echo "$fsck_output" | grep "error:"
        else
            echo "$fsck_output"
        fi
        return 1
    else
        log_success "Git repository integrity OK"
    fi

    # Note about encryption
    log_success "Using OpenSSL PBKDF2 encryption (AES-256-CBC)"

    # Check remote connectivity
    if git ls-remote &>/dev/null; then
        log_success "Remote repository accessible"
    else
        log_warn "Cannot reach remote repository"
    fi

    # Check backup files exist
    if [[ -d backup-files ]] && [[ -n "$(ls -A backup-files 2>/dev/null)" ]]; then
        local file_count
        file_count=$(find backup-files -type f | wc -l | tr -d ' ')
        log_success "Backup contains $file_count files"
    else
        log_warn "No backup files found"
    fi

    # Check metadata
    if [[ -f "$METADATA_FILE" ]]; then
        if jq empty "$METADATA_FILE" 2>/dev/null; then
            log_success "Metadata format valid"

            # Warn if any legacy absolute path keys remain.
            if jq -e '.files | keys[] | select(startswith("/"))' "$METADATA_FILE" >/dev/null 2>&1; then
                log_warn "Metadata contains absolute path keys (legacy). Run 'keys-manage sync' to normalize."
            fi
        else
            log_fail "Metadata format invalid"
            return 1
        fi
    else
        log_warn "No metadata file (legacy v1)"
    fi

    echo ""
    echo -e "✅ Validation complete${NC}"
    echo ""
}
