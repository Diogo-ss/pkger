local fn = require "src.utils.fn"
local fs = require "src.utils.fs"
local tbl = require "src.utils.tbl"
local log = require "src.utils.log"
local config = require "src.core.config"

local M = {}

function M:new()
  return setmetatable({
    limit = 3600,
    db = {},
  }, { __index = self })
end

function M:save(name, cache)
  local C = {
    timestamp = os.time(),
    cache = cache,
  }

  local text = "return " .. fn.inspect(C)
  local file = fs.join(PKGER_CACHE, name)

  self.db[name] = cache

  return fs.write_file(file, text)
end

function M:load(name, flags)
  if self.db[name] and (os.time() - (self.db[name].timestamp or 0) < self.limit) then
    return self.db[name].cache
  end

  local file = fs.join(PKGER_CACHE, name)
  local ok, C = pcall(dofile, file)

  if ok and (os.time() - (C.timestamp or 0) < self.limit) then
    self.db[name] = C
    return C.cache
  end

  return nil
end

function M:clear(name)
  local file = fs.join(PKGER_CACHE, name or "")

  if name then
    self.db[name] = nil
    if fs.is_file(file) then
      return fs.rm(file)
    end
  end

  if not name then
    self.db = {}
    if fs.is_dir(PKGER_CACHE) then
      return fs.rm_dir(PKGER_CACHE)
    end
  end

  return false, nil
end

-- function M:print()
--   print(self.limit)
-- end

return M
