# ~/.bashrc

# 1. Interactive check
[[ -z "$PS1" ]] && return

# 2. History
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=5000
HISTFILESIZE=10000
HISTTIMEFORMAT="%F %T "
shopt -s cmdhist histreedit histverify

# 3. Prompt
shopt -s checkwinsize
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"
if [[ -x /usr/bin/tput ]] && tput setaf 1 >/dev/null 2>&1; then
    base_PS1="\[\033[35m\]\$(/bin/date '+%Y-%m-%d %H:%M:%S') \[\033[1;31m\]\u@\h \[\033[1;34m\]\$(pwd)\[\033[0m\] "
else
    base_PS1="\$(/bin/date '+%Y-%m-%d %H:%M:%S') \u@\h \$(pwd) "
fi
PROMPT_COMMAND='ret=$?; PS1="$base_PS1$( [[ $ret -ne 0 ]] && printf "\001\033[0;31m\002(%d)\001\033[0m\002 " $ret)-> "'

# 4. Colors
if [[ -x /usr/bin/dircolors ]]; then
    eval "$(dircolors -b ~/.dircolors 2>/dev/null || dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# 5. Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -alF --group-directories-first'
alias ducks='du -hs * | sort -hr'
alias reload='source ~/.bashrc'
alias dcu='docker compose up'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcdu='docker compose down && docker compose up -d'
alias dcl='docker compose logs -f'

# 6. Variables
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LESS='-R'

# 7. Completion
[[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion

# 8. Extra
shopt -s dotglob globstar
