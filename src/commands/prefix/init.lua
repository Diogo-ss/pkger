local lpkg = require "src.core.pkg"
local log = require "src.utils.log"

local M = {}

function M.parser(args, flags)
  if #args == 0 then
    log(PKGER_PREFIX)
    return
  end

  local pkgs = lpkg.parse(args)

  for name, version in pairs(pkgs) do
    local prefix = lpkg.prefix(name, version)

    if not prefix then
      log.error(name .. " isn't installed.")
      return
    end

    log(prefix)
  end
end

return M
