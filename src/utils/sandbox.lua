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

local function run_sandbox(code, custom_env)
  local chunk, err = load(code, "sandbox", "t", custom_env)

  if not chunk then
    log.err("Error loading code: " .. err)
  end

  if type(chunk) ~= "function" then
    log.err "It was not possible to obtain a function when loading the file."
  end

  local ok, result = pcall(chunk)

  if not ok then
    log.err("Error executing code: " .. result)
  end

  return custom_env
end

M.run = function(code, custom_env)
  custom_env = tbl.deep_extend(env(), custom_env or {})
  return pcall(run_sandbox, code, custom_env)
end

return M
