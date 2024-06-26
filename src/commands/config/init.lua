local fn = require "src.utils.fn"
local log = require "src.utils.log"
local c = require "src.utils.colors"
local sys = require "src.utils.sys"

local M = {}

local function _log(key, value)
  log(c.green(key) .. ": " .. value)
end

function M.config()
  for key, value in pairs(_G) do
    if type(value) == "string" and fn.startswith(key, "PKGER") then
      _log(key, value)
    end
  end

  _log("OS", sys.os)
  _log("ARCH", sys.arch)
end

function M.parser(_, flags)
  if flags.name then
    log(_G[flags.name] or "")
    return
  end

  M.config()
end

return M
