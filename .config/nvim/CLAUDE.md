# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Current Configuration

Complete minimal Neovim setup with essential development features in `init.lua`.

## Implemented Features

### Core Settings
- Line numbers, 2-space indentation
- Smart case-insensitive search with incremental search
- Bracket matching and auto-save on focus loss

### Key Mappings
- Leader key: `<Space>`
- File navigation: `<leader>ff` (find files), `<leader>fg` (grep), `<leader>fb` (buffers)
- Window navigation: `<C-h/j/k/l>`
- LSP: `gd` (definition), `K` (hover), `<leader>rn` (rename), `<leader>ca` (code actions)
- Terminal: `<C-\>` (toggle floating terminal)

### Plugins (13 total)
1. **lazy.nvim** - Plugin manager
2. **onedark.nvim** - Atom One Dark colorscheme
3. **telescope.nvim** - Fuzzy finder and file navigation
4. **nvim-treesitter** - Syntax highlighting
5. **nvim-autopairs** - Auto-close brackets/quotes
6. **nvim-lspconfig** - Language server integration (Python)
7. **nvim-cmp** - Code completion with LSP/buffer/path sources
8. **gitsigns.nvim** - Git status indicators in gutter
9. **indent-blankline.nvim** - Visual indent guides
10. **which-key.nvim** - Keybinding discovery
11. **nvim-tree.lua** - File tree explorer
12. **lualine.nvim** - Statusline with rounded separators
13. **toggleterm.nvim** - Floating terminal integration

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