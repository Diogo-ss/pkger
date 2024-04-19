local curl = require("utils.curl")
local fn = require("utils.fn")
local tbl = require("utils.tbl")

local default = {
	"https://raw.githubusercontent.com/pkger/core-pkgs/main/repo.lua",
}

local M = {}

function M.get_repos()
	local ok, f = pcall(io.open, PKGER_REPOS_FILE, "r")
	local respos = {}

	if ok and f then
		respos = fn.split(f:read("*all"), "\n")
		respos = tbl.map(respos, fn.trim)
		respos = tbl.map(respos, function(str)
			return not fn.startswith(str, "#") and str or nil
		end)
		f:close()
	end

	return tbl.isempty(respos) and default or respos
end

function M.get_file(url)
	local ok, result = pcall(curl.get, url)

	if ok then
		return result
	end

	return nil
end

return M
