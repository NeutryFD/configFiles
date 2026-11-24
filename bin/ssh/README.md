# ssh

| Script | Command | What it does |
|---|---|---|
| `gita.sh` | `gita` | Starts a fresh ssh-agent and adds the private keys picked with fzf |
| `sshs.sh` | `sshs [query]` | Picks a host from `~/.ssh/config` with fzf and opens an SSH session in this terminal |
| `copy-ssh-pubkey.sh` | `public` | Copies a picked `~/.ssh/*.pub` key to the clipboard |

## gita

`gita` is a zsh function that sources `gita.sh`, because `ssh-agent` only works for the shell that holds its `SSH_AUTH_SOCK`. Run directly, the script refuses and exits 1.

- Kills every running `ssh-agent` first, so only the picked keys stay loaded and you know which identity is in use.
- Lists the files in `~/.ssh/` that `file` reports as private keys, Tab/Shift-Tab to move, and `ssh-add`s each pick.
- `alias lazygit='gita && lazygit'` loads a key before lazygit pushes.
- Background `vpn` tunnels run ssh with `BatchMode=yes`, so their key must be loaded with `gita` first.

## sshs

- Lists the `Host` aliases of `~/.ssh/config` (override with `SSH_CONFIG`), following `Include` and skipping wildcard (`*`, `?`) and negated (`!`) patterns. Each alias appears once.
- The preview shows the resolved `hostname`, `user`, `port`, `identityfile` and `proxyjump` from `ssh -G`.
- `sshs <query>` starts filtered and connects straight away when only one host matches.
- `exec`s `ssh`, so closing the session returns to the shell.
