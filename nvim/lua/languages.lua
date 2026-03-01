-- Single source of truth for language tooling.
-- Each plugin (mason, lsp, conform, lint, treesitter) reads this and builds its own config.
-- ft keys double as treesitter parser names.

---@class LanguageConfig
---@field lsps? string[]             LSP server names (configured in M.servers)
---@field formatters? string[]       Formatter names, chained in order (conform.nvim)
---@field linters? string[]          Linter names (nvim-lint)
---@field format_on_save? boolean    Format on save (default: true)

---@class LanguageServerConfig
---@field cmd? string[]              Command to start the LSP server
---@field filetypes? string[]        Filetypes the server should attach to (overrides ft in M.langs)
---@field settings? table            LSP-specific settings table (passed to lspconfig)
---@field capabilities? table        LSP capabilities (passed to lspconfig)

local M = {
  -- LSP server configs keyed by lspconfig server name.
  -- Java (jdtls) is managed separately via ftplugin/java.lua.
  ---@type table<string, LanguageServerConfig>
  servers = {
    clangd = {
      cmd = { 'clangd', '--background-index' },
      filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'h.inc', 'cpp.inc' },
    },
    pyright = {},
    rust_analyzer = {},
    vhdl_ls = {},
    lua_ls = {
      settings = { Lua = { completion = { callSnippet = 'Replace' } } },
    },
    emmylua_ls = {},
  },

  -- Per-filetype tooling. Keys are also treesitter parser names.
  ---@type table<string, LanguageConfig>
  langs = {
    c = {
      lsps = { 'clangd' },
      formatters = { 'clang-format' },
      linters = { 'clangtidy' },
    },
    cpp = {
      lsps = { 'clangd' },
      formatters = { 'clang-format' },
      linters = { 'clangtidy' },
    },
    python = {
      lsps = { 'pyright' },
      formatters = { 'black' },
      linters = { 'ruff' },
    },
    rust = {
      lsps = { 'rust-analyzer' },
      -- formatters = { 'rustfmt' },
      linters = { 'clippy' },
    },
    java = {
      -- lsp managed via ftplugin/java.lua (jdtls)
      formatters = { 'google-java-format' },
      linters = { 'checkstyle' },
    },
    lua = {
      lsps = { 'lua_ls', 'emmylua_ls' },
      formatters = { 'stylua' },
    },
    vhdl = {
      lsps = { 'vhdl_ls' },
    },
    markdown = {
      formatters = { 'prettier' },
      linters = { 'markdownlint' },
    },
    json = { linters = { 'jsonlint' } },
    dockerfile = { linters = { 'hadolint' } },
  },
}

M.servers['lua-language-server'] = M.servers.lua_ls -- mason-lspconfig name
M.servers['rust-analyzer'] = M.servers['rust_analyzer'] -- mason-lspconfig name

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

---All unique tool names across servers, formatters, and linters.
---@return string[]
function M.tools()
  local seen, result = {}, {}
  local function add(name)
    if not seen[name] then
      seen[name] = true
      table.insert(result, name)
    end
  end
  for name in pairs(M.servers) do
    add(name)
  end
  for _, lang in pairs(M.langs) do
    for _, t in ipairs(lang.formatters or {}) do
      add(t)
    end
    for _, t in ipairs(lang.linters or {}) do
      add(t)
    end
  end
  return result
end

---formatters_by_ft table ready for conform.nvim.
---@return table<string, string[]>
function M.formatters()
  local result = {}
  for ft, lang in pairs(M.langs) do
    if lang.formatters and #lang.formatters > 0 then
      result[ft] = lang.formatters
    end
  end
  return result
end

---linters_by_ft table ready for nvim-lint.
---@return table<string, string[]>
function M.linters()
  local result = {}
  for ft, lang in pairs(M.langs) do
    if lang.linters and #lang.linters > 0 then
      result[ft] = lang.linters
    end
  end
  return result
end

---All treesitter parser names (ft keys).
---@return string[]
function M.languages()
  return vim.tbl_keys(M.langs)
end

---Set of filetypes where format-on-save is disabled.
---@return table<string, true>
function M.no_format_save_fts()
  ---@type table<string, true>
  local result = { text = true, plaintext = true }
  for ft, lang in pairs(M.langs) do
    if lang.format_on_save == false then
      result[ft] = true
    end
  end
  return result
end

return M
