local notify = require("notify")

notify.setup({
  timeout = 3000, -- duration in ms
  stages = "slide", -- animation style
  render = "default", -- default rendering function
})
