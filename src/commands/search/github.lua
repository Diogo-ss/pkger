local curl = require "utils.curl"
local json = require "dkjson"
local fn = require "utils.fn"
local list = require "utils.list"
local c = require "utils.colors"

local M = {}

local function search_packages(tree, name)
  local packages = {}

  for _, file in pairs(tree) do
    local pkg, version = string.match(file.path, "pkgs/([^/]+)/([^/]+)/pkg.lua")

    if not pkg then
      pkg = string.match(file.path, "pkgs/([^/]+)/script.lua")
      version = c.red "script"
    end

    if pkg and version and fn.startswith(pkg, name) then
      packages[pkg] = list.extend(packages[pkg] or {}, { version })
    end
  end

  return packages
end

function M.search(url, name)
  local ok, response = pcall(curl.get, url)
  local info = string.match(url, "/repos/(.+)/git")
  local repo = info and "GitHub: " .. info or "not found"
  local result = {}

  if ok then
    local files = json.decode(response)
    result[repo] = { pkgs = search_packages(files.tree, name) }
  end

  return result
end

return M
