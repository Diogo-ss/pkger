local fs = require "src.utils.fs"
local log = require "src.utils.log"
local tbl = require "src.utils.tbl"
local lpkg = require "src.core.pkg"
local fn = require "src.utils.fn"
local repo = require "src.core.repo"
local R = require "src.commands.remove"
local c = require "src.utils.colors"
local U = require "src.commands.unlink"

local cache = {}

local M = {}

function M.load_pkg(pkg, is_dependency, flags)
  is_dependency = is_dependency or false
  flags = flags or {}

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
    log.err "Error trying to create installation directory."
  end

  fs.cd(dir)
  pkg.prefix = fs.join(dir, pkg.bin)
  pkg.INSTALLATION_DIRECTORY = dir
  cache.installation_directory = dir

  lpkg.get_source_code(pkg)

  lpkg.run_pkg(pkg)

  lpkg.gen_dotinfos_file(pkg, { is_dependency = is_dependency })

  if flags.upgrade then
    log.info(("Installation completed: %s@%s"):format(pkg.name, pkg.version))
    return
  end

  -- TODO: adiconar caso onde é flag de upgrade e é uma depencia
  -- if flags.upgrade and is_dependency then
  -- end

  if not lpkg.get_current_pkg(pkg.name) then
    lpkg.create_link(pkg)
    lpkg.gen_dotpkg_file(pkg, { pinned = false })
  else
    log.info "The package has been installed but the link has not been created. I use a switch to switch between versions."
  end

  log.info "Installation completed."
end

function M.install(name, version, is_dependency, flags)
  is_dependency = is_dependency or false
  flags = flags or {}

  local pkg = lpkg.get_pkg(cache.repos, name, version)

  if not pkg then
    log.err(("Could not get a valid script for: %s@%s"):format(name, version))
  end

  lpkg.show(pkg)

  local has = lpkg.has_package(pkg.name, pkg.version)

  if has and not flags.force then
    local infos = dofile(has)

    -- If the package is not a dependency, it does not need to be changed.
    if not infos.is_dependency and not is_dependency then
      log.warn "Installation skipped as the package is already installed."
      -- log.warn "The package is already installed. Use `--force` to reinstall it."
      return
    end

    -- the package will be marked as non-dependency.
    if infos.is_dependency and not is_dependency then
      lpkg.gen_dotinfos_file(infos, { is_dependency = false })
      log.warn(("%s has been updated, %s has been added to list of packages."):format(PKGER_DOT_INFOS, c.green(name)))
      return
    end

    return
  end

  -- TODO: testar o uso durante a instalação
  if has and flags.force then
    U.unlink(name)
    -- R.remove(pkg.name, pkg.version, is_dependency)
  end

  log.info(("Starting installation: %s@%s"):format(pkg.name, pkg.version))

  M.load_pkg(pkg, is_dependency)
end

function M.install_pkgs(pkgs, flags)
  log.arrow "Loading repos..."
  cache.repos = cache.repos or repo.load_all()
  -- remover esse repo padrão e decomentar acima
  -- cache.repos = {
  --   {
  --     manteiners = { "Diogo-ss" },
  --     os = "linux",
  --     arch = "x86",
  --     search = {
  --       type = "github",
  --       url = "https://api.github.com/repos/pkger/core-pkgs/git/trees/main?recursive=1",
  --     },
  --     url = "https://raw.githubusercontent.com/pkger/core-pkgs/main/pkgs/${{ name }}/${{ version }}/pkg.lua",
  --   },
  -- }

  cache.current_dir = fs.cwd()

  if not cache.repos then
    log.error "No valid repo was found."
    fn.exit(1)
  end

  for name, version in pairs(pkgs) do
    local ok, err = pcall(M.install, name, version, false, flags)

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

function M.parser(args, flags)
  local pkgs = lpkg.parse(args)

  if tbl.is_empty(pkgs) then
    log.error "No targets specified. Use --help."
    fn.exit(1)
  end

  -- TODO: load cache
  -- M.load_cache()

  M.install_pkgs(pkgs, flags)
end

return M
