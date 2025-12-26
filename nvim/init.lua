-- Modules PAHT
package.path = package.path .. ';' .. os.getenv("HOME") .. '/configFiles/nvim/lua/?.lua'

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
vim.keymap.set("n", "<leader>n", ":set number! relativenumber!<CR>", { desc = "Toggle line numbers" })

-- Hide the Command-line when no use it
vim.o.cmdheight = 0

-- statusline
-- Load the custom statusline from lua/config/statusline.lua
local Statusline = require('config.statusline')

-- load and configure tokyonight colorscheme
-- Apply the colorscheme after setup
require('config.tokyonight')

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


-- Requiere nvim-cmp autocompletation
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
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Confirm selection with Enter
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


local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })


-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true


-- nvim-tree setup with options
require("nvim-tree").setup({
  sort = {
    sorter = "case_sensitive",
  },
  view = {
    width = 30,
  },
  renderer = {
    group_empty = true,
    icons = {
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true,
      },
    },
  },
  filters = {
    dotfiles = false,
	git_ignored = false,
	custom = {}, -- Add any other patterns you want to ignore
  },
})

vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
vim.keymap.set("n", "<leader>t", ":NvimTreeFocus<CR>", { desc = "Focus file explorer" })
vim.keymap.set("n", "<leader>b", "<C-w>p", { desc = "Back to previous window" })

vim.opt.termguicolors = true



-- terminal
--vim.keymap.set("n", "<leader><CR>", ":botright 10split | terminal<CR>", { desc = "Open terminal in bottom split" })

-- In normal mode, pressing <Esc>\ moves to previous window
vim.api.nvim_set_keymap('n', '<Esc>\\', '<C-w>p', { noremap = true, silent = true })

-- In terminal mode, pressing <Esc>\ exits terminal mode and moves to previous window
vim.api.nvim_set_keymap('t', '<Esc>\\', [[<C-\><C-n><C-w>p]], { noremap = true, silent = true })

vim.keymap.set("n", "<leader><CR>", function()
  -- Check if a terminal buffer already exists
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
      -- Try to find a window displaying this buffer
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == buf then
          -- Jump to the window showing the terminal buffer
          vim.api.nvim_set_current_win(win)
          vim.cmd("startinsert")
          return
        end
      end
      -- Terminal buffer exists but no window showing it - open in split
      vim.cmd("botright 10split")
      vim.api.nvim_win_set_buf(0, buf)
      vim.cmd("startinsert")
      return
    end
  end

  -- No terminal buffer found, create new terminal split like before
  local buf = vim.api.nvim_create_buf(false, true)
  vim.cmd("botright 10split")
  vim.api.nvim_win_set_buf(0, buf)
  vim.bo[buf].bufhidden = "wipe"

  vim.fn.termopen(os.getenv("SHELL") or "bash", {
    on_exit = function()
      local win = vim.api.nvim_get_current_win()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })

  vim.cmd("startinsert")
end, { desc = "Open or jump to terminal in bottom split" })

