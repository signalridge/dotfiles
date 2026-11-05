#!/usr/bin/env bash
# Included in the work Mac's LaunchDaemon. api() is supplied by the daemon;
# its API bearer header stays in the root-only runtime directory.
company_compat() {
    local selected current desired
    local api="$1" jq_bin="$2"
    selected="$(api "$api/proxies/Egress" | "$jq_bin" -er '.now')" || return 1
    desired=Rule
    if [ "$selected" = company ]; then desired=company; fi
    current="$(api "$api/configs" | "$jq_bin" -er '.mode')" || return 1
    [ "$current" = "$desired" ] && return 0
    api -X PATCH -H 'Content-Type: application/json' \
        -d "$("$jq_bin" -cn --arg mode "$desired" '{mode: $mode}')" \
        "$api/configs" || return 1
    # sing-box clears its DNS cache on mode changes. Flush the macOS cache too;
    # browsers retaining their own IPv6 addresses get a fast route rejection.
    /usr/bin/dscacheutil -flushcache
    echo "sing-box: Egress $selected: compatibility mode $current -> $desired" >&2
}
