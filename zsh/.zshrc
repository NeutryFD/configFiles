export ZSH="$HOME/.oh-my-zsh"
export EDITOR=/bin/nvim
export PATH=$PATH:/home/neutry/.lmstudio/bin

ZSH_THEME="robbyrussell"


################################################## funtions 

public ()
{
  xclip -sel clip ~/.ssh/id_rsa.pub
}

git-set ()
{
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
         zsh-syntax-highlighting)


source $ZSH/oh-my-zsh.sh
################################################### alias
alias lc="lsd -la"
alias icat="kitty +kitten icat"
#alias cat="bat --style=plain --theme TwoDark"
alias copy="xclip -sel clip"
alias ll="lsd -la"
alias vim="nvim"
alias master="sudo /usr/local/bin/reconnect-mm712.sh"
alias lazygit="git-set && lazygit"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
