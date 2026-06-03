local api = vim.api
local fn = vim.fn
local notify = vim.notify

vim.g.terraform_fmt_on_save = 0

api.nvim_create_autocmd("BufWritePre", {
  group = api.nvim_create_augroup("TerraformFmt", { clear = true }),
  pattern = { "*.tf", "*.tfvars" },
  callback = function()
    local bufnr = api.nvim_get_current_buf()
    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local input = table.concat(lines, "\n")

    local result = fn.system("terraform fmt -check -no-color -", input)

    if vim.v.shell_error ~= 0 then
      notify(result, vim.log.levels.ERROR, { title = "Terraform Format" })
      return
    end

    local formatted = fn.system("terraform fmt -no-color -", input)

    if vim.v.shell_error == 0 and formatted ~= input then
      api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(formatted, "\n"))
    end
  end,
})
