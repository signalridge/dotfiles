# shellcheck shell=bash
# ===== Unified Status Command =====

# Command: status - Unified backup and restore status
cmd_status() {
    require_cmd git jq || return 1

    log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_section "Keys Manager Status"
    log_section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Repository status
    if [[ -d "$REPO_DIR/.git" ]]; then
        log_success "Repository: ${REPO_DIR}"
        cd "$REPO_DIR" || {
            log_error "Failed to change directory to $REPO_DIR"
            return 1
        }

        local remote_url
        remote_url=$(git remote get-url origin 2>/dev/null || echo "N/A")
        echo "  Remote: $remote_url"

        local current_commit current_msg
        current_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "N/A")
        current_msg=$(git log -1 --format="%s (%ar)" 2>/dev/null || echo "N/A")
        echo "  Current: $current_commit - $current_msg"

        local backup_count
        backup_count=$(git rev-list --count HEAD -- backup-files/ 2>/dev/null || echo "0")
        echo "  Total backups: $backup_count"
    else
        log_warn "Repository not initialized"
        echo "  Run 'keys-manage init' to initialize"
        return 0
    fi

    # Metadata status
    if [[ -f "$METADATA_FILE" ]]; then
        local version file_count
        version=$(jq -r '.version // 1' "$METADATA_FILE")
        file_count=$(jq '.files | length' "$METADATA_FILE")
        log_success "Metadata: v$version ($file_count files tracked)"
    else
        log_warn "Metadata not initialized (legacy v1)"
    fi

    # Backup list
    if [[ -f "$BACKUP_LIST" ]]; then
        local selected_count
        selected_count=$(iter_backup_list_rel | wc -l | tr -d ' ')
        log_success "Backup list: $selected_count files selected"
    else
        log_warn "No backup list"
        return 0
    fi

    # File status (combined backup and restore view)
    echo ""
    log_section "File Status (Backup & Restore):"
    echo ""

    local total=0 unchanged=0 modified=0 new=0 missing=0

    while IFS= read -r file; do
        total=$((total + 1))
        local status
        status=$(get_file_status "$file")

        if [[ ! -f "$file" ]]; then
            echo "  ${STATUS_REMOVED} Missing locally: $(basename "$file")"
            missing=$((missing + 1))
        elif [[ "$status" == *"✓"* ]]; then
            echo "  ${STATUS_OK} $(basename "$file")"
            unchanged=$((unchanged + 1))
        elif [[ "$status" == *"⚠"* ]]; then
            echo "  ${STATUS_WARN} Modified: $(basename "$file")"
            modified=$((modified + 1))
        else
            echo "  ${STATUS_NEW} New: $(basename "$file")"
            new=$((new + 1))
        fi
    done < <(iter_backup_list_abs)

    echo ""
    echo "Summary: $total total, $unchanged unchanged, $modified modified, $new new, $missing missing"
    echo ""

    if [[ $modified -gt 0 ]] || [[ $new -gt 0 ]]; then
        echo "  → Run 'keys-manage sync' to sync changes"
    elif [[ $missing -gt 0 ]]; then
        echo "  → Run 'keys-manage restore' to restore missing files"
    else
        echo "  → All files up to date"
    fi
    echo ""
}

