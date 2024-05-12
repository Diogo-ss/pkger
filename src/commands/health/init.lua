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

function M.check()
  for _, value in pairs(programs) do
    if fn.executable(value.cmd) then
      log.info(("%s was found."):format(c.green(value.cmd)))
    else
      log[value.type](("%s was not found."):format(c.yellow(value.cmd)))
    end
  end
end

function M.parser(args)
  M.check()
end

return M
