local tbl = require "utils.tbl"
local fn = require "utils.fn"
local curl = require "utils.curl"
local fs = require "utils.fs"
local log = require "utils.log"

local M = {}

local function env()
  return {
    system = fn.system,
    shell_code = fn.shell_code,
    get = curl.get,
    rm = fs.rm,
    rm_dir = fs.rm_dir,
    cp = fs.cp,
    cd = fs.cd,
    cwd = fs.cwd,
    extract = fs.extract,
    print = log,
    log = log,
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
