local fs = require("utils.fs")
local sys = require("utils.sys")
local tbl = require("utils.tbl")
local sandbox = require("utils.sandbox")
local filter = require("utils.filter")

local M = {}

M.opts = {
	repos = {
		"https://github.com/pkger/core-pkgs",
	},
  colors = true
}

function M.global()
	local HOME = os.getenv("HOME")
	-- PKGER_BIN = PKGER_PREFIX .. "/bin"
	PKGER_PREFIX = HOME .. "/.local/pkger"
	PKGER_CACHE = PKGER_PREFIX .. "/cache"
	PKGER_DATA = PKGER_PREFIX .. "/data"
	PKGER_ETC = PKGER_PREFIX .. "/etc"
	-- PKGER_LIB = PKGER_PREFIX .. "/lib"
	-- PKGER_MODULES = PKGER_PREFIX .. "/modules"
	-- PKGER_REPOS = PKGER_PREFIX .. "/repos"
	PKGER_VERSION = "1.0"
	PKGER_CONFIG_FILE = HOME .. "/.config/pkger/config.lua"
end

function M.user_config()
	if not fs.is_file(PKGER_CONFIG_FILE) then
		return true, {}
	end

	local ok, f = pcall(io.open, PKGER_CONFIG_FILE, "r")
	if not (ok and f) then
		return false, "Unable to read user config."
	end

	local text = f:read("*all")
	f:close()

	local sucess, config = pcall(sandbox.run, text)

	if not sucess then
		return false, "Error while trying to load user config - " .. config
	end

	local _ok, _config = pcall(filter.config, config)

	if not _ok then
		local msg = [[
Check your config.
Error while filtering user config.
]]
		return false, msg
	end

	return true, _config
end

function M.set(opts)
	M.opts = tbl.deep_extend(M.opts, opts or {})
end

return M
