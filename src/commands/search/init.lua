local repo = require "src.core.repo"
local tbl = require "src.utils.tbl"
local c = require "src.utils.colors"
local log = require "src.utils.log"

local M = {}

function M.show(results)
  for _, value in pairs(results) do
    log(c.cyan(value.engine) .. ": " .. c.yellow(value.repo))
    for name, versions in pairs(value.pkgs) do
      local versions_str = table.concat(versions, ", ")
      log(string.format("  %s: %s", c.green(name), versions_str))
    end
  end
end

local function search(url, engine_type, name)
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

  log.info "Loading repos..."
  local repos = tbl.map(repo.load_all(), function(val)
    if val.search and val.search.url and val.search.type then
      return val.search
    end
  end)

  if tbl.isempty(repos) then
    log.error "No repository with search support was found."
    os.exit(1)
  end

  for _, repo_search in pairs(repos) do
    local result = search(repo_search.url, repo_search.type, name)

    if results then
      table.insert(results, result)
    end
  end

  return results
end

function M.parser(args)
  if #args ~= 1 then
    log.warn "Search for a single package."
    return
  end

  local results = M.find(args[1])

  if tbl.isempty(results) then
    log.warn("No packages found for: " .. args[1])
    os.exit(1)
  end

  M.show(results)
end

return M
