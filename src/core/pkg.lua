local curl = require "src.utils.curl"
local fn = require "src.utils.fn"
local tbl = require "src.utils.tbl"
local sandbox = require "src.utils.sandbox"
local log = require "src.utils.log"
local json = require "dkjson"
local v = require "semver"
local fs = require "src.utils.fs"
local sys = require "src.utils.sys"

local M = {}

local function env()
  return {
    system = fn.system,
    shell_code = fn.shell_code,
    get = curl.download,
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

function M.parse(pkgs)
  local results = {}

  for _, pkg in pairs(pkgs) do
    if pkg:find "@" then
      local name, version = pkg:match "^(.+)@(.+)$"

      if pkg == "@" or not (version or name) then
        log.error("Package name is invalid: " .. pkg)
        os.exit(1)
      end

      results[name] = version
    else
      results[pkg] = "script"
    end
  end

  return results
end

function M.has_package(name, version)
  local file = fs.join(PKGER_DATA, name, version, ".pkger")

  return fs.is_file(file)
end

-- TODO: refatorar (gambiarra)
function M.list_packages()
  local pkgs = {}

  fs.each(fs.join(PKGER_DATA, "*"), function(P)
    if fn.endswith(P, ".pkger") then
      local infos = dofile(P)

      table.insert(pkgs, infos)
    end
  end, {
    delay = true,
    recurse = true,
  })

  return pkgs
end

function M.get_pkg_infos(name, version)
  local file = fs.join(PKGER_DATA, name, version, ".pkger")

  local ok, infos = pcall(dofile, file)

  if not ok then
    return nil
  end

  return infos
end

function M.get_master_pkg(name)
  local file = fs.join(PKGER_DATA, name, PKGER_MAIN_PKG)

  local ok, infos = pcall(dofile, file)

  if not ok then
    return nil
  end

  return { version = infos.version, file = file }
end

-- TODO: adicinar suporte a versões
function M.list_all_dependent_pkgs(name)
  local pkgs = M.list_packages()
  local list = {}

  for _, pkg in pairs(pkgs) do
    for _, depend_name in pairs(pkg.depends or {}) do
      if depend_name == name then
        table.insert(list, { name = pkg.name, version = pkg.version })
      end
    end
  end

  return list
end

function M.gen_pkger_file(pkg, is_dependency)
  local dir = pkg.INSTALLATION_DIRECTORY
  local f = io.open(fs.join(dir, ".pkger"), "w+")

  local infos = {
    pkger_version = PKGER_VERSION,
    os = sys.os,
    arch = sys.arch,
    aliases = pkg.aliases,
    name = pkg.name,
    version = pkg.version,
    bin = pkg.bin,
    is_dependency = is_dependency or false,
    depends = pkg.depends or {},
    script_infos = pkg.script_infos,
    dir = pkg.INSTALLATION_DIRECTORY,
    prefix = fs.join(dir, pkg.bin),
  }

  if not f then
    log.error "Failed to create `.pkger` file."
    error()
  end

  f:write("return " .. fn.inspect(infos))
  f:close()
end

function M.gen_pkg_file(pkg)
  local file = fs.join(PKGER_DATA, pkg.name, PKGER_MAIN_PKG)
  local f = io.open(file, "w+")

  local infos = {
    pkger_version = PKGER_VERSION,
    name = pkg.name,
    -- aliases = pkg.aliases,
    version = pkg.version,
    dir = file,
  }

  if not f then
    log.error(("Failed to create `%s` file."):format(PKGER_MAIN_PKG))
    error()
  end

  f:write("return " .. fn.inspect(infos))
  f:close()
end

function M.run_pkg(pkg)
  log.info "Starting script execution..."

  local order = {
    "pre_biuld",
    "biuld",
    "pos_biuld",
    "pre_install",
    "install",
    "pos_install",
    "clean",
    -- "test",
  }

  -- --TODO: add check type
  for _, n in pairs(order) do
    local func = pkg[n]

    if not func then
      goto continue
    end

    if type(func) ~= "function" then
      log.error(n .. " não é do tipo função.")
      error()
    end

    local ok, _ = pcall(func)

    if not ok then
      log.error(n .. " cannot be executed.")
      error()
    end

    ::continue::
  end
end

function M.get_source_code(pkg)
  local dir = pkg.INSTALLATION_DIRECTORY

  -- TODO: add git suporte

  local url = M.replace(pkg.url, { name = pkg.name, version = pkg.version })

  local file = url:gsub("/$", ""):match ".*/(.*)$"

  log.info(("Downloading %s from %s"):format(file, url))
  local ok, _ = pcall(curl.download, url, file)

  if not ok then
    log.error("Error trying to download file: " .. url)
    error()
  end

  -- if pkg.version ~= "script" and pkg.version ~= "head" then
  --   log.info "Inciando chacagem sha1..."
  --   local sha1 = fn.sha1sum(file)
  --   if sha1 ~= pkg.hash then
  --     error("Os sha1 não são iguais. Abortando instalação do " .. pkg.name)
  --   end
  -- end

  local _ok, _ = fs.extract(file)

  if not _ok then
    log.error("Error trying to extract file: " .. file)
    error()
  end

  -- fs.rm(dir .. "/" .. file)
end

function M.create_link(pkg)
  local dir = pkg.INSTALLATION_DIRECTORY

  fs.mkdir(PKGER_BIN)

  if not fs.is_dir(PKGER_BIN) then
    log.error "Couldn't get the directory for bin."
    error()
  end

  local bin_name = pkg.bin:match ".+/([^/]+)$" or pkg.bin
  local bin_path = fs.join(dir, pkg.bin)
  local dest_path = fs.join(PKGER_BIN, bin_name)

  local ok, msg = fs.link(bin_path, dest_path, true)

  if not ok then
    log.error("Error creating symbolic link to bin: " .. bin_path .. ". Error: " .. msg)
    error()
  end

  -- TODO: use test
  -- local _ok, _ = pcall(pkg.test)

  -- if not _ok then
  --   log.error "O teste apresentou falha na instlação. Deseja remover o binário?"
  -- end
end

return M
