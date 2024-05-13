local c = require "src.utils.colors"
local log = require "src.utils.log"
local lpkg = require "src.core.pkg"
local fn = require "src.utils.fn"
local fs = require "src.utils.fs"
local L = require "src.commands.unlink"

local M = {}

function M.link(name, version, flags)
  local current_pkg = lpkg.get_current_pkg(name)

  if current_pkg and current_pkg.name == name and current_pkg.version == version then
    log.info(c.green(name) .. " is already in " .. c.cyan(version))
    return
  end

  if current_pkg and not flags.overwrite then
    log.warn "This package has a symbolic link to another version. Use `unlink` first or use `--overwrite`"
    return
  end

  if current_pkg then
    L.unlink(name)
  end

  local new_pkg = lpkg.get_pkg_infos(name, version)

  if not new_pkg then
    log.err(("version %s is not installed"):format(c.cyan(version)))
  end

  new_pkg.INSTALLATION_DIRECTORY = new_pkg.dir
  -- TODO: set false in is_dependency

  lpkg.gen_dotpkg_file(new_pkg, { pinned = false })
  lpkg.gen_dotinfos_file(new_pkg, { is_dependency = false })
  lpkg.create_link(new_pkg)

  log.info(("Complete, %s@%s is available."):format(name, version))
end

function M.parser(args, flags)
  if #args ~= 1 then
    log.error "A single package name is required."
    return
  end

  local pkg = lpkg.parse(args)

  local name = next(pkg)
  local version = pkg[name]

  local ok, _ = pcall(M.link, name, version, flags)
end

return M
