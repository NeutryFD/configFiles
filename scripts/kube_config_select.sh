#!/bin/bash

# =============================================================================
# selec the kube config file
# Select and export KUBECONFIG environment variable
# =============================================================================

config_files=()
for f in "$HOME/.kube/"*; do
  if [[ -f "$f" ]]; then
    config_files+=("$f")
  fi
done

if [[ ${#config_files[@]} -gt 0 ]]; then
  selected_config_files=$(printf "%s\n" "${config_files[@]}" | fzf --layout=reverse --header="Select config_files")
  
  if [[ -n "$selected_config_files" ]]; then
export KUBECONFIG="$selected_config_files"
    echo "using: $selected_config_files"
  else
    echo "No config file selected."
  fi
else
  echo "No config file found in ~/.kube/"
fi

