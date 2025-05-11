export ZSH="$HOME/.oh-my-zsh"
export EDITOR=/bin/nvim
export PATH=$PATH:/home/neutry/.lmstudio/bin
ZSH_THEME="robbyrussell"


################################################## funtions
sshfslocal (){
	host=$1
	dir=$2
if [ -z "$dir" ]; then
	mkdir -p $HOME/remoteDir
	dir="$HOME/remoteDir"
fi
sshfs -o  idmap=user $host $dir &&cd $dir
}


public (){
	xclip -sel clip ~/.ssh/id_rsa.pub
}

git-set (){
	pkill ssh-agent 2>/dev/null
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/github 
}

clean-copy (){
	rm -rf /run/user/1000/clipmenu*
	pgrep -f clipmenu | xargs  kill > /dev/null
	bspc wm -r
	echo "clipboard cleaned"
}


################################################### plugins
plugins=(git
		zsh-autosuggestions
		zsh-syntax-highlighting
		)


source $ZSH/oh-my-zsh.sh
################################################### alias
alias icat="kitty +kitten icat"
#alias cat="bat --style=plain --theme TwoDark"
alias copy="xclip -sel clip"
alias ll="lsd -la"
alias vim="nvim"
alias master="sudo /usr/local/bin/reconnect-mm712.sh"
alias lazygit="git-set && lazygit"
alias mountvault="sudo mount -t nfs santos.local:/Plex /NFS-Vault"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
