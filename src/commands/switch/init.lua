local log = require "src.utils.log"
local lpkg = require "src.core.pkg"
local c = require "src.utils.colors"
local L = require "src.commands.link"
local U = require "src.commands.unlink"
local fn = require "src.utils.fn"

local M = {}

function M.switch(name, version)
  local pkg = lpkg.get_current_pkg(name)

  if pkg and pkg.name == name and pkg.version == version then
    log.info(c.green(name) .. " is already in " .. c.cyan(version))
    return
  end

  if not lpkg.get_pkg_infos(name, version) then
    log.err(("Version %s is not installed"):format(c.cyan(version)))
  end

  if pkg and pkg.pinned then
    log.err(("%s can't be updated because %s is pinned. Use `unpin` to undo."):format(pkg.name, pkg.version))
  end

  U.unlink(name)
  L.link(name, version, { overwrite = true })

  -- TODO: set false in is_dependency

  if pkg and pkg.version then
    log.info(("%s: %s --> %s"):format(name, pkg.version, version))
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
