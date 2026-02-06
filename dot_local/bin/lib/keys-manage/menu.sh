# shellcheck shell=bash
# ===== Interactive Menu =====

cmd_menu() {
    require_cmd fzf || {
        log_warn "FZF not found, showing status instead"
        cmd_status
        return 0
    }

    while true; do
        local selected
        if ! selected=$(
            {
                cat <<'MENU'
init           Initialize backup repository
select         Add/remove files
sync           Sync all changes
verify         Verify backup integrity
history        Show backup history
restore        Restore from backup
validate       Validate repository
status         Show current status
password       Manage password
MENU
                # Keep navigation actions visually consistent.
                echo -e "${YELLOW}quit           Exit to shell${NC}"
            } | fzf --ansi \
                --height=60% \
                --border=rounded \
                --header="keys-manage" \
                --preview='
                    cmd=$(echo {} | awk "{print \$1}")
                    echo -e "\033[1;34m━━━ $cmd ━━━\033[0m"
                    echo ""
                    case "$cmd" in
                        init) echo "Initialize encrypted backup repository" ;;
	                        select) echo "Interactively select/deselect files to backup"
	                              echo ""
	                              echo "• Add files: marks to add (local only)"
	                              echo "• Remove files: marks to remove (local only)"
	                              echo "• Done: saves locally; run keys-manage sync to encrypt + commit + push" ;;
                        sync) echo "Sync all changes (auto re-encrypt + git push/pull)"
                              echo ""
                              echo "• Automatically detects modified files"
                              echo "• Re-encrypts modified files and commits"
                              echo "• Pushes all changes to remote"
                              echo "• Exits after completion" ;;
                        verify) echo "Verify backup integrity (read-only)"
                              echo ""
                              echo "• Compare local files with backup checksums"
                              echo "• Shows which files are modified"
                              echo "• Exits after completion" ;;
                        history) echo "Show sync event log"
                              echo "• Exits after completion" ;;
                        restore) echo "Restore files from backup (per-file version picker)"
                              echo ""
                              echo "• Select one file at a time"
                              echo "• View only commits affecting that file"
                              echo "• Exits after restore" ;;
                        validate) echo "Validate repository integrity"
                              echo "• Exits after completion" ;;
                        status) echo "Show backup and restore status"
                              echo "• Exits after completion" ;;
                        password) echo "Manage encryption password in gopass"
                              echo ""
                              echo "• save: Save password to gopass"
                              echo "• show: Display password"
                              echo "• test: Test password works"
                              echo "• delete: Remove password"
                              echo "• Back: returns to main menu" ;;
                        quit) echo "Exit to shell" ;;
                    esac
                    echo ""
                    echo -e "\033[1;34m━━━ Quick Status ━━━\033[0m"
                    echo ""
                    if [[ -d "$HOME/.local/share/keys-backup/.git" ]]; then
                        cd "$HOME/.local/share/keys-backup"
                        echo "Repository: $(git remote get-url origin 2>/dev/null || echo "N/A")"
                        echo "Last commit: $(git log -1 --format="%ar" 2>/dev/null || echo "N/A")"
                        if [[ -f "$HOME/.local/share/keys-backup/backup-list.txt" ]]; then
                            echo "Files: $(wc -l < "$HOME/.local/share/keys-backup/backup-list.txt" | tr -d " ") selected"
                        fi
                    else
                        echo "⚠ Not initialized"
                        echo "Run init to initialize"
                    fi
                ' \
                --preview-window='right:50%:wrap' \
                --preview-label="[ keys-manage ]"
        ); then
            return "$RC_EXIT"
        fi

        local cmd
        cmd=$(echo "$selected" | awk '{print $1}')
        local action_fn=""

        echo ""

        case "$cmd" in
        init) action_fn="cmd_init" ;;
        select) action_fn="cmd_select" ;;
        sync) action_fn="cmd_sync" ;;
        verify) action_fn="cmd_verify" ;;
        history) action_fn="cmd_history" ;;
        restore) action_fn="cmd_restore" ;;
        validate) action_fn="cmd_validate" ;;
        status) action_fn="cmd_status" ;;
        password) action_fn="cmd_password" ;;
        quit) return 0 ;;
        *) log_warn "Unknown command: $cmd" ;;
        esac

        if [[ -n "$action_fn" ]]; then
            local rc=0
            "$action_fn" || rc=$?

            case "$rc" in
            0)
                return 0
                ;;
            "$RC_BACK")
                echo ""
                continue
                ;;
            "$RC_EXIT")
                return "$RC_EXIT"
                ;;
            *)
                echo ""
                log_error "Command '$cmd' failed (exit $rc)"
                return "$rc"
                ;;
            esac
        fi

        echo ""
    done
}
