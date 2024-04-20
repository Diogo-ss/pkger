local path = require "path"
local fn = require "utils.fn"
-- local lpath = require "lpath"

local M = {}

function M.read_file(dir, mode)
  local ok, f = pcall(io.open, dir, mode or "r")

  if ok and f then
    local data = f:read "*all"
    f:close()
    return true, data
  end

  return false, nil
end

function M.write_file(dir, contents, mode)
  local ok, f = pcall(io.open, dir, mode or "w+")
  if ok and f then
    f:write(contents)
    f:close()
    return true, dir
  end

  return false, nil
end

function M.cd_safe(dir)
  if not INSTALLATION_ENVIRONMENT then
    return nil, "The `cd_safe` function can only be used in installation environments."
  end

  local ok, err = M.cd(dir)
  if not ok then
    return false, "Error navigating to directory: " .. err
  end

  -- INSTALLATION_DIRECTORY is defined in installation environments
  if string.match(M.cwd(), INSTALLATION_DIRECTORY) then
    return true
  else
    M.cd(INSTALLATION_DIRECTORY)
    return nil, "Navigation outside of safe scope."
  end
end

function M.extract(file, format)
  local extract_commands = {
    ["7z"] = { "7z x" },
    tar = { "tar -xf" },
    zip = { "unzip" },
    rar = { "unrar x" },
    gz = { "tar -xfv" },
    bz2 = { "tar -xvjf" },
    xz = { "tar -xf", "xz -d" },
  }

  local cmds = extract_commands[format]
  if not cmds then
    error "Unsupported file format."
  end

  for _, cmd in ipairs(cmds) do
    local exit_code = fn.system { cmd, file }
    if exit_code == 0 then
      return true
    end
  end

  error "Error extracting the file."
end

M.cwd = path.currentdir

M.normalize = path.normalize

M.mkdir = path.mkdir

M.rm_dir = path.rmdir

M.cd = path.chdir

M.exists = path.exists

M.is_dir = path.isdir

M.is_file = path.isfile

M.is_link = path.islink

M.rm = path.remove

M.join = path.join

M.home = path.user_home

M.cp = path.copy

M.mv = path.move

M.size = path.size

M.SEP = path.DIR_SEP

M.each = path.each

return M
