eval "$(starship init zsh)"
eval "$(atuin init zsh)"
eval "$(zoxide init zsh)"

# export PATH=$HOME/.local/bin:$PATH
# export NVM_DIR="/opt/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

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

# File operations
alias rm="rm -vdrf"
alias cp="cp -r"
alias mkdir="mkdir -p"

# Directory listing
alias ls="exa -a --across --icons -s age"
alias l="exa -al --across --icons -s age"
alias ll="exa -ahlg --across --icons -s age"
alias lt="l --tree"

# Command shortcuts
alias m="amumax"
alias op="xdg-open"
alias se="sudoedit"
alias pm="podman"
alias cat="bat -Pp"
alias pmps="pm ps -a --sort status --format 'table {{.Names}} {{.Status}} {{.Created}} {{.Image}}'"
alias sysu="systemctl --user"

# Directory navigation
# alias cd="z"
# alias d="z"
alias ".."="cd .."
alias "..."="cd ../.."
alias "...."="cd ../../.."

# Utility commands
alias myip="curl ifconfig.me && echo"
alias ghs="gh copilot suggest -t shell"
alias ghe="gh copilot explain"
alias ghc="gh copilot"
alias lg="lazygit"
alias tldr="tldr -q"


alias mv="mv -i"          # Prompt before overwriting files
alias cp="cp -ir"         # Interactive and recursive by default
alias ln="ln -i"          # Prompt before creating symlinks
alias rm="rm -Iv --preserve-root" # Prompt on removal, especially root


alias now="date '+%Y-%m-%d %H:%M:%S'"   # Current date and time
alias utc="date -u '+%Y-%m-%d %H:%M:%S UTC'"  # UTC date and time


# Function to search file contents
fsearch() {
    grep -r "$1" . 2>/dev/null | less
}

# Function to show top largest files in the directory
bigfiles() {
    du -ah . | sort -rh | head -n 10
}

# Function to extract archives
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xvjf "$1" ;;
            *.tar.gz)  tar xvzf "$1" ;;
            *.tar.xz)  tar xvJf "$1" ;;
            *.bz2)     bunzip2 "$1" ;;
            *.rar)     unrar x "$1" ;;
            *.gz)      gunzip "$1" ;;
            *.tar)     tar xvf "$1" ;;
            *.tbz2)    tar xvjf "$1" ;;
            *.tgz)     tar xvzf "$1" ;;
            *.zip)     unzip "$1" ;;
            *.Z)       uncompress "$1" ;;
            *.7z)      7z x "$1" ;;
            *)         echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

alias reload="source ~/.zshrc && echo 'Configuration reloaded!'"

mkdir -p /tmp/runtime-$(id -u)
export XDG_RUNTIME_DIR=/tmp/runtime-$(id -u)