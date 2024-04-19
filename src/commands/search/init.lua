local sandbox = require "utils.sandbox"
local fn = require "utils.fn"
local repo = require "core.repo"
local tbl = require "utils.tbl"
local list = require "utils.list"
local c = require "utils.colors"

local M = {}

local function show_results(results)
  for ru, value in pairs(results) do
    print(c.yellow(ru))
    for name, versions in pairs(value.pkgs) do
      local version_str = table.concat(versions, ", ")
      version_str = version_str == "script" and c.red "script" or version_str
      print(string.format("  %s: %s", c.green(name), version_str))
    end
    print()
  end
end

local function _search(env, name)
  local url = env.search.url:gsub("%${{ pkg%.name }}", name)

  local ok, engine = pcall(require, "commands.search." .. env.search.type:lower())

  if ok then
    return engine.search(url, name)
  end

  return nil
end

function M.find(name)
  local rl = repo.get_repos()
  local results = {}

  for _, link in pairs(rl) do
    local contents = repo.get_file(link)

    -- TODO: filter

    if contents then
      local ok, env = pcall(sandbox.run, contents)

      if ok and env.search then
        results = tbl.extend(results, _search(env, name))
        -- table.insert(results, _search(env, name))
      end
    end
  end

  show_results(results)
end

return M
