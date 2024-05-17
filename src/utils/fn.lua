local inspect = require "inspect"
local which = require "which"
local sha1 = require "sha1"
local list = require "src.utils.list"
local log = require "src.utils.log"
local tbl = require "src.utils.tbl"

local M = {}

local shell_code = 0

function M.system(cmd)
  local str = type(cmd) == "table" and table.concat(cmd, " ") or cmd
  local ok, handle = pcall(io.popen, str)

  if not ok or not handle then
    return -1, nil
  end

  if PKGER_DEBUG_MODE then
    while true do
      local line = handle:read "*l"
      if not line then
        break
      end
      log(line)
    end
  end

  local output = handle:read "*a"
  local exit_code = { handle:close() }

  shell_code = exit_code[3]

  return exit_code[3], output
end

M.safe_system = function(cmd)
  if not INSTALLATION_ENVIRONMENT then
    return nil, "`safe_system` function can only be used in installation environments."
  end

  local code, output = M.system(cmd)

  if code ~= 0 then
    log.err("The command cannot be executed: " .. output)
  end

  return code, output
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
  local _tbl = {}
  sep = sep == nil and "%s" or sep

  for s in string.gmatch(str, "([^" .. sep .. "]+)") do
    table.insert(_tbl, s)
  end
  return _tbl
end

function M.startswith(str, s)
  return str:sub(1, #s) == s
end

function M.endswith(str, s)
  return str:sub(- #s) == s
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

function M.exit(code, close)
  -- TODO: remove lockfile

  os.exit(code, close)
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

function M.args_parser(a)
  local command = a[1]
  local args = list.unique { table.unpack(a, 2) }
  local flags = {}

  for i, _arg in ipairs(args) do
    if M.startswith(_arg, "--") and _arg:find "=" then
      local flag, value = _arg:match "^%-%-(%w+)%=(.+)"
      if flag and value then
        flags[flag] = value
        args[i] = nil
        goto continue
      end

      log.error("Invalid flag format: " .. _arg)
      M.exit(1)
    end

    if M.startswith(_arg, "--") then
      local flag = string.sub(_arg, 3)
      flags[flag] = true
      args[i] = nil
    end

    ::continue::
  end

  return command, args, flags
end

function M.falsy(val)
  if type(val) == "table" then
    return tbl.is_empty(val)
  end

  return M.is_empty(val)
end

function M.truthy(val)
  return not M.falsy(val)
end

function M.is_dir_in_path(dir)
  local paths = os.getenv "PATH"

  if paths then
    local path_list = M.split(paths, ":")

    for _, path in pairs(path_list) do
      if M.trim(path) == (dir .. "/") then
        return true
      end
    end
  end

  return false
end

function M.f(s, ...)
  return string.format(s, ...)
end

return M
