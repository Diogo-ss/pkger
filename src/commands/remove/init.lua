local lpkg = require "src.core.pkg"
local log = require "src.utils.log"
local tbl = require "src.utils.tbl"
local fs = require "src.utils.fs"
local fn = require "src.utils.fn"
local U = require "src.commands.unlink"

local M = {}

local function _version_suffix(version)
  return version ~= PKGER_SCRIPT_VERSION and ("@" .. version) or ""
end

function M.remove(name, version, flags)
  local pkg = nil

  if not version or version == PKGER_SCRIPT_VERSION then
    pkg = lpkg.get_current_pkg(name)
  else
    pkg = lpkg.get_pkg_infos(name, version)
  end

  if not pkg then
    log.err(fn.f("Could not find package: %s%s", name, _version_suffix(version)))
  end

  local dependents = lpkg.list_all_dependent_pkgs(name)

  if not flags.force and not tbl.is_empty(dependents) then
    local str = ""

    tbl.map(dependents, function(val)
      str = val.name .. "@" .. val.version .. " "
    end)

    log.err(fn.f("%s is a dependency for: %s", name, str))
  end

  local dir = pkg.INSTALLATION_DIRECTORY

  if not fs.is_dir(dir) then
    log.err(("The directory for %s@%s doesn't exist."):format(name, version))
  end

  local primary_pkg = lpkg.get_current_pkg(name)

  if primary_pkg and primary_pkg.version == pkg.version then
    U.unlink(name)
  end

  if not fs.rm_dir(dir) == nil then
    log.err(fn.f("Package could not be removed: %s@%s", name, pgk.version))
  end

  log.info(fn.f("package has been removed: %s@%s", name, pkg.version))
  -- M.clean_pkgs()
end

function M.parser(args, flags)
  local pkgs = lpkg.parse(args)

  if tbl.is_empty(pkgs) then
    log.error "No targets specified. Use --help."
    fn.exit(1)
  end

  for name, version in pairs(pkgs) do
    local ok, msg = pcall(M.remove, name, version, flags or {})

    if PKGER_DEBUG_MODE then
      log(msg)
    end

    if not ok then
      log.error(fn.f("%s%s could not be removed.", name, _version_suffix(version)))
    end
  end
end

return M
