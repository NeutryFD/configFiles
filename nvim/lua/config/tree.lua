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


vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
vim.keymap.set("n", "<leader>t", ":NvimTreeFocus<CR>", { desc = "Focus file explorer" })
vim.keymap.set("n", "<leader>b", "<C-w>p", { desc = "Back to previous window" })
vim.opt.termguicolors = true
