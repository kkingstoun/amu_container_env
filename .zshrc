eval "$(starship init zsh)"
eval "$(atuin init zsh)"
stty stop undef # Disables ctrl+S to freeze the terminal
setopt extendedglob # Extended globbing. Allows using regular expressions with *
setopt nocaseglob # Case insensitive globbing
setopt rcexpandparam # Array expension with parameters
setopt numericglobsort # Sort filenames numerically when it makes sense
setopt nobeep                                                   
setopt appendhistory # Immediately append history instead of overwriting
setopt histignorealldups # If a new command is a duplicate, remove the older one
setopt share_history # Import new commands and appends typed commands to history
zle_highlight=('paste:none') # remove past highlight


zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case insensitive tab completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colored completion (different colors for dirs/files/etc)
zstyle ':completion:*' rehash true # automatically find new executables in path 
zstyle ':completion:*' file-patterns '%p(D):globbed-files *(D-/):directories' '*(D):all-files'
zstyle ':completion:*' accept-exact '*(N)' # Speed up completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh

HISTFILE=$XDG_CACHE_HOME/.zhistory
HISTSIZE=100000
SAVEHIST=100000
# Don't consider certain characters part of the word
WORDCHARS=${WORDCHARS//\/[&.;]}

# Color man pages
export LESS_TERMCAP_mb=$'\E[01;32m'
export LESS_TERMCAP_md=$'\E[01;32m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;47;34m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;36m'
export LESS=-r

conda activate my_env