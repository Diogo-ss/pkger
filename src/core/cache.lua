local fn = require "src.utils.fn"
local fs = require "src.utils.fs"
local tbl = require "src.utils.tbl"
local log = require "src.utils.log"
local config = require "src.core.config"

local M = {}
local limit = 3600

function M.save(name, cache)
  local C = {
    timestamp = os.time(),
    cache = cache,
  }

  local text = "return " .. fn.inspect(C)
  local file = fs.join(PKGER_CACHE, name)
  return fs.write_file(file, text)
end

function M.load(name, flags)
  local file = fs.join(PKGER_CACHE, name)
  local ok, C = pcall(dofile, file)

  if ok and (os.time() - (C.timestamp or 0) < limit) then
    return C.cache
  end

  return nil
end

function M.clear(name)
  local file = fs.join(PKGER_CACHE, name or "")

  if name and fs.is_file(file) then
    return fs.rm(file)
  end

  if not name and fs.is_dir(PKGER_CACHE) then
    return fs.rm_dir(PKGER_CACHE)
  end

  return false, nil
end

return M
