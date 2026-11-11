#!/usr/bin/env bash
set -euo pipefail

temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT
source .chezmoitemplates/sing-box/company-compat.sh

mock_selected=Direct
mock_mode=Rule
mock_signature=wifi-a
ipv6=0
patches=0
flushes=0

api() {
    case "$*" in
    */proxies/Egress) jq -cn --arg now "$mock_selected" '{now: $now}' ;;
    */configs)
        if [ "$1" = -X ]; then
            printf '%s\n' "$6" >"$temporary/patch"
        else
            jq -cn --arg mode "$mock_mode" '{mode: $mode}'
        fi
        ;;
    *) return 1 ;;
    esac
}
direct_network_signature() { printf '%s' "$mock_signature"; }
direct_ipv6_usable() { [ "$ipv6" = 1 ]; }
flush_system_dns() { flushes=$((flushes + 1)); }

check() {
    local expected="$1"
    rm -f "$temporary/patch"
    company_compat http://fixture jq
    if [ -f "$temporary/patch" ]; then
        mock_mode=$(jq -er .mode "$temporary/patch")
        patches=$((patches + 1))
    fi
    [ "$mock_mode" = "$expected" ] || {
        printf 'expected %s, got %s\n' "$expected" "$mock_mode" >&2
        exit 1
    }
}

check direct-ipv4
check direct-ipv4
[ "$patches" = 1 ] && [ "$flushes" = 1 ]
mock_selected=company
check company
mock_selected=other
check Rule
mock_selected=Direct
check direct-ipv4
ipv6=1
mock_signature=wifi-b
check Rule
ipv6=0
# shellcheck disable=SC2154 # direct_ipv6_next is set by the sourced company-compat.sh
SECONDS=$((direct_ipv6_next + 1))
check direct-ipv4
ipv6=1
# shellcheck disable=SC2154 # direct_ipv6_next is set by the sourced company-compat.sh
SECONDS=$((direct_ipv6_next + 1))
check Rule
printf 'ok - Direct IPv6 fallback, network changes, recovery and other exits\n'
