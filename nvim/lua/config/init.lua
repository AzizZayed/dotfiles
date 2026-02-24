require("config.options")
require("config.remap")
require("config.lazy")
require("config.health")

vim.filetype.add({
  pattern = {
    ['.*%.h%.inc']   = 'cpp',  -- or 'c' if you prefer
    ['.*%.cpp%.inc'] = 'cpp',
  },
})

