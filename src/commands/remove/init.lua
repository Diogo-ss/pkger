local lpkg = require "src.core.pkg"
local c = require "src.utils.colors"
local log = require "src.utils.log"
local fn = require "src.utils.fn"
local tbl = require "src.utils.tbl"
local fs = require "src.utils.fs"

local M = {}

function M.remove_depends(name, version)
  local pkg = lpkg.get_pkg_infos(name, version)

  if not (pkg and pkg.depends) then
    return
  end

  for _, depend_name in pairs(pkg.depends) do
    local depend_pkg = lpkg.get_master_pkg(depend_name)

    local infos = lpkg.get_pkg_infos(depend_name, depend_pkg.version)

    if infos.is_dependency == true then
      local all_pkg = lpkg.list_all_dependent_pkgs(infos.name)

      for n, _depend in pairs(all_pkg) do
        if _depend.name == name and _depend.version == version then
          all_pkg[n] = nil
        end
      end

      if tbl.isempty(all_pkg) then
        M.remove(name, infos.version)
      end
    end
  end
end

function M.remove(name, version, is_dependency)
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

  local dir = fs.join(PKGER_DATA, name, version)

  if not fs.is_dir(dir) then
    log.error(("The directory for %s@%s doesn't exist."):format(name, version))
    error()
  end

  -- TODO: fix remove_depends

  -- M.remove_depends(name, version)

  print("Removido: " .. name .. " " .. version)

  fs.rm_dir(dir)

  if pkg_file then
    fs.rm(pkg_file)
  end

  log.info(("Package removed: %s@%s"):format(name, version))
end

function M.remove_pkgs(pkgs)
  for name, version in pairs(pkgs) do
    local ok, msg = pcall(M.remove, name, version)
    if not ok then
      print(msg)
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
