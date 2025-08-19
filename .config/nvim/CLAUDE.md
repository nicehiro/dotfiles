# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Current Configuration

Complete minimal Neovim setup with essential development features in `init.lua`.

## Implemented Features

### Core Settings
- Line numbers, 2-space indentation
- Smart case-insensitive search with incremental search
- Bracket matching and auto-save on focus loss
- Custom status line showing file info and position

### Key Mappings
- Leader key: `<Space>`
- File navigation: `<leader>ff` (find files), `<leader>fg` (grep), `<leader>fb` (buffers)
- Window navigation: `<C-h/j/k/l>`
- LSP: `gd` (definition), `K` (hover), `<leader>rn` (rename), `<leader>ca` (code actions)
- Terminal: `<C-\>` (toggle floating terminal)

### Plugins (8 total)
1. **lazy.nvim** - Plugin manager
2. **telescope.nvim** - Fuzzy finder and file navigation
3. **nvim-treesitter** - Syntax highlighting
4. **nvim-autopairs** - Auto-close brackets/quotes
5. **nvim-lspconfig** - Language server integration (Lua + Python)
6. **nvim-cmp** - Code completion with LSP/buffer/path sources
7. **gitsigns.nvim** - Git status indicators in gutter
8. **indent-blankline.nvim** - Visual indent guides
9. **which-key.nvim** - Keybinding discovery
10. **toggleterm.nvim** - Floating terminal integration

### Language Support
- **Lua**: lua_ls language server (install: `brew install lua-language-server`)
- **Python**: pyright language server (install: `npm install -g pyright`)

## Development Commands

- Open Neovim: `nvim`
- Check health: `:checkhealth`
- Reload config: `:source ~/.config/nvim/init.lua`
- Plugin management: `:Lazy` (install/update/clean)
- LSP info: `:LspInfo`

## Configuration Principles

1. Minimal plugin count - only essential functionality
2. Single-file structure (ready for modularization)
3. Fast startup and lightweight operation
4. Development-focused with LSP integration