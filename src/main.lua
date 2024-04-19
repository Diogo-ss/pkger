local config = require("core.config")
local log = require("utils.log")
local search = require("commands.search")

config.init()

local function parse_args(args)
	local command = args[1]
	return {
		command = command,
		args = { table.unpack(args, 2) },
	}
end

local _args = parse_args(arg)

if not _args.command then
	log.error("Use 'pkger --help' for usage information.")
	return
end

if _args.command == "--help" then
	local msg = [[
Usage: pkger <command> [arguments]

Available commands:
  pkger install <package> [...]    Install one or more packages
  pkger remove <package> [...]     Remove one or more packages
  pkger search <package>           Search for a package
  ]]

	log.info(msg)
	return
end

if _args.command == "search" then
	if #_args.args == 0 then
		log.warn("You can only search for a single package.")
		return
	end

	if #_args.args > 1 then
		log.warn("You can only search for a single package.")
		return
	end

	search.find(_args.args[1])
	return
end

log.warn("Invalid command. Use 'pkger --help' for usage information.")
