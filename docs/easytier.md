# EasyTier mesh

A private EasyTier network evaluated alongside Tailscale. All nodes share one
network name/secret. Membership is by role, never by hostname
(`.chezmoitemplates/easytier/role.tmpl`): **every Mac** joins as a client with a
DHCP-assigned virtual IP (nix-darwin LaunchDaemon), and a **Linux machine**
joins only as an exit when its own `~/.config/chezmoi/chezmoi.toml` `[data]`
sets `easytierExit = "<name>"` (a key of `easytier.exits`, which holds the
fixed IPs clients point at). Both run the official release binaries from
`/nix/store`. The bastion relay and the NAS are deployed by hand and recorded
here so the whole mesh can be rebuilt. This repository is public: the bastion
address lives in gopass `easytier/bastion-host`, and public IPs appear here only
as placeholders.

| Node       | Role                               | Virtual IP      | Deployed by                                    |
| ---------- | ---------------------------------- | --------------- | ---------------------------------------------- |
| bastion    | discovery + fallback relay, no TUN | —               | systemd unit (below), `<bastion-ip>:11010`     |
| nas        | member                             | 10.144.144.2/24 | Docker Compose on DSM (below)                  |
| every Mac  | client                             | DHCP (in /24)   | this repo: nix-darwin LaunchDaemon (see below) |
| gpuserver1 | member, exit `gpuserver`           | 10.144.144.3/24 | this repo: systemd unit (see below)            |

All nodes run v2.6.4 (`easytier-core 2.6.4-8428a89d`); the binaries are
byte-identical to the official GitHub release assets (bastion zip, NAS image
`easytier/easytier:v2.6.4@sha256:91d6732e…`, Mac zip via `fetchurl`). Public
shared nodes (`-e`) are never used; STUN uses the bastion's own endpoints
`<bastion-ip>:38478-38480`.

Members (Mac, NAS, Linux nodes) listen on **UDP only** (`udp://0.0.0.0:11010`,
`easytier.listeners`): with a TCP listener a peer that can reach it (e.g. over
public IPv6) links over TCP first and EasyTier never upgrades an existing direct
link, and path loss then throttles tunnelled TCP; TCP hole punching is disabled
for the same reason. Only IPv4
can be hole-punched (both ends drop unsolicited inbound IPv6 UDP). Macs pass
`--bind-device true`, which pins EasyTier's own sockets (peers, STUN, hole
punching) to the physical NIC, so a TUN owning the default route (Surge
Enhanced Mode, sing-box) never carries them — the same way Tailscale's own
WireGuard traffic bypasses its exit-node routes.
The bastion keeps TCP + UDP for discovery and fallback relay.

## Exit nodes

Members pick an internet egress **locally** (Surge policy group, sing-box
selector); nothing restarts and no root is needed to switch. Exits run
**shadowsocks-rust** (`ssserver`, Shadowsocks 2022 `2022-blake3-aes-256-gcm`,
TCP + UDP) on their **virtual IP only**. Its ACL accepts only clients in
`10.144.144.0/24` — Linux accepts packets for a local address on any
interface, so a same-LAN host could otherwise reach the port via the physical
NIC — and refuses loopback, private and overlay destinations. `config.json`
holds `${SS_PASSWORD}`; the key (gopass `easytier/exit-ss-password`) lives in a
separate 0600 env file.

| Exit       | Address             | Deployed by                                                                                                  |
| ---------- | ------------------- | ------------------------------------------------------------------------------------------------------------ |
| gpuserver1 | `10.144.144.3:1080` | this repo: `easytierExit` → systemd --user `ss-exit.service`, `~/.config/ss-exit/{config.json,acl.list,env}` |
| nas        | `10.144.144.2:1080` | container `ss-exit` in the NAS compose below; `ss-exit.{json,acl,env}` (0600, env written from gopass)       |

- Clients: Surge on the home Mac (`ss` proxies `gpuserver`, `nas`,
  `encrypt-method=2022-blake3-aes-256-gcm`, `udp-relay=true`; group
  `Exit = select, DIRECT, …`; mesh/LAN/peer CIDRs `DIRECT`, then `FINAL,Exit`);
  sing-box everywhere else (see "sing-box" below).
- Not used, and why: EasyTier's `--socks5` takes only a port and listens on all
  interfaces without authentication; gost's Shadowsocks UDP (`ssu`) rejects
  Shadowsocks 2022 UDP from Surge (`cipher: message authentication failed`).
