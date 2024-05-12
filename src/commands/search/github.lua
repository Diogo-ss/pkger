local curl = require "src.utils.curl"
local json = require "dkjson"
local fn = require "src.utils.fn"
local list = require "src.utils.list"
local c = require "src.utils.colors"
local log = require "src.utils.log"
local tbl = require "src.utils.tbl"

local M = {}

local function filter(tree, name)
  local packages = {}

  for _, file in pairs(tree) do
    local pkg, version = string.match(file.path, "pkgs/([^/]+)/([^/]+)/pkg.lua")

    if pkg and version and string.find(pkg, name) then
      packages[pkg] = list.extend(packages[pkg] or {}, { version })
    end
  end

  return packages
end

function M.search(url, name)
  local response = curl.get_content(url)
  local info = string.match(url, "/repos/(.+)/git")
  local repo = info or "not found"

  if not response then
    log.error("Could not access: " .. url)
    return nil
  end

  local files = json.decode(response)
  local pkgs = filter(files.tree, name)

  if tbl.is_empty(pkgs) then
    return nil
  end

  return { repo = repo, pkgs = pkgs, engine = "GitHub" }
end

return M
