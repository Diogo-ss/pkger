local config = require "core.config"
local log = require "utils.log"
local c = require "utils.colors"

config.init()

local args = { command = arg[1], args = { table.unpack(arg, 2) } }

if not args.command then
  log.error "Use 'pkger --help' for usage information."
  return
end

if args.command == "--help" then
  local msg = [[
Usage: pkger <command> [arguments]

Available commands:
  pkger install <package> [...]    Install one or more packages
  pkger remove <package> [...]     Remove one or more packages
  pkger search <package>           Search for a package
]]

  log._print(msg)
  return
end

local ok, cmd = pcall(require, "commands." .. args.command)

if ok then
  cmd.parse(args.args)
  return
end

log.warn "Invalid command. Use 'pkger --help' for usage information."
