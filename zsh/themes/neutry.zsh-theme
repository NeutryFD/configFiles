# Timer functions for command execution time
preexec() {
  timer=${timer:-$EPOCHREALTIME}
}

precmd() {
if [ $UID -eq 0 ]; then
    _user_icon="  "
  elif sudo -n true 2>/dev/null; then
    _user_icon="  "
  else
    _user_icon="  "
  fi

  if [ ${timer} ]; then
    timer_sec=$(echo "$EPOCHREALTIME - $timer" | bc)
    if (( $(echo "$timer_sec >= 3600" | bc -l) )); then
      timer_h=$(printf "%.0f" $(echo "$timer_sec / 3600" | bc))
      timer_m=$(printf "%.0f" $(echo "($timer_sec % 3600) / 60" | bc))
      timer_show="${timer_h}h ${timer_m}m"
    elif (( $(echo "$timer_sec >= 60" | bc -l) )); then
      timer_m=$(printf "%.0f" $(echo "$timer_sec / 60" | bc))
      timer_s=$(printf "%.0f" $(echo "$timer_sec % 60" | bc))
      timer_show="${timer_m}m ${timer_s}s"
    else
      timer_show=$(printf "%.1fs" $timer_sec)
    fi
    RPROMPT="%F{cyan}⏳ ${timer_show}%f"
    unset timer
  fi
  _folder_icon="  "
}

# Main prompt (based on robbyrussell + user) - single line
PROMPT="%(?::%{$fg_bold[red]%}❯)%{$fg_bold[green]%}\${_user_icon}%n%{$reset_color%} %{$fg_bold[cyan]%}%c\$_folder_icon%{$reset_color%}"
PROMPT+=' $(git_prompt_info)'
PROMPT+='%{$fg_bold[green]%}❯ %{$reset_color%}'

# Git prompt (original robbyrussell style)
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[magenta]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[magenta]%}) %{$fg[yellow]%}%1{✗%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[magenta]%})"
