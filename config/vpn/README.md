# vpn

`bin/vpn.sh` (alias `vpn`) runs one VPN per client and sshuttle tunnels over it.
Client configs live in `~/.config/vpn/` (mode 700). That directory holds secrets, so it is never linked from this repo. `install.sh --only vpn` creates it. `example/` documents the file format.

```
~/.config/vpn/<client>/
  client.conf            label, color
  vpn.conf               type, config, args          (optional)
  tunnels/<tunnel>.conf  remote, subnets, exclude, dns, auto_nets, needs_vpn, args
  secrets/               VPN configs, certs and keys (dir 700, files 600)
```

The files are read as plain `key=value` lines. They are never sourced, and unknown keys, duplicate keys and stray quotes are errors.

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

## Privileges

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
