local fn = require "utils.fn"
local log = require "utils.log"
local c = require "utils.colors"

local M = {}

local programs = {
  {
    cmd = "git",
    type = "error",
    text = "git was not found. It is an essential component. Use `pkger install git` to install it.",
  },
  {
    cmd = "tar",
    type = "error",
    text = "tar was not found. It is required for extraction. Install tar to continue.",
  },
  {
    cmd = "7z",
    type = "error",
    text = "7z was not found. It is required for extraction. Install 7z to continue.",
  },
  {
    cmd = "unzip",
    type = "error",
    text = "unzip was not found. It is required for extraction. Install unzip to continue.",
  },
  {
    cmd = "rar",
    type = "error",
    text = "rar was not found. It is required for extraction. Install rar to continue.",
  },
}

function M.check()
  for _, value in pairs(programs) do
    if fn.executable(value.cmd) then
      log.info(("%s was found."):format(value.cmd))
    else
      log[value.type](value.text)
    end
  end
end

function M.parse(args)
  M.check()
end

return M
