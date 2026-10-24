# EasyTier mesh

A private EasyTier network evaluated alongside Tailscale. All nodes share one
network name/secret. Hosts listed under `easytier.nodes` in
`.chezmoidata/easytier.yaml` are managed by this repository (macOS via a
nix-darwin LaunchDaemon, Linux via a systemd unit; both run the official
release binaries from `/nix/store`); the bastion relay and the NAS are
deployed by hand and recorded here so the whole mesh can be rebuilt.

| Node       | Role                               | Virtual IP      | Deployed by                                    |
| ---------- | ---------------------------------- | --------------- | ---------------------------------------------- |
| bastion    | discovery + fallback relay, no TUN | —               | systemd unit (below), `<bastion-ip>:11010`   |
| nas        | member                             | 10.144.144.2/24 | Docker Compose on DSM (below)                  |
| summit     | member                             | 10.144.144.1/24 | this repo: nix-darwin LaunchDaemon (see below) |
| gpuserver1 | member                             | 10.144.144.3/24 | this repo: systemd unit (see below)            |

All nodes run v2.6.4 (`easytier-core 2.6.4-8428a89d`); the binaries are
byte-identical to the official GitHub release assets (bastion zip, NAS image
`easytier/easytier:v2.6.4@sha256:91d6732e…`, Mac zip via `fetchurl`). Public
shared nodes (`-e`) are never used; STUN uses the bastion's own endpoints
`<bastion-ip>:38478-38480`.

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

- `.chezmoidata/easytier.yaml` — peers, STUN servers, and `nodes`: only hosts
  listed there get the daemon; every other machine renders an empty module.
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
- Surge Enhanced Mode: exclude only the underlay peers, e.g.
  `tun-excluded-routes = <bastion-ip>/32, <nas-public-ip>/32`, so hole-punched
  UDP is not relayed in user space. Never list `10.144.144.0/24` or
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
      - --listeners=tcp://0.0.0.0:11010
      - --listeners=udp://0.0.0.0:11010
      - --stun-servers=<bastion-ip>:38478
      - --stun-servers=<bastion-ip>:38479
      - --stun-servers=<bastion-ip>:38480
      - --enable-quic-proxy=true
      - --enable-kcp-proxy=true
      - --rpc-portal=127.0.0.1:15888
      - --rpc-portal-whitelist=127.0.0.1/32
      - --default-protocol=udp
      - --private-mode=true
      - --console-log-level=info
    logging:
      driver: json-file
      options:
        max-size: 10m
        max-file: "3"
```

Status: `sudo docker exec easytier easytier-cli peer`.

## Removal

- Mac: delete `summit` from `easytier.nodes` (the module becomes empty), then
  `chezmoi apply ~/.chezmoiscripts/02_init.sh`; `sudo rm -rf /etc/easytier`;
  `rm ~/.local/state/chezmoi/easytier-env.sha256`. To remove it from the repo
  entirely, revert the EasyTier commits (data, module, versions, script, docs).
- bastion: `systemctl disable --now easytier`; remove the unit, `/opt/easytier`,
  `/etc/easytier`, `/var/lib/easytier`, `/usr/local/bin/easytier-cli`,
  `userdel easytier`; restore the firewall with
  `cp -p /usr/local/sbin/vps-firewall.bak-20261024160103-pre-easytier /usr/local/sbin/vps-firewall`
  then `vps-firewall --check && vps-firewall`.
- NAS: `cd /volume1/docker/easytier && sudo docker compose down`,
  `sudo docker image rm easytier/easytier:v2.6.4`, delete the directory.
- gopass: `gopass rm -r easytier`.