- Exit roles are set per machine (`easytierExit` in its local chezmoi data;
  the NAS is listed in `exits` but deployed by hand), never inferred from
  `headless`: an exit relays other machines' traffic from its own IP.

### gost features and their replacements

gost was removed from aqua. Its features map to these tools. Only sing-box,
shadowsocks-rust, Hysteria2 and realm are installed (none of the last three
on work machines, which only consume the exits); the rest is one
`nix run nixpkgs#<name>` away:

| gost feature                         | Use instead                                                                         |
| ------------------------------------ | ----------------------------------------------------------------------------------- |
| Shadowsocks / proxy server           | shadowsocks-rust `ssserver`; sing-box `socks`/`http`/`mixed` inbounds               |
| Local protocol conversion            | Surge, sing-box, `sslocal`                                                          |
| Multi-hop chains with node selection | sing-box `detour` + `selector`/`urltest`; Surge `underlying-proxy`                  |
| Reverse tunnels / NAT traversal      | EasyTier, Tailscale                                                                 |
| L3 tunnel (TUN)                      | EasyTier, Tailscale                                                                 |
| TCP/UDP port forwarding (any target) | `realm`; sing-box `direct` inbound with an override target                          |
| KCP transport                        | EasyTier `--enable-kcp-proxy` / `--enable-quic-proxy` (on); Hysteria2 for lossy WAN |
| fake-TCP (UDP disguised as TCP)      | EasyTier `faketcp://` listener (experimental)                                       |
| ICMP tunnel                          | none installed (`nix run nixpkgs#pingtunnel`)                                       |
| WebSocket / TLS / QUIC camouflage    | sing-box (VLESS Reality, AnyTLS, WS), Hysteria2, bastion v2ray + Caddy              |
| DNS forwarder                        | sing-box `dns`                                                                      |
| Rate limiting                        | `tc` (Linux), `pf` (macOS)                                                          |
| Per-connection logs                  | sing-box connections API, Surge Dashboard, `ssserver -v`                            |
| Prometheus metrics                   | node_exporter (host level)                                                          |

Ad hoc, gost itself is still one command away: `nix run nixpkgs#gost`.

Not used: kcptun (upstream repository gone in 2026), udp2raw and ptunnel-ng
(unmaintained, no macOS builds), rathole (no release since 2023).

## sing-box (every machine)

Every machine has sing-box (macOS: nix package from the official release,
`nix-config/modules/sing-box{,-package}.nix.tmpl`; Linux: aqua). How it runs is
decided by `.chezmoitemplates/sing-box/mode.tmpl`, and all variants share one
config template, `.chezmoitemplates/sing-box/config.tmpl`:

| Machine        | Mode      | Runs as                                           | Default   |
| -------------- | --------- | ------------------------------------------------- | --------- |
| every Mac      | `system`  | root LaunchDaemon `org.nixos.sing-box` with a TUN | always on |
| headless Linux | `service` | systemd --user `sing-box.service`                 | always on |
| other Linux    | —         | CLI only                                          | —         |

- Config: mixed SOCKS5/HTTP inbound `127.0.0.1:7890`; private/overlay
  destinations direct, everything else via selector `Exit`: `direct` (default),
  every entry of `easytier.exits` except the machine's own, and `edge` when
  gopass `sing-box/edge-outbound` exists. Clash API and metacubexd panel at
  `http://127.0.0.1:9090/ui` (secret: `gopass show -o sing-box/clash-api-secret`).
  Secrets: gopass `easytier/exit-ss-password`, `sing-box/clash-api-secret`;
  without them the mode falls back to CLI only.
- Macs (`system`), like a Tailscale exit node: a TUN with `auto_route` carries
  every app's traffic; `Exit` defaults to `direct`, so nothing changes until an
  exit is picked. It never sets the system proxy and leaves system DNS alone
  (`dns_mode: disabled`); LAN/company/VPN ranges, the mesh, Tailscale,
  link-local and multicast stay off the TUN (`singBox.tunExcludeAddress`).
  EasyTier's own traffic bypasses it via `--bind-device`. Because sing-box binds
  its outbounds to the default NIC under a TUN, the daemon injects EasyTier's
  utun (dynamic unit number) as `bind_interface` into the exit outbounds at
  start and restarts when it changes. A root daemon is also exempt from macOS
  Local Network privacy, which makes a user-launched sing-box fail to reach the
  LAN DNS server (`write: broken pipe`). Config:
  `.chezmoiscripts/run_after_25_sing-box.sh.tmpl` fills the gopass secrets in
  with jq at run time, runs `sing-box check` and writes
  `/etc/sing-box/config.json` (root:wheel 0600). Log `/var/log/sing-box.log`.
  Only one TUN may own the default route, so Surge Enhanced Mode must be off.
