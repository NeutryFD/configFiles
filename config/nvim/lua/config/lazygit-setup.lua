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
