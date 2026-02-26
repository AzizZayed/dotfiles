return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      -- {
      --   '<leader>cf',
      --   function()
      --     require('conform').format { async = true, lsp_format = 'fallback' }
      --   end,
      --   mode = { 'n', 'x' },
      --   desc = '[F]ormat Code/Selection',
      -- },
    },
    config = function()
      local langs = require 'languages'
      local no_fmt_fts = langs.no_format_save_fts()

      require('conform').setup {
        notify_on_error = false,
        formatters_by_ft = langs.formatters(),
        format_on_save = function(bufnr)
          if no_fmt_fts[vim.bo[bufnr].filetype] then
            return nil
          end
          return { timeout_ms = 500, lsp_format = 'fallback' }
        end,
      }
    end,
  },
}
