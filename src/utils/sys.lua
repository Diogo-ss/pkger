--[[
This file is the enhancement of a Gist.

This code was based on Gist: https://gist.github.com/soulik/82e9d02a818ce12498d1
License: unknown

Changes made at: https://github.com/bluebird75/lua_get_os_name
License: Unlicense license

New features and improvements by: https://github.com/Diogo-ss
License: Unlicense license
--]]

local M = {}

local os_patterns = {
  ["windows"] = "Windows",
  ["linux"] = "Linux",
  ["osx"] = "Mac",
  ["mac"] = "Mac",
  ["darwin"] = "Mac",
  ["^mingw"] = "Windows",
  ["^cygwin"] = "Windows",
  ["bsd$"] = "BSD",
  ["sunos"] = "Solaris",
}

local arch_patterns = {
  ["^x86$"] = "x86",
  ["i[%d]86"] = "x86",
  ["amd64"] = "x86_64",
  ["x86_64"] = "x86_64",
  ["x64"] = "x86_64",
  ["power macintosh"] = "powerpc",
  ["^arm"] = "arm",
  ["^mips"] = "mips",
  ["i86pc"] = "x86",
}

local function match_pattern(value, patterns)
  for pattern, name in pairs(patterns) do
    if value:match(pattern) then
      return name
    end
  end
  return "unknown"
end

local function _os()
  local raw_os = ""

  if jit and jit.os then
    raw_os = jit.os
  else
    if package.config:sub(1, 1) == "\\" then
      -- Windows
      local env_os = os.getenv "OS"
      if env_os then
        raw_os = env_os
      end
    else
      local ok, f = pcall(io.popen, "uname -s", "r")

      if ok and f then
        raw_os = f:read "*l"
      end
    end
  end

  return match_pattern(raw_os:lower(), os_patterns)
end

local function arch()
  local raw_arch = ""

  if jit and jit.arch then
    raw_arch = jit.arch
  else
    if package.config:sub(1, 1) == "\\" then
      -- Windows
      local env_arch = os.getenv "PROCESSOR_ARCHITECTURE"
      if env_arch then
        raw_arch = env_arch
      end
    else
      local ok, f = pcall(io.popen, "uname -m", "r")

      if ok and f then
        raw_arch = f:read "*l"
      end
    end
  end

  return match_pattern(raw_arch:lower(), arch_patterns)
end

local function is(name)
  local os_name = _os()

  if name == "mac" then
    return os_name == "Mac"
  end

  if name == "linux" then
    return os_name == "Linux"
  end

  if name == "bsd" then
    return os_name == "BSD"
  end

  if name == "unix" then
    local list = { "Linux", "Mac", "BSD", "Solaris" }
    for _, value in pairs(list) do
      if value == os_name then
        return true
      end
    end
  end

  if name == "win" then
    return os_name == "Windows"
  end

  if name == "wsl" then
    local ok, f = pcall(io.popen, "uname -a", "r")

    if ok and f then
      -- Is using a lowercase string to identify the WSL.
      -- WSL 1: Microsoft
      -- WSL 2: microsoft
      return string.match(f:read("*l"):lower(), "microsoft") ~= nil
    end
  end

  return false
end

M.is = {}
setmetatable(M.is, {
  __index = function(_, value)
    return is(value)
  end,
})

setmetatable(M, {
  __index = function(_, value)
    if value == "os" then
      return _os()
    end

    if value == "arch" then
      return arch()
    end
  end,
})

return M
