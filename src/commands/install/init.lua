local tbl = require "utils.tbl"
local fn = require "utils.fn"
local curl = require "utils.curl"
local fs = require "utils.fs"
local log = require "utils.log"

local M = {}

local env = {
  system = fn.system,
  shell_code = fn.shell_code,
  get = curl.get,
  rm = fs.rm,
  rm_dir = fs.rm_dir,
  cp = fs.cp,
  cd = fs.cd,
  cwd = fs.cwd,
  extract = fs.extract,
}

function M.install(pkg) end

function M.parse(args) end

return M
