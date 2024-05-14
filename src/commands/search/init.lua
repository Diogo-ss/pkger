local repo = require "src.core.repo"
local tbl = require "src.utils.tbl"
local c = require "src.utils.colors"
local log = require "src.utils.log"
local fn = require "src.utils.fn"

local M = {}

local function show(results)
  for _, value in pairs(results) do
    log(c.cyan(value.engine) .. ": " .. c.yellow(value.repo))
    for name, versions in pairs(value.pkgs) do
      local versions_str = table.concat(versions, ", ")
      log(string.format("  %s: %s", c.green(name), versions_str))
    end
  end
end

local function _find(url, engine_type, name)
  url = url:gsub("%${{%sname%s}}", name)
  local ok, engine = pcall(require, "src.commands.search." .. engine_type:lower())

  return ok and engine.search(url, name) or nil
end

--[[
return a table
{
repo: string
engine: string
pkgs: {
  name: { "v1", "v2" }
  name2: { "v1", "v2" }
}
}
--]]
function M.find(name)
  local results = {}

  log.arrow "Loading repos..."
  local repos = tbl.map(repo.load_all(), function(val)
    if val.search and val.search.url and val.search.type then
      return val.search
    end
  end)

  if tbl.is_empty(repos) then
    log.err "No repository with search support was found."
  end

  for _, repo_search in pairs(repos) do
    local result = _find(repo_search.url, repo_search.type, name)

    if results then
      table.insert(results, result)
    end
  end

  return results
end

function M.search(name, flags)
  local results = M.find(name)

  if tbl.is_empty(results) then
    log.warn("No packages found for: " .. name)
    return
  end

  show(results)
end

function M.parser(args, flags)
  if #args ~= 1 then
    log.warn "Search for a single package."
    return
  end

  local ok, _ = pcall(M.search, args[1], flags)
end

return M
