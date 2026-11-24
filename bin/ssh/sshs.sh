#!/bin/bash

# =============================================================================
# SSH Session Script
# Select a host from ~/.ssh/config and open an SSH session in this terminal
# Usage: sshs [query]
# =============================================================================

SSH_CONFIG="${SSH_CONFIG:-$HOME/.ssh/config}"

# Print Host aliases from a config file, following Include directives
list_hosts() {
  local file="$1" key value pattern inc patterns
  [[ -f "$file" ]] || return 0
  while read -r key value; do
    read -ra patterns <<< "$value"
    case "${key,,}" in
      host)
        for pattern in "${patterns[@]}"; do
          [[ "$pattern" == *[\*\?\!]* ]] || echo "$pattern"
        done
        ;;
      include)
        for pattern in "${patterns[@]}"; do
          [[ "$pattern" == /* || "$pattern" == "~"* ]] || pattern="$HOME/.ssh/$pattern"
          pattern="${pattern/#\~/$HOME}"
          for inc in $pattern; do
            list_hosts "$inc"
          done
        done
        ;;
    esac
  done < <(sed -E 's/#.*//; s/^[[:space:]]+//; s/[[:space:]]*=[[:space:]]*/ /' "$file")
}

mapfile -t hosts < <(list_hosts "$SSH_CONFIG" | awk '!seen[$0]++')

if [[ ${#hosts[@]} -eq 0 ]]; then
  echo "No hosts found in $SSH_CONFIG"
  exit 1
fi

selected_host=$(printf "%s\n" "${hosts[@]}" | fzf --cycle --layout=reverse --header="Select SSH host" --bind "tab:down,btab:up" \
  --query="$*" --select-1 \
  --preview 'ssh -G {} 2>/dev/null | grep -iE "^(hostname|user|port|identityfile|proxyjump) "' --preview-window=down,6)

if [[ -z "$selected_host" ]]; then
  echo "No host selected."
  exit 0
fi

exec ssh "$selected_host"
