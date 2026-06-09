vim.g.terraform_fmt_on_save = 1
vim.g.terraform_align = 1

require("tf").setup({
  filetypes = { "terraform", "tf", "terraform-vars", "tfvars", "hcl" },
  state = {
    filter = { case_sensitive = true },
    detail = { folds = true, foldmethod = "syntax" },
    window = {
      mode = "float",
      split = { position = "botright", size = 80 },
      float = { width = 0.7, height = 0.8 },
      focus = true,
    },
  },
})
