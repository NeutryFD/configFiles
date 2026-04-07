require("noice").setup({
	views = {
		notify = {
    		enabled = true,
    		view = "notify",
			merge = true,
		},
		cmdline_popup = {
        	position = {
        		row = 30,
        		col = "50%",
        	},
        size = {
          width = 60,
          height = "auto",
        },
      },
      popupmenu = {
        relative = "editor",
        position = {
          row = 8,
          col = "50%",
        },
        size = {
          width = 60,
          height = 10,
        },
        border = {
          style = "rounded",
          padding = { 0, 1 },
        },
        win_options = {
          winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
        },
      },
    },
  })
