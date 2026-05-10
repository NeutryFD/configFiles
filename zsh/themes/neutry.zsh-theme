# Timer functions for command execution time
preexec() {
  timer=${timer:-$EPOCHREALTIME}
}

precmd() {
if [ $UID -eq 0 ]; then
    _user_icon=""
  elif sudo -n true 2>/dev/null; then
    _user_icon=""
  else
    _user_icon=""
  fi

  if [ ${timer} ]; then
    timer_show=$(printf "%.1f" $(echo "$EPOCHREALTIME - $timer" | bc))
    RPROMPT="%F{cyan}⏳ ${timer_show}s%f"
    unset timer
  fi
}

# Main prompt (based on robbyrussell + user) - single line
PROMPT="%(?:%{$fg_bold[green]%}❯ :%{$fg_bold[red]%}➜ )%{$fg_bold[cyan]%}\${_user_icon}%{$reset_color%} %{$fg_bold[magenta]%}%n%{$reset_color%} %{$fg_bold[cyan]%}%c%{$reset_color%}"
PROMPT+='$(git_prompt_info)'
PROMPT+='%F{default}%f❯ '

# Git prompt (original robbyrussell style)
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}%1{✗%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
