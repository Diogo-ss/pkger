local path = require "path"
local fn = require "src.utils.fn"
local lfs = require "lfs"
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
    ["7z"] = { "7z x %s" },
    tar = { "tar -xf %s" },
    zip = { "unzip %s" },
    rar = { "unrar x %s" },
    gz = { "tar -xzf %s" },
    bz2 = { "tar -xvjf %s" },
    xz = { "tar -xf %s", "xz -d %s" },
  }

  format = format or file:match "%.([^.]+)$"

  local cmds = extract_commands[format]
  if not (cmds and format) then
    return false, "Unsupported file format."
  end

  for _, cmd in ipairs(cmds) do
    local exit_code = fn.system((cmd):format(file))
    if exit_code == 0 then
      return true, "Done."
    end
  end

  return false, "Error extracting the file."
end

M.cwd = path.currentdir

M.normalize = path.normalize

M.mkdir = path.mkdir

M.rm_dir = function(dir)
  path.each(path.join(dir, "*"), function(P, mode)
    if mode == "directory" then
      path.rmdir(P)
    else
      path.remove(P)
    end
  end, {
    param = "fm",
    delay = true,
    recurse = true,
    reverse = true,
  })
  path.rmdir(dir)
end

M.cd = path.chdir

M.each = path.each

M.split = path.split

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

M.lock_dir = lfs.lock_dir

M.link = lfs.link

M.is_empty = path.isempty

M.splitext = path.splitext

return M
