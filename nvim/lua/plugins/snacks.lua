return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      bufdelete = { enabled = true },
      dim = { enabled = true },
      gitbrowse = { enabled = true },
      notifier = {
        enabled = true,
        timeout = 3000,
        level = vim.log.levels.TRACE,
        icons = {
          error = ' ',
          warn = ' ',
          info = ' ',
          debug = ' ',
          trace = ' ',
        },
        more_format = ' ↓ %d lines ',
        top_down = false,
      },
      quickfile = { enabled = true },
    },
    keys = {
      {
        '<leader>bd',
        function()
          Snacks.bufdelete.delete()
        end,
        desc = '[D]elete Buffer',
      },
      {
        '<leader>bD',
        function()
          Snacks.dim()
        end,
        desc = 'Toggle [D]imming',
      },
      {
        '<leader>br',
        function()
          Snacks.rename.rename_file()
        end,
        desc = '[R]ename File',
      },
      {
        '<leader>bg',
        function()
          Snacks.gitbrowse()
        end,
        desc = '[G]it Browse',
        mode = { 'n', 'v' },
      },
      {
        '<leader>n',
        function()
          Snacks.notifier.show_history()
        end,
        desc = '[N]otification History',
      },
    },
  },
}
