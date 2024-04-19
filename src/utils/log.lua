local c = require("utils.colors")

local M = {}

-- TODO: save log to file
-- local function save(text)
-- end

local function _print(text)
	print(text)
end

function M.error(text)
	_print(c.red("ERROR: ") .. text)
end

function M.warn(text)
	_print(c.yellow("WARN: ") .. text)
end

function M.info(text)
	_print(c.white("INFO: ") .. text)
end

function M.debug(text)
	_print(c.green("DEBUG: ") .. text)
end

return M
