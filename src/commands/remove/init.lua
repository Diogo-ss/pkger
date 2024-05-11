local lpkg = require "src.core.pkg"
local c = require "src.utils.colors"
local log = require "src.utils.log"
local fn = require "src.utils.fn"
local tbl = require "src.utils.tbl"
local fs = require "src.utils.fs"

local M = {}

function M.clean_pkgs()
  local pkgs = lpkg.list_packages()

  fn.print(pkgs)

  for _, pkg in pairs(pkgs) do
    if pkg.is_dependency == true then
      local dependents = lpkg.list_all_dependent_pkgs(pkg.name)

      if tbl.isempty(dependents) then
        M.remove(pkg.name, pkgs.version)
      end
    end
  end
end

function M.remove(name, version, is_dependency, force)
  local pkg_file = nil
  local dotpkg = lpkg.get_master_pkg(name)

  if not version or version == "script" or (dotpkg and version == dotpkg.version) then
    if not dotpkg then
      log.error("It was not possible to determine the main version of the package: " .. name)
      error()
    end

    version = dotpkg.version
    pkg_file = dotpkg.file
  end

  local dependents = lpkg.list_all_dependent_pkgs(name)

  if not force and not tbl.isempty(dependents) then
    local str = ""

    for _, dependent in pairs(dependents) do
      str = dependent.name .. "@" .. dependent.version .. " "
    end

    log.error("It was not possible to remove the package because it is a dependency for: " .. str)
    error()
  end

  if not lpkg.has_package(name, version) then
    log.warn(("Package is not installed: %s@%s"):format(name, version))
    return
  end

  local dir = fs.join(PKGER_DATA, name, version)

  if not fs.is_dir(dir) then
    log.error(("The directory for %s@%s doesn't exist."):format(name, version))
    error()
  end

  fs.rm_dir(dir)

  if pkg_file then
    fs.rm(pkg_file)
  end

  M.clean_pkgs()

  log.info(("Package removed: %s@%s"):format(name, version))
end

function M.remove_pkgs(pkgs)
  for name, version in pairs(pkgs) do
    local ok, msg = pcall(M.remove, name, version)
    if not ok then
      version = version ~= "script" and "@" .. version or ""
      log.error("The package could not be removed: " .. name .. version)
    end
  end
end

function M.parser(args)
  local pkgs = lpkg.parse(args)

  if tbl.isempty(pkgs) then
    log.error "No targets specified. Use --help."
    os.exit(1)
  end

  M.remove_pkgs(pkgs)
end

return M
