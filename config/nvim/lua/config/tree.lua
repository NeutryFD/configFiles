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
      glyphs = {
        git = {
          unstaged  = " ",
		  staged    = " ",
		  unmerged  = "",
		  renamed   = "➜",
		  untracked = "★ ",
		  deleted   = " ",
		  ignored   = "◌",
        },
      },
    },
  },
  filters = {
    dotfiles = false,
    git_ignored = false,
    custom = {},
  },
})

vim.api.nvim_set_hl(0, "NvimTreeGitDirty", {
  fg = "#DA70D6", -- orange
  bold = true,
})

-- Auto open file when created from nvim-tree
local api = require("nvim-tree.api")
api.events.subscribe(api.events.Event.FileCreated, function(file)
  vim.cmd("edit " .. vim.fn.fnameescape(file.fname))
end)

-- Make nvim-tree commands silent (No show popoups when toggling or focusing)
local function silent_cmd(cmd)
  return function()
    local old_notify = vim.notify
    vim.notify = function() end
    vim.cmd(cmd)
    vim.notify = old_notify
  end
end

vim.keymap.set("n", "<leader>e", silent_cmd("NvimTreeToggle"), { desc = "Toggle file explorer (silent)" })
vim.keymap.set("n", "<leader>t", silent_cmd("NvimTreeFocus"),  { desc = "Focus file explorer (silent)" })
vim.keymap.set("n", "<leader>b", silent_cmd("wincmd p"),       { desc = "Back to previous window (silent)" })

vim.opt.termguicolors = true
