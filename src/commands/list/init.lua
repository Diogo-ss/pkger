local pkg = require "src.core.pkg"
local c = require "src.utils.colors"
local log = require "src.utils.log"
local fn = require "src.utils.fn"

local M = {}

function M.parser(args)
  local pkgs = pkg.list_packages()

  for _, _pkg in pairs(pkgs) do
    log(fn.inspect(_pkg))
  end
end

return M
