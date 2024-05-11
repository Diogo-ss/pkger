local fs = require "src.utils.fs"
local log = require "src.utils.log"
local tbl = require "src.utils.tbl"
local lpkg = require "src.core.pkg"
local curl = require "src.utils.curl"
local fn = require "src.utils.fn"
local sys = require "src.utils.sys"
local json = require "dkjson"

local cache = {}

local M = {}

function M.get_source_code(pkg)
  local dir = pkg.INSTALLATION_DIRECTORY

  -- TODO: add git suporte

  local url = lpkg.replace(pkg.url, { name = pkg.name, version = pkg.version })

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

function M.create_link(pkg)
  local dir = pkg.INSTALLATION_DIRECTORY

  fs.mkdir(PKGER_BIN)

  if not fs.is_dir(PKGER_BIN) then
    log.error "Couldn't get the directory for bin."
    error()
  end

  local bin_name = pkg.bin:match ".+/([^/]+)$" or pkg.bin
  local src_path = fs.join(dir, pkg.bin)
  local dest_path = fs.join(PKGER_BIN, bin_name)

  local ok, msg = fs.link(src_path, dest_path, true)

  if not ok then
    log.error("Error creating symbolic link to bin: " .. src_path .. ". Error: " .. msg)
    error()
  end

  -- local _ok, _ = pcall(pkg.test)

  -- if not _ok then
  --   log.error "O teste apresentou falha na instlação. Deseja remover o binário?"
  -- end
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
  }

  if not f then
    log.error "failed to create `.pkger` file."
    error()
  end

  f:write("return " .. fn.inspect(infos))
  f:close()
end

function M.load_pkg(pkg, is_dependency)
  local dir = fs.join(PKGER_DATA, pkg.name, pkg.version)

  if fs.is_dir(dir) then
    fs.rm_dir(dir)
  end

  local depends = lpkg.parse(pkg.depends)

  log.info "Checking for dependencies...."
  -- for name, version in pairs(depends) do
  --   local has = lpkg.has_package(name, version)

  --   if not has then
  --     M.install(name, version, true)
  --   end
  -- end

  fs.mkdir(dir)
  if not fs.is_dir(dir) then
    log.error "Error trying to create installation directory."
    error()
  end

  fs.cd(dir)
  pkg.INSTALLATION_DIRECTORY = dir
  cache.installation_directory = dir

  M.get_source_code(pkg)

  M.run_pkg(pkg)

  M.gen_pkger_file(pkg, is_dependency)

  -- M.create_link(pkg)

  log.info "Installation completed."
end

function M.install(name, version, is_dependency, force)
  local has = lpkg.has_package(name, version)

  if not is_dependency and has and not force then
    log.warn "The package is already installed. Use `--force` to reinstall it."
    return
  end

  -- TODO: remove pkg
  -- if has and force then
  -- pkg.remove(pkg, version)
  -- end

  log.info(("Starting installation: %s@%s"):format(name, version))

  local pkg = lpkg.get_pkg(cache.repos, name, version)

  if not pkg then
    log.error(("Could not get a valid script for: %s@%s"):format(name, version))
    error()
  end

  M.load_pkg(pkg, is_dependency)
end

function M.install_pkgs(pkgs)
  log.info "Loading repos..."
  -- cache.repos = cache.repos or repo.load_all()
  -- remover esse repo padrão e decomentar acima
  cache.repos = {
    {
      manteiners = { "Diogo-ss" },
      os = "linux",
      arch = "x86",
      search = {
        type = "github",
        url = "https://api.github.com/repos/pkger/core-pkgs/git/trees/main?recursive=1",
      },
      url = "https://raw.githubusercontent.com/pkger/core-pkgs/main/pkgs/${{ name }}/${{ version }}/pkg.lua",
    },
  }

  cache.current_dir = fs.cwd()

  if not cache.repos then
    log.error "No valid repo was found."
    os.exit(1)
  end

  for name, version in pairs(pkgs) do
    local ok, err = pcall(M.install, name, version)

    if not ok then
      log.error(("Installation not completed: %s@%s"):format(name, version))
      local dir = cache.installation_directory
      if dir and fs.is_dir(dir) then
        fs.rm_dir(dir)
      end
    end
    fs.cd(cache.current_dir)
  end
end

function M.parser(args)
  local pkgs = lpkg.parse(args)

  if tbl.isempty(pkgs) then
    log.error "No targets specified. Use --help."
    os.exit(1)
  end

  -- TODO: load cache
  -- M.load_cache()

  M.install_pkgs(pkgs)
end

return M
