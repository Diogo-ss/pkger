local sandbox = require("utils.sandbox")
local fn = require("utils.fn")
local repo = require("core.repo")
local tbl = require("utils.tbl")
local list = require("utils.list")

local M = {}

local function _search(env, name)
	-- local l = {
	--   use/repo = "GitHub: user/repo"
	--   pkgs = {
	--       neovim = { "0.0.3"}
	--     }
	-- }
	local url = env.search.url:gsub("%${{ pkg%.name }}", name)

	local ok, engine = pcall(require, "commands.search." .. env.search.type:lower())

	if ok then
		return engine.search(url, name)
	end
end

function M.find(name)
	local rl = repo.get_repos()
	local results = {}

	for _, link in pairs(rl) do
		local contents = repo.get_file(link)

		-- TODO: filter

		if contents then
			local ok, env = pcall(sandbox.run, contents)

			if ok and env.search then
				results = tbl.extend(results, _search(env, name))
				-- table.insert(results, _search(env, name))
			end
		end
	end

	fn.print(results)

	-- M.show_results(results)
end

return M
