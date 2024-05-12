local inspect = require "inspect"
local which = require "which"
local sha1 = require "sha1"

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
  if type(value) == "table" then
    print(M.inspect(value))
    return
  end
  print(value)
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

function M.split(str, sep)
  local tbl = {}
  sep = sep == nil and "%s" or sep

  for s in string.gmatch(str, "([^" .. sep .. "]+)") do
    table.insert(tbl, s)
  end
  return tbl
end

function M.startswith(str, s)
  return str:sub(1, #s) == s
end

function M.endswith(str, s)
  return str:sub(-#s) == s
end

function M.sleep(sec)
  local t = os.clock() + sec
  while os.clock() < t do
  end
end

function M.sha1sum(path)
  local exit_code, output = M.system { "sha1sum", path }

  if exit_code == 0 and output then
    local _sha1 = output:match "(%w+)"
    return M.trim(_sha1)
  else
    return nil
  end
end

function M.sha1(path)
  if M.executable "sha1sum" then
    return M.sha1sum(path)
  end

  local ok, f = pcall(io.open, path, "rb")

  if ok and f then
    local data = f:read "*a"
    f:close()
    return sha1.sha1(data)
  end

  return nil
end

return M
