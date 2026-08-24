#!/bin/bash

set -euo pipefail

# Remove only the old Pi extension implementations and package installs that the
# published @signalridge packages replace, so Pi never loads two copies of the
# same extension. Runtime sessions, auth, permissions, and workflow project data
# are intentionally not touched.
echo ":: [19] Removing legacy Pi extension sources"

agent_dir="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
legacy_extension_dir="$agent_dir/extensions"
removed=0

remove_file() {
    local path="$1"
    if [[ -f "$path" ]]; then
        rm -f -- "$path"
        removed=$((removed + 1))
    fi
}

remove_package_dir() {
    local path="$1"
    local expected_name="$2"
    [[ -d "$path" && -f "$path/package.json" ]] || return 0
    command -v jq >/dev/null 2>&1 || return 0
    jq -e --arg expected "$expected_name" '.name == $expected' "$path/package.json" >/dev/null 2>&1 || return 0
    rm -rf -- "$path"
    removed=$((removed + 1))
}

remove_file "$legacy_extension_dir/herdr-pi-state.ts"
remove_file "$legacy_extension_dir/pi-gpt-fast.ts"
remove_file "$legacy_extension_dir/pi-welcome.ts"
remove_file "$legacy_extension_dir/pi-worktree-guard.ts"
remove_package_dir "$legacy_extension_dir/pi-input-history" "pi-input-history"
remove_package_dir "$legacy_extension_dir/pi-input-prefix" "pi-ext-input-prefix"
remove_package_dir "$legacy_extension_dir/pi-statusline" "@narumitw/pi-statusline"
remove_package_dir "$legacy_extension_dir/tmux-state" "pi-ext-tmux-state"

# Remove exact package installs that would otherwise leave a second copy
# discoverable in Pi's global package directory.
# installed directories.
legacy_npm_root="$agent_dir/npm"
legacy_npm_manifest="$legacy_npm_root/package.json"
legacy_npm_lock="$legacy_npm_root/bun.lock"
legacy_npm_packages=(
    "@tintinweb/pi-subagents"
    "@quintinshaw/pi-dynamic-workflows"
    "@narumitw/pi-goal"
    "@narumitw/pi-statusline"
    "pi-input-history"
)

# Remove the declarations as well as the installed directories. Pi's Bun-backed
# package manager installs from this manifest; deleting only node_modules would
# let a later `pi update --extensions` resurrect the legacy implementations.
if [[ -f "$legacy_npm_manifest" ]] && command -v jq >/dev/null 2>&1; then
    manifest_needs_cleanup=false
    for package_name in "${legacy_npm_packages[@]}"; do
        if jq -e --arg name "$package_name" '
            any((.dependencies // {}) | keys[]; . == $name) or
            any((.optionalDependencies // {}) | keys[]; . == $name) or
            any((.devDependencies // {}) | keys[]; . == $name)
        ' "$legacy_npm_manifest" >/dev/null 2>&1; then
            manifest_needs_cleanup=true
            break
        fi
    done
    if [[ "$manifest_needs_cleanup" == true ]]; then
        if command -v bun >/dev/null 2>&1; then
            if bun uninstall --cwd "$legacy_npm_root" "${legacy_npm_packages[@]}" >/dev/null 2>&1; then
                removed=$((removed + 1))
            else
                echo "    Bun could not reconcile the legacy npm project; removing declarations with jq" >&2
            fi
        fi
        # A machine without Bun can still leave a safe manifest behind. Remove
        # the lock so the next Pi update regenerates it from the remaining peers.
        if ! jq -e --argjson names "$(printf '%s\n' "${legacy_npm_packages[@]}" | jq -R . | jq -s .)" '
            any((.dependencies // {}) | keys[]; (. as $key | $names | index($key)) != null) or
            any((.optionalDependencies // {}) | keys[]; (. as $key | $names | index($key)) != null) or
            any((.devDependencies // {}) | keys[]; (. as $key | $names | index($key)) != null)
        ' "$legacy_npm_manifest" >/dev/null 2>&1; then
            :
        else
            tmp_manifest="$(mktemp "${legacy_npm_manifest}.XXXXXX")"
            jq --argjson names "$(printf '%s\n' "${legacy_npm_packages[@]}" | jq -R . | jq -s .)" '
                def remove_legacy: with_entries(select(.key as $key | ($names | index($key)) == null));
                .dependencies = ((.dependencies // {}) | remove_legacy) |
                .optionalDependencies = ((.optionalDependencies // {}) | remove_legacy) |
                .devDependencies = ((.devDependencies // {}) | remove_legacy)
            ' "$legacy_npm_manifest" >"$tmp_manifest"
            mv -- "$tmp_manifest" "$legacy_npm_manifest"
            rm -f -- "$legacy_npm_lock" "$legacy_npm_root/package-lock.json" "$legacy_npm_root/npm-shrinkwrap.json"
            removed=$((removed + 1))
        fi
    fi
fi

npm_dir="$legacy_npm_root/node_modules"
for package_path in \
    "$npm_dir/@tintinweb/pi-subagents" \
    "$npm_dir/@quintinshaw/pi-dynamic-workflows" \
    "$npm_dir/@narumitw/pi-goal" \
    "$npm_dir/@narumitw/pi-statusline" \
    "$npm_dir/pi-input-history"; do
    if [[ -e "$package_path" ]]; then
        rm -rf -- "$package_path"
        removed=$((removed + 1))
    fi
done

# Remove the dynamic-workflows plugin's global configuration. Keep existing workflow
# project run history untouched for rollback and manual migration.
workflow_dir="$HOME/.pi/workflows"
remove_file "$workflow_dir/settings.json"
remove_file "$workflow_dir/model-tiers.json"

# Remove an obsolete statusline-only display override without rewriting any
# other user preference. Invalid JSON is left untouched for manual recovery.
for settings_file in \
    "$agent_dir/pi-statusline-settings.json" \
    "$agent_dir/pi-statusline.json"; do
    [[ -f "$settings_file" ]] || continue
    command -v jq >/dev/null 2>&1 || continue
    jq -e . "$settings_file" >/dev/null 2>&1 || continue
    tmp_settings="$(mktemp "${settings_file}.XXXXXX")"
    if jq 'del(.extensionStatusIcons.caffeinate)' "$settings_file" >"$tmp_settings"; then
        mv -- "$tmp_settings" "$settings_file"
    else
        rm -f -- "$tmp_settings"
    fi
done

if ((removed > 0)); then
    echo "    Removed $removed legacy Pi extension source/install entr$( ((removed == 1)) && printf 'y' || printf 'ies')"
else
    echo "    No legacy Pi extension sources found"
fi
