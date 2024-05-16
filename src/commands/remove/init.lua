local lpkg = require "src.core.pkg"
local log = require "src.utils.log"
local tbl = require "src.utils.tbl"
local fs = require "src.utils.fs"
local fn = require "src.utils.fn"

local M = {}

function M.clean_pkgs()
  local pkgs = lpkg.list_packages()

  for _, pkg in pairs(pkgs) do
    if pkg.is_dependency == true then
      local dependents = lpkg.list_all_dependent_pkgs(pkg.name)

      if tbl.is_empty(dependents) then
        M.remove(pkg.name, pkgs.version)
      end
    end
  end

  fs.each(fs.join(PKGER_PKGS, "*"), function(P, mode)
    if mode == "directory" then
      if fs.is_empty(P) then
        fs.rm(P)
      end
    end
  end, {
    param = "fm",
    delay = true,
  })
end

function M.remove(name, version, flags)
  flags = flags or {}

  local pkg_file = nil
  local dotpkg = lpkg.get_current_pkg(name)

  if not version or version == "script" or (dotpkg and version == dotpkg.version) then
    if not dotpkg then
      log.error("It was not possible to determine the main version of the package: " .. name)
      error()
    end

    version = dotpkg.version
    pkg_file = dotpkg.file
  end

  local dependents = lpkg.list_all_dependent_pkgs(name)

  if not flags.force and not tbl.is_empty(dependents) then
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

  local dir = fs.join(PKGER_PKGS, name, version)

  if not fs.is_dir(dir) then
    log.error(("The directory for %s@%s doesn't exist."):format(name, version))
    error()
  end

  if pkg_file or (dotpkg and dotpkg.version == version and dotpkg.name == name) then
    local infos = lpkg.get_pkg_infos(name, version)

    local bin_name = infos and infos.bin_name or nil

    -- remove symbolic link
    if bin_name then
      local path = fs.join(PKGER_BIN, bin_name)
      fs.rm(path)
    else
      log.err(("It was not possible to remove the symbolic link: %s@%s"):format(name, version))
    end

    if not fs.rm(pkg_file) then
      log.err("Could not remove " .. PKGER_DOT_PKG)
    end
  end

  fs.rm_dir(dir)
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

  if tbl.is_empty(pkgs) then
    log.error "No targets specified. Use --help."
    fn.exit(1)
  end

  M.remove_pkgs(pkgs)
end

return M
