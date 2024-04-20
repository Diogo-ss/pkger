local fn = require "utils.fn"
local tbl = require "utils.tbl"
local log = require "utils.log"
local c = require "utils.colors"

local M = {}

function M.parse(args)
  for key, value in pairs(_G) do
    if type(value) == "string" and fn.startswith(key, "PKGER") then
      log(c.green(key) .. ": " .. value)
    end
  end
end

return M
