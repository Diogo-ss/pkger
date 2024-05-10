local curl = require "src.utils.curl"
local fn = require "src.utils.fn"
local tbl = require "src.utils.tbl"
local sandbox = require "src.utils.sandbox"
local log = require "src.utils.log"
local list = require "src.utils.list"

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

    respos = list.unique(respos)
  end

  return tbl.isempty(respos) and default or respos
end

-- function M.get_all_contents()
--   local urls = M.get_repos()
--   local contents = {}

--   for _, url in pairs(urls) do
--     if url then
--       local content = curl.get_content(url)

--       if not content then
--         log.warn("Could not retrieve the contents of: " .. url)
--       end

--       table.insert(contents, content)
--     end
--   end

--   return contents
-- end

function M.load_all()
  local urls = M.get_repos()
  local repos = {}

  for _, url in pairs(urls) do
    local contents = curl.get_content(url)

    if not contents then
      log.error("Could not access: " .. url)
      goto continue
    end

    local ok, env = sandbox.run(contents)

    if not (ok and env) then
      log.warn(("There was a problem loading content from the repo. Error: %s"):format(env))
      goto continue
    end

    table.insert(repos, {
      manteiners = env.manteiners,
      url = env.url,
      search = env.search,
      os = env.os,
      arch = env.arch,
    })

    ::continue::
  end

  return repos
end

return M
