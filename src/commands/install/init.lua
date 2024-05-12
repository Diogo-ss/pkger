local fs = require "src.utils.fs"
local log = require "src.utils.log"
local tbl = require "src.utils.tbl"
local lpkg = require "src.core.pkg"
local curl = require "src.utils.curl"
local fn = require "src.utils.fn"
local sys = require "src.utils.sys"
local json = require "dkjson"
local repo = require "src.core.repo"
local remove = require "src.commands.remove"

local cache = {}

local M = {}

function M.load_pkg(pkg, is_dependency)
  local dir = fs.join(PKGER_DATA, pkg.name, pkg.version)

  if fs.is_dir(dir) then
    fs.rm_dir(dir)
  end

  local depends = lpkg.parse(pkg.depends or {})

  -- if depends[pkg.name] == pkg.version then
  --   log.error "dependencies loop found"
  -- end

  log.info "Checking for dependencies...."
  for name, version in pairs(depends) do
    local has = lpkg.has_package(name, version)

    if not has then
      M.install(name, version, true)
    end
  end

  fs.mkdir(dir)
  if not fs.is_dir(dir) then
    log.error "Error trying to create installation directory."
    error()
  end

  fs.cd(dir)
  pkg.INSTALLATION_DIRECTORY = dir
  cache.installation_directory = dir

  lpkg.get_source_code(pkg)

  lpkg.run_pkg(pkg)

  lpkg.gen_pkger_file(pkg, is_dependency)

  if not lpkg.get_current_pkg(pkg.name) then
    lpkg.create_link(pkg)
    lpkg.gen_pkg_file(pkg)
  else
    log.info "The package has been installed but the link has not been created. I use a switch to switch between versions."
  end

  log.info "Installation completed."
end

function M.install(name, version, is_dependency, force)
  local pkg = lpkg.get_pkg(cache.repos, name, version)

  if not pkg then
    log.error(("Could not get a valid script for: %s@%s"):format(name, version))
    error()
  end

  local has = lpkg.has_package(pkg.name, pkg.version)

  if has and not force then
    if not is_dependency then
      log.warn "The package is already installed. Use `--force` to reinstall it."
    end
    return
  end

  -- TODO: testar o uso durante a instalação
  if has and force then
    pkg.remove(pkg.name, pkg.version)
  end

  log.info(("Starting installation: %s@%s"):format(pkg.name, pkg.version))

  M.load_pkg(pkg, is_dependency)
end

function M.install_pkgs(pkgs)
  log.info "Loading repos..."
  cache.repos = cache.repos or repo.load_all()
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

    fn.print(err)

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

  if tbl.is_empty(pkgs) then
    log.error "No targets specified. Use --help."
    os.exit(1)
  end

  -- TODO: load cache
  -- M.load_cache()

  M.install_pkgs(pkgs)
end

return M
