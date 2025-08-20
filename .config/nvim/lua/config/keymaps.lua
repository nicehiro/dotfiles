-- Key mappings

-- Telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})

-- Basic navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", {})
vim.keymap.set("n", "<C-j>", "<C-w>j", {})
vim.keymap.set("n", "<C-k>", "<C-w>k", {})
vim.keymap.set("n", "<C-l>", "<C-w>l", {})

-- LSP keymaps
vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})

-- Emacs-style keybindings
-- File operations
vim.keymap.set("n", "<C-x><C-f>", builtin.find_files, { desc = "Find files (Emacs style)" })
vim.keymap.set("n", "<C-x><C-s>", ":w<CR>", { desc = "Save file (Emacs style)" })
vim.keymap.set("n", "<C-x><C-c>", ":q<CR>", { desc = "Quit (Emacs style)" })

-- Additional useful Emacs keybindings
-- Navigation
vim.keymap.set({"n", "i"}, "<C-a>", "<Home>", { desc = "Beginning of line" })
vim.keymap.set({"n", "i"}, "<C-e>", "<End>", { desc = "End of line" })
vim.keymap.set("n", "<C-g>", "<Esc>", { desc = "Cancel/Escape" })
vim.keymap.set("i", "<C-g>", "<Esc>", { desc = "Cancel/Escape" })

-- Editing
vim.keymap.set("v", "<C-w>", "d", { desc = "Kill region" })
vim.keymap.set("v", "<M-w>", "y", { desc = "Copy region" })
vim.keymap.set({"n", "i"}, "<C-y>", "<C-r>0", { desc = "Yank (paste)" })

-- Character and word navigation
vim.keymap.set({"n", "i"}, "<C-f>", "<Right>", { desc = "Forward character" })
vim.keymap.set({"n", "i"}, "<C-b>", "<Left>", { desc = "Backward character" })
vim.keymap.set({"n", "i"}, "<M-f>", "<C-Right>", { desc = "Forward word" })
vim.keymap.set({"n", "i"}, "<M-b>", "<C-Left>", { desc = "Backward word" })

-- Line navigation
vim.keymap.set({"n", "i"}, "<C-n>", "<Down>", { desc = "Next line" })
vim.keymap.set({"n", "i"}, "<C-p>", "<Up>", { desc = "Previous line" })

-- Character transpose
vim.keymap.set("i", "<C-t>", "<Esc>xpa", { desc = "Transpose characters" })

-- Search
vim.keymap.set("n", "<C-s>", "/", { desc = "Search forward" })
vim.keymap.set("n", "<C-r>", "?", { desc = "Search backward" })

-- Buffer management
vim.keymap.set("n", "<C-x>b", builtin.buffers, { desc = "Switch buffer" })
vim.keymap.set("n", "<C-x><C-b>", builtin.buffers, { desc = "Buffer list" })

-- File tree
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file tree" })

-- Window management
vim.keymap.set("n", "<C-x>1", ":only<CR>", { desc = "Close other windows" })
vim.keymap.set("n", "<C-x>2", ":split<CR>", { desc = "Split horizontally" })
vim.keymap.set("n", "<C-x>3", ":vsplit<CR>", { desc = "Split vertically" })
vim.keymap.set("n", "<C-x>o", "<C-w>w", { desc = "Other window" })
