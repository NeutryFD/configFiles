export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

################################################## funtions 

public ()
{
  xclip -sel clip ~/.ssh/id_rsa.pub
}

git-set ()
{
  kill ssh-agent 2>/dev/null
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/github 
}

################################################### plugins
plugins=(git
         zsh-autosuggestions
         zsh-syntax-highlighting)


source $ZSH/oh-my-zsh.sh
################################################### alias
alias lc="lsd -la"
alias icat="kitty +kitten icat"
alias cat="bat --style=plain --theme TwoDark"
alias copy="xclip -sel clip"
alias ll="lsd -la"
alias vim="nvim"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
