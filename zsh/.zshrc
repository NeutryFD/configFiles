export ZSH="$HOME/.oh-my-zsh"
export EDITOR=/usr/local/bin/nvim
ZSH_THEME="robbyrussell"


################################################## funtions

#add-zsh-hook precmd () {
#  printf '\033[6 q'
#}

sshfslocal (){
        host=$1
        dir=$2
if [ -z "$dir" ]; then
        mkdir -p $HOME/remoteDir
        dir="$HOME/remoteDir"

fi
sshfs -o  idmap=user ${host} $dir && cd $dir
}


public (){
        xclip -sel clip ~/.ssh/id_rsa.pub
}

git-ssh-agent (){
	# Terminate any existing ssh-agent instances
	pkill ssh-agent 2>/dev/null
    # Start the ssh-agent if it's not running
    eval "$(ssh-agent -s)"
    
    # Find all private keys using file command to check file type
    private_keys=()
    for f in $HOME/.ssh/*; do
        if [[ -f "$f" && "$f" != *.pub ]] && file "$f" | grep -qi "private key"; then
            private_keys+=("$f")
        fi
    done
    
    # Use fzf for interactive selection if keys are found
    if [ ${#private_keys[@]} -gt 0 ]; then
        selected_keys=$(printf "%s\n" "${private_keys[@]}" | fzf --multi --header="Select SSH keys (TAB to select multiple, ENTER to confirm)")
        
        if [ -n "$selected_keys" ]; then
            echo "$selected_keys" | while read -r key; do
                ssh-add "$key" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo "Added key: $key"
                fi
            done
        else
            echo "No keys selected."
        fi
    else
        echo "No private keys found in ~/.ssh/"
    fi
}


clean-copy (){
        rm -rf /run/user/1000/clipmenu*
        pgrep -f clipmenu | xargs  kill > /dev/null
        bspc wm -r
        echo "clipboard cleaned"
}

sky(){
~/astroterm-linux-x86_64 --color --constellations --speed 100 --fps 20 --city Barcelona
}



################################################### plugins
plugins=(git
		     zsh-autosuggestions
		     zsh-syntax-highlighting
		)

source $ZSH/oh-my-zsh.sh
source <(kubectl completion zsh)
################################################### alias
alias lc="lsd -la"

alias icat="kitty +kitten icat"
#alias cat="bat --style=plain --theme TwoDark"
alias copy="xclip -sel clip"
alias ll="lsd -la"
alias vim="nvim"
alias master="sudo /usr/local/bin/reconnect-mm712.sh"
alias mountvault="sudo mount -t nfs santos.local:/Plex /NFS-Vault"
alias tn="tmux new -s"
alias tl="tmux ls"
alias ta="tmux a -t"
alias workspace="cd ~/workspace"
alias config="cd ~/configFiles"
alias k8s-dev='export KUBECONFIG="${KUBECONFIG}:${HOME}/.kube/config-sydney"'

#autoload -Uz add-zsh-hook
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


# nvm (node version manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/neutry/.lmstudio/bin"
# End of LM Studio CLI section


# opencode
export PATH=/home/neutry/.opencode/bin:$PATH
