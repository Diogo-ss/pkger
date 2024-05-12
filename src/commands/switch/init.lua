local log = require "src.utils.log"
local tbl = require "src.utils.tbl"
local lpkg = require "src.core.pkg"
local fn = require "src.utils.fn"
local lfs = require "lfs"
local fs = require "src.utils.fs"
local c = require "src.utils.colors"

local M = {}

function M.switch(name, version)
  local current_pkg = lpkg.get_master_pkg(name)

  if current_pkg and current_pkg.name == name and current_pkg.version == version then
    log.info(c.green(name) .. " is already in " .. c.cyan(version))
    return
  end

  local new_pkg = lpkg.get_pkg_infos(name, version)

  if not new_pkg then
    log.err(("version %s is not installed"):format(c.cyan(version)))
  end

  if current_pkg then
    local path = fs.join(PKGER_BIN, current_pkg.bin_name)

    if fs.is_file(path) and not fs.rm(path) then
      log.err("It was not possible to remove the symbolic link: " .. path)
    end
  end

  new_pkg.INSTALLATION_DIRECTORY = new_pkg.dir

  lpkg.gen_pkg_file(new_pkg)
  lpkg.create_link(new_pkg)

  if current_pkg and current_pkg.version then
    log.info(("%s: %s --> %s"):format(name, current_pkg.version, version))
    return
  end

  log.info(("Complete, %s@%s is available."):format(name, version))
end

function M.parser(args)
  if #args ~= 1 then
    log.error "A single package name is required."
    return
  end

  local pkg = lpkg.parse(args)

  local name = next(pkg)
  local version = pkg[name]

  local ok, _ = pcall(M.switch, name, version)
end

return M
