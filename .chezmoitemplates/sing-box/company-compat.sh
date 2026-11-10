#!/usr/bin/env bash
# Included in the Mac LaunchDaemon. api() is supplied by the daemon;
# its API bearer header stays in the root-only runtime directory.
direct_signature=
direct_ipv6_next=0
direct_ipv6_ok=0

direct_network_signature() {
    local state primary
    state="$(printf 'show State:/Network/Global/IPv4\n' | /usr/sbin/scutil)"
    primary="$(printf '%s\n' "$state" | /usr/bin/awk '/PrimaryInterface/ { print $3 }')"
    [ -n "$primary" ] || return 1
    printf '%s\n' "$state"
    /sbin/ifconfig "$primary" 2>/dev/null
}

direct_ipv6_usable() {
    local primary
    primary="$(printf 'show State:/Network/Global/IPv4\n' | /usr/sbin/scutil | /usr/bin/awk '/PrimaryInterface/ { print $3 }')"
    [ -n "$primary" ] || return 1
    # Bind the probe to the physical interface, not the TUN. The address and
    # certificate name are fixed so testing IPv6 does not depend on DNS.
    /usr/bin/curl -6 -fsS --noproxy '*' --interface "$primary" --connect-timeout 2 --max-time 3 \
        --resolve 'cloudflare-dns.com:443:[2606:4700:4700::1111]' \
        -o /dev/null 'https://cloudflare-dns.com/' 2>/dev/null
}

flush_system_dns() { /usr/bin/dscacheutil -flushcache; }

company_compat() {
    local selected current desired signature
    local api="$1" jq_bin="$2"
    selected="$(api "$api/proxies/Egress" | "$jq_bin" -er '.now')" || return 1
    desired=Rule
    if [ "$selected" = company ]; then desired=company; fi
    if [ "$selected" = Direct ]; then
        signature="$(direct_network_signature)" || signature=unavailable
        if [ "$direct_signature" != "$signature" ] || [ "$SECONDS" -ge "$direct_ipv6_next" ]; then
            direct_signature="$signature"
            direct_ipv6_next=$((SECONDS + 30))
            if direct_ipv6_usable; then direct_ipv6_ok=1; else direct_ipv6_ok=0; fi
        fi
        [ "$direct_ipv6_ok" = 1 ] || desired=direct-ipv4
    fi
    current="$(api "$api/configs" | "$jq_bin" -er '.mode')" || return 1
    [ "$current" = "$desired" ] && return 0
    # shellcheck disable=SC2016 # jq, not the shell, expands $mode
    api -X PATCH -H 'Content-Type: application/json' \
        -d "$("$jq_bin" -cn --arg mode "$desired" '{mode: $mode}')" \
        "$api/configs" || return 1
    # sing-box clears its DNS cache on mode changes. Flush the macOS cache too;
    # browsers retaining their own IPv6 addresses get a fast route rejection.
    flush_system_dns
    echo "sing-box: Egress $selected: compatibility mode $current -> $desired" >&2
}
