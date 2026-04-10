# =============================================================================
# Configuration
# =============================================================================

# Oh-My-Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Editor
export EDITOR="/usr/local/bin/nvim"

# =============================================================================
# PATH Configuration
# =============================================================================
export PATH="$HOME/configFiles/scripts:$PATH"
export PATH="$PATH:$HOME/.lmstudio/bin"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

# fnm (Copilot dependency)
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi

# =============================================================================
# Zsh Optimizations
# =============================================================================
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"
ZSH_COMPDUMP="$HOME/.zcompdump-$ZSH_VERSION"
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
ZSH_AUTOSUGGEST_USE_ASYNC=1

# =============================================================================
# Plugins
# =============================================================================
plugins=(
  zsh-autosuggestions
  zsh-syntax-highlighting
)
source "$ZSH/oh-my-zsh.sh"

# =============================================================================
# Kubernetes completion
# ============================================================================
source <(kubectl completion zsh)

# =============================================================================
# FZF
# =============================================================================
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# =============================================================================
# Starship
# =============================================================================
export STARSHIP_CONFIG="$HOME/configFiles/starship/starship.toml"
eval "$(starship init zsh)"

# =============================================================================
# Aliases & Functions
# =============================================================================

# General
alias lc="lsd -la"
alias ll="lsd -la"
alias icat="kitty +kitten icat"
alias copy="xclip -sel clip"
alias vim="nvim"
alias vimdiff="nvim -d"

# System
alias master="sudo /usr/local/bin/reconnect-mm712.sh"
alias mountvault="sudo mount -t nfs 192.168.1.130:/vault-media /NFS-Vault"

# Tmux
alias tn="tmux new -s"
alias tl="tmux ls"
alias ta="tmux a -t"

# Navigation
alias workspace="cd ~/workspace"
alias config="cd ~/configFiles"

# Kubernetes
alias k="kubectl"
alias k8s-syd='export KUBECONFIG="${KUBECONFIG}:${HOME}/.kube/config-sydney"'
alias k8s-dev-tek='export KUBECONFIG="${KUBECONFIG}:${HOME}/.kube/config-dev-tekniker"'
alias k8s-pro-tek='export KUBECONFIG="${KUBECONFIG}:${HOME}/.kube/config-pro-tekniker"'
alias lazygit='git-ssh-agent && lazygit'
alias public='copy-ssh-pubkey.sh'

# Simple functions
sky() { ~/astroterm-linux-x86_64 --color --constellations --speed 100 --fps 20 --city Barcelona; }
push() { git add . && git commit -m "$*" && git push; }

# SSH Agent - source to preserve environment variables
git-ssh-agent() {
  source "$HOME/configFiles/scripts/git-ssh-agent.sh"
}

# =============================================================================
# Bash Completion for Terraform
# =============================================================================
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform
