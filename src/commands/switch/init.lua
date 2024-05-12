local log = require "src.utils.log"
local tbl = require "src.utils.tbl"
local lpkg = require "src.core.pkg"
local fn = require "src.utils.fn"
local lfs = require "lfs"
local fs = require "src.utils.fs"
local c = require "src.utils.colors"
local L = require "src.commands.link"
local U = require "src.commands.unlink"

local M = {}

function M.switch(name, version)
  local current_pkg = lpkg.get_current_pkg(name)

  if current_pkg and current_pkg.name == name and current_pkg.version == version then
    log.info(c.green(name) .. " is already in " .. c.cyan(version))
    return
  end

  if not lpkg.get_pkg_infos(name, version) then
    log.err(("Version %s is not installed"):format(c.cyan(version)))
  end

  U.unlink(name)
  L.link(name, version, { overwrite = true })

  if current_pkg and current_pkg.version then
    log.info(("%s: %s --> %s"):format(name, current_pkg.version, version))
    return
  end
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
