-- Set leader key early
vim.g.mapleader = " "

-- Load configuration modules
require("config.options")
require("config.autocmds") 
require("config.plugins")
require("config.keymaps")
