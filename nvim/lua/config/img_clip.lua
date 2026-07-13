local img_clip = require('img-clip')

img_clip.setup({
  default = {
    dir_path = 'assets/imgs',
    use_absolute_path = false,
    relative_to_current_file = false,
    prompt_for_file_name = true,
    template = '$FILE_PATH',
  },
  filetypes = {
    markdown = {
      template = '![]($FILE_PATH)',
      download_images = false,
    },
    html = {
      template = '<img src="$FILE_PATH" alt="">',
    },
    tex = {
      template = [[\includegraphics[width=\linewidth]{$FILE_PATH}]],
    },
    css = {
      template = 'background-image: url("$FILE_PATH");',
    },
  },
})

vim.api.nvim_create_user_command('pastemd', function()
  img_clip.paste_image({ insert_template_after_cursor = false })
end, {})

