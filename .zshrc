eval "$(starship init zsh)"

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
# Autosuggestions: style the inline "ghost text" so it's readable.
# (This is the suggestion you see without pressing Tab.)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#5c6370'

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
# Enable colored completion listings (needed for "menu select" to be readable).
zmodload -i zsh/complist 2>/dev/null || true

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# If you have LS_COLORS from elsewhere, use it. Otherwise enable the zsh defaults
# by setting an empty value (per zshmodules/zshcompsys docs).
if [[ -n "${LS_COLORS:-}" ]]; then
  zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"
else
  zstyle ':completion:*:default' list-colors ''
fi

# Make the completion menu actually visible.
zstyle ':completion:*' menu select
zstyle ':completion:*' list-prompt '%S%M matches%s'
zstyle ':completion:*' select-prompt '%SScrolling: current selection at %p%s'

zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias vim='nvim'
alias c='clear'

# Shell integrations
eval "$(fzf --zsh)"

# fzf theme
export FZF_DEFAULT_OPTS=" \
--color=bg+:#414559,bg:#303446,spinner:#f2d5cf,hl:#e78284 \
--color=fg:#c6d0f5,header:#e78284,info:#ca9ee6,pointer:#f2d5cf \
--color=marker:#babbf1,fg+:#c6d0f5,prompt:#ca9ee6,hl+:#e78284 \
--color=selected-bg:#51576d \
--multi"

# mactex bin
# export PATH=$PATH:/Library/TeX/texbin
export PATH=$PATH:/usr/local/texlive/2025/bin/universal-darwin/

# hledger main file
export LEDGER_FILE=/Users/fangyuan/Documents/account.journal

# cc
if [[ -f ~/Documents/keys/claude.key ]]; then
    source ~/Documents/keys/claude.key
fi

# gemini
if [[ -f ~/Documents/keys/gemini.key ]]; then
    source ~/Documents/keys/gemini.key
fi
