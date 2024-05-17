local c = require "src.utils.colors"
local log = require "src.utils.log"
local lpkg = require "src.core.pkg"

local M = {}

local function _log(key, value)
  log(c.green(key) .. ": " .. value)
end

function M.parser(_, flags)
  local pkgs = lpkg.list_packages()

  for _, pkg in pairs(pkgs) do
    local current_pkg = lpkg.get_current_pkg(pkg.name) or {}
    local suffix = current_pkg.version == pkg.version and c.cyan " ●" or ""

    if flags.name and pkg.name ~= flags.name then
      goto continue
    end

    _log(pkg.name, pkg.version .. suffix)

    ::continue::
  end
end

return M
