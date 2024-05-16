local fs = require "src.utils.fs"
local log = require "src.utils.log"
local tbl = require "src.utils.tbl"
local lpkg = require "src.core.pkg"
local fn = require "src.utils.fn"
local repo = require "src.core.repo"
local c = require "src.utils.colors"

local R = require "src.commands.remove"
local U = require "src.commands.unlink"

local cache = {}

local M = {}

local function _install(name, version, is_dependency, flags)
  is_dependency = is_dependency or false

  local pkg = lpkg.get_pkg(cache.repos, name, version)

  if not pkg then
    log.err(("Could not get a valid script for: %s@%s"):format(name, version))
  end

  lpkg.show(pkg)

  local dotinfos = lpkg.get_pkg_infos(pkg.name, pkg.version)

  if dotinfos and not flags.force then
    -- If the package is not a dependency, it does not need to be changed.
    if not dotinfos.is_dependency and not is_dependency then
      log.warn "Installation skipped as the package is already installed."
      -- log.warn "The package is already installed. Use `--force` to reinstall it."
      return
    end

    -- the package will be marked as non-dependency.
    if dotinfos.is_dependency and not is_dependency then
      lpkg.gen_dotinfos_file(dotinfos, { is_dependency = false })
      log.warn(("%s has been updated, %s has been added to list of packages."):format(PKGER_DOT_INFOS, c.green(name)))
      return
    end

    return
  end

  -- TODO: testar o uso durante a instalação
  if dotinfos and flags.force then
    R.remove(pkg.name, pkg.version, {})
  end

  log.info(fn.f("Starting installation: %s@%s", pkg.name, pkg.version))

  M.load_pkg(pkg, is_dependency, {})
end

function M.load_pkg(pkg, is_dependency, flags)
  is_dependency = is_dependency or false

  local dir = pkg.INSTALLATION_DIRECTORY
  cache.installation_directory = dir

  if fs.is_dir(dir) and not fs.rm_dir(dir) == nil then
    log.err("Unable to clear directory for installation: " .. dir)
  end

  local depends = lpkg.parse(pkg.depends or {})

  log.info "Checking for dependencies...."
  for name, version in pairs(depends) do
    local has = lpkg.has_package(name, version)

    if not has then
      _install(name, version, true, {})
    end
  end

  if not fs.is_dir(dir) and not fs.mkdir(dir) then
    log.err "Error trying to create installation directory."
  end

  if not fs.cd(dir) then
    log.err("Could not access installation directory: " .. dir)
  end

  pkg = lpkg.get_source_code(pkg)

  lpkg.run_pkg(pkg)

  lpkg.gen_dotinfos_file(pkg, { is_dependency = is_dependency })

  if not pkg.keep_source_dir and fs.is_dir(pkg.source_dir) then
    fs.rm_dir(pkg.source_dir)
  end

  if not pkg.keep_source_file and fs.is_file(pkg.source_file) then
    fs.rm(pkg.source_file)
  end

  if flags.upgrade then
    log.info(("Installation completed: %s@%s"):format(pkg.name, pkg.version))
    return
  end

  if not lpkg.get_current_pkg(pkg.name) then
    lpkg.create_links(pkg)
    lpkg.gen_dotpkg_file(pkg, { pinned = false })
  else
    log.info "The package has been installed but the link has not been created. I use a switch to switch between versions."
  end

  log.info "Installation completed."
end

function M.install(name, version, is_dependency, flags)
  if not cache.repos then
    log.arrow "Loading repos..."
    cache.repos = repo.load_all()
  end

  if not cache.repos then
    log.err "No valid repo was found."
    fn.exit(1)
  end

  cache.current_dir = fs.cwd()

  local ok, msg = pcall(_install, name, version, false, flags or {})

  if PKGER_DEBUG_MODE then
    log(msg)
  end

  if not ok then
    local dir = cache.installation_directory

    log.error(("Installation not completed: %s@%s"):format(name, version))

    if dir and fs.is_dir(dir) then
      fs.rm_dir(dir)
    end
  end

  fs.cd(cache.current_dir)
end

-- not safe to use
function M.file(flags)
  local file = fs.is_file(flags.file)

  if not file then
    log.error "não é arquivo"
    return
  end

  local ok, content = fs.read_file(fs.is_file(flags.file))

  local pkg = lpkg.load_script(content)

  if not pkg then
    log.error "não achou pacote"
  end

  M.load_pkg(pkg, false, {})
end

function M.parser(args, flags)
  local pkgs = lpkg.parse(args)

  if flags.file then
    M.file(flags)
    return
  end

  if tbl.is_empty(pkgs) then
    log.error "No targets specified. Use --help."
    fn.exit(1)
  end

  for name, version in pairs(pkgs) do
    local ok, _ = pcall(M.install, name, version, false, flags or {})
  end
end

return M
