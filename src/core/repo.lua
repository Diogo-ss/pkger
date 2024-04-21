local curl = require "utils.curl"
local fn = require "utils.fn"
local tbl = require "utils.tbl"
local sandbox = require "utils.sandbox"
local log = require "utils.log"

local default = {
  "https://raw.githubusercontent.com/pkger/core-pkgs/main/repo.lua",
}

local M = {}

function M.get_repos()
  local ok, f = pcall(io.open, PKGER_REPOS_FILE, "r")
  local respos = {}

  if ok and f then
    respos = fn.split(f:read "*all", "\n")
    respos = tbl.map(respos, fn.trim)
    respos = tbl.map(respos, function(str)
      return not fn.startswith(str, "#") and str or nil
    end)
    f:close()
  end

  return tbl.isempty(respos) and default or respos
end

function M.get_all_contents()
  local links = M.get_repos()
  local contents = {}

  for _, link in pairs(links) do
    if link then
      table.insert(contents, curl.get_file(link))
    end
  end

  return contents
end

function M.load_all()
  local repos_contents = M.get_all_contents()
  local repos = {}

  for _, contents in pairs(repos_contents) do
    local ok, results = sandbox.run(contents)

    if ok then
      -- TODO: add env
      table.insert(repos, { manteiners = results.manteiners, url = results.url, search = results.search })
      goto continue
    end

    log.warn(("There was a problem loading the repo. It was ignored. Error: %s"):format(results))
    ::continue::
  end

  if tbl.isempty(repos) then
    return nil
  end

  return repos
end

return M
