local fn = require "src.utils.fn"
local tbl = require "src.utils.tbl"
local fs = require "src.utils.fs"
local log = require "src.utils.log"

local M = {}

function M.create()
  return fs.write_file(PKGER_LOCKED, "pkger locked")
end

function M.delete()
  if fs.is_file(PKGER_LOCKED) then
    return fs.rm(PKGER_LOCKED)
  end
  return false, nil
end

function M.wait()
  while fs.is_file(PKGER_LOCKED) do
    log.arrow("PKGER blocked. Waiting for another instance: " .. PKGER_LOCKED)
    fn.sleep(1)
  end
end

return M
