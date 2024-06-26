local c = require "src.utils.colors"
local log = require "src.utils.log"
local lpkg = require "src.core.pkg"
local fs = require "src.utils.fs"

local M = {}

function M.unlink(name)
  local current_pkg = lpkg.get_current_pkg(name)

  if not current_pkg then
    log.info "The package does not have a symbolic link."
    return
  end

  if not current_pkg.is_libary then
    local bin = fs.join(PKGER_BIN, current_pkg.bin_name)

    if fs.is_file(bin) and not fs.rm(bin) then
      log.err("It was not possible to remove the symbolic link of bin: " .. bin)
    end

    log.info("Symbolic link has been removed: " .. c.cyan(bin))
  end

  local opt_name = current_pkg.is_libary and current_pkg.name or current_pkg.bin_name

  local opt = fs.join(PKGER_OPT, opt_name)

  if fs.is_dir(opt) and not fs.rm_folder_link(opt) then
    log.err("It was not possible to remove the symbolic link of opt: " .. opt)
  end

  fs.rm(current_pkg.file)

  log.info("Symbolic link has been removed: " .. c.cyan(opt))
end

function M.parser(args)
  if #args ~= 1 then
    log.error "A single package name is required."
    return
  end

  local _, msg = pcall(M.unlink, args[1])

  if msg and PKGER_DEBUG_MODE then
    log(msg)
  end
end

return M
