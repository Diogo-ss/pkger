local tbl = require "src.utils.tbl"
local fn = require "src.utils.fn"
local curl = require "src.utils.curl"
local fs = require "src.utils.fs"
local log = require "src.utils.log"
local repo = require "src.core.repo"
local sandbox = require "src.utils.sandbox"
local lpkg = require "src.core.pkg"
local utils_pkgs = require "src.commands.install.pkgs"

local cache = {}

local M = {}

-- remover
-- cache.repos = {
--   {
--     manteiners = { "Diogo-ss" },
--     url = "https://raw.githubusercontent.com/pkger/core-pkgs/main/pkgs/${{ name }}/${{ version }}/pkg.lua",
--   },
-- }

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
    INSTALLATION_ENVIRONMENT = true,
  }
end

function M.install_pkgs(pkgs)
  log.info "Loading repos..."
  cache.repos = cache.repos or repo.load_all()
  local current_dir = fs.cwd()

  if not cache.repos then
    log.error "No valid repo was found."
    os.exit(1)
  end
end

function M.parser(args)
  local pkgs = utils_pkgs.parse(args)

  if tbl.isempty(pkgs) then
    log.error "No targets specified. Use --help."
    os.exit(1)
  end

  -- TODO: load cache
  -- M.load_cache()

  M.install_pkgs(pkgs)
end

return M
