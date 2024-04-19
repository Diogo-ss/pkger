local c = require "utils.colors"

local M = {}

-- TODO: save log to file
-- local function save(text)
-- end

function M._print(text)
  print(text)
end

function M.error(text)
  M._print(c.red "ERROR: " .. text)
end

function M.warn(text)
  M._print(c.yellow "WARN: " .. text)
end

function M.info(text)
  M._print(c.cyan "INFO: " .. text)
end

function M.debug(text)
  M._print(c.green "DEBUG: " .. text)
end

return M
