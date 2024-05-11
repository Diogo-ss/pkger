local log = require "src.utils.log"
local tbl = require "src.utils.tbl"
local lpkg = require "src.core.pkg"
local fn = require "src.utils.fn"
local lfs = require "lfs"
local fs = require "src.utils.fs"

local M = {}

function M.remove_empty_directories(dir) end

function M.parser(args)
  -- if #args ~= 1 then
  --   log.error "A single package name is required."
  --   return
  -- end

  -- local pkg = lpkg.parse(args)

  M.remove_empty_directories(PKGER_DATA)
end

return M
