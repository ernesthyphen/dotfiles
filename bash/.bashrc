#▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
#█░▄▄█░▄▄▀█░▄▄▀█░▄▄█░▄▄█▄░▄█░████░██░█▀▄▄▀█░████░▄▄█░▄▄▀
#█░▄▄█░▀▀▄█░██░█░▄▄█▄▄▀██░██░▄▄░█░▀▀░█░▀▀░█░▄▄░█░▄▄█░██░
#█▄▄▄█▄█▄▄█▄██▄█▄▄▄█▄▄▄██▄██▄██▄█▀▀▀▄█░████▄██▄█▄▄▄█▄██▄
#▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

GREEN='\[\e[32m\]'
BLUE='\[\e[34m\]'
RESET='\[\e[0m\]'

PS1="${GREEN}\u@\h${RESET}:${BLUE}\w${RESET}\$ "

# Set terminal title to current command or directory

__title_set() {
  printf '\033]0;%s\007' "$1"
}

__title_prompt() {
  __title_set "$USER@$HOSTNAME: ${PWD/#$HOME/~}"
}

__title_preexec() {
  # BASH_COMMAND is the command about to run
  local cmd="$BASH_COMMAND"

  # Ignore our own plumbing and other noisy internals
  case "$cmd" in
    __title_*|history*|trap*|PROMPT_COMMAND*|printf* ) return ;;
  esac

  # Keep it readable: first word (so "btop", not the whole pipeline)
  __title_set "${cmd%% *}"
}

# Set title to command when it starts...
trap '__title_preexec' DEBUG
# ...and set it back to a nice prompt title when we return to the prompt.
PROMPT_COMMAND="__title_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}"


#add both Flatpak-related directories to XDG_DATA_DIRS, while preserving the default paths
export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share"

#python env vars
#export PYENV_ROOT="$HOME/.pyenv"
#export PATH="$PYENV_ROOT/bin:$PATH"
#eval "$(pyenv init -)"

## If I feel like changing editors
export EDITOR=nvim
#export EDITOR=emacs
#export EDITOR=nano

## Modified commands
alias grep='grep --color=auto'
alias mkdir='mkdir -p -v'
alias ping='ping -c 5'

# ls
alias ls='ls -hF --color=auto'
alias ll='ls -lh --color=auto'
alias la='ll -A --color=auto'
alias l='ls -CF --color=auto'
alias lr='ls -Ra | more' # recursive ls
alias lm='la --color=auto| more'

## Safety checks
alias rm='rm -i' #-i prompts user before deletion
alias cp='cp -i' #-i prompts user before overwriting
alias mv='mv -i'

alias hf='history|fzf'
alias vim='nvim'
alias neovim='nvim'
alias ff='clear && fastfetch'

alias bat='bat --paging=never'

alias upd='paru'
alias cleanup='paru -Sc'
alias orphan='sudo pacman -Rns $(pacman -Qtdq)'

#notes
alias notes="nvim $HOME/Dropbox/Obsidian_Vault/steves_vault/00_Inbox/1_Scratch.md"

#use hollywood docker container
#alias hollywood="docker run -it --rm cgr.dev/chainguard/hollywood"

#add preview to fzf
export FZF_DEFAULT_OPTS="--preview='bat --color=always {}'"

# Functions
ffa() {
    clear
    fastfetch -c all.jsonc
}

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=50000
HISTFILESIZE=100000

# run fastfetch
fastfetch

# Enable fzf autocomplete and keybindings
[ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash
[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash

# Enable programmable completion features
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

#git autocomplete 
source /usr/share/bash-completion/completions/git

# SSH host autocompletion
complete -o default -o nospace -W "$(awk '/^Host / {for (i=2; i<=NF; i++) print $i}' ~/.ssh/config 2>/dev/null)" ssh scp sftp

# Created by `pipx` on 2026-02-22 19:28:29
export PATH="$PATH:/home/steve/.local/bin"
