#!/bin/bash

# =============================================================================
# Copy Public Key Script
# Select and copy SSH public keys to clipboard
# =============================================================================

# Find public keys in ~/.ssh/
public_keys=()
for f in "$HOME/.ssh/"*.pub; do
  if [[ -f "$f" ]]; then
    public_keys+=("$f")
  fi
done

if [[ ${#public_keys[@]} -gt 0 ]]; then
  selected_key=$(printf "%s\n" "${public_keys[@]}" | fzf --cycle --multi --layout=reverse --header="Select public key to copy")
  
  if [[ -n "$selected_key" ]]; then
    xclip -sel clip < "$selected_key"
    echo "Copied to clipboard: $selected_key"
  else
    echo "No key selected."
  fi
else
  echo "No public keys found in ~/.ssh/"
fi
