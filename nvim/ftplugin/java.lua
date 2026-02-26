local utils = require 'utils'
local jdtls_ok, jdtls = pcall(require, 'jdtls')
if not jdtls_ok then
  vim.notify('jdtls not found. Java LSP will not be started.', vim.log.levels.WARN)
  return
end

local JDTLS_LOCATION = vim.fn.stdpath 'data' .. '/mason/packages/jdtls'

local root_markers = { 'gradlew', 'mvnw', 'pom.xml', 'build.gradle', 'settings.gradle', '.git' }
local root_dir = require('jdtls.setup').find_root(root_markers)
if root_dir == nil then
  return
end

local OS = utils.get_os()

local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
local workspace_dir = vim.fn.stdpath 'data' .. '/jdtls-workspace/' .. project_name

local extendedClientCapabilities = jdtls.extendedClientCapabilities
extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

jdtls.start_or_attach {
  root_dir = root_dir,
  capabilities = require('blink.cmp').get_lsp_capabilities(),

  settings = {
    java = {
      signatureHelp = { enabled = true },
      contentProvider = { preferred = 'fernflower' },
    },
  },

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
    JDTLS_LOCATION .. '/config_' .. OS,
    '-data',
    workspace_dir,
  },
}

require('jdtls.setup').add_commands()
