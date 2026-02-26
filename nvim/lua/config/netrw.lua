local utils = require 'utils'

-- Stack tracking trashed files so deletes can be undone via <leader>D
local delete_stack = {}

-- Returns a unique path in trash_dir for filename, appending a timestamp if needed
local function unique_trash_path(trash_dir, filename)
  local path = trash_dir .. '/' .. filename
  if not vim.uv.fs_stat(path) then
    return path
  end
  local base = vim.fn.fnamemodify(filename, ':r')
  local ext = vim.fn.fnamemodify(filename, ':e')
  local ts = os.time()
  if ext ~= '' then
    return string.format('%s/%s_%d.%s', trash_dir, base, ts, ext)
  else
    return string.format('%s/%s_%d', trash_dir, base, ts)
  end
end

-- Set up an autocommand to handle file deletion in netrw
-- D  → move to trash, wipe buffer, push to undo stack
-- <C-D> → restore last trashed file (pop from stack)
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

      local current_dir = vim.b.netrw_curdir
      local filepath = current_dir .. '/' .. filename

      local trash_dir
      if current_os == utils.OS.MAC then
        trash_dir = os.getenv 'HOME' .. '/.Trash'
      elseif current_os == utils.OS.LINUX then
        trash_dir = os.getenv 'HOME' .. '/.local/share/Trash/files'
      else
        vim.notify('Unsupported OS for trash operation', vim.log.levels.ERROR)
        return
      end

      local trash_path = unique_trash_path(trash_dir, filename)
      local result = os.execute(string.format('mv "%s" "%s"', filepath, trash_path))
      if result ~= 0 then
        vim.notify('Failed to move to trash: ' .. filename, vim.log.levels.ERROR)
        return
      end

      -- Wipe the buffer so it can't be accidentally reopened from the buffer list
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf) == filepath then
          vim.api.nvim_buf_delete(buf, { force = true })
          break
        end
      end

      table.insert(delete_stack, { original = filepath, trash = trash_path })
      vim.notify('Trashed: ' .. filename .. '  (<leader>D to undo)', vim.log.levels.INFO)
      vim.cmd 'edit'
    end

    local function undo_delete()
      if #delete_stack == 0 then
        vim.notify('Nothing to restore', vim.log.levels.WARN)
        return
      end

      local entry = table.remove(delete_stack) -- pop most recent
      local result = os.execute(string.format('mv "%s" "%s"', entry.trash, entry.original))
      if result == 0 then
        vim.notify('Restored: ' .. vim.fn.fnamemodify(entry.original, ':t'), vim.log.levels.INFO)
        vim.cmd 'edit'
      else
        vim.notify('Failed to restore: ' .. entry.original, vim.log.levels.ERROR)
        table.insert(delete_stack, entry) -- push back on failure
      end
    end

    vim.keymap.set('n', 'D', trash_file, { buffer = true, noremap = true, silent = true })
    vim.keymap.set('n', '<C-D>', undo_delete, { buffer = true, noremap = true, silent = true })
  end,
})

-- Set up an autocommand to handle file renaming in netrw
-- This will allow users to rename files directly from netrw using the 'R' key
-- Then, the buffer will be reloaded to reflect the changes
vim.api.nvim_create_autocmd({ 'FileType' }, {
  pattern = { 'netrw' },
  group = vim.api.nvim_create_augroup('NetrwOnRename', { clear = true }),
  callback = function()
    local function promp_rename_file()
      local filename = vim.fn.expand '<cfile>'
      if filename == '' then
        vim.notify('No file under cursor', vim.log.levels.WARN)
        return
      end

      local current_dir = vim.b.netrw_curdir
      local old_path = current_dir .. '/' .. filename

      vim.ui.input({ prompt = 'Move/rename to:', default = old_path }, function(new_path)
        if not new_path or new_path == '' or new_path == old_path then
          return
        end

        local new_path_exists = vim.uv.fs_access(new_path, 'W')
        if new_path_exists then
          vim.notify('File already exists: ' .. new_path, vim.log.levels.ERROR)
          return
        end

        local ok, err = vim.uv.fs_rename(old_path, new_path)
        if not ok then
          vim.notify('Failed to rename: ' .. err, vim.log.levels.ERROR)
          return
        end

        -- Find and update any open buffer with the old path
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_get_name(buf) == old_path then
            vim.api.nvim_buf_set_name(buf, new_path)
            -- Reload the buffer to avoid "file changed" warnings
            vim.api.nvim_buf_call(buf, function()
              vim.cmd 'edit'
            end)
            break
          end
        end

        local new_name = vim.fn.fnamemodify(new_path, ':t')
        vim.notify('Renamed: ' .. filename .. ' → ' .. new_name, vim.log.levels.INFO)

        vim.cmd 'edit' -- refresh netrw
      end)
    end

    vim.keymap.set('n', 'R', promp_rename_file, { buffer = true, remap = true, silent = true })
  end,
})
