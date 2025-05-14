-- Modules PAHT
package.path = package.path .. ';/home/neutry/configFiles/nvim/lua/?.lua'

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


-- Hide the Command-line when no use it
vim.o.cmdheight = 0

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

-- Requiere nvim-cmp
local cmp = require'cmp'

cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body) -- Usa LuaSnip
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Confirmar selección
  
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, { 'i', 's' }),

    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, { 'i', 's' }),
}),


  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' }, -- Para snippets
    { name = 'buffer' },
    { name = 'path' },
  })
})

-- Autocomplet for `/` (search)
cmp.setup.cmdline('/', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

-- Autocomplet for `:` (command)
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})


