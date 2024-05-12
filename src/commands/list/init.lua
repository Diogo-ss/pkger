local c = require "src.utils.colors"
local log = require "src.utils.log"
local lpkg = require "src.core.pkg"

local M = {}

function M.parser(_)
  local pkgs = lpkg.list_packages()

  for _, pkg in pairs(pkgs) do
    local current_pkg = lpkg.get_current_pkg(pkg.name) or {}
    local suffix = current_pkg.version == pkg.version and c.cyan " ●" or ""
    log(c.green(pkg.name) .. ": " .. pkg.version .. suffix)
  end
end

return M
