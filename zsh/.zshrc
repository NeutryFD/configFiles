#zmodload zsh/zprof
# =========================
# Zsh optimnizations options
# =========================
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"
ZSH_COMPDUMP="$HOME/.zcompdump-$ZSH_VERSION"
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
ZSH_AUTOSUGGEST_USE_ASYNC=1

# =========================
# Oh-My-Zsh Setup
# =========================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell" 

# =========================
# Plugins
# =========================
plugins=(
  #git
  zsh-autosuggestions
  zsh-syntax-highlighting
)
source "$ZSH/oh-my-zsh.sh"
source <(kubectl completion zsh)
export EDITOR="/usr/local/bin/nvim"

# =========================
# Helpers
# =========================

# Mount remote FS via SSHFS and cd into it
sshfslocal() {
  local host="$1"
  local dir="${2:-$HOME/remoteDir}"
  mkdir -p "$dir"
  sshfs -o idmap=user "$host" "$dir" && cd "$dir"
}

# Copy public SSH key to clipboard
public() {
  xclip -sel clip < "$HOME/.ssh/id_rsa.pub"
}

# Start ssh-agent and add private keys interactively
git-ssh-agent() {
  pkill ssh-agent 2>/dev/null
  eval "$(ssh-agent -s)"

  local private_keys=()
  for f in "$HOME/.ssh/"*; do
    if [[ -f "$f" && "$f" != *.pub ]] && file "$f" | grep -qi "private key"; then
      private_keys+=("$f")
    fi
  done

  if [[ ${#private_keys[@]} -gt 0 ]]; then
    local selected_keys
    selected_keys=$(printf "%s\n" "${private_keys[@]}" | fzf --multi --header="Select SSH keys (TAB to select multiple, ENTER to confirm)")
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
}

# Clean clipboard and restart bspwm
clean-copy() {
  rm -rf /run/user/1000/clipmenu*
  pgrep -f clipmenu | xargs -r kill >/dev/null
  bspc wm -r
  echo "Clipboard cleaned"
}

# Kubernetes helpers
kubectl_pod_usage() {
  local namespace="$1"
  local label_selector="$2"
  [[ -z "$namespace" ]] && { echo "Usage: kubectl_pod_usage <namespace> [label_selector]"; return 1; }

  local metrics_url="/apis/metrics.k8s.io/v1beta1/namespaces/$namespace/pods"
  [[ -n "$label_selector" ]] && metrics_url="$metrics_url?labelSelector=$label_selector"

  echo -e "POD_NAME\tCPU_USAGE\tMEMORY_USAGE"
  echo -e "--------\t---------\t------------"
  kubectl get --raw "$metrics_url" | jq -r '
    .items[] |
    (.containers[0].usage.cpu // "0") as $cpu |
    (.containers[0].usage.memory // "0") as $mem |
    ($cpu | gsub("n$"; "") | tonumber / 1000000000) as $cpu_cores |
    ($mem | gsub("Ki$"; "") | tonumber / 1048576) as $mem_gb |
    "\(.metadata.name)\t\($cpu_cores | . * 1000 | round / 1000) cpu\t\($mem_gb | . * 100 | round / 100) GB"
  ' | column -t | head -15
}

kubectl_pod_request() {
  local namespace="$1"
  local label_selector="$2"
  [[ -z "$namespace" ]] && { echo "Usage: kubectl_pod_request <namespace> [label_selector]"; return 1; }

  echo -e "POD_NAME\tCPU_REQUEST\tMEMORY_REQUEST"
  echo -e "--------\t-----------\t--------------"

  if [[ -n "$label_selector" ]]; then
    kubectl get pods -n "$namespace" -l "$label_selector" -o json | \
      jq -r '.items[] | select(.status.phase=="Running") | "\(.metadata.name)\t\(.spec.containers[0].resources.requests.cpu // "N/A")\t\(.spec.containers[0].resources.requests.memory // "N/A")"' | column -t | head -15
  else
    kubectl get pods -n "$namespace" -o json | \
      jq -r '.items[] | select(.status.phase=="Running") | "\(.metadata.name)\t\(.spec.containers[0].resources.requests.cpu // "N/A")\t\(.spec.containers[0].resources.requests.memory // "N/A")"' | column -t | head -15
  fi
}

function kubectl_node_resources() {
	kubectl get nodes -o custom-columns=NODE:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory | \
	awk 'NR>1 {mem=$3; gsub(/[KMGi]+/, "", mem); printf "%-20s CPU: %s cores  Memory: %.1f GB\n", $1, $2, $3/1024000}'
}

sky() { ~/astroterm-linux-x86_64 --color --constellations --speed 100 --fps 20 --city Barcelona; }
push() { git add . && git commit -m "$*" && git push; }

# =========================
# Aliases
# =========================
alias lc="lsd -la"
alias ll="lsd -la"
alias icat="kitty +kitten icat"
alias copy="xclip -sel clip"
alias vim="nvim"
alias vimdiff="nvim -d"
alias master="sudo /usr/local/bin/reconnect-mm712.sh"
alias mountvault="sudo mount -t nfs 192.168.1.130:/Plex /NFS-Vault"
alias tn="tmux new -s"
alias tl="tmux ls"
alias ta="tmux a -t"
alias workspace="cd ~/workspace"
alias config="cd ~/configFiles"
alias k8s-syd='export KUBECONFIG="${KUBECONFIG}:${HOME}/.kube/config-sydney"'
alias k8s-dev-tekniker='export KUBECONFIG="${KUBECONFIG}:${HOME}/.kube/config-dev-tekniker"'
alias k8s-pro-tekiner='export KUBECONFIG="${KUBECONFIG}:${HOME}/.kube/config-pro-tekniker"'

# =========================
# fnm: Copilot dependency
# ========================
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi

# =========================
# FZF
# =========================
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# =========================
# Starship
# =========================
export STARSHIP_CONFIG="$HOME/configFiles/starship/starship.toml"
eval "$(starship init zsh)"

# =========================
# Other PATHs
# =========================
export PATH="$PATH:/home/neutry/.lmstudio/bin"
export PATH="$PATH:/usr/local/go/bin"
export PATH="/home/neutry/.opencode/bin:$PATH"

# =========================
# Bash completion for Terraform
# =========================
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform
#zprof
