local log = require "src.utils.log"
local tbl = require "src.utils.tbl"
local lpkg = require "src.core.pkg"
local fn = require "src.utils.fn"

local M = {}

--luacheck: ignore flags
function M.pin(name, flags)
  local infos = lpkg.get_current_pkg(name)

  if not infos then
    log.error(("%s does not have a primary version."):format(name))
    return
  end

  if infos.pinned then
    log.info(("%s is already pinned in version %s. Use unpin to undo it."):format(name, infos.version))
    return
  end

  local pkg = lpkg.get_pkg_infos(name, infos.version)

  if not pkg then
    log.err(("The %s indicated by .pkg does not exist. Do a check using `pkger check --package`"):format(name))
  end

  lpkg.gen_dotpkg_file(pkg, { pinned = true })
  log.info(("%s was pinned in version %s"):format(name, pkg.version))
end

function M.parser(args, flags)
  if tbl.is_empty(args) then
    log.error "No targets specified. Use --help."
    fn.exit(1)
  end

  for _, name in pairs(args) do
    local _, msg = pcall(M.pin, name, flags)

    if msg and PKGER_DEBUG_MODE then
      log(msg)
    end
  end
end

return M
