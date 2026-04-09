#!/bin/bash

# =============================================================================
# SSH Agent Script
# Start ssh-agent and add private keys interactively
# Must be SOURCED to preserve SSH_AUTH_SOCK environment variable
# Usage: source git-ssh-agent
# =============================================================================

FZF_OPTS="--layout=reverse"

is_sourced() {
    [[ -z "${ZSH_VERSION}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0
    [[ -n "${ZSH_VERSION}" ]] && [[ "$0" != *git-ssh-agent* ]] && return 0
    return 1
}

# Show usage if executed instead of sourced
if ! is_sourced; then
    echo "Source this script: source $0"
    exit 1
fi

# Kill any existing ssh-agent
pkill ssh-agent 2>/dev/null

# Start new ssh-agent and capture environment
eval "$(ssh-agent -s)"

# Find private keys in ~/.ssh/
private_keys=()
for f in "$HOME/.ssh/"*; do
  if [[ -f "$f" && "$f" != *.pub ]] && file "$f" | grep -qi "private key"; then
    private_keys+=("$f")
  fi
done

# Select keys with fzf and add them
if [[ ${#private_keys[@]} -gt 0 ]]; then
  selected_keys=$(printf "%s\n" "${private_keys[@]}" | fzf --multi --layout=reverse --header="Select SSH keys to add")
  if [[ -n "$selected_keys" ]]; then
    while IFS= read -r key; do
      ssh-add "$key" 2>/dev/null && echo "Added key: $key"
    done <<< "$selected_keys"
  else
    echo "No keys selected."
  fi
else
  echo "No private keys found in ~/.ssh/"
fi
