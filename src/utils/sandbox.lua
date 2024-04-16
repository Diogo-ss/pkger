local tbl = require("utils.tbl")
local fn = require("utils.fn")
local curl = require("utils.curl")
local fs = require("utils.fs")

local M = {}

local env = {
	system = fn.system,
	shell_code = fn.shell_code,
	get = curl.get,
	download = curl.download,
	-- rm = fs.remove,
	-- rm_dir = fs.remove_dir,
	-- cp = fs.copy,
	-- cp_dir = fs.copy_dir,
	-- tar = fs.tar,
	-- unzip = fs.unzip,
	-- cd = fs.cd,
	-- pwd = fs.pwd,
	next = next,
	pairs = pairs,
	pcall = pcall,
	print = print,
	select = select,
	tonumber = tonumber,
	tostring = tostring,
	type = type,
	_VERSION = _VERSION,
	xpcall = xpcall,
	string = {
		byte = string.byte,
		char = string.char,
		find = string.find,
		format = string.format,
		gmatch = string.gmatch,
		gsub = string.gsub,
		len = string.len,
		lower = string.lower,
		match = string.match,
		rep = string.rep,
		reverse = string.reverse,
		sub = string.sub,
		upper = string.upper,
	},
	table = {
		insert = table.insert,
		remove = table.remove,
		sort = table.sort,
		keys = tbl.keys,
		extend = tbl.extend,
		isempty = tbl.isempty,
		deep_extend = tbl.deep_extend,
		map = tbl.map,
	},
	os = { clock = os.clock, difftime = os.difftime, time = os.time },
}

local function run_sandbox(code, sandbox)
	local chunk, err = load(code, "sandbox", "t", sandbox)
	if chunk then
		local success, result = pcall(chunk)
		if success then
			return true, result
		else
			return false, "Error executing code: " .. result
		end
	else
		return false, "Error loading code: " .. err
	end
end

M.run = function(code, _env)
	env = tbl.deep_extend(env, _env)
	return run_sandbox(code, env)
end

return M
