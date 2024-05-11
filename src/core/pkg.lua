local curl = require "src.utils.curl"
local fn = require "src.utils.fn"
local tbl = require "src.utils.tbl"
local sandbox = require "src.utils.sandbox"
local log = require "src.utils.log"
local json = require "dkjson"
local v = require "semver"
local fs = require "src.utils.fs"

local M = {}

local function env()
  return {
    system = fn.system,
    shell_code = fn.shell_code,
    get = curl.get,
    rm = fs.rm,
    rm_dir = fs.rm_dir,
    cp = fs.cp,
    cd = fs.cd,
    log = log,
    cwd = fs.cwd,
    extract = fs.extract,
    INSTALLATION_ENVIRONMENT = true,
  }
end

function M.checkver(url, jsonpath, regex)
  local contents = curl.get_content(url)

  if not contents then
    return nil
  end

  local text = ""

  if jsonpath then
    local data = json.decode(contents)
    text = data[jsonpath]
  end

  text = string.match(text, regex)
  return text ~= "" and text or nil
end

function M.replace(url, infos)
  for key, value in pairs(infos) do
    url = url:gsub("%${{%s" .. key .. "%s}}", value)
  end

  return url
end

function M.load_script(script)
  local ok, pkg = sandbox.run(script, env())

  if ok and not pkg.version then
    local checkver = pkg.checkver
    pkg.version = M.checkver(checkver.url, checkver.jsonpath, checkver.regex)
  end

  if not pkg.version then
    error "It was not possible to determine the version of the package."
  end

  return pkg
end

function M.get_pkg(repos, name, version)
  for _, repo in pairs(repos) do
    local url = M.replace(repo.url, { name = name, version = version })
    local content = curl.get_content(url)

    if not content then
      goto continue
    end

    local ok, pkg = pcall(M.load_script, content)

    if ok then
      pkg.script_infos = {
        url = url,
        content = content,
        name = name,
        version = version,
      }
      return pkg
    end

    ::continue::
  end

  return nil
end

return M
