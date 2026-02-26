return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true }, -- Disable features when opening large files
      bufdelete = { enabled = true }, -- Delete buffers without disrupting window layout.
      dim = { enabled = true }, -- Dim all except active scope
      gitbrowse = { enabled = true }, -- Open current file in git remote repo
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
      -- Other
      {
        '<leader>bd',
        function()
          Snacks.dim()
        end,
        desc = 'Toggle [D]imming',
      },
      {
        '<leader>n',
        function()
          Snacks.notifier.show_history()
        end,
        desc = '[N]otification History',
      },
      {
        '<leader>bd',
        function()
          Snacks.bufdelete.delete()
        end,
        desc = '[D]elete [B]uffer',
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
    },
  },
}
