# ernesthyphen 2025
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Enable fzf autocomplete and keybindings
[ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash
[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

#add both Flatpak-related directories to XDG_DATA_DIRS, while preserving the default paths
export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:/var/lib/flatpak/exports/share:/home/steve/.local/share/flatpak/exports/share"

## Choose your weapon
EDITOR=/usr/bin/nvim
#EDITOR=/usr/bin/emacs
#EDITOR=/usr/bin/nano
export EDITOR

# aliases
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -lha'
alias l='ls -CF'
alias rm='rm -i' #-i prompts user before deletion
alias cp='cp -i' #-i prompts user before overwriting

alias hf='history|fzf'
alias vim='nvim'
alias neovim='nvim'
alias ff='fastfetch'

#use bat instead of cat temporarily
alias cat='bat'

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000


PS1='[\u@\h \W]\$ '

# run fastfetch
fastfetch

eval "$(starship init bash)"

# Enable programmable completion features
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

#git autocomplete 
source /usr/share/bash-completion/completions/git

# SSH host autocompletion
complete -o default -o nospace -W "$(awk '/^Host / {for (i=2; i<=NF; i++) print $i}' ~/.ssh/config 2>/dev/null)" ssh scp sftp

