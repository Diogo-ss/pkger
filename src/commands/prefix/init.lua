local lpkg = require "src.core.pkg"
local log = require "src.utils.log"

local M = {}

function M.prefix(args)
  if #args == 0 then
    log(PKGER_PREFIX)
    return
  end

  local pkgs = lpkg.parse(args)

  for name, version in pairs(pkgs) do
    local pkg = nil

    if version == PKGER_SCRIPT_VERSION then
      pkg = lpkg.get_current_pkg(name)
    else
      pkg = lpkg.get_pkg_infos(name, version)
    end

    if not pkg then
      version = version ~= PKGER_SCRIPT_VERSION and "@" .. version or ""
      log.error(name .. version .. " isn't installed.")
      return
    end

    log(pkg.prefix)
  end
end

function M.parser(args, flags)
  M.prefix(args)
end

return M
