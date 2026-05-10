# Timer functions for command execution time
preexec() {
  timer=${timer:-$EPOCHREALTIME}
}

precmd() {
if [ $UID -eq 0 ]; then
    _user_icon="  "
  elif sudo -n true 2>/dev/null; then lg
    _user_icon="  "
  else
    _user_icon="  "
  fi

  if [ ${timer} ]; then
    timer_show=$(printf "%.1f" $(echo "$EPOCHREALTIME - $timer" | bc))
    RPROMPT="%F{cyan}⏳ ${timer_show}s%f"
    unset timer
  fi
  _folder_icon="  "
}

# Main prompt (based on robbyrussell + user) - single line
PROMPT="%(?::%{$fg_bold[red]%}❯:)%{$fg_bold[cyan]%}\${_user_icon}%n%{$reset_color%} %{$fg_bold[blue]%}%c\$_folder_icon%{$reset_color%}"
PROMPT+="$(git_prompt_info)"
PROMPT+="%{$fg_bold[green]%}❯ %{$reset_color%}"

# Git prompt (original robbyrussell style)
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[magenta]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[magenta]%}) %{$fg[yellow]%}%1{✗%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[magenta]%})"
