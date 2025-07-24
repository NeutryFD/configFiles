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

github-set (){
        pkill ssh-agent 2>/dev/null
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/github
}

gitlab-set (){
        pkill ssh-agent 2>/dev/null
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/gitlab.dev.hpcnow.com
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

#autoload -Uz add-zsh-hook
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
