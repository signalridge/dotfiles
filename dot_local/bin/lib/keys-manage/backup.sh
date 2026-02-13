# shellcheck shell=bash
# ===== Backup Commands (from keys-backup) =====

# Command: init - Initialize backup repository
cmd_init() {
    require_cmd git || return 1

    log_header "Keys Backup Repository Initialization"
    echo ""
    log_info "Using OpenSSL PBKDF2 encryption (AES-256-CBC with 100k iterations)"
    echo ""

    # Check if repository already exists
    if [[ -d "$REPO_DIR/.git" ]]; then
        log_success "Repository already initialized: $REPO_DIR"
        cd "$REPO_DIR" || {
            log_error "Failed to change directory to $REPO_DIR"
            return 1
        }

        # Ensure the repo is on the new "encrypted control files" layout.
        ensure_repo_ignores_plain_control_files

        local changed=false
        migrate_plain_control_files_to_gitignored >/dev/null 2>&1 && changed=true || true

        # If encrypted control files are missing, create them from local plaintext (requires password).
        if [[ ! -f "$BACKUP_LIST_ENC" || ! -f "$METADATA_FILE_ENC" ]]; then
            require_cmd openssl || return 1
            local password
            password=$(get_encryption_password) || return 1
            ensure_control_files_encrypted_for_commit "$password" || return 1
            changed=true
        fi

        if [[ "$changed" == true ]]; then
            git add backup-list.txt.enc backup-metadata.json.enc .gitignore 2>/dev/null || true
            safe_git_commit "Init: setup encrypted control files" || true
        fi

        echo ""
        log_note "Run 'keys-manage sync' to pull/push with remote"
        echo ""
        log_success "Repository ready"
        return 0
    fi

    # If local directory exists but is not a git repository, handle explicitly
    if [[ -d "$REPO_DIR" ]] && [[ ! -d "$REPO_DIR/.git" ]]; then
        if [[ -n "$(ls -A "$REPO_DIR" 2>/dev/null)" ]]; then
            log_error "Local directory exists but is not a git repository: $REPO_DIR"
            echo ""
            echo "To continue safely, choose one:"
            echo "  1. Move existing files elsewhere"
            echo "  2. Remove directory: rm -rf \"$REPO_DIR\""
            echo "  3. Then run: keys-manage init"
            return 1
        fi

        # Empty directory blocks git clone; remove it first.
        rmdir "$REPO_DIR" 2>/dev/null || true
    fi

    # Check if remote repository is configured
    if [[ -z "$KEYS_REPO" ]]; then
        log_error "Repository URL not configured"
        echo ""
        echo "Please set keysRepository in your chezmoi config (data.keysRepository)."
        echo ""
        echo "Example (~/.config/chezmoi/chezmoi.toml):"
        echo "  [data]"
        echo "  keysRepository = \"git@github.com:username/keypairs.git\""
        return 1
    fi

    echo "Repository URL: $KEYS_REPO"
    echo "Local path: $REPO_DIR"
    echo ""

    # Clone repository
    log_info "Cloning keys repository..."
    local clone_error=""
    clone_error=$(mktemp)
    register_temp_file "$clone_error"

    if ! git clone "$KEYS_REPO" "$REPO_DIR" 2>"$clone_error"; then
        echo ""
        log_warn "Failed to clone repository"
        echo ""

        # Show git error
        if [[ -s "$clone_error" ]]; then
            echo "Git error:"
            sed 's/^/  /' "$clone_error"
            echo ""
        fi

        # Determine likely cause and provide guidance
        local error_content
        error_content=$(cat "$clone_error" 2>/dev/null)
        rm -f "$clone_error"

        if echo "$error_content" | grep -q "already exists and is not an empty directory"; then
            log_error "Local path already exists and is not empty: $REPO_DIR"
            echo "Please move/delete it, then run init again."
            return 1
        elif echo "$error_content" | grep -q "not found\|does not exist"; then
            log_note "Repository does not exist yet (first time setup)"
        elif echo "$error_content" | grep -q "Authentication\|Permission denied\|publickey"; then
            log_error "Authentication failed"
            echo ""
            echo "Possible causes:"
            echo "  - SSH key not added to git server"
            echo "  - Wrong repository URL"
            echo "  - Insufficient permissions"
            echo ""
            echo "To fix:"
            echo "  1. Add your SSH key: ssh-add ~/.ssh/your_key"
            echo "  2. Test connection: ssh -T git@github.com (or your git server)"
            echo "  3. Verify repository URL: $KEYS_REPO"
            return 1
        fi

        echo ""
        echo "Options:"
        echo "  1. Create a new empty repository on your git server first, then run init again"
        echo "  2. Or initialize a local repository now (you can push later)"
        echo ""
        read -r -p "Initialize local repository? (y/n): " create_new
        if [[ "$create_new" != "y" ]]; then
            echo "Initialization cancelled"
            echo ""
            echo "Next steps:"
            echo "  1. Create repository on your git server: $KEYS_REPO"
            echo "  2. Run: keys-manage init"
            return 1
        fi

        # Initialize new repository
        mkdir -p "$REPO_DIR"
        cd "$REPO_DIR" || {
            log_error "Failed to change directory to $REPO_DIR"
            return 1
        }
        if ! git init -b main &>/dev/null; then
            git init
        fi
        git remote add origin "$KEYS_REPO"

        # Create initial plaintext control files (gitignored); encrypted versions are tracked.
        echo ""
        log_info "Initializing repository..."
        mkdir -p "$REPO_DIR/$BACKUP_FILES_DIR"
        touch "$BACKUP_LIST"
        init_metadata

        local password
        password=$(get_encryption_password) || return 1
        ensure_control_files_encrypted_for_commit "$password" || return 1

        git add .gitignore backup-list.txt.enc backup-metadata.json.enc 2>/dev/null || true
        safe_git_commit "Initial commit: setup encrypted control files" || return 1

        echo ""
        log_success "New repository created and configured"
        echo ""
        log_note "Files will be encrypted with OpenSSL PBKDF2 before backup"
        echo ""
        echo "Next steps:"
        echo "  1. Create the remote repository: $KEYS_REPO"
        local default_branch
        default_branch=$(git branch --show-current 2>/dev/null || echo "main")
        echo "  2. Run: git -C $REPO_DIR push -u origin $default_branch"
        echo "  3. Run: keys-manage select  # Select files (local only)"
        echo "  4. Run: keys-manage sync    # Encrypt + commit + push"

        log_event "Repository initialized (new)"
        return 0
    fi

    # Repository cloned successfully
    rm -f "$clone_error"
    cd "$REPO_DIR" || {
        log_error "Failed to change directory to $REPO_DIR"
        return 1
    }
    log_success "Repository cloned"
    echo ""
    log_note "Files will be encrypted with OpenSSL PBKDF2 before backup"
    echo ""

    local password
    password=$(get_encryption_password) || return 1

    # Ensure encrypted control files exist in repo; create them if missing.
    ensure_control_files_encrypted_for_commit "$password" || return 1
    migrate_plain_control_files_to_gitignored >/dev/null 2>&1 || true
    git add backup-list.txt.enc backup-metadata.json.enc .gitignore 2>/dev/null || true
    if ! git diff --cached --quiet 2>/dev/null; then
        safe_git_commit "Initialize encrypted control files" || return 1
        log_note "Run 'keys-manage sync' to publish initialization changes to remote"
    fi

    echo ""
    log_success "Repository initialized successfully"
    echo ""
    echo "Next steps:"
    echo "  1. Run: keys-manage select  # Select files (local only)"
    echo "  2. Run: keys-manage sync    # Encrypt + commit + push"

    log_event "Repository initialized (clone)"
}

