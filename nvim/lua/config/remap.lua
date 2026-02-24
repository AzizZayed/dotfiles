-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>dq', vim.diagnostic.setloclist, { desc = 'Open [D]iagnostic [Q]uickfix list' })

-- better up/down

vim.keymap.set('i', '<C-c>', '<Esc>')

vim.keymap.set({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, '<Down>', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, '<Up>', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')

vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Window resizing
vim.keymap.set('n', '<leader>wl', '<C-w><C-l>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<leader>wh', '<C-w><C-h>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<leader>wj', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<leader>wk', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Window resizing
vim.keymap.set('n', '<leader>w.', '<cmd>vertical resize -5<cr>', { desc = 'Shrink window horizontally' })
vim.keymap.set('n', '<leader>w,', '<cmd>vertical resize +5<cr>', { desc = 'Expand window horizontally' })
vim.keymap.set('n', '<leader>w-', '<cmd>resize -5<cr>', { desc = 'Shrink window vertically' })
vim.keymap.set('n', '<leader>w=', '<cmd>resize +5<cr>', { desc = 'Expand window vertically' })
vim.keymap.set('n', '<leader>w5', "5<C-w>_") -- minimize terminal split
-- vim.keymap.set('n', '<leader>wt', function()
--   vim.cmd 'terminal' -- open terminal in current buffer
--   vim.cmd 'startinsert' -- drop straight into insert mode
-- end, { desc = 'Open terminal in current window' })

-- Window splits
vim.keymap.set('n', '+', '<C-w>s', { desc = 'Horizontal split' })
vim.keymap.set('n', '|', '<C-w>v', { desc = 'Vertical split' })
vim.keymap.set('n', '<leader>wc', '<cmd>close<cr>', { desc = 'Close window' })
vim.keymap.set('n', '<leader>wo', '<cmd>only<cr>', { desc = 'Keep only current window' })

-- Buffers (keep Tab/S-Tab, add close/switch)
vim.keymap.set('n', '<Tab>', '<cmd>bnext<cr>', { silent = true, desc = 'Next buffer' })
vim.keymap.set('n', '<S-Tab>', '<cmd>bprevious<cr>', { silent = true, desc = 'Previous buffer' })
-- vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<cr>', { desc = 'Delete buffer' })
-- vim.keymap.set('n', '<leader>bo', '<cmd>%bd|e#|bd#<cr>', { desc = 'Close all but current buffer' })

-- Open netrw
vim.keymap.set('n', '<leader>e', vim.cmd.Ex, { desc = 'Open [E]xplorer' })
vim.keymap.set('n', '<leader>we', ':Vexplore<CR>', { desc = 'Open V[e]xplorer [W]indow' })

-- Terminal
-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<leader>wt', function()
  local term_buf = nil
  -- Look for an existing buffer named "Term"
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf):match 'Term$' then
      term_buf = buf
      break
    end
  end

  if term_buf then
    -- Check if it's visible in any window
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == term_buf then
        -- Close the window showing the terminal
        vim.api.nvim_win_close(win, true)
        return
      end
    end
    -- If terminal exists but not visible, reopen it
    vim.cmd('20split | buffer ' .. term_buf)
    -- vim.cmd 'startinsert'
  else
    -- Otherwise, open a new terminal
    vim.cmd '20split | terminal' -- Open terminal in horizontal split
    vim.cmd 'file Term' -- Rename the buffer to "Term"
    -- vim.cmd 'startinsert' -- Start in insert mode
  end
end, { desc = 'Toggle Terminal' })
