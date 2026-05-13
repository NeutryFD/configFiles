# =============================================================================
# Zsh Core Options (replaces oh-my-zsh defaults)
# =============================================================================
setopt autocd              # cd by typing directory name
setopt interactive_comments # allow comments in interactive shell
setopt hist_ignore_all_dups # no duplicate entries in history
setopt hist_reduce_blanks  # remove extra blanks from history
setopt share_history       # share history between sessions
setopt append_history      # append to history file
setopt inc_append_history  # write to history immediately
setopt no_beep             # no terminal beeps

# Faster completions
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

# =============================================================================
# Completion
# =============================================================================
autoload -Uz compinit
# Only regenerate .zcompdump once a day
if [[ -n "$HOME/.zcompdump-$ZSH_VERSION"(#qN.mh+24) ]]; then
    compinit -d "$HOME/.zcompdump-$ZSH_VERSION"
else
    compinit -C -d "$HOME/.zcompdump-$ZSH_VERSION"
fi

# =============================================================================
# Editor
# =============================================================================
export EDITOR="/usr/local/bin/nvim"

# =============================================================================
# PATH Configuration
# =============================================================================
export PATH="$HOME/configFiles/scripts:$PATH"
export PATH="$PATH:$HOME/.lmstudio/bin"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="neutry"

# fnm (Copilot dependency - needed at startup for nvim)
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi

# =============================================================================
# Plugins (oh-my-zsh framework)
# =============================================================================
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
ZSH_AUTOSUGGEST_USE_ASYNC=1

plugins=(
	git
	fzf-tab
	zsh-autosuggestions
	zsh-interactive-cd
	zsh-syntax-highlighting
)
source $ZSH/oh-my-zsh.sh

# =============================================================================
# FZF
# =============================================================================
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# =============================================================================
# Starship
# =============================================================================
#export STARSHIP_CONFIG="$HOME/configFiles/starship/starship.toml"
#eval "$(starship init zsh)"

# =============================================================================
# Lazy-loaded completions
# =============================================================================

# kubectl - loads completion on first use
kubectl() {
    unfunction kubectl
    source <(command kubectl completion zsh)
    kubectl "$@"
}

# terraform - loads bashcompinit on first use
terraform() {
    unfunction terraform
    autoload -U +X bashcompinit && bashcompinit
    complete -o nospace -C /usr/bin/terraform terraform
    terraform "$@"
}

# =============================================================================
# Aliases & Functions
# =============================================================================

# General
alias lc="lsd -la"
alias ll="lsd -la"
alias ls="lsd"
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
alias kconfig="source kube_config_select.sh"
alias lazygit='git-ssh-agent && lazygit'
alias public='copy-ssh-pubkey.sh'

# Simple functions
sky() { ~/astroterm-linux-x86_64 --color --constellations --speed 100 --fps 20 --city Barcelona; }
push() { git add . && git commit -m "$*" && git push; }

# SSH Agent - source to preserve environment variables
git-ssh-agent() {
  source "$HOME/configFiles/scripts/git-ssh-agent.sh"
}
export PATH=$HOME/.local/bin:$PATH
