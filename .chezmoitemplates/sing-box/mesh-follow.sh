#!/usr/bin/env bash
# Included in the Mac LaunchDaemon, next to company-compat.sh. api() is supplied
# by the daemon (bearer header in the root-only runtime directory), and
# `mesh_net` / `tun_ip` come from the daemon's variables.
#
# The `Mesh` selector (.chezmoitemplates/sing-box/config.tmpl) says how this Mac
# reaches the mesh: EasyTier (the kernel route, hole-punched p2p) or bastion
# (the mesh traffic rides the bastion tunnel, so no EasyTier packet leaves the
# machine, which is what a network that blocks it needs).
#
# Two separate duties, so a hand-picked Mesh survives:
#   - Egress CHANGES -> Mesh follows it: bastion and "<exit> via bastion" mean
#     bastion, a VPN endpoint (listed in mesh_keep) leaves Mesh as it is (in a
#     network that blocks EasyTier, resuming it would also expose the bastion's
#     address), anything else means EasyTier. The first look after a start
#     only records Egress (the selection is remembered across restarts).
#   - Mesh decides the machine's state, whoever set it:
#       bastion   pause EasyTier (marker file; easytier.nix waits on it) and send
#                 the mesh into the TUN with two /25 routes, which beat
#                 EasyTier's /24 the moment they exist.
#       EasyTier  drop the routes and the marker; the waiting EasyTier starts.
# The marker lives in /var/db, so a reboot in a blocking network stays quiet.
# Stuck paused (daemon gone)? `sudo rm /var/db/easytier-paused`.
# shellcheck disable=SC2154,SC2016 # mesh_net/tun_ip/mesh_keep come from the daemon; jq, not the shell, expands $n
mesh_pause_marker=/var/db/easytier-paused
mesh_applied=
mesh_last_egress=

mesh_tun_iface() {
    /sbin/ifconfig 2>/dev/null | /usr/bin/awk -v ip="$tun_ip" '
        /^[a-z0-9]+:/ { i = $1; sub(/:$/, "", i) }
        $1 == "inet" && $2 == ip { print i; exit }'
}

# The two halves of the mesh /24 (10.144.144.0/25 and 10.144.144.128/25).
mesh_halves() {
    # awk, not shell parameter expansion: the daemon script is a Nix string, where a dollar-brace means Nix.
    /usr/bin/awk -v net="$mesh_net" 'BEGIN { split(net, o, /[.\/]/); printf "%s.%s.%s.0/25\n%s.%s.%s.128/25\n", o[1], o[2], o[3], o[1], o[2], o[3] }'
}

mesh_routes_del() {
    local half
    for half in $(mesh_halves); do
        /sbin/route -n delete -net "$half" >/dev/null 2>&1 || true
    done
}

mesh_routes_add() {
    local tun half
    tun="$(mesh_tun_iface)"
    [ -n "$tun" ] || return 1
    mesh_routes_del
    for half in $(mesh_halves); do
        /sbin/route -n add -net "$half" -interface "$tun" >/dev/null 2>&1 || return 1
    done
}

mesh_apply() {
    local want="$1"
    [ "$want" = "$mesh_applied" ] && return 0
    case "$want" in
    bastion)
        # Routes first: if the TUN has no address yet, leave EasyTier alone.
        mesh_routes_add || return 1
        : >"$mesh_pause_marker"
        /bin/launchctl kickstart -k system/org.nixos.easytier >/dev/null 2>&1 || true
        ;;
    *)
        mesh_routes_del
        /bin/rm -f "$mesh_pause_marker"
        ;;
    esac
    echo "sing-box: Mesh $want (EasyTier $([ -e "$mesh_pause_marker" ] && echo paused || echo running))" >&2
    mesh_applied="$want"
}

mesh_follow() {
    local api="$1" jq_bin="$2" egress mesh want
    mesh="$(api "$api/proxies/Mesh" | "$jq_bin" -er '.now')" || return 0 # no Mesh group here
    egress="$(api "$api/proxies/Egress" | "$jq_bin" -er '.now')" || return 1
    if [ "$egress" != "$mesh_last_egress" ]; then
        if [ -n "$mesh_last_egress" ]; then
            case "$egress" in
            bastion | *' via bastion') want=bastion ;;
            *) want=EasyTier ;;
            esac
            if printf '%s\n' "$mesh_keep" | /usr/bin/grep -qxF -- "$egress"; then want="$mesh"; fi
            if [ "$want" != "$mesh" ]; then
                api -X PUT -H 'Content-Type: application/json' \
                    -d "$("$jq_bin" -cn --arg n "$want" '{name: $n}')" \
                    "$api/proxies/Mesh" || return 1
                mesh="$want"
            fi
        fi
        mesh_last_egress="$egress"
    fi
    mesh_apply "$mesh"
}
