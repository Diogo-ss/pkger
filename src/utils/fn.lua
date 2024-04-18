local inspect = require "inspect"
local which = require "which"

local M = {}

local shell_code = 0

function M.system(cmd)
  local str = type(cmd) == "table" and table.concat(cmd, " ") or cmd
  local ok, handle = pcall(io.popen, str)

  if not (ok or handle) then
    return -1, nil
  end

  local output = handle:read "*a"
  local exit_code = { handle:close() }

  shell_code = exit_code[3]

  return exit_code[3], output
end

function M.executable(command)
  local path = which(command)

  return path and true or false
end

function M.shell_code()
  return shell_code
end

function M.read_file(path, mode)
  local f = assert(io.open(path, mode or "r"))
  local c = f:read "*a"
  f:close()
  return c
end

function M.write_file(path, contents, mode)
  local f = assert(io.open(path, mode or "w+"))
  f:write(contents)
  f:close()
end

function M.is_empty(value)
  return not (value ~= "" and value ~= nil)
end

function M.trim(str)
  return str:match "^%s*(.-)%s*$"
end

function M.inspect(value)
  return inspect(value)
end

function M.print(value)
  print(M.inspect(value))
end

function M.json_path(data, path)
  local keys = {}

  for key in path:gmatch "[^%.]+" do
    table.insert(keys, key)
  end

  for _, part in ipairs(keys) do
    data = data[part]
    if data == nil then
      break
    end
  end

  return type(data) == "string" and data or nil
end

return M
