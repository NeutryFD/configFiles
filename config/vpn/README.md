# vpn

Client config format for [`bin/network/vpn.sh`](../../bin/network/README.md) (alias `vpn`), which runs one VPN per client and sshuttle tunnels over it.
Client configs live in `~/.config/vpn/` (mode 700). That directory holds secrets, so it is never linked from this repo. `install.sh --only vpn` creates it. `example/` documents the file format.

```
~/.config/vpn/<client>/
  client.conf            label, color
  vpn.conf               type, config, args          (optional)
  tunnels/<tunnel>.conf  remote, subnets, exclude, dns, auto_nets, needs_vpn, args, via
  secrets/               VPN configs, certs and keys (dir 700, files 600)
```

`via="external"` lists other tunnels of the same client (tried in order) that this tunnel can run nested over, when its remote does not answer directly. A via tunnel cannot have `via` itself, and `via` cannot be combined with `needs_vpn=yes` (`needs_vpn` defaults to `no` with `via`).

The files are read as plain `key=value` lines. They are never sourced, and unknown keys, duplicate keys and stray quotes are errors.
