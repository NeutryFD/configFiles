-- set leader key
vim.g.mapleader = " "  -- Set Space as the leader key
vim.g.maplocalleader = " "  -- Also set local leader to Space


-- mouse funcionality
vim.o.mouse = "a"

-- theme
vim.cmd("colorscheme slate")
-- transparencybackgroud 
vim.cmd([[highlight Normal guibg=NONE ctermbg=NONE]])
vim.cmd([[highlight NormalNC guibg=NONE ctermbg=NONE]])
vim.cmd([[highlight EndOfBuffer guibg=NONE ctermbg=NONE]])

-- backgroud of visual mode
vim.cmd([[highlight Visual guibg=#3e4451 guifg=#ffffff]])  -- backgroud grey and text white
-- Change the color of the mode indicator (ModeMsg)
vim.cmd([[highlight ModeMsg guibg=#3b4252 guifg=#d8dee9]])  -- Dark background and light text (grey colors)


-- numbers
vim.opt.number = true      -- Show absolute line numbers
vim.opt.relativenumber = true  -- Show relative line numbers
vim.keymap.set("n", "<leader>n", ":set number! relativenumber!<CR>", { desc = "Toggle line numbers" })
