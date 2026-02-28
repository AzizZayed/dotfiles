return {
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-context',
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
    opts = function()
      return {
        ensure_installed = require('languages').languages(),
        auto_install = true,
        highlight = {
          enable = true,
          -- Ruby requires vim regex for indent rules
          additional_vim_regex_highlighting = { 'ruby' },
        },
        indent = { enable = true, disable = { 'ruby' } },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<C-space>',
            node_incremental = '<C-space>',
            -- scope_incremental = false,
            node_decremental = '<C-backspace>',
          },
        },
      }
    end,
  },
}