# Command: password - Manage encryption password in gopass
cmd_password() {
    local action="${1:-menu}"

    # Direct command line call - execute once and exit
    if [[ "$action" != "menu" ]]; then
        case "$action" in
        save)
            # Save/update password in gopass
            if ! command -v gopass &>/dev/null; then
                log_error "gopass not installed"
                echo ""
                echo "Install gopass:"
                echo "  macOS: brew install gopass"
                echo "  Linux: apt install gopass"
                return 1
            fi

            log_header "Save Password to gopass"
            echo ""

            gopass insert keys-manage/password
            log_success "Password saved to gopass (keys-manage/password)"
            ;;

        show)
            # Display password from gopass
            if ! command -v gopass &>/dev/null; then
                log_error "gopass not installed"
                return 1
            fi

            gopass show keys-manage/password
            ;;

        delete)
            # Remove password from gopass
            if ! command -v gopass &>/dev/null; then
                log_error "gopass not installed"
                return 1
            fi

            local gopass_path="keys-manage/password"
            echo "This will delete: $gopass_path"
            echo ""
            read -rp "Are you sure? (y/N): " confirm

            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                gopass rm "$gopass_path"
                log_success "Password deleted from gopass"
            else
                log_warn "Cancelled"
            fi
            ;;

        test)
            # Test password encryption/decryption
            log_header "Test Password"
            echo ""

            local password
            password=$(get_encryption_password) || {
                log_error "Failed to get password"
                return 1
            }

            # Create test file
            local test_file
            test_file=$(mktemp "${TMPDIR:-/tmp}/keys-manage-test.XXXXXX")
            local test_content
            test_content="keys-manage password test $(date)"
            echo "$test_content" >"$test_file"

            echo "Testing encryption/decryption..."
            echo ""

            # Test encryption
            if encrypt_file "$test_file" "$test_file.enc" "$password" 2>/dev/null; then
                log_success "✓ Encryption successful"
            else
                log_error "✗ Encryption failed"
                rm -f "$test_file" "$test_file.enc"
                return 1
            fi

            # Test decryption
            if decrypt_file "$test_file.enc" "$test_file.dec" "$password" 2>/dev/null; then
                log_success "✓ Decryption successful"
            else
                log_error "✗ Decryption failed"
                rm -f "$test_file" "$test_file.enc" "$test_file.dec"
                return 1
            fi

            # Verify content matches
            if diff -q "$test_file" "$test_file.dec" &>/dev/null; then
                log_success "✓ Content verification successful"
                echo ""
                log_success "Password is correct and working"
            else
                log_error "✗ Content verification failed"
                rm -f "$test_file" "$test_file.enc" "$test_file.dec"
                return 1
            fi

            # Cleanup
            rm -f "$test_file" "$test_file.enc" "$test_file.dec"
            ;;

        help | *)
            cat <<'EOF'
Usage: keys-manage password [action]

Actions:
  (no action)   Interactive menu
  save          Save/update password in gopass
  show          Display password from gopass
  delete        Remove password from gopass
  test          Test password encryption/decryption

Examples:
  keys-manage password           # Interactive menu
  keys-manage password save      # Save password to gopass
  keys-manage password show      # View password
  keys-manage password test      # Test password works
  gopass show keys-manage/password  # Direct gopass access

