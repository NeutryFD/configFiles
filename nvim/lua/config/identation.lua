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

