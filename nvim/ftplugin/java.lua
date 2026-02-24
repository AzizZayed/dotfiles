local jdtls_ok, jdtls = pcall(require, 'jdtls')
if not jdtls_ok then
  vim.notify('jdtls not found. Java LSP will not be started.', vim.log.levels.WARN)
  return
end

local JDTLS_LOCATION = vim.fn.stdpath 'data' .. '/mason/packages/jdtls'
local home = os.getenv 'HOME'

-- File types that signify a Java project's root directory. This will be
-- used by eclipse to determine what constitutes a workspace
local root_markers = { 'gradlew', 'mvnw', 'pom.xml', 'build.gradle', 'settings.gradle', '.git' }
local root_dir = require('jdtls.setup').find_root(root_markers)

if root_dir == nil then
  return
end

-- Only for Linux and Mac
local SYSTEM = 'linux'
if vim.fn.has 'mac' == 1 then
  SYSTEM = 'mac'
end

local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
local workspace_folder = vim.fn.stdpath 'data' .. '/jdtls-workspace/' .. project_name

local extendedClientCapabilities = jdtls.extendedClientCapabilities
extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

-- Helper function for creating keymaps
function nnoremap(rhs, lhs, bufopts, desc)
  bufopts.desc = desc
  vim.keymap.set('n', rhs, lhs, bufopts)
end

-- The on_attach function is used to set key maps after the language server
local on_attach = function(client, bufnr)
  -- Regular Neovim LSP client keymappings
  local bufopts = { noremap = true, silent = true, buffer = bufnr }

  -- Java extensions provided by jdtls
  nnoremap('<C-o>', jdtls.organize_imports, bufopts, 'Organize imports')
  nnoremap('<leader>cev', jdtls.extract_variable, bufopts, '[E]xtract [V]ariable')
  nnoremap('<leader>cec', jdtls.extract_constant, bufopts, '[E]xtract [C]onstant')
  vim.keymap.set(
    'v',
    '<leader>cem',
    [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
    { noremap = true, silent = true, buffer = bufnr, desc = '[E]xtract [M]ethod' }
  )
end

local config = {
  root_dir = root_dir,
  on_attach = on_attach,
  capabilities = require("blink.cmp").get_lsp_capabilities(),

  -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  settings = {
    java = {
      signatureHelp = { enabled = true },
      contentProvider = { preferred = 'fernflower' }, -- Use fernflower to decompile library code
    },
  },
  -- cmd is the command that starts the language server. Whatever is placed
  -- here is what is passed to the command line to execute jdtls.
  -- Note that eclipse.jdt.ls must be started with a Java version of 17 or higher
  -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
  -- for the full list of options
  cmd = {
    'java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',
    '-jar',
    vim.fn.glob(JDTLS_LOCATION .. '/plugins/org.eclipse.equinox.launcher_*.jar'),
    '-configuration',
    JDTLS_LOCATION .. '/config_' .. SYSTEM,
    '-data',
    workspace_folder,
  },
}

-- Finally, start jdtls. This will run the language server using the configuration we specified,
-- setup the keymappings, and attach the LSP client to the current buffer
jdtls.start_or_attach(config)
require("jdtls.setup").add_commands()
