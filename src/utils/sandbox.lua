local tbl = require "utils.tbl"

local M = {}

local function env()
  return {
    print = print,
    -- tar = fs.tar,
    -- unzip = fs.unzip,
    -- next = next,
    -- pairs = pairs,
    -- pcall = pcall,
    -- select = select,
    -- tonumber = tonumber,
    -- tostring = tostring,
    -- type = type,
    -- _VERSION = _VERSION,
    -- xpcall = xpcall,
    -- string = {
    --   byte = string.byte,
    --   char = string.char,
    --   find = string.find,
    --   format = string.format,
    --   gmatch = string.gmatch,
    --   gsub = string.gsub,
    --   len = string.len,
    --   lower = string.lower,
    --   match = string.match,
    --   rep = string.rep,
    --   reverse = string.reverse,
    --   sub = string.sub,
    --   upper = string.upper,
    -- },
    -- table = {
    --   insert = table.insert,
    --   remove = table.remove,
    --   sort = table.sort,
    --   keys = tbl.keys,
    --   extend = tbl.extend,
    --   isempty = tbl.isempty,
    --   deep_extend = tbl.deep_extend,
    --   map = tbl.map,
    -- },
    -- os = { clock = os.clock, difftime = os.difftime, time = os.time },
  }
end

local function run_sandbox(code, _env)
  local chunk, err = load(code, "sandbox", "t", _env)

  if not chunk then
    error("Error loading code: " .. err)
  end

  local ok, result = pcall(chunk)

  if not ok then
    error("Error executing code: " .. result)
  end

  return _env
end

M.run = function(code, _env)
  return pcall(run_sandbox, code, tbl.deep_extend(env(), _env or {}))
end

return M
