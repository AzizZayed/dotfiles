-- lua/utils.lua
local M = {}

M.OS = {
  MAC = "mac",
  LINUX = "linux",
  WINDOWS = "windows",
  UNKNOWN = "unknown",
}

function M.get_os()
  local uname = vim.uv.os_uname()
  local sysname = uname.sysname

  if sysname == "Darwin" then
    return M.OS.MAC
  elseif sysname == "Linux" then
    return M.OS.LINUX
  elseif sysname:find("Windows") then
    return M.OS.WINDOWS
  else
    return M.OS.UNKNOWN
  end
end

M.is_mac = function()
  return M.get_os() == M.OS.MAC
end

M.is_linux = function()
  return M.get_os() == M.OS.LINUX
end

return M
