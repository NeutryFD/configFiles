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
