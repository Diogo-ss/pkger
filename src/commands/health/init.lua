local fn = require "src.utils.fn"
local log = require "src.utils.log"
local c = require "src.utils.colors"

local M = {}

local programs = {
  {
    cmd = "git",
    type = "error",
  },
  {
    cmd = "tar",
    type = "error",
  },
  {
    cmd = "7z",
    type = "error",
  },
  {
    cmd = "unzip",
    type = "error",
  },
  {
    cmd = "rar",
    type = "error",
  },
  {
    cmd = "sha1sum",
    type = "error",
  },
}

function M.health()
  for _, value in pairs(programs) do
    if fn.executable(value.cmd) then
      log.info(fn.f("%s was found.", c.green(value.cmd)))
    else
      log[value.type](fn.f("%s was not found.", c.yellow(value.cmd)))
    end
  end

  if not fn.is_dir_in_path(PKGER_BIN) then
    log.warn(fn.f("bin directory (%s) isn't in PATH.", PKGER_BIN))
  else
    log.info(fn.f("bin directory (%s) is in PATH.", PKGER_BIN))
  end
end

function M.parser(args)
  M.health()
end

return M
