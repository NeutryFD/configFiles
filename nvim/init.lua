-- Modules PAHT
package.path = package.path .. ';' .. os.getenv("HOME") .. '/configFiles/nvim/lua/?.lua'

-- #############################################################
-- Settings generals options fo Neovim
-- set leader key
vim.g.mapleader = " "  -- Set Space as the leader key
vim.g.maplocalleader = " "  -- Also set local leader to Space
-- visualitation of tabs

-- vim.o.list = true  -- Enable visualizing spaces and tabs
-- vim.o.listchars = "tab:▸-,trail:·,lead:·"
vim.o.tabstop = 4        -- Each tab is 4 spaces wide
vim.o.shiftwidth = 4
-- mouse funcionality
vim.o.mouse = "a"

-- numbers
vim.opt.number = true      -- Show absolute line numbers
vim.opt.relativenumber = true  -- Show relative line numbers

-- Hide the Command-line when no use it
vim.o.cmdheight = 0

-- disable netrw at the very start of your init.lua reccomended by nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- #############################################################
-- Keymaps

vim.keymap.set("n", "<leader>n", ":set number! relativenumber!<CR>", { desc = "Toggle line numbers" })

-- In normal mode, pressing <Esc>\ moves to previous window
vim.api.nvim_set_keymap('n', '<Esc>\\', '<C-w>p', { noremap = true, silent = true })

-- In terminal mode, pressing <Esc>\ exits terminal mode and moves to previous window
vim.api.nvim_set_keymap('t', '<Esc>\\', [[<C-\><C-n><C-w>p]], { noremap = true, silent = true })

-- uset the system clipboardvim.opt.clipboard = "unnamedplus"
vim.keymap.set("n", "yy", '"+yy', { noremap = true })
vim.keymap.set("v", "y", '"+y', { noremap = true })

-- #############################################################
-- statusline
-- Load the custom statusline from lua/config/statusline.lua
local Statusline = require('config.statusline')
-- Set the statusline using the active statusline function
vim.opt.statusline = "%!v:lua.Statusline.active()"

-- Optionally, update the statusline dynamically when entering or leaving windows/buffers
vim.api.nvim_exec([[
  augroup Statusline
  au!
  au WinEnter,BufEnter * setlocal statusline=%!v:lua.Statusline.active()
  au WinLeave,BufLeave * setlocal statusline=%!v:lua.Statusline.active()
  augroup END
]], false)

-- #############################################################
-- Load plugins and configurations
require('config.tokyonight')
require('config.markdown-renderer')
require('config.lazygit-setup')
require('config.tree')
require('config.terminal')
require('config.identation')
require('config.telescope')
require('config.cmp')