- Headless Linux (`service`): no TUN; chezmoi renders
  `~/.config/sing-box/config.json` (0600); a shell opts in with `proxy-on` /
  `proxy-off` (`dot_custom/functions.sh`). Logs `journalctl --user -u sing-box`,
  panel via `ssh -L 9090:127.0.0.1:9090 <host>`.
- Edge outbound: `ssh <edge-host> cat /etc/vps-proxy/clients/<name>.conf |
edge-import` converts the device profile the edge host issues (Surge format:
  vmess + WebSocket + TLS + PKCS#12 client certificate) into one sing-box
  outbound, tag `edge`, stored as gopass `sing-box/edge-outbound`. Re-run after
  the device's credentials are rotated. The entry is a complete outbound
  object, so a different protocol later only means a different gopass value.
- Switch exits in the panel or by API:
  `curl -X PUT -H "Authorization: Bearer $secret" -d '{"name":"nas"}' http://127.0.0.1:9090/proxies/Exit`
  (the choice persists in the cache file).

## Installed replacement tools

aqua: `sing-box` (Linux; Macs run the nix build from
`nix-config/modules/sing-box.nix`). `aqua-private.yaml`, skipped on work
machines (consumers only): `ssserver`/`sslocal` (shadowsocks-rust),
`hysteria` (Hysteria2), `realm`.

## Credentials

Generated with gopass and never stored in this repository:

- `easytier/network-name`, `easytier/network-secret` (64 alphanumerics each)
- Every node reads them from a root-only env file as
  `ET_NETWORK_NAME` / `ET_NETWORK_SECRET` (never on a command line):
  - Mac: `/etc/easytier/easytier.env` (root:wheel 0600), written by
    `.chezmoiscripts/run_after_24_easytier-node.sh`
  - Linux nodes: `/etc/easytier/easytier.env` (root:root 0600), same script
  - bastion: `/etc/easytier/easytier.env` (root:root 0600, dir 0700)
  - NAS: `/volume1/docker/easytier/easytier.env` (0600, dir 0700 with the
    inherited Synology ACL removed — `/volume1/docker` grants everyone read)

Rotate: `gopass generate -f --symbols=false easytier/network-secret 64`, then

```sh
render() { printf 'ET_NETWORK_NAME=%s\nET_NETWORK_SECRET=%s\n' \
  "$(gopass show -o easytier/network-name)" "$(gopass show -o easytier/network-secret)"; }
render | ssh bastion 'umask 077; cat >/etc/easytier/easytier.env && systemctl restart easytier'
render | ssh nas 'umask 077; cat >/volume1/docker/easytier/easytier.env \
  && cd /volume1/docker/easytier && sudo docker compose up -d --force-recreate'
chezmoi apply ~/.chezmoiscripts/24_easytier-node.sh   # each repo-managed node (sudo on Mac)
```

## Mac (this repo)

- `.chezmoidata/easytier.yaml` — bastion ports, listeners and `exits`; every
  Mac gets the daemon (`--dhcp true`), no per-host entry needed. Without gopass
  `easytier/bastion-host` (fresh machine, CI) the module renders empty.
- `.chezmoidata/versions.yaml` — `easytier` + macOS zip digests, bumped by the
  `update-versions` workflow (stable releases only).
- `nix-config/modules/easytier.nix.tmpl` — packages the official zip (not the
  nixpkgs package) and runs `org.nixos.easytier` as root (TUN needs root).
  `easytier-cli` is on PATH from the same build. Logs: `/var/log/easytier.log`
  (rotated by newsyslog).
- Apply: `chezmoi apply ~/.chezmoiscripts/02_init.sh ~/.chezmoiscripts/24_easytier-node.sh`
  (02 runs `darwin-rebuild switch` when the module hash changes).
- Status: `easytier-cli peer`, `easytier-cli route`, `easytier-cli node`.
- easytier-core adds the `10.144.144.0/24 → utunN` route once and never
  restores it. If another tool deletes it, `10.144.144.x` silently falls into
  the default route; recover with `sudo launchctl kickstart -k system/org.nixos.easytier`.
- Surge Enhanced Mode: with `--bind-device` no `tun-excluded-routes` entries are
  needed for EasyTier peers. Never list `10.144.144.0/24` or
  `100.64.0.0/10` there: Surge implements exclusions as `en0` routes, which
  hijack the EasyTier/Tailscale routes (and removing them later deletes
  EasyTier's route). Enabling Enhanced Mode also stops Tailscale once; reconnect
  it and both run side by side.

## Linux nodes (this repo)

- Needs a multi-user nix (root-owned `/nix/store`), `/dev/net/tun`, and sudo
  for the user running `chezmoi apply`; no Docker.
- `run_after_24_easytier-node.sh` builds the flake output `easytier`
  (`nix-config/modules/easytier-package.nix`, out-link
  `~/.local/state/easytier/easytier` as the GC root), renders
  `/etc/systemd/system/easytier.service` with `ExecStart` pointing at that
  store path, writes the env file, and restarts the unit — sudo only when the
  unit, the credentials or the running state changed. The unit runs as a
  `DynamicUser` with only `CAP_NET_ADMIN`/`CAP_NET_RAW` and `/dev/net/tun`.
- Apply on such a host (the script must run after `~/nix-config` is written):
  `chezmoi apply ~/nix-config && chezmoi apply ~/.chezmoiscripts/24_easytier-node.sh`.
  A full `chezmoi apply` orders this correctly by itself.
- Status: `~/.local/state/easytier/easytier/bin/easytier-cli peer`, `systemctl status easytier`.

## bastion

Binaries: `/opt/easytier/2.6.4/{easytier-core,easytier-cli}` from
`easytier-linux-x86_64-v2.6.4.zip`, `/opt/easytier/current` → `2.6.4`,
`/usr/local/bin/easytier-cli` → current. System user `easytier` (nologin).

`/etc/systemd/system/easytier.service`:

```ini
[Unit]
Description=EasyTier private relay/discovery node (no TUN, no virtual IP)
Documentation=https://easytier.cn/en/guide/network/configurations.html
After=network-online.target vps-firewall.service
Wants=network-online.target

[Service]
Type=simple
User=easytier
Group=easytier
# ET_NETWORK_NAME / ET_NETWORK_SECRET live only here (root:root 0600).
EnvironmentFile=/etc/easytier/easytier.env
ExecStart=/opt/easytier/current/easytier-core \
  --hostname bastion \
  --no-tun true \
  --private-mode true \
  --listeners tcp://0.0.0.0:11010 udp://0.0.0.0:11010 \
  --rpc-portal 127.0.0.1:15888 \
  --rpc-portal-whitelist 127.0.0.1/32 \
  --stun-servers <bastion-ip>:38478 <bastion-ip>:38479 <bastion-ip>:38480 \
  --stun-servers-v6 \
  --console-log-level info
Restart=on-failure
RestartSec=5s
StateDirectory=easytier
WorkingDirectory=/var/lib/easytier

NoNewPrivileges=yes
CapabilityBoundingSet=
AmbientCapabilities=
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectKernelLogs=yes
ProtectControlGroups=yes
ProtectClock=yes
ProtectHostname=yes
ProtectProc=invisible
ProcSubset=pid
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX AF_NETLINK
RestrictNamespaces=yes
RestrictRealtime=yes
RestrictSUIDSGID=yes
LockPersonality=yes
# MemoryDenyWriteExecute=yes  -> easytier-core 2.6.4 SEGVs at startup with it
SystemCallArchitectures=native
SystemCallFilter=@system-service
SystemCallFilter=~@privileged @resources
UMask=0077
MemoryMax=256M
TasksMax=64

[Install]
WantedBy=multi-user.target
```

Firewall: two lines added to `public_input` in `/usr/local/sbin/vps-firewall`
right after `udp dport {{38478,38479,38480}} accept`, applied with
`vps-firewall --check && vps-firewall` (never raw `nft`):

```text
  tcp dport 11010 accept
  udp dport 11010 accept
```

Backup of the pre-change script: `/usr/local/sbin/vps-firewall.bak-20261024160103-pre-easytier`;
ruleset snapshots: `/root/vps_guard.{pre,post}-easytier.nft`.

## NAS (Synology DSM 7.4.1)

`/dev/net/tun` and the `tun` module are present by default. `YixianLu` may run
only `/usr/local/bin/docker` via passwordless sudo. Nothing is shared with the
`hysteria-*` / `rsyncd-*` stacks.

`/volume1/docker/easytier/compose.yaml`:

```yaml
name: easytier
services:
  easytier:
    # v2.6.4 index digest; easytier-core inside == official linux-x86_64 zip.
    image: easytier/easytier:v2.6.4@sha256:91d6732ea5ff71542fdb99333d2ee7b168e973443114db84db061e452427d91e
    container_name: easytier
    restart: unless-stopped
    network_mode: host
    cap_drop: [ALL]
    cap_add: [NET_ADMIN, NET_RAW]
    devices:
      - /dev/net/tun:/dev/net/tun
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
    env_file: ./easytier.env
    command:
      - --hostname=nas
      - --ipv4=10.144.144.2/24
      - --peers=tcp://<bastion-ip>:11010
      - --listeners=udp://0.0.0.0:11010
      - --stun-servers=<bastion-ip>:38478
      - --stun-servers=<bastion-ip>:38479
      - --stun-servers=<bastion-ip>:38480
      - --enable-quic-proxy=true
      - --enable-kcp-proxy=true
      - --rpc-portal=127.0.0.1:15888
      - --rpc-portal-whitelist=127.0.0.1/32
      - --default-protocol=udp
      - --disable-tcp-hole-punching=true
      - --private-mode=true
      - --console-log-level=info
    logging:
      driver: json-file
      options:
        max-size: 10m
        max-file: "3"
  # Shadowsocks 2022 exit (shadowsocks-rust) on the virtual IP only; ss-exit.acl
  # accepts only mesh clients and refuses private/overlay destinations. The key
  # comes from ss-exit.env (gopass easytier/exit-ss-password), not the config.
  # Retried until easytier has brought up 10.144.144.2.
  ss-exit:
    image: ghcr.io/shadowsocks/ssserver-rust:v1.25.0@sha256:22240c07d8ce3a36421ede770bd775dcc5fc56d5d829943196957b05452dc36f
    container_name: ss-exit
    user: "1026:100"
    restart: unless-stopped
    network_mode: host
    depends_on: [easytier]
    cap_drop: [ALL]
    security_opt:
      - no-new-privileges:true
    read_only: true
    env_file: ./ss-exit.env
    volumes:
      - ./ss-exit.json:/etc/shadowsocks-rust/config.json:ro
      - ./ss-exit.acl:/etc/shadowsocks-rust/acl.list:ro
    # The image default adds `-a nobody`, which needs root; this runs as 1026.
    command:
      - ssserver
      - --log-without-time
      - -c
      - /etc/shadowsocks-rust/config.json
    logging:
      driver: json-file
      options:
        max-size: 10m
        max-file: "3"
```

Status: `sudo docker exec easytier easytier-cli peer`.

## Removal

- Macs: all Macs are members, so removal is repo-wide: drop
  `./modules/easytier.nix` from the flake (or the gopass `easytier/bastion-host`
  entry on one machine to opt just that Mac out), then
  `chezmoi apply ~/.chezmoiscripts/02_init.sh`; `sudo rm -rf /etc/easytier`;
  `rm ~/.local/state/chezmoi/easytier-env.sha256`. To remove it from the repo
  entirely, revert the EasyTier commits (data, module, versions, script, docs).
- bastion: `systemctl disable --now easytier`; remove the unit, `/opt/easytier`,
  `/etc/easytier`, `/var/lib/easytier`, `/usr/local/bin/easytier-cli`,
  `userdel easytier`; restore the firewall with
  `cp -p /usr/local/sbin/vps-firewall.bak-20261024160103-pre-easytier /usr/local/sbin/vps-firewall`
  then `vps-firewall --check && vps-firewall`.
- NAS: `cd /volume1/docker/easytier && sudo docker compose down`,
  `sudo docker image rm easytier/easytier:v2.6.4 ghcr.io/shadowsocks/ssserver-rust:v1.25.0`, delete the directory.
- Exits: on gpuserver1 run `systemctl --user disable --now ss-exit` and drop
  `easytierExit` from its chezmoi.toml (the unit and `~/.config/ss-exit` then stop rendering; delete
  them); remove the `gpuserver`/`nas` proxies and the `Exit` group
  from Surge; `gopass rm easytier/exit-ss-password`.
- gopass: `gopass rm -r easytier`.
- sing-box: `gopass rm -r sing-box` (every mode then falls back to CLI only).
  Mac: `chezmoi apply ~/.chezmoiscripts/02_init.sh` drops the daemon; then
  `sudo rm -r /etc/sing-box /var/lib/sing-box /var/run/sing-box`. Linux:
  `systemctl --user disable --now sing-box`, delete `~/.config/sing-box`,
  `~/.local/state/sing-box`. To drop it entirely, revert the sing-box commits
  (data, templates, nix modules, versions, aqua entry, import script).
