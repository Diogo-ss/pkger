local config = require "src.core.config"
local log = require "src.utils.log"
local c = require "src.utils.colors"
local list = require "src.utils.list"
local fn = require "src.utils.fn"
local cache = require "src.core.cache"

config.init()

local command, args, flags = fn.args_parser(arg)

-- if flags["no-cache"] then
--   cache.clear()
-- end

if flags.debug then
  PKGER_DEBUG_MODE = true
end

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
