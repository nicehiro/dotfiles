typeset -U path

path_prepend_if_exists() {
  [[ -d "$1" ]] && path=("$1" $path)
}

for brew_bin in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  if [[ -x "$brew_bin" ]]; then
    eval "$("$brew_bin" shellenv)"
    break
  fi
done

path_prepend_if_exists "$HOME/.local/bin"
for texlive_bin in /usr/local/texlive/2026/bin/*(N); do
  path_prepend_if_exists "$texlive_bin"
done
if [[ "$OSTYPE" == darwin* ]]; then
  path_prepend_if_exists "/Library/TeX/texbin"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
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

if command -v eza >/dev/null 2>&1; then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --group-directories-first -- $realpath'
elif command -v gls >/dev/null 2>&1; then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'gls --color=always -- $realpath'
else
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always -- $realpath 2>/dev/null || ls -G -- $realpath'
fi

# Aliases
if command -v gls >/dev/null 2>&1; then
  alias ls='gls --color=auto'
elif ls --color=auto >/dev/null 2>&1; then
  alias ls='ls --color=auto'
else
  alias ls='ls -G'
fi

if command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi

alias vim='nvim'
alias c='clear'
alias wandb='uvx wandb'

# Shell integrations
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

# fzf theme
export FZF_DEFAULT_OPTS=" \
--color=bg+:#414559,bg:#303446,spinner:#f2d5cf,hl:#e78284 \
--color=fg:#c6d0f5,header:#e78284,info:#ca9ee6,pointer:#f2d5cf \
--color=marker:#babbf1,fg+:#c6d0f5,prompt:#ca9ee6,hl+:#e78284 \
--color=selected-bg:#51576d \
--multi"

export EDITOR=nvim
export LEDGER_FILE="$HOME/Documents/account.journal"
export BIBTEX_PATH="$HOME/Documents/roam/library.bib"

if [[ -f "$HOME/Documents/keys/claude.key" ]]; then
  source "$HOME/Documents/keys/claude.key"
fi

if [[ -f "$HOME/Documents/keys/openai.key" ]]; then
  source "$HOME/Documents/keys/openai.key"
fi
