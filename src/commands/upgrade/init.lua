local log = require "src.utils.log"
local lpkg = require "src.core.pkg"
local c = require "src.utils.colors"
local search = require "src.commands.search"
local fn = require "src.utils.fn"
local tbl = require "src.utils.tbl"
local repo = require "src.core.repo"
local fs = require "src.utils.fs"
local v = require "semver"

local S = require "src.commands.switch"
local L = require "src.commands.link"
local I = require "src.commands.install"
local U = require "src.commands.unlink"

local M = {}

local cache = {}

function M.upgrade_pkg(pkg, is_dependency, flags)
  log.arrow "Loading repos..."
  cache.repos = cache.repos or repo.load_all()
  cache.current_dir = fs.cwd()

  if not cache.repos then
    log.error "No valid repo was found."
    fn.exit(1)
  end

  if pkg.pinned then
    log.err(fn.f("%s can't be updated because %s is pinned. Use `unpin` to undo.", pkg.name, pkg.version))
  end

  log.info "Checking for a new version...."
  local new_pkg = lpkg.get_pkg(cache.repos, pkg.name, PKGER_SCRIPT_VERSION)

  if not new_pkg then
    log.warn("Could not get the script for: " .. pkg.name)
    return
  end

  local current_version = v(pkg.version)
  local new_version = v(new_pkg.version)

  local dotpkg = lpkg.has_package(new_pkg.name, new_pkg.version)
  local ok, _ = pcall(dofile, dotpkg)

  if new_version > current_version then
    log.info(fn.f("New version of %s available: %s", new_pkg.name, new_pkg.version))

    if not ok then
      I.load_pkg(new_pkg, false, { upgrade = true })
    end

    -- TODO: create save orignal link
    S.switch(new_pkg.name, new_pkg.version)

    log.info(("%s be updated."):format(pkg.name))
    return
  end

  log.info(fn.f("The latest version of %s is already installed: %s", new_pkg.name, current_version))

  -- -- TODO: upgrade dependencie
  -- local ok, _ = I.install(pkg.name, "script", false, { upgrade = true })

  -- -- TODO: no link checar se a versão é válida antes de desfazer o link
  -- if not ok then
  --   log.err(("%s cannot be updated."):format(pkg.name))
  -- end

  -- log.info(("%s be updated."):format(pkg.version))
end

function M.parser(args, flags)
  local pkgs = {}

  if #args == 0 then
    pkgs = lpkg.list_primary_pkgs()
  end

  if #args > 0 then
    for _, name in pairs(args) do
      local pkg = lpkg.get_current_pkg(name)

      if pkg then
        table.insert(pkgs, pkg)
      else
        log.warn(("%s does not have a primary version."):format(name))
      end
    end
  end

  if tbl.is_empty(pkgs) then
    log.error "No valid packages were found to be updated."
  end

  for _, pkg in pairs(pkgs) do
    local ok, msg = pcall(M.upgrade_pkg, pkg, flags)
    if PKGER_DEBUG_MODE then
      log(msg)
    end
  end
end

return M
