local config = require "src.core.config"
local log = require "src.utils.log"
local c = require "src.utils.colors"
local fn = require "src.utils.fn"

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

local ok, cmd = pcall(require, "src.commands." .. args.command)

if ok and type(cmd) == "table" and type(cmd.parser) == "function" then
  cmd.parser(args.args)
  return
end

log.warn(("Invalid subcommand. Use '%s' for usage information."):format(c.green "pkger --help"))
