local c = require "src.utils.colors"
local log = require "src.utils.log"
local lpkg = require "src.core.pkg"
local fn = require "src.utils.fn"
local fs = require "src.utils.fs"

local M = {}

function M.unlink(name)
  local current_pkg = lpkg.get_current_pkg(name)

  if not current_pkg then
    log.info "The package does not have a symbolic link."
    return
  end

  local path = fs.join(PKGER_BIN, current_pkg.bin_name)

  if fs.is_file(path) and not fs.rm(path) then
    log.err("It was not possible to remove the symbolic link: " .. path)
  end

  fs.rm(current_pkg.file)

  log.info("Symbolic link has been removed: " .. c.cyan(path))
end

function M.parser(args)
  if #args ~= 1 then
    log.error "A single package name is required."
    return
  end

  local ok, _ = pcall(M.unlink, args[1])
end

return M
