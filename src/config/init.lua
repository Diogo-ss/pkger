local tbl = require("utils.tbl")

local M = {}

M.opts = {
	repos = {
		"https://github.com/pkger/core-pkgs",
	},
}

function M.set(opts)
	M.opts = tbl.deep_extend(M.opts, opts or {})
end

return M
