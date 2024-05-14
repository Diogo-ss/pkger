local lpkg = require "src.core.pkg"
local log = require "src.utils.log"
local fn = require "src.utils.fn"

local M = {}

function M.parser(args, flags)
  if #args == 0 then
    log(PKGER_PREFIX)
    return
  end

  local pkgs = lpkg.parse(args)

  for name, version in pairs(pkgs) do
    local prefix = nil

    if version == "script" then
      version = nil
    end
    prefix = lpkg.get_prefix(name)

    if version ~= "script" then
      local pkg = lpkg.get_pkg_infos(name, version)

      if pkg then
        prefix = pkg.prefix
      end
    end

    if not prefix then
      version = version and "@" .. version or ""
      log.error(fn.f("%s%s isn't installed.", name, version))
      return
    end

    log(prefix)
  end
end

return M
