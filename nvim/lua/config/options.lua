-- Must be set before plugins load
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

vim.opt.guicursor = {
  'n-v-c:block-Cursor/lCursor',
  'i-ci-ve-t:ver25-Cursor/lCursor',
  'r-cr-o:hor20-Cursor/lCursor',
}

vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.opt.mousemoveevent = true
vim.o.showmode = false

-- Sync OS clipboard after UI loads to avoid startup delay
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.confirm = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10

vim.opt.colorcolumn = '100'
vim.opt.wrap = false

vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.o.autoindent = true
vim.o.smartindent = true

-- Treesitter-based folding (built-in nvim 0.10+)
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldlevel = 99

-- Window title shows the cwd basename
vim.g.start_dir = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
vim.opt.title = true
vim.opt.titlestring = '%{g:start_dir}'

vim.o.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions'

-- netrw: use trash instead of permanent delete
vim.g.netrw_banner = 0
vim.g.netrw_localcopydircmd = 'cp -r'
vim.g.netrw_localrmdircmd = 'trash'
vim.g.netrw_localrmfilecmd = 'trash'
