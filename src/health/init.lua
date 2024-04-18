local fn = require("utils.fn")
local log = require("utils.log")
local c = require("utils.colors")

local M = {}

local programs = {
	{
		cmd = "git",
		type = "error",
		text = "git was not found. It is an essential component. Use `pkger install git` to install it.",
	},
}

function M.check()
	for _, value in pairs(programs) do
		if fn.executable(value.cmd) then
			log.info(("%s was found."):format(value.cmd))
		else
			log[value.type](value.text)
		end
	end
end

return M
