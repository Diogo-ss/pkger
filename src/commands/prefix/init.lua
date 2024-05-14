local lpkg = require "src.core.pkg"
local log = require "src.utils.log"

local M = {}

function M.parser(args, flags)
  if #args == 0 then
    log(PKGER_PREFIX)
    return
  end

  for _, name in pairs(args) do
    local path = lpkg.get_prefix(name)

    if not path then
      log.error(name .. " isn't installed.")
      return
    end

    log(path)
  end
end

return M