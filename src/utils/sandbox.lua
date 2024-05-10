local log = require "src.utils.log"
local tbl = require "src.utils.tbl"
local fn = require "src.utils.fn"
-- local curl = require "utils.curl"
-- local fs = require "utils.fs"

local M = {}

local function env()
  return {
    print = log,
    log = log,
    trim = fn.trim,
  }
end

local function run_sandbox(code, _env)
  local chunk, err = load(code, "sandbox", "t", _env)

  if not chunk then
    error("Error loading code: " .. err)
  end

  local ok, result = pcall(chunk)

  if not ok then
    error("Error executing code: " .. result)
  end

  return _env
end

M.run = function(code, _env)
  _env = tbl.deep_extend(env(), _env or {})
  return pcall(run_sandbox, code, _env)
end

return M
