local fs = require("utils.fs")
local tbl = require("utils.tbl")
local sandbox = require("utils.sandbox")
local filter = require("utils.filter")
local log = require("utils.log")

local M = {}

M.opts = {
	repos = {
		"https://raw.githubusercontent.com/pkger/core-pkgs/main/repo.lua",
	},
	colors = true,
	logfile = false,
}

function M.read_user_config()
	if not fs.is_file(PKGER_CONFIG_FILE) then
		return {}
	end

	local ok, f = pcall(io.open, PKGER_CONFIG_FILE, "r")
	if not (ok and f) then
		error("Unable to read user config.")
	end

	local text = f:read("*all")
	f:close()

	local sucess, config = pcall(sandbox.run, text)
	if not sucess then
		error("Error while trying to load user config - " .. config)
	end

	local _ok, _config = pcall(filter.config, config)
	if not _ok then
		error("Check your config.\nError while filtering user config.")
	end

	return _config
end

function M.init()
	-- load global config
	require("core.global")

	local ok, result = pcall(M.read_user_config)

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
