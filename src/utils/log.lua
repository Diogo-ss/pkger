local c = require "src.utils.colors"

local M = {}

-- TODO: save log to file
-- local function save(text)
-- end

local function _print(text)
  print(text)
end

function M.error(text)
  _print(c.red "ERROR: " .. text)
end

function M.warn(text)
  _print(c.yellow "WARN: " .. text)
end

function M.info(text)
  _print(c.cyan "INFO: " .. text)
end

function M.debug(text)
  _print(c.green "DEBUG: " .. text)
end

function M.arrow(text, color)
  _print(c[color or "blue"] "==> " .. text)
end

function M.err(text)
  M.error(text)
  error(text)
end

setmetatable(M, {
  __call = function(_, text)
    _print(text)
  end,
})

return M
