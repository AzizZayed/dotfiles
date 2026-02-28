local opts = { noremap = true, silent = true }

-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- better up/down

vim.keymap.set('i', '<C-c>', '<Esc>')

vim.keymap.set({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, '<Down>', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, '<Up>', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

vim.keymap.set('v', '<', '<gv', opts)
vim.keymap.set('v', '>', '>gv', opts)

vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')

vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

vim.keymap.set('n', 'x', '"_x', opts) -- Delete a character without copying it into the register
vim.keymap.set('v', '<leader>p', '"_dP', opts) -- Paste over selected text without copying it into the register

-- Replace the word cursor is on globally
-- vim.keymap.set('n', '<leader>s', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Replace word cursor is on globally' })

-- Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Keybinds to make split navigation easier.
vim.keymap.set('n', '<C-h>', ':wincmd h<CR>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', ':wincmd l<CR>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', ':wincmd j<CR>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', ':wincmd k<CR>', { desc = 'Move focus to the upper window' })

-- Window splits
vim.keymap.set('n', '+', '<C-w>s', { desc = 'Horizontal split' })
vim.keymap.set('n', '|', '<C-w>v', { desc = 'Vertical split' })
vim.keymap.set('n', '<leader>wc', '<cmd>close<cr>', { desc = 'Close window' })
vim.keymap.set('n', '<leader>wo', '<cmd>only<cr>', { desc = 'Keep only current window' })

-- Buffers (keep Tab/S-Tab, add close/switch)
vim.keymap.set('n', '<Tab>', '<cmd>bnext<cr>', { silent = true, desc = 'Next buffer' })
vim.keymap.set('n', '<S-Tab>', '<cmd>bprevious<cr>', { silent = true, desc = 'Previous buffer' })

-- Open netrw
vim.keymap.set('n', '<leader>e', vim.cmd.Ex, { desc = 'Open [E]xplorer' })
vim.keymap.set('n', '<leader>we', ':Vexplore<CR>', { desc = 'Open V[e]xplorer [W]indow' })

-- Terminal
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Diagnostics
vim.keymap.set('n', '<leader>cd', function()
  if vim.diagnostic.is_enabled() then
    vim.diagnostic.enable(false)
  else
    vim.diagnostic.enable()
  end
end, { desc = 'Toggle [D]iagnostics' })