-- LazyGit with SSH key selection
vim.keymap.set("n", "<leader>lg", function()
  -- === helper: open floating window with transparency ===
  local function open_float(buf, width, height)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      row = row,
      col = col,
      width = width,
      height = height,
      style = "minimal",
      border = "rounded",
    })
    vim.bo[buf].bufhidden = "wipe"
    --vim.api.nvim_win_set_option(win, "winblend", 15)  -- transparency
    vim.api.nvim_win_set_option(win, "winhl", "Normal:NormalFloat,FloatBorder:FloatBorder")
    return win
  end

  -- === collect private keys ===
  local keys = {}
  --local handle = io.popen('ls ~/.ssh | grep -v ".pub$"')
  local handle = io.popen('bash -c \'for f in $HOME/.ssh/*; do [[ "$f" != *.pub ]] && file "$f" | grep -qi "private key" && echo "$f"; done\'')
  if handle then
    for line in handle:lines() do
      table.insert(keys, line)
    end
    handle:close()
  end

  -- === show message if no keys ===
  if #keys == 0 then
    local buf = vim.api.nvim_create_buf(false, true)
    local w = open_float(buf, 40, 5)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "No private SSH keys found!" })
    return
  end

  -- === create menu buffer and lines ===
  local menu_buf = vim.api.nvim_create_buf(false, true)
  local lines = { "Select SSH key (j/k + Enter, q to quit):" }
  for _, key in ipairs(keys) do
    table.insert(lines, key)
  end

  vim.bo[menu_buf].modifiable = true
  vim.api.nvim_buf_set_lines(menu_buf, 0, -1, false, lines)
  vim.bo[menu_buf].modifiable = false

  local height = math.min(#lines, 15)
  local width = math.floor(vim.o.columns * 0.5)
  local menu_win = open_float(menu_buf, width, height)
  vim.wo[menu_win].cursorline = true

  local current = 1

  -- === function to move cursor ===
  local function render_menu()
    current = math.max(1, math.min(current, #keys))
    local target_line = current + 1  -- +1 for header line
    vim.api.nvim_win_set_cursor(menu_win, { target_line, 0 })
  end

  render_menu()

  local function move(delta)
    current = math.max(1, math.min(#keys, current + delta))
    render_menu()
  end

  -- === keymaps for navigation ===
  vim.keymap.set("n", "j", function() move(1) end, { buffer = menu_buf })
  vim.keymap.set("n", "k", function() move(-1) end, { buffer = menu_buf })
  vim.keymap.set("n", "<Down>", function() move(1) end, { buffer = menu_buf })
  vim.keymap.set("n", "<Up>", function() move(-1) end, { buffer = menu_buf })

  -- === launch LazyGit with selected key ===
  vim.keymap.set("n", "<CR>", function()
    local selected_key = keys[current]
    vim.api.nvim_win_close(menu_win, true)

    local lg_buf = vim.api.nvim_create_buf(false, true)
    local lg_win = open_float(lg_buf, math.floor(vim.o.columns * 0.9), math.floor(vim.o.lines * 0.9))

    local cmd = string.format([[
      pkill ssh-agent 2>/dev/null
      eval "$(ssh-agent -s)"
      ssh-add %s
      lazygit
    ]], selected_key)

    vim.fn.termopen({ "bash", "-c", cmd }, {
      on_exit = function(_, _, _)
        if vim.api.nvim_win_is_valid(lg_win) then
          vim.api.nvim_win_close(lg_win, true)
        end
      end,
    })
    vim.cmd("startinsert")
  end, { buffer = menu_buf })

  -- === quit menu ===
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(menu_win) then
      vim.api.nvim_win_close(menu_win, true)
    end
  end, { buffer = menu_buf })
end, { noremap = true, silent = true })

-- identation helper
require("ibl").setup {
  indent = {
    char = "│", -- You can use "┊" or "┆" or "▏" too
  },
  scope = {
    enabled = false,
    show_start = true,
    show_end = true,
    highlight = { "Function", "Label" },
  },
  exclude = {
    filetypes = { "help", "terminal", "lazy", "dashboard", "NvimTree" },
    buftypes = { "terminal", "nofile" },
  },
}
vim.opt.termguicolors = true


-- uset the system clipboardvim.opt.clipboard = "unnamedplus"
vim.keymap.set("n", "yy", '"+yy', { noremap = true })
vim.keymap.set("v", "y", '"+y', { noremap = true })


require("cyberdream").setup({
    -- Set light or dark variant
    variant = "default", -- use "light" for the light variant. Also accepts "auto" to set dark or light colors based on the current value of `vim.o.background`

    -- Enable transparent background
    transparent = false,

    -- Reduce the overall saturation of colours for a more muted look
    saturation = 1, -- accepts a value between 0 and 1. 0 will be fully desaturated (greyscale) and 1 will be the full color (default)

    -- Enable italics comments
    italic_comments = false,

    -- Replace all fillchars with ' ' for the ultimate clean look
    hide_fillchars = false,

    -- Apply a modern borderless look to pickers like Telescope, Snacks Picker & Fzf-Lua
    borderless_pickers = false,

    -- Set terminal colors used in `:terminal`
    terminal_colors = true,

    -- Improve start up time by caching highlights. Generate cache with :CyberdreamBuildCache and clear with :CyberdreamClearCache
    cache = false,

    -- Override highlight groups with your own colour values
    highlights = {
        -- Highlight groups to override, adding new groups is also possible
        -- See `:h highlight-groups` for a list of highlight groups or run `:hi` to see all groups and their current values

        -- Example:
        Comment = { fg = "#696969", bg = "NONE", italic = true },

        -- More examples can be found in `lua/cyberdream/extensions/*.lua`
    },

    -- Override a highlight group entirely using the built-in colour palette
    overrides = function(colors) -- NOTE: This function nullifies the `highlights` option
        -- Example:
        return {
            Comment = { fg = colors.green, bg = "NONE", italic = true },
            ["@property"] = { fg = colors.magenta, bold = true },
        }
    end,

    -- Override colors
    colors = {
        -- For a list of colors see `lua/cyberdream/colours.lua`

        -- Override colors for both light and dark variants
        bg = "#000000",
        green = "#00ff00",

        -- If you want to override colors for light or dark variants only, use the following format:
        dark = {
            magenta = "#ff00ff",
            fg = "#eeeeee",
        },
        light = {
            red = "#ff5c57",
            cyan = "#5ef1ff",
        },
    },

    -- Disable or enable colorscheme extensions
    extensions = {
        telescope = true,
        notify = true,
        mini = true,
        ...
    },
})
