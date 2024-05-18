local fs = require "src.utils.fs"
local log = require "src.utils.log"
local tbl = require "src.utils.tbl"
local lpkg = require "src.core.pkg"
local fn = require "src.utils.fn"
local repo = require "src.core.repo"
local c = require "src.utils.colors"
local curl = require "src.utils.curl"

local R = require "src.commands.remove"

local cache = {}

local M = {}

local function _install(name, version, is_dependency, flags)
  is_dependency = is_dependency or false

  cache.repos = cache.repos or repo.load_all()

  if not cache.repos then
    log.error "No valid repo was found."
    fn.exit(1)
  end

  local pkg = lpkg.get_pkg(cache.repos, name, version)

  if not pkg then
    log.err(("Could not get a valid script for: %s@%s"):format(name, version))
  end

  lpkg.show(pkg)

  local dotinfos = lpkg.get_pkg_infos(pkg.name, pkg.version)

  if dotinfos and not flags.force then
    -- If the package is not a dependency, it does not need to be changed.
    if not dotinfos.is_dependency and not is_dependency then
      log.arrow "Installation skipped as the package is already installed."
      -- log.warn "The package is already installed. Use `--force` to reinstall it."
      return
    end

    -- the package will be marked as non-dependency.
    if dotinfos.is_dependency and not is_dependency then
      lpkg.gen_dotinfos_file(dotinfos, { is_dependency = false })
      log.arrow(("%s has been updated, %s has been added to list of packages."):format(PKGER_DOT_INFOS, c.green(name)))
      return
    end

    -- false and false ok

    -- true and false ok

    -- false and true

    -- true and true

    log.arrow "The dependency is already installed."
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

  local dir = pkg.pkgdir
  cache.installation_directory = dir

  if fs.is_dir(dir) and fs.rm_dir(dir) ~= nil then
    log.err("Unable to clear directory for installation: " .. dir)
  end

  local depends = lpkg.parse(pkg.depends or {})

  if pkg.depends then
    local str = table.concat(pkg.depends, ", ")
    log.arrow("Dependencies: " .. str, "green")
  end

  for name, version in pairs(depends) do
    -- local current_pkg = lpkg.get_current_pkg(name)

    -- if current_pkg and version ~= PKGER_SCRIPT_VERSION then
    --   if current_pkg.version == version then
    --     log.arrow " The dependency is already installed."
    --     goto continue
    --   end

    -- local infos = lpkg.get_pkg_infos(name, version)

    -- if infos and infos.version ~= current_pkg.version then
    --   log.warn(
    --     fn.f(
    --       "%s is defined in the %s version, and the package requires the %s version. A `switch` is recommended.",
    --       name,
    --       current_pkg.version,
    --       version
    --     )
    --   )
    --   goto continue
    -- end

    -- end

    _install(name, version, true, {})

    -- ::continue::
  end

  if not fs.is_dir(dir) and not fs.mkdir(dir) then
    log.err "Error trying to create installation directory."
  end

  if not fs.cd(dir) then
    log.err("Could not access installation directory: " .. dir)
  end

  pkg = lpkg.get_source_code(pkg)

  pkg = lpkg.run_pkg(pkg)

  lpkg.gen_dotinfos_file(pkg, { is_dependency = is_dependency })

  if not pkg.keep_source_dir and fs.is_dir(pkg.source_dir) then
    fs.rm_dir(pkg.source_dir)
  end

  -- TODO: use table map in source dir
  -- if not pkg.keep_source_file and fs.is_file(pkg.source_file) then
  --   fs.rm(pkg.source_file)
  -- end

  if flags.upgrade then
    log.info(("Installation completed: %s@%s"):format(pkg.name, pkg.version))
    return
  end

  if not lpkg.get_current_pkg(pkg.name) then
    lpkg.create_links(pkg)
    lpkg.gen_dotpkg_file(pkg, { pinned = false })
  else
    log.info "Package installed. Another version is set as primary. Use `switch` to change the version."
  end

  log.info "Installation completed."
end

--luacheck: ignore is_dependency
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

  if msg and PKGER_DEBUG_MODE then
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
function M.file(content)
  log.warn "This command is intended for development, it may cause packages to break."

  local pkg = lpkg.load_script(content)

  if not pkg then
    log.error "Could not load the package."
    return
  end

  local _ok, msg = pcall(M.load_pkg, pkg, false, {})

  if not _ok then
    log.error(("Installation not completed: %s@%s"):format(pkg.name, pkg.version))
    return
  end

  if msg and PKGER_DEBUG_MODE then
    log(msg)
  end
end

function M.parser(args, flags)
  local pkgs = lpkg.parse(args)

  if flags.file and flags.url then
    log.error "It is not possible to use `file` and `url` flags in the same command."
    fn.exit(1)
  end

  if flags.file then
    local file = fs.is_file(flags.file)

    if not file then
      log.error("non-existent file: " .. file)
      return
    end

    local ok, content = fs.read_file(fs.is_file(flags.file))

    if not ok then
      log.error("Could not retrieve the contents of the file: " .. flags.file)
      return
    end

    M.file(content)
    return
  end

  if flags.url then
    local content = curl.get_content(flags.url)
    if not content then
      log.error("Could not retrieve the contents of the url: " .. flags.url)
      return
    end

    M.file(content)
    return
  end

  if tbl.is_empty(pkgs) then
    log.error "No targets specified. Use --help."
    fn.exit(1)
  end

  for name, version in pairs(pkgs) do
    local _, msg = pcall(M.install, name, version, false, flags or {})

    if msg and PKGER_DEBUG_MODE then
      log(msg)
    end
  end
end

return M
