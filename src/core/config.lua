local fs = require "src.utils.fs"
local tbl = require "src.utils.tbl"
local sandbox = require "src.utils.sandbox"
local log = require "src.utils.log"

local M = {}

M.opts = {
  colors = true,
  logfile = false,
  cache = {
    enabled = true,
    limit = 3600,
  },
}

function M.read_user_config()
  if not fs.is_file(PKGER_CONFIG_FILE) then
    return {}
  end

  local ok, f = pcall(io.open, PKGER_CONFIG_FILE, "r")
  if not (ok and f) then
    error "Unable to read user config."
  end

  local text = f:read "*all"
  f:close()

  local sucess, config = sandbox.run(text)
  if not sucess then
    error("Error while trying to load user config: " .. config)
  end

  return config
end

function M.init()
  -- load global config
  require "src.core.global"

  local m = fs.mkdir
  m(PKGER_PREFIX)
  m(PKGER_BIN)
  m(PKGER_ETC)
  m(PKGER_LIB)
  m(PKGER_PKGS)
  m(PKGER_CACHE)
  m(PKGER_TMP)
  m(PKGER_CONFIG)
  m(PKGER_OPT)

  local ok, result = pcall(M.read_user_config)

  if ok then
    M.set(result)
    return
  end

  log.error(result)
end

function M.set(opts)
  M.opts = tbl.deep_extend(M.opts, opts or {})
end

return M
