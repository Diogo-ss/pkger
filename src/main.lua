local config = require "core.config"
local log = require "utils.log"
local c = require "utils.colors"

config.init()

local args = { command = arg[1], args = { table.unpack(arg, 2) } }

if not args.command then
  log.error(("Use '%s' for usage information."):format(c.green "pkger --help"))
  return
end

if args.command == "--help" then
  log "Fazer um texto de ajudar."
  return
end

local ok, cmd = pcall(require, "commands." .. args.command)
if ok and type(cmd) == "table" and type(cmd.parse) == "function" then
  cmd.parse(args.args)
  return
end

log.warn(("Invalid subcommand. Use '%s' for usage information."):format(c.green "pkger --help"))