Note: Password is stored at: keys-manage/password
EOF
            ;;
        esac
        return 0
    fi

    # Interactive menu mode - pick one action then exit.
    require_cmd fzf || {
        log_warn "FZF not found, showing help instead"
        cat <<'EOF'
Usage: keys-manage password [action]

Actions:
  save          Save/update password in gopass
  show          Display password from gopass
  delete        Remove password from gopass
  test          Test password encryption/decryption

Examples:
  keys-manage password save      # Save password to gopass
  keys-manage password show      # View password
  keys-manage password test      # Test password works
EOF
        return 0
    }

    log_section "Password Management"
    echo ""

    local selected
    if ! selected=$(printf "%b\n%b\n%b\n%b\n%b\n" \
        "${GREEN}save${NC} - Save/update password in gopass" \
        "${CYAN}show${NC} - Display password from gopass" \
        "${YELLOW}test${NC} - Test password encryption/decryption" \
        "${RED}delete${NC} - Remove password from gopass" \
        "${YELLOW}Back${NC} - Return to main menu" |
        fzf --ansi \
            --height=50% \
            --border=rounded \
            --header="Select operation" \
            --preview='
            action=$(echo {} | awk "{print \$1}")
            echo -e "\033[1;36m━━━ Password Management ━━━\033[0m"
            echo ""
	            case "$action" in
                save)
                    echo "Save or update your encryption password in gopass"
                    echo ""
                    echo "Path: keys-manage/password"
                    echo ""
                    echo "After saving, the password will be automatically"
                    echo "loaded for all future operations."
                    ;;
                show)
                    echo "Display the stored password"
                    echo ""
                    echo "Note: Password will be visible on screen"
                    ;;
                test)
                    echo "Test password by encrypting and decrypting a file"
                    echo ""
                    echo "Verifies that:"
                    echo "  • Password can be retrieved"
                    echo "  • Encryption works"
                    echo "  • Decryption works"
                    echo "  • Data integrity is maintained"
                    ;;
                delete)
                    echo "Remove password from gopass"
                    echo ""
                    echo "⚠ Warning: You will need to re-enter"
                    echo "  the password for future operations"
                    ;;
	                Back) echo "Return to previous menu" ;;
	            esac
	        ' \
            --preview-window='right:50%:wrap'); then
        return "$RC_EXIT"
    fi

    local cmd
    cmd=$(echo "$selected" | awk '{print $1}')

    # Handle Back
    if [[ "$cmd" == "Back" ]]; then
        return "$RC_BACK"
    fi

    echo ""

    case "$cmd" in
    save)
        # Save/update password in gopass
        if ! command -v gopass &>/dev/null; then
            log_error "gopass not installed"
            echo ""
            echo "Install gopass:"
            echo "  macOS: brew install gopass"
            echo "  Linux: apt install gopass"
            return 1
        else
            log_header "Save Password to gopass"
            echo ""

            gopass insert keys-manage/password
            log_success "Password saved to gopass (keys-manage/password)"
        fi
        ;;

    show)
        # Display password from gopass
        if ! command -v gopass &>/dev/null; then
            log_error "gopass not installed"
            return 1
        else
            gopass show keys-manage/password
        fi
        ;;

    delete)
        # Remove password from gopass
        if ! command -v gopass &>/dev/null; then
            log_error "gopass not installed"
            return 1
        else
            local gopass_path="keys-manage/password"
            echo "This will delete: $gopass_path"
            echo ""
            read -rp "Are you sure? (y/N): " confirm

            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                gopass rm "$gopass_path"
                log_success "Password deleted from gopass"
            else
                log_warn "Cancelled"
            fi
        fi
        ;;

    test)
        # Test password encryption/decryption
        log_header "Test Password"
        echo ""

        local password
        if password=$(get_encryption_password); then
            # Create test file
            local test_file
            test_file=$(mktemp "${TMPDIR:-/tmp}/keys-manage-test.XXXXXX")
            local test_content
            test_content="keys-manage password test $(date)"
            echo "$test_content" >"$test_file"

            echo "Testing encryption/decryption..."
            echo ""

            local test_failed=false

            # Test encryption
            if encrypt_file "$test_file" "$test_file.enc" "$password" 2>/dev/null; then
                log_success "✓ Encryption successful"
            else
                log_error "✗ Encryption failed"
                test_failed=true
            fi

            # Test decryption
            if [[ "$test_failed" == false ]] && decrypt_file "$test_file.enc" "$test_file.dec" "$password" 2>/dev/null; then
                log_success "✓ Decryption successful"
            else
                log_error "✗ Decryption failed"
                test_failed=true
            fi

            # Verify content matches
            if [[ "$test_failed" == false ]] && diff -q "$test_file" "$test_file.dec" &>/dev/null; then
                log_success "✓ Content verification successful"
                echo ""
                log_success "Password is correct and working"
            else
                if [[ "$test_failed" == false ]]; then
                    log_error "✗ Content verification failed"
                fi
            fi

            # Cleanup
            rm -f "$test_file" "$test_file.enc" "$test_file.dec"
        else
            log_error "Failed to get password"
            return 1
        fi
        ;;
    esac

    echo ""
    return 0
}