# Command: select - Interactive file selection (for menu only)
cmd_select() {
    require_cmd fzf || return 1

    # Ensure local directory exists
    ensure_local_dir

    log_section "Manage backup list"
    echo ""
    echo -e "${BOLD}Actions:${NC}"
    echo -e "  ${GREEN}Add files${NC}    - Browse and add files with yazi"
    echo -e "  ${RED}Remove files${NC} - Remove files from backup list"
    echo -e "  ${CYAN}Done${NC}         - Save changes (local)"
    echo -e "  ${YELLOW}Back${NC}         - Cancel all changes"
    echo ""

    # Track pending changes
    local -a pending_add=()
    local -a pending_remove=()

    # Create temp files for preview
    local pending_add_file
    local pending_remove_file
    pending_add_file=$(mktemp)
    pending_remove_file=$(mktemp)
    register_temp_file "$pending_add_file"
    register_temp_file "$pending_remove_file"

    while true; do
        # Load current backup list
        local current_files=()
        while IFS= read -r file; do
            [[ -n "$file" ]] && current_files+=("$file")
        done < <(iter_backup_list_abs)

        # Calculate preview counts
        local total_files=${#current_files[@]}
        local add_count=${#pending_add[@]}
        local remove_count=${#pending_remove[@]}
        local final_count=$((total_files + add_count - remove_count))

        # Write pending lists to temp files for preview
        printf '%s\n' "${pending_add[@]}" >"$pending_add_file"
        printf '%s\n' "${pending_remove[@]}" >"$pending_remove_file"

        # Action menu with expanded variables
        local action
        action=$(printf "%b\n%b\n%b\n%b\n" \
            "${GREEN}Add files${NC}" \
            "${RED}Remove files${NC}" \
            "${CYAN}Done${NC}" \
            "${YELLOW}Back${NC}" |
            fzf --ansi \
                --height=50% \
                --border=rounded \
                --header="Current: $total_files | +$add_count -$remove_count | Final: $final_count" \
                --preview="
                action=\$(echo {} | awk '{print \$1}')

                echo -e \"\033[1;36m━━━ Current Backup List ($total_files files) ━━━\033[0m\"
                echo ''
                if [[ $total_files -gt 0 ]]; then
                    if [[ -f '$BACKUP_LIST' ]]; then
                        grep -v '\[0\;' '$BACKUP_LIST' 2>/dev/null | grep -v 'Add Custom' | grep -v 'File path' | grep -v 'Tip:' | grep -v '^$' | nl
                    fi
                else
                    echo 'List is empty'
                fi

                echo ''
                echo -e \"\033[1;32m━━━ Pending Add ($add_count) ━━━\033[0m\"
                if [[ -s '$pending_add_file' ]]; then
                    nl '$pending_add_file'
                else
                    echo 'None'
                fi

                echo ''
                echo -e \"\033[1;31m━━━ Pending Remove ($remove_count) ━━━\033[0m\"
                if [[ -s '$pending_remove_file' ]]; then
                    nl '$pending_remove_file'
                else
                    echo 'None'
                fi

                echo ''
                echo -e \"\033[1;36m━━━ Action ━━━\033[0m\"
                case \"\$action\" in
                    Add) echo 'Browse and select files (will be added when Done)' ;;
                    Remove) echo 'Select files to remove (will be removed when Done)' ;;
                    Done) echo 'Apply all changes locally (no encryption yet)' ;;
                    Back) echo 'Cancel all pending changes' ;;
                esac
            " \
                --preview-window='right:50%:wrap') || {
            rm -f "$pending_add_file" "$pending_remove_file"
            log_warn "Cancelled"
            return 0
        }

        local cmd
        cmd=$(echo "$action" | awk '{print $1}')

        echo ""
        case "$cmd" in
        Add)
            # Add files with yazi (record only, don't encrypt yet)
            log_section "Add files with yazi"
            echo ""

            # Capture yazi selection
            local yazi_files
            if yazi_files=$(yazi_select_files); then
                # Add to pending list
                while IFS= read -r file; do
                    if [[ -n "$file" ]]; then
                        # Check if in pending remove (cancel removal)
                        local in_pending_remove=false
                        local new_pending_remove=()
                        for pending_file in "${pending_remove[@]}"; do
                            if [[ "$file" == "$pending_file" ]]; then
                                in_pending_remove=true
                                log_success "Cancelled removal: $(basename "$file")"
                            else
                                new_pending_remove+=("$pending_file")
                            fi
                        done
                        if [[ "$in_pending_remove" == true ]]; then
                            pending_remove=("${new_pending_remove[@]}")
                            continue
                        fi

                        # Check if already in backup list
                        local already_in_list=false
                        for current_file in "${current_files[@]}"; do
                            if [[ "$file" == "$current_file" ]]; then
                                already_in_list=true
                                break
                            fi
                        done

                        # Check if already in pending add
                        local already_pending=false
                        for pending_file in "${pending_add[@]}"; do
                            if [[ "$file" == "$pending_file" ]]; then
                                already_pending=true
                                break
                            fi
                        done

                        if [[ "$already_in_list" == true ]]; then
                            log_warn "Already in backup: $(basename "$file")"
                        elif [[ "$already_pending" == true ]]; then
                            log_warn "Already pending: $(basename "$file")"
                        else
                            pending_add+=("$file")
                            log_success "Marked to add: $(basename "$file")"
                        fi
                    fi
                done <<<"$yazi_files"
            else
                local yazi_rc=$?
                case "$yazi_rc" in
                "$RC_BACK" | "$RC_EXIT")
                    log_warn "Cancelled"
                    ;;
                *)
                    return "$yazi_rc"
                    ;;
                esac
            fi
            echo ""
            ;;

        Remove)
            # Remove files (record only, don't delete yet)
            # Build list: current_files + pending_add
            local removable_files=()
            removable_files+=("${current_files[@]}")
            removable_files+=("${pending_add[@]}")

            if [[ ${#removable_files[@]} -eq 0 ]]; then
                log_warn "No files to remove"
                echo ""
                continue
            fi

            log_section "Remove files from backup list"
            echo -e "Use ${CYAN}Tab${NC} to select files to remove, ${CYAN}Enter${NC} to confirm"
            echo ""

            local to_remove
            to_remove=$(printf '%s\n' "${removable_files[@]}" | fzf_multi_select \
                "Tab: select to remove | Enter: confirm" \
                "$FILE_PREVIEW") || {
                echo ""
                continue
            }

            if [[ -n "$to_remove" ]]; then
                while IFS= read -r file; do
                    if [[ -n "$file" ]]; then
                        # Check if in pending add (cancel addition)
                        local in_pending_add=false
                        local new_pending_add=()
                        for pending_file in "${pending_add[@]}"; do
                            if [[ "$file" == "$pending_file" ]]; then
                                in_pending_add=true
                                log_success "Cancelled addition: $(basename "$file")"
                            else
                                new_pending_add+=("$pending_file")
                            fi
                        done
                        if [[ "$in_pending_add" == true ]]; then
                            pending_add=("${new_pending_add[@]}")
                            continue
                        fi

                        # Check if already in pending remove
                        local already_pending=false
                        for pending_file in "${pending_remove[@]}"; do
                            if [[ "$file" == "$pending_file" ]]; then
                                already_pending=true
                                break
                            fi
                        done

                        if [[ "$already_pending" == true ]]; then
                            log_warn "Already pending removal: $(basename "$file")"
                        else
                            pending_remove+=("$file")
                            log_success "Marked to remove: $(basename "$file")"
                        fi
                    fi
                done <<<"$to_remove"
            else
                log_warn "No files selected"
            fi
            echo ""
            ;;

        Done)
            # Done - apply pending changes locally (no encryption/commit here)
            if [[ ${#pending_add[@]} -eq 0 ]] && [[ ${#pending_remove[@]} -eq 0 ]]; then
                log_warn "No pending changes"
                echo ""
                break # Return to main menu
            fi

            echo ""
            log_section "Applying changes (local)..."
            echo ""

            touch "$BACKUP_LIST"

            local tmp
            tmp=$(mktemp)
            register_temp_file "$tmp"

            # Build removal set (HOME-relative).
            local -A remove_set=()
            local pending_file rel
            for pending_file in "${pending_remove[@]}"; do
                rel=$(to_home_rel_path "$pending_file" 2>/dev/null || true)
                [[ -n "$rel" ]] && remove_set["$rel"]=1
            done

            # Keep existing entries not marked for removal.
            while IFS= read -r rel; do
                [[ -z "$rel" ]] && continue
                [[ -n "${remove_set[$rel]:-}" ]] && continue
                echo "$rel" >>"$tmp"
            done < <(iter_backup_list_rel)

            # Add new entries (HOME-relative).
            for pending_file in "${pending_add[@]}"; do
                rel=$(to_home_rel_path "$pending_file" 2>/dev/null || true)
                [[ -n "$rel" ]] && echo "$rel" >>"$tmp"
            done

            sort -u "$tmp" -o "$BACKUP_LIST"
            rm -f "$tmp"

            # Optionally clean metadata entries for removed files (local only).
            if [[ -f "$METADATA_FILE" ]] && [[ ${#pending_remove[@]} -gt 0 ]]; then
                for pending_file in "${pending_remove[@]}"; do
                    remove_file_metadata "$pending_file" || true
                done
            fi

            log_success "Changes saved locally"
            log_note "Run 'keys-manage sync' to encrypt + commit + push to remote"
            break
            ;;

        Back)
            # Back - cancel all pending changes
            if [[ ${#pending_add[@]} -gt 0 ]] || [[ ${#pending_remove[@]} -gt 0 ]]; then
                log_warn "Discarded ${#pending_add[@]} additions and ${#pending_remove[@]} removals"
            fi
            rm -f "$pending_add_file" "$pending_remove_file"
            return "$RC_BACK"
            ;;
        esac
    done

    # Cleanup temp files
    rm -f "$pending_add_file" "$pending_remove_file"

    # Show final summary
    local count
    count=$(wc -l <"$BACKUP_LIST" 2>/dev/null | tr -d ' ')
    echo ""
    if [[ $count -eq 0 ]]; then
        log_warn "No files in backup"
    else
        log_success "Current backup: $count files"
    fi
    echo ""
    log_note "Run 'keys-manage sync' to encrypt + commit + push to remote."
}

# Command: add - Add files to backup list (append)
cmd_add() {
    local picker="auto" # auto|yazi|fzf
    local scope="home"  # home|keys

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --fzf)
            picker="fzf"
            shift
            ;;
        --yazi)
            picker="yazi"
            shift
            ;;
        --home)
            scope="home"
            shift
            ;;
        --keys | --keys-only)
            scope="keys"
            shift
            ;;
        -h | --help)
            cat <<EOF
Usage: keys-manage add [--fzf|--yazi] [--home|--keys]

Add files to backup list without replacing existing selections.

Pickers:
  --yazi   Use yazi file picker (default when installed)
  --fzf    Use fzf picker (useful to test / when yazi is unavailable)

Scopes (fzf only):
  --home   Browse files under \$HOME (default; may be slow)
  --keys   Only discover common key dirs (~/.ssh, ~/.gnupg, ~/.config/age)
EOF
            return 0
            ;;
        *)
            log_error "Unknown option for add: $1"
            return 1
            ;;
        esac
    done

    # Ensure local directory exists (doesn't need git yet)
    ensure_local_dir

    # Load current list (absolute paths for UI)
    local current_files=()
    while IFS= read -r file; do
        [[ -n "$file" ]] && current_files+=("$file")
    done < <(iter_backup_list_abs)

    if [[ ${#current_files[@]} -gt 0 ]]; then
        log_section "Current backup list: ${#current_files[@]} files"
        echo ""
    else
        log_section "No existing backup list - starting fresh"
        echo ""
    fi

    local to_add=""

    # Prefer yazi for add (consistent with interactive select workflow).
    if [[ "$picker" != "fzf" ]] && command -v yazi &>/dev/null; then
        log_section "Select files to add"
        echo ""
        to_add=$(yazi_select_files) || {
            local rc=$?
            case "$rc" in
            "$RC_BACK" | "$RC_EXIT")
                log_warn "Cancelled"
                return 0
                ;;
            *)
                return "$rc"
                ;;
            esac
        }
    elif [[ "$picker" == "yazi" ]]; then
        log_error "yazi not found. Install with: brew install yazi"
        return 1
    else
        require_cmd fzf || return 1

        local list_file
        list_file=$(mktemp)
        register_temp_file "$list_file"
        printf '%s\n' "${current_files[@]}" >"$list_file"

        local header="Select files to ADD (Tab: toggle, Ctrl-A: all, Ctrl-D: none, Ctrl-/: preview)"
        if [[ "$scope" == "keys" ]]; then
            header="Select files to ADD (key dirs only) (Tab/Ctrl-A/Ctrl-D/Ctrl-/)"
        else
            header="Select files to ADD (all under \$HOME) (Tab/Ctrl-A/Ctrl-D/Ctrl-/)"
        fi

        echo -e "(Tab: multi-select, ESC: cancel)"
        echo ""

        local pick_cmd="discover_home_files"
        if [[ "$scope" == "keys" ]]; then
            pick_cmd="discover_key_files"
        fi

        # FZF to select files to add. Filter out files already in the list.
        if [[ -s "$list_file" ]]; then
            to_add=$(awk 'NR==FNR{seen[$0]=1; next} !seen[$0]' "$list_file" <($pick_cmd) | fzf --ansi --multi \
                --height=50% \
                --border=rounded \
                --header="$header" \
                --preview="$FILE_PREVIEW" \
                --preview-window='right:50%:wrap:border-left' \
                --bind='ctrl-a:select-all' \
                --bind='ctrl-d:deselect-all' \
                --bind='ctrl-/:toggle-preview') || {
                rm -f "$list_file"
                log_warn "Selection cancelled"
                return 0
            }
        else
            to_add=$($pick_cmd | fzf --ansi --multi \
                --height=50% \
                --border=rounded \
                --header="$header" \
                --preview="$FILE_PREVIEW" \
                --preview-window='right:50%:wrap:border-left' \
                --bind='ctrl-a:select-all' \
                --bind='ctrl-d:deselect-all' \
                --bind='ctrl-/:toggle-preview') || {
                rm -f "$list_file"
                log_warn "Selection cancelled"
                return 0
            }
        fi

        rm -f "$list_file"
    fi

    if [[ -z "$to_add" ]]; then
        log_warn "No files selected"
        return 0
    fi

    local before_count after_count
    before_count=$(wc -l <"$BACKUP_LIST" 2>/dev/null | tr -d ' ' || echo 0)

    # Write clean list (only valid file paths)
    local tmp
    tmp=$(mktemp)
    register_temp_file "$tmp"

    # Add existing valid files (write HOME-relative entries)
    for file in "${current_files[@]}"; do
        local rel
        rel=$(to_home_rel_path "$file") || continue
        echo "$rel" >>"$tmp"
    done

    # Add new files (write HOME-relative entries)
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local rel
        rel=$(to_home_rel_path "$file") || continue
        echo "$rel" >>"$tmp"
    done <<<"$to_add"

    # Sort and deduplicate
    sort -u "$tmp" -o "$BACKUP_LIST"
    rm -f "$tmp"

    after_count=$(wc -l <"$BACKUP_LIST" 2>/dev/null | tr -d ' ' || echo 0)
    local added_count
    if [[ "$after_count" =~ ^[0-9]+$ ]] && [[ "$before_count" =~ ^[0-9]+$ ]] && [[ "$after_count" -ge "$before_count" ]]; then
        added_count=$((after_count - before_count))
    else
        added_count=$(echo "$to_add" | wc -l | tr -d ' ')
    fi

    log_success "Added $added_count file(s) to backup list (local)"
    echo ""
    echo "$to_add" | sed 's/^/  /'
    echo ""
    log_note "Run 'keys-manage sync' to encrypt + commit + push to remote"
}

# Command: remove - Remove files from backup list
cmd_remove() {
    require_cmd fzf || return 1

    # Ensure local directory exists (doesn't need git yet)
    ensure_local_dir

    if [[ ! -f "$BACKUP_LIST" ]] || [[ ! -s "$BACKUP_LIST" ]]; then
        log_warn "Backup list is empty"
        return 1
    fi

    # Load current list (absolute paths for UI)
    local current_files=()
    while IFS= read -r file; do
        [[ -n "$file" ]] && current_files+=("$file")
    done < <(iter_backup_list_abs)

    if [[ ${#current_files[@]} -eq 0 ]]; then
        log_warn "Backup list is empty or corrupted"
        return 1
    fi

    log_section "Current backup list: ${#current_files[@]} files"
    echo -e "(Tab: multi-select, ESC: cancel)"
    echo ""

    # FZF to select files to remove
    local to_remove
    to_remove=$(printf '%s\n' "${current_files[@]}" | fzf --ansi --multi \
        --height=50% \
        --border=rounded \
        --header="Select files to REMOVE (Tab: toggle, Ctrl-A: all, Ctrl-D: none, Ctrl-/: preview)" \
        --bind='ctrl-a:select-all' \
        --bind='ctrl-d:deselect-all' \
        --bind='ctrl-/:toggle-preview' \
        --preview="
            file={}
            echo -e \"\033[1;31m━━━ WILL BE REMOVED ━━━\033[0m\"
            echo \"\"
            echo \"Path: \$file\"
            if [[ -f \"\$file\" ]]; then
                echo \"Status: Exists\"
            else
                echo \"Status: Missing\"
            fi
        " \
        --preview-window='right:50%:wrap') || {
        log_warn "Selection cancelled"
        return 0
    }

    if [[ -z "$to_remove" ]]; then
        log_warn "No files selected"
        return 0
    fi

    # Confirm removal
    local remove_count
    remove_count=$(echo "$to_remove" | wc -l | tr -d ' ')
    echo "Will remove $remove_count files from backup list:"
    echo ""
    echo "$to_remove" | sed 's/^/  /'
    echo ""
    read -r -p "Confirm removal? (y/N): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo "Cancelled"
        return 0
    fi

    # Remove from backup list (write clean list, HOME-relative)
    local tmp
    tmp=$(mktemp)
    register_temp_file "$tmp"

    local -A remove_set=()
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local rel
        rel=$(to_home_rel_path "$file") || continue
        remove_set["$rel"]=1
    done <<<"$to_remove"

    while IFS= read -r rel; do
        [[ -z "$rel" ]] && continue
        [[ -n "${remove_set[$rel]:-}" ]] && continue
        echo "$rel" >>"$tmp"
    done < <(iter_backup_list_rel)

    mv "$tmp" "$BACKUP_LIST"
    normalize_backup_list_file

    # Clean up metadata for removed files
    if [[ -f "$METADATA_FILE" ]]; then
        while IFS= read -r file; do
            remove_file_metadata "$file"
        done <<<"$to_remove"
    fi

    log_success "Removed $remove_count files from backup list (local)"
    echo ""

    local remaining
    remaining=$(wc -l <"$BACKUP_LIST" | tr -d ' ')
    echo "Remaining files: $remaining"
    echo ""
    log_note "Run 'keys-manage sync' to encrypt + commit + push to remote"
}

# Command: sync - Git synchronization only (pull + push)
cmd_sync() {
    require_cmd git jq openssl || return 1

    log_header "Keys Sync - Sync All Changes"
    echo ""

    # Initialize repo
    init_repo_if_needed || return 1
    cd "$REPO_DIR" || {
        log_error "Failed to change directory to $REPO_DIR"
        return 1
    }

    # Check if repository is initialized
    if ! git rev-parse --git-dir &>/dev/null; then
        log_error "Git repository not initialized"
        return 1
    fi

    # Sync with remote first to avoid working on stale history.
    if ! sync_with_remote --require-online; then
        log_error "Cannot continue sync until remote issues are resolved"
        return 1
    fi

    # Sync requires password because repo control files are stored encrypted.
    local password
    password=$(get_encryption_password) || {
        log_error "Cannot proceed without password"
        return 1
    }

    # Ensure plaintext control files exist locally, then update encrypted copies for git.
    # This is the "control file integrity check" after clone/pull.
    ensure_control_files_encrypted_for_commit "$password" || return 1
    ensure_repo_ignores_plain_control_files
    migrate_plain_control_files_to_gitignored >/dev/null 2>&1 || true

    # Commit control file changes even if no backup-files changed, so list edits can be synced.
    git add backup-list.txt.enc backup-metadata.json.enc .gitignore 2>/dev/null || true
    if ! git diff --cached --quiet 2>/dev/null; then
        safe_git_commit "Sync: update control files" || return 1
    fi

    # [1/5] Check for modified files and re-encrypt
    if [[ -f "$BACKUP_LIST" ]] && [[ -s "$BACKUP_LIST" ]]; then
        echo "[1/5] Checking for modified files..."
        echo ""

        # Load current files from list
        local current_files=()
        while IFS= read -r file; do
            [[ -n "$file" ]] && current_files+=("$file")
        done < <(iter_backup_list_abs)

        # Find modified files
        local modified_files=()
        local modified_count=0

        for file in "${current_files[@]}"; do
            if [[ ! -f "$file" ]]; then
                continue
            fi

            # Calculate current checksum
            local current_checksum
            current_checksum=$(calc_checksum "$file")

            # Get checksum from metadata
            local stored_checksum
            stored_checksum=$(get_file_info "$file" "sha256" 2>/dev/null || true)

            # Check if file is modified
            if [[ -z "$stored_checksum" ]] || [[ "$current_checksum" != "$stored_checksum" ]]; then
                modified_files+=("$file")
                modified_count=$((modified_count + 1))
            fi
        done

        # Re-encrypt modified files if any
        if [[ $modified_count -gt 0 ]]; then
            echo "Found $modified_count modified file(s), re-encrypting..."
            echo ""

            local failed_reencrypt=0
            local -a failed_reencrypt_files=()

            for file in "${modified_files[@]}"; do
                local filename
                filename=$(basename "$file")
                echo "  Encrypting: $filename"

                local backup_path
                backup_path=$(get_backup_path "$file") || {
                    log_error "  ✗ Invalid path (must be under \$HOME): $file"
                    failed_reencrypt=$((failed_reencrypt + 1))
                    failed_reencrypt_files+=("$file")
                    continue
                }

                # Encrypt file
                if encrypt_file "$file" "$REPO_DIR/$backup_path" "$password"; then
                    # Update metadata
                    if update_file_metadata "$file"; then
                        log_success "  ✓ Updated: $filename"
                    else
                        log_error "  ✗ Failed to update metadata: $filename"
                        failed_reencrypt=$((failed_reencrypt + 1))
                        failed_reencrypt_files+=("$file")
                    fi
                else
                    log_error "  ✗ Failed: $filename"
                    failed_reencrypt=$((failed_reencrypt + 1))
                    failed_reencrypt_files+=("$file")
                fi
            done

            echo ""

            if [[ $failed_reencrypt -gt 0 ]]; then
                log_error "Sync aborted: $failed_reencrypt file(s) failed during re-encryption"
                local failed_file
                for failed_file in "${failed_reencrypt_files[@]}"; do
                    echo "  - $failed_file"
                done
                return 1
            fi

            # Commit changes
            if commit_backup_changes "Sync: re-encrypt $modified_count modified file(s)"; then
                log_success "Changes committed"
                echo ""
            else
                log_error "Failed to commit changes"
                return 1
            fi
        else
            log_success "All files up-to-date"
            echo ""
        fi
    else
        echo "[1/5] No backup list found, skipping file check"
        echo ""
    fi

    # [2/5] Remove encrypted files no longer present in backup list
    echo "[2/5] Cleaning removed files..."
    local removed_count=0
    local -A keep_rel=()
    while IFS= read -r rel; do
        [[ -n "$rel" ]] && keep_rel["$rel"]=1
    done < <(iter_backup_list_rel)

    # Safety: avoid wiping the entire backup repo if the control file is missing/empty.
    local selected_count repo_file_count
    selected_count=$(iter_backup_list_rel | wc -l | tr -d ' ')
    repo_file_count=$(find "$REPO_DIR/$BACKUP_FILES_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$selected_count" -eq 0 && "$repo_file_count" -gt 0 ]]; then
        log_warn "Backup list is empty but repository contains $repo_file_count backup file(s)"
        if [[ -t 0 ]]; then
            local confirm
            read -r -p "Delete ALL backup files from repository? (y/N): " confirm
            if [[ "$confirm" != "y" ]]; then
                log_warn "Aborted (refusing to delete all backups)"
                return 1
            fi
        else
            log_error "Refusing to delete all backups without a TTY confirmation"
            return 1
        fi
    fi
    if [[ -f "$BACKUP_LIST" ]]; then
        while IFS= read -r encrypted_file; do
            local rel_path
            rel_path="${encrypted_file#"$REPO_DIR/$BACKUP_FILES_DIR"/}"

            if [[ -z "${keep_rel[$rel_path]:-}" ]]; then
                rm -f "$encrypted_file"
                remove_file_metadata "$rel_path"
                removed_count=$((removed_count + 1))
            fi
        done < <(find "$REPO_DIR/$BACKUP_FILES_DIR" -type f 2>/dev/null | sort)
    fi

    if [[ $removed_count -gt 0 ]]; then
        if commit_backup_changes "Sync: remove $removed_count file(s) no longer in backup list"; then
            log_success "Removed $removed_count stale backup file(s)"
        else
            log_error "Failed to commit removed files cleanup"
            return 1
        fi
    else
        log_success "No removed files to clean"
        echo ""
    fi

    # [3/5] Check for unpushed commits
    echo ""
    echo "[3/5] Checking for unpushed commits..."
    local unpushed=0

    if git rev-parse --abbrev-ref '@{upstream}' &>/dev/null; then
        # Has upstream, count unpushed commits
        unpushed=$(git rev-list '@{upstream}..HEAD' 2>/dev/null | wc -l | tr -d ' ')
    elif git remote get-url origin &>/dev/null; then
        # Has remote but no upstream, check if any commits exist
        if git rev-parse HEAD &>/dev/null; then
            # Has commits, assume all are unpushed
            unpushed=$(git rev-list --count HEAD 2>/dev/null || echo "0")
        fi
    fi

    if [[ "$unpushed" -eq 0 ]]; then
        log_success "Already in sync (nothing to push)"
        return 0
    fi

    log_info "Found $unpushed unpushed commit(s)"

    # Show recent unpushed commits
    echo ""
    echo "Recent commits to push:"
    if git rev-parse --abbrev-ref '@{upstream}' &>/dev/null; then
        git log -n 5 '@{upstream}..HEAD' --oneline --color=always
    else
        git log -n 5 --oneline --color=always
    fi

    # [4/5] Push to remote
    echo ""
    echo "[4/5] Pushing to remote..."
    if safe_git_push; then
        echo ""
        log_success "Successfully synced (pushed $unpushed commit(s))"
        return 0
    else
        log_error "Push failed"
        echo ""
        echo "Your backup is saved locally in: $REPO_DIR"
        echo "You can push manually later: cd $REPO_DIR && git push"
        return 1
    fi
}

# Command: verify - Verify backup integrity
cmd_verify() {
    require_cmd git jq openssl || return 1

    [[ ! -d "$REPO_DIR/.git" ]] && {
        log_error "Repository not initialized"
        return 1
    }

    cd "$REPO_DIR" || {
        log_error "Failed to change directory to $REPO_DIR"
        return 1
    }

    log_info "Verifying backup integrity (comparing SHA256 checksums)..."
    echo ""

    # Get password once for all verifications (also used to unlock encrypted control files if needed).
    local password
    password=$(get_encryption_password) || {
        log_error "Cannot proceed without password"
        return 1
    }

    # Ensure plaintext backup list exists locally (repo stores an encrypted copy).
    if [[ ! -f "$BACKUP_LIST" ]]; then
        if [[ -f "$BACKUP_LIST_ENC" ]]; then
            ensure_repo_ignores_plain_control_files
            if decrypt_file "$BACKUP_LIST_ENC" "$BACKUP_LIST" "$password" 2>/dev/null; then
                chmod 600 "$BACKUP_LIST" 2>/dev/null || true
            else
                log_error "Failed to decrypt backup-list (wrong password?)"
                return 1
            fi
        else
            log_error "No backup list found"
            return 1
        fi
    fi

    echo "Checking that local files match their backups..."
    echo ""

    local errors=0
    local verified=0

    while IFS= read -r file; do
        local filename
        filename=$(basename "$file")

        if [[ ! -f "$file" ]]; then
            log_warn "Local file missing: $file"
            continue
        fi

        # Get backup path
        local backup_path
        backup_path=$(get_backup_path "$file") || {
            log_warn "Invalid backup path (must be under \$HOME): $file"
            errors=$((errors + 1))
            continue
        }
        if [[ ! -f "$REPO_DIR/$backup_path" ]]; then
            log_fail "Not in backup: $filename"
            errors=$((errors + 1))
            continue
        fi

        if verify_file "$file" "$password"; then
            log_success "OK: $filename"
            verified=$((verified + 1))
        else
            log_fail "Mismatch: $filename"
            errors=$((errors + 1))
        fi
    done < <(iter_backup_list_abs)

    echo ""
    if [[ $errors -eq 0 ]]; then
        echo -e "✅ All $verified files verified${NC}"
        return 0
    else
        echo -e "❌ $errors verification failures${NC}"
        return 1
    fi
}

# Command: history - Show backup history
cmd_history() {
    local limit="${1:-20}"

    if ! [[ "$limit" =~ ^[0-9]+$ ]] || [[ "$limit" -lt 1 ]]; then
        limit=20
    fi

    [[ ! -f "$HISTORY_LOG" ]] && {
        echo "No history available"
        return 0
    }

    log_section "Backup History (latest first)"
    echo ""

    # Group contiguous lines that share the same timestamp, so multi-line events
    # (e.g. Sync summary + changed files) stay together when shown newest-first.
    awk -v limit="$limit" '
        function flush() { if (block != "") { blocks[++n] = block; block = "" } }
        function extract_ts(line) {
            # POSIX awk: avoid match(..., ..., array) capture groups.
            if (line !~ /^\[/) return ""
            sub(/^\[/, "", line)
            sub(/\].*$/, "", line)
            return line
        }
        {
            ts = extract_ts($0)

            if (NR == 1) { cur = ts; block = $0 "\n"; next }

            if (ts == cur) { block = block $0 "\n"; next }

            flush()
            cur = ts
            block = $0 "\n"
        }
        END {
            flush()
            printed = 0
            for (i = n; i >= 1; i--) {
                printf "%s", blocks[i]
                printed++
                if (limit > 0 && printed >= limit) break
            }
        }
    ' "$HISTORY_LOG"
    echo ""
}
