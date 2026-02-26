require 'config.options'
require 'config.remap'
require 'config.lazy'
require 'config.health'
require 'config.netrw'

vim.filetype.add {
  pattern = {
    ['.*%.h%.inc'] = 'cpp',
    ['.*%.cpp%.inc'] = 'cpp',
  },
}
