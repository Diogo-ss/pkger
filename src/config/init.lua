local fs = require("utils.fs")
local sys = require("utils.sys")
local tbl = require("utils.tbl")
local sandbox = require("utils.sandbox")
local filter = require("utils.filter")
local log = require("utils.log")

local M = {}

M.opts = {
	repos = {
		"https://github.com/pkger/core-pkgs",
	},
	colors = true,
	logfile = false,
}

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

function M.init()
	-- load global config
	require("config.global")

	local ok, result = M.user_config()

	if ok then
		M.set(result)
		return
	end

	log.error(result)
end

function M.set(opts)
	M.opts = tbl.deep_extend(M.opts, opts or {})
end

return M
