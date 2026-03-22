# Environment for login shells (interactive terminals and tools like Emacs)
if status is-login
    # Homebrew
    if test -f /opt/homebrew/bin/brew
        eval (/opt/homebrew/bin/brew shellenv)
    end

    # Environment
    set -gx EDITOR nvim
    set -gx LEDGER_FILE /Users/fangyuan/Documents/account.journal
    set -gx BIBTEX_PATH ~/Documents/roam/library.bib
    fish_add_path /usr/local/texlive/2026/bin/universal-darwin

    # API keys (make available to Emacs and other tools)
    if test -f ~/Documents/keys/claude.fish.key
        source ~/Documents/keys/claude.fish.key
    end
    if test -f ~/Documents/keys/openai.fish.key
        source ~/Documents/keys/openai.fish.key
    end
    if test -f ~/Documents/keys/wandb.fish.key
        source ~/Documents/keys/wandb.fish.key
    end
    if test -f ~/Documents/keys/brave.fish.key
        source ~/Documents/keys/brave.fish.key
    end
    if test -f ~/Documents/keys/zotero.fish.key
        source ~/Documents/keys/zotero.fish.key
    end
end

# Interactive-only configuration (UI, aliases, prompt, fzf, etc.)
if status is-interactive
    # Autosuggestion color (brighter for transparent bg)
    set -g fish_color_autosuggestion 808080

    # Emacs keybindings
    set -g fish_key_bindings fish_default_key_bindings

    # History
    set -g fish_history default
    bind \cp history-search-backward
    bind \cn history-search-forward

    # Aliases
    alias ls 'ls --color'
    alias vim nvim
    alias c clear
    alias wandb 'uvx wandb'

    # fzf
    fzf --fish | source

    # fzf theme (catppuccin frappe)
    set -gx FZF_DEFAULT_OPTS "\
--color=bg+:#414559,bg:#303446,spinner:#f2d5cf,hl:#e78284 \
--color=fg:#c6d0f5,header:#e78284,info:#ca9ee6,pointer:#f2d5cf \
--color=marker:#babbf1,fg+:#c6d0f5,prompt:#ca9ee6,hl+:#e78284 \
--color=selected-bg:#51576d \
--multi"

    # Starship prompt
    starship init fish | source
end
