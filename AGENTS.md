# AGENTS.md

Personal dotfiles for macOS. Config files use their native formats.

## Neovim (.config/nvim/)
- **Validate**: `nvim --headless "+checkhealth" "+qa"` or `:checkhealth`
- **Reload**: `:source ~/.config/nvim/init.lua`
- **Plugins**: `:Lazy` (install/update/sync/clean)
- **Style**: 2-space indent, `vim.o.*` for options, `vim.keymap.set()` for keymaps
- **Structure**: `init.lua` loads `lua/config/{options,autocmds,plugins,keymaps}.lua`

## Zsh (.zshrc)
- **Plugin manager**: zinit (auto-bootstraps from zdharma-continuum)
- **Reload**: `source ~/.zshrc`
- **Style**: Emacs keybindings (`bindkey -e`), aliases at bottom

## Tmux (.config/tmux/tmux.conf)
- **Plugin manager**: TPM (`~/.tmux/plugins/tpm/tpm`)
- **Reload**: `tmux source ~/.config/tmux/tmux.conf`
- **Style**: vi-mode for copy, vim-style pane nav (hjkl), 1-indexed windows

## Terminal Emulators
- **Alacritty** (.config/alacritty/): TOML format, imports theme from `themes/`
- **Ghostty** (.config/ghostty/): Key-value format, one setting per line

## Other Configs
- **Starship** (.config/starship.toml): Prompt config, TOML with nerd font symbols
- **Git** (.gitconfig): Standard INI format
