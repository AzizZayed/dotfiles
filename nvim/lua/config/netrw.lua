local utils = require 'utils'

vim.api.nvim_create_autocmd({ 'FileType' }, {
  pattern = { 'netrw' },
  group = vim.api.nvim_create_augroup('NetrwOnDelete', { clear = true }),
  callback = function()
    local current_os = utils.get_os()

    local function trash_file()
      local filename = vim.fn.expand '<cfile>'
      if filename == '' then
        vim.notify('No file under cursor', vim.log.levels.WARN)
        return
      end

      -- Get the full path by combining netrw's current dir with the filename
      local current_dir = vim.b.netrw_curdir
      local file = current_dir .. '/' .. filename

      local trash_cmd

      if current_os == utils.OS.MAC then
        local trash_dir = os.getenv 'HOME' .. '/.Trash'
        trash_cmd = string.format('mv "%s" "%s"', file, trash_dir)
      elseif current_os == utils.OS.LINUX then
        local trash_dir = os.getenv 'HOME' .. '/.local/share/Trash/files'
        trash_cmd = string.format('mv "%s" "%s"', file, trash_dir)
      else
        vim.notify('Unsupported OS for trash operation', vim.log.levels.ERROR)
        return
      end

      -- vim.notify('Running command: ' .. trash_cmd, vim.log.levels.INFO)

      local result = os.execute(trash_cmd)
      if result == 0 then
        vim.notify('Moved to trash: ' .. file, vim.log.levels.INFO)
        vim.cmd 'edit'
      else
        vim.notify('Failed to move to trash: ' .. file, vim.log.levels.ERROR)
      end
    end

    vim.keymap.set('n', 'D', trash_file, { buffer = true, noremap = true, silent = true })
  end,
})
