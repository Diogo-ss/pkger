local curl = require "src.utils.curl"
local fn = require "src.utils.fn"
local tbl = require "src.utils.tbl"
local sandbox = require "src.utils.sandbox"
local log = require "src.utils.log"
local json = require "dkjson"

local M = {}

local function replace(url, infos)
  for match in url:gmatch "%${{%s(%w+)%s}}" do
    url = url:gsub("%${{%s" .. match .. "%s}}", infos[match])
  end

  return url
end

function M.checkver(url, jsonpath, regex)
  -- return "0.9.5"

  --- remover
  local contents = curl.get_content(url)

  if not contents then
    return nil
  end

  local text = ""

  if jsonpath then
    local data = json.decode(contents)
    text = data[jsonpath]
  end

  -- testari isso
  text = string.match(text, regex)
  -- if regex then
  --   text = string.match(text, regex)
  --   if type(text) == "table" then
  --     text = table.concat(text, ".")
  --   end
  -- end

  return text ~= "" and text or nil
end

function M.get_pkg(repos, pkg)
  -- local contents = curl.get_file(repos[1])

  -- for _, repo in pairs(repos) do

  -- end
  -- TODO: adicionar chagem para todos os repos, e pegar a mairo versão

  local repo = repos[1]

  repo.url = replace(repo.url, pkg)

  return curl.get_content(repo.url)

  --- remover
  --   local text = [[
  -- name = "neovim"
  -- version = "0.9.5"
  -- description = "Vim-fork focused on extensibility and usability"
  -- homepage = "https://neovim.io"
  -- license = "Apache-2.0"
  -- manteiners = "Diogo-ss"
  -- url = "https://github.com/neovim/neovim/releases/download/v${{ version }}/nvim-linux64.tar.gz"
  -- hash = "c3d7cfd161ccfca866fb690d53c5f0ab0df67934"

  -- bin = "nvim-linux64/bin/nvim"

  -- checkver = {
  --   url = "https://api.github.com/repos/neovim/neovim/releases/latest",
  --   jsonpath = "tag_name",
  --   regex = "[Vv]?(.+)",
  -- }

  -- depends = {
  --   'libluv',
  --   'libtermkey',
  --   'libuv'
  -- }

  -- function install()
  --   -- extract "nvim-linux64.tar.gz"
  --   print("install")
  -- end

  -- function test()
  --   -- extract { "nvim", "--version" }
  --   print("test")
  -- end
  --   ]]

  -- return text
end

function M.load_pkg(pkg, env)
  local ok, result = sandbox.run(pkg, env)

  if ok and not result.version then
    local checkver = result.checkver
    result.version = M.checkver(checkver.url, checkver.jsonpath, checkver.regex)
  end

  if not result.version then
    log.error "Não foi possível determinar a versão do pacote"
    error()
  end

  result.url = replace(result.url, result)

  if not result.url then
    log.error "Não foi possível obter a url final do pacote"
    error()
  end

  return result
end

return M
