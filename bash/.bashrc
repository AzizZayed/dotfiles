# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History control
HISTCONTROL=ignoreboth
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

eval "$(starship init bash)"
neofetch
