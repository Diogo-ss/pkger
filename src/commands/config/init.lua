local fn = require "src.utils.fn"
local log = require "src.utils.log"
local c = require "src.utils.colors"

local M = {}

-- function parse_opts(args)
--   local pkgs = {}
--   local opts = {}

--   for i, value in ipairs(args) do
--     if fn.startswith(value, "--") then
--       local option, arg_value = value:match "^%-%-(%w+)%=(.+)"
--       if option then
--         opts[option] = tonumber(arg_value) or arg_value
--       else
--         opts[value:sub(3)] = true
--       end
--     else
--       table.insert(pkgs, value)
--     end
--   end

--   return { pkgs = pkgs, opts = opts }
-- end

function M.parser(args)
  for key, value in pairs(_G) do
    if type(value) == "string" and fn.startswith(key, "PKGER") then
      log(c.green(key) .. ": " .. value)
    end
  end
end

return M
