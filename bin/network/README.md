# network

| Script | What it does |
|---|---|
| `vpn.sh` (alias `vpn`) | Runs one VPN per client and sshuttle tunnels over it, see below |
| `dns.sh` | Points `/etc/resolv.conf` at the home DNS server, or at `127.0.0.1` when it is unreachable |

# vpn

Client configs live in `~/.config/vpn/` (format: [`config/vpn/`](../../config/vpn/README.md)).

## Commands

| Command | Effect |
|---|---|
| `vpn` | fzf picker over clients and `client/tunnel` entries, then `up` |
| `vpn up <client>` | `sudo openfortivpn -c …` / `sudo openvpn --cd … --config …` in the foreground, Ctrl-C stops it |
| `vpn up <client>/<tunnel>` | If the remote already routes through a VPN: sshuttle in the foreground. Otherwise: the VPN in the foreground, then sshuttle in the background once the remote routes through `ppp*`/`tun*`/`wg*` (log in `$XDG_RUNTIME_DIR/vpn/<client>-<tunnel>.log`). The tunnel stops when the VPN exits |
| `vpn down [<client>[/<tunnel>]]` | Stop a tunnel, a client (tunnels first) or everything |
| `vpn status [--json]` | VPNs, tunnels, unmanaged sshuttle/VPN processes, VPN interfaces |
| `vpn list` / `vpn edit <target>` | List entries / open the client dir or a tunnel file in `$EDITOR` |

`VPN_TIMEOUT` (default 90 s) bounds the wait between the VPN process starting (after the sudo prompt) and the tunnel remote routing through it.

## Privileges and the terminal

The VPN lives as long as its terminal: Ctrl-C, closing the terminal or the VPN dropping stops its tunnels first, then the VPN. sudo runs the VPN in a session of its own, so `vpn` starts it as a background job and signals it itself on exit (no password needed for that).


`sudo` asks for the password every time. sshuttle runs as the user and calls `sudo` itself for its firewall rules. In the background case, the sudo ticket cached for this terminal by `sudo openfortivpn` is refreshed with `sudo -n -v` right before sshuttle starts. If the ticket has expired, the tunnel is not started and you are told to run it from another terminal. Background sshuttle uses `ssh -o BatchMode=yes` (unless `args` sets `-e`), so neither sudo nor ssh can prompt over the VPN's password/OTP prompt.

## status --json (version 1)

The key set is fixed. Keys are always present and `null` when unknown. Times are Unix epoch seconds.

```
{
  "version": 1,
  "generated": <epoch>,
  "clients": [{
    "name": "leonardo", "label": "Leonardo", "color": "#rrggbb" | null,
    "error": null | "<config error>",
    "vpn": null | {
      "type": "openfortivpn" | "openvpn",
      "state": "up" | "connecting" | "down",
      "up": <bool>, "managed": <bool>,          managed = started by vpn.sh
      "pid": <int> | null, "iface": "ppp0" | null, "since": <epoch> | null,
      "config": "<absolute path>"
    },
    "tunnels": [{
      "name": "internal", "id": "leonardo/internal", "error": null | "<config error>",
      "state": "up" | "down", "up": <bool>, "managed": <bool>,
      "pid": <int> | null, "since": <epoch> | null,
      "remote": "<ssh alias>", "subnets": [..], "exclude": [..],
      "dns": <bool>, "auto_nets": <bool>, "needs_vpn": <bool>,
      "route": null | {"ip": "<ipv4>" | null, "dev": "ppp0" | null, "via_vpn": <bool>},
      "log": "<path>" | null
    }]
  }],
  "unmanaged": {
    "vpns":    [{"pid": <int>, "type": "openvpn", "config": "<path>" | null, "since": <epoch>}],
    "tunnels": [{"pid": <int>, "remote": "<alias>" | null, "subnets": [..], "client": "<client with that remote>" | null, "since": <epoch>}]
  },
  "interfaces": [{"name": "ppp0", "up": <bool>, "addr": "<ipv4>" | null}]
}
```

An openfortivpn/openvpn process started outside `vpn` counts as that client's VPN (`managed: false`) when its config path matches. An external sshuttle counts as a tunnel when its remote and subnet set match. Anything else is listed under `unmanaged`.
