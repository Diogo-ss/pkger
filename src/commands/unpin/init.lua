local fs = require "src.utils.fs"
local log = require "src.utils.log"
local tbl = require "src.utils.tbl"
local lpkg = require "src.core.pkg"
local fn = require "src.utils.fn"
local repo = require "src.core.repo"

local M = {}

function M.unpin(name, flags)
  local infos = lpkg.get_current_pkg(name)

  if not infos then
    log.error(("%s does not have a primary version."):format(name))
    return
  end

  if not infos.pinned then
    log.info(("%s isn't pinned."):format(name, infos.version))
    return
  end

  local pkg = lpkg.get_pkg_infos(name, infos.version)

  if not pkg then
    log.err(("The %s indicated by .pkg does not exist. Do a check using `pkger check --package`"):format(name))
  end

  lpkg.gen_dotpkg_file(pkg, { pinned = false })
  log.info(("%s was unpinned. Use `pin` to undo it"):format(name))
end

function M.parser(args, flags)
  if tbl.is_empty(args) then
    log.error "No targets specified. Use --help."
    os.exit(1)
  end

  for _, name in pairs(args) do
    local ok, _ = pcall(M.unpin, name, flags)
  end
end

return M
