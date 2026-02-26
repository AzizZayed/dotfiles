return {
  { 'nvim-lua/plenary.nvim' },

  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    enabled = false,
    opts = {},
    lazy = false,
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      { '-', '<Cmd>Oil<CR>', desc = 'Browse files from here' },
    },
  },

  {
    'tpope/vim-sleuth',
    event = { 'BufReadPost', 'BufNewFile' },
  },

  {
    'rmagatti/auto-session',
    lazy = false,
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
      suppressed_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
    },
  },

  {
    'MeanderingProgrammer/render-markdown.nvim',
    enabled = false,
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      code = { width = 'block', border = 'none' },
    },
  },

  {
    'lervag/vimtex',
    lazy = false,
    tag = 'v2.16',
    init = function()
      vim.g.vimtex_view_method = 'skim'
      vim.g.vimtex_compiler_method = 'latexmk'
      vim.g.vimtex_compiler_latexmk = {
        out_dir = 'out',
        aux_dir = 'out',
        executable = 'latexmk',
        options = {
          '-verbose',
          '-file-line-error',
          '-synctex=1',
          '-interaction=nonstopmode',
        },
      }
    end,
  },

  {
    'github/copilot.vim',
    event = 'VimEnter',
    config = function()
      vim.keymap.set('i', '<S-Tab>', '<Plug>(copilot-accept-word)')
    end,
  },

  {
    'salkin-mada/openscad.nvim',
    dependencies = { 'L3MON4D3/LuaSnip', 'junegunn/fzf.vim' },
    config = function()
      vim.g.openscad_load_snippets = true
      vim.g.openscad_cheatsheet_toggle_key = '<leader>dc'
      vim.g.openscad_exec_openscad_trig_key = '<leader>dr'
      require 'openscad'
    end,
  },
}
