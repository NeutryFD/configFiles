require('nvim-treesitter').setup({
  ensure_installed = { 'regex', 'bash', 'html', 'yaml' },
  auto_install = true,
  highlight = { enable = true },
})
