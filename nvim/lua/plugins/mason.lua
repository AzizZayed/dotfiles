return {
  { 'mason-org/mason.nvim', opts = {} },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    opts = function()
      local registry = require 'mason-registry'
      local tools = vim.tbl_filter(registry.has_package, require('languages').tools())
      return { ensure_installed = tools }
    end,
  },
}
