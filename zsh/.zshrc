export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

################################################## funtions 

public ()
{
  xclip -sel clip ~/.ssh/id_rsa.pub
export EDITOR=/bin/nvim
export PATH=$PATH:/home/neutry/.lmstudio/bin
source $ZSH/oh-my-zsh.sh
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
  #pgrep -f clipmenu | xargs  kill > /dev/null
  #rm -rf /run/user/1001/clipmenu*
  #bspc wm -r
  clipdel -d ".*" > /dev/null
  echo "clipboard cleaned"
	rm -rf /run/user/1000/clipmenu*
	pgrep -f clipmenu | xargs  kill > /dev/null
	bspc wm -r
	echo "clipboard cleaned"
}

configfiles () 
{
  cd /home/lsantos/configFiles/
}

################################################### plugins
plugins=(git
		zsh-autosuggestions
		zsh-syntax-highlighting
		)


################################################### alias
alias lc="lsd -la"
alias icat="kitty +kitten icat"
#alias cat="bat --style=plain --theme TwoDark"
alias copy="xclip -sel clip"
alias ll="lsd -la"
alias vim="nvim"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
