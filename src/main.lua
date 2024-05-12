local config = require "src.core.config"
local log = require "src.utils.log"
local c = require "src.utils.colors"
local list = require "src.utils.list"
local fn = require "src.utils.fn"

config.init()

local command = arg[1]
local args = { table.unpack(arg, 2) }
local flags = {}

for i, arg in ipairs(args) do
  if string.sub(arg, 1, 2) == "--" then
    flags[string.sub(arg, 3)] = true
    args[i] = nil
  end
end

args = list.unique(args)

if not command then
  log.error(("Use '%s' for usage information."):format(c.green "pkger --help"))
  return
end

if command == "--help" then
  log "Fazer um texto de ajudar."
  return
end

local ok, cmd = pcall(require, "src.commands." .. command)

if ok and type(cmd) == "table" and type(cmd.parser) == "function" then
  cmd.parser(args, flags)
  return
end

log.warn(("Invalid subcommand. Use '%s' for usage information."):format(c.green "pkger --help"))
