local log = require "src.utils.log"
local tbl = require "src.utils.tbl"
local lpkg = require "src.core.pkg"
local fn = require "src.utils.fn"

local M = {}

function M.parser(args)
  if #args ~= 1 then
    log.error "A single package name is required."
    return
  end

  local pkg = lpkg.parse(args)

  fn.print(pkg)
end

return M
