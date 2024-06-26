local curl = require "src.utils.curl"
local fn = require "src.utils.fn"
local tbl = require "src.utils.tbl"
local sandbox = require "src.utils.sandbox"
local log = require "src.utils.log"
local json = require "dkjson"
local fs = require "src.utils.fs"
local sys = require "src.utils.sys"
local c = require "src.utils.colors"

local M = {}

local function env()
  return {
    system = fn.safe_system,
    shell_code = fn.shell_code,
    get = curl.download,
    rm = fs.rm,
    rm_dir = fs.rm_dir,
    cp = fs.cp,
    cd = fs.cd,
    log = log,
    cwd = fs.cwd,
    print = print,
    join = fs.join,
    is_file = fs.is_file,
    is_dir = fs.is_file,
    pkg = M.pkg,
    mkdir = fs.mkdir,
    tbl = tbl,
    extract = fs.extract,
    INSTALLATION_ENVIRONMENT = true,
    PKGER_PREFIX = PKGER_PREFIX,
    PKGER_VERSION = PKGER_VERSION,
    PKGER_BIN = PKGER_BIN,
    PKGER_ETC = PKGER_ETC,
    PKGER_LIB = PKGER_LIB,
    PKGER_DATA = PKGER_PKGS,
    PKGER_CACHE = PKGER_CACHE,
    PKGER_TMP_DIR = PKGER_TMP,
    PKGER_DEBUG_MODE = PKGER_DEBUG_MODE,
  }
end

function M.checkver(url, jsonpath, regex)
  local contents = curl.get_content(url)

  if not contents then
    return nil
  end

  local text

  if jsonpath then
    local data = json.decode(contents)
    text = data[jsonpath]

    -- if type(text) == "table" then
    --   text = table.concat(text, "")
    -- end
  else
    text = contents
  end

  text = string.match(text, regex)

  text = fn.trim(text)
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
    log.err "It was not possible to determine the version of the package."
  end

  pkg.bin_name = (pkg.bin and pkg.bin:match ".+/([^/]+)$") or pkg.bin

  local dir = fs.join(PKGER_PKGS, pkg.name, pkg.version)
  local etc = fs.join(dir, (pkg.etc or "etc"))
  local share = fs.join(dir, (pkg.share or "share"))
  local include = fs.join(dir, (pkg.include or "include"))
  local lib = fs.join(dir, (pkg.lib or "lib"))

  -- script
  pkg.pkgdir = dir
  pkg.pkgetc = etc
  pkg.pkgshare = share
  pkg.pkginclude = include
  pkg.pkglib = lib

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
        fn.exit(1)
      end

      results[name] = version
    else
      results[pkg] = PKGER_SCRIPT_VERSION
    end
  end

  return results
end

function M.has_package(name, version)
  local file = fs.join(PKGER_PKGS, name, version, PKGER_DOT_INFOS)

  return fs.is_file(file)
end

-- TODO: refatorar (gambiarra)
function M.list_packages()
  local pkgs = {}

  fs.each(fs.join(PKGER_PKGS, "*"), function(P)
    if fn.endswith(P, PKGER_DOT_INFOS) then
      local ok, infos = pcall(dofile, P)

      if ok then
        table.insert(pkgs, infos)
      end
    end
  end, {
    delay = true,
    recurse = true,
  })

  return pkgs
end

function M.list_primary_pkgs()
  local current_pkgs = {}

  fs.each(fs.join(PKGER_PKGS, "*"), function(pkg_dir)
    if fs.is_dir(pkg_dir) then
      local main_pkg_file = fs.join(pkg_dir, PKGER_DOT_PKG)
      if fs.is_file(main_pkg_file) then
        local ok, main_pkg = pcall(dofile, main_pkg_file)
        if ok then
          table.insert(current_pkgs, main_pkg)
        end
      end
    end
  end, {
    delay = true,
    recurse = false,
  })

  return current_pkgs
end

function M.list_available_versions(name)
  local pkgs = M.list_packages()
  local versions = {}

  for _, pkg in pairs(pkgs) do
    if pkg.name == name then
      table.insert(versions, pkg.version)
    end
  end

  return versions
end

function M.get_pkg_infos(name, version)
  local file = fs.join(PKGER_PKGS, name, version, PKGER_DOT_INFOS)

  local ok, infos = pcall(dofile, file)

  if not ok then
    return nil
  end

  return infos
end

function M.get_current_pkg(name)
  local file = fs.join(PKGER_PKGS, name, PKGER_DOT_PKG)

  local ok, infos = pcall(dofile, file)

  if not ok then
    return nil
  end

  return infos
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

function M.gen_dotinfos_file(pkg, flags)
  flags = flags or {}

  local dir = pkg.pkgdir
  local file = fs.join(PKGER_PKGS, pkg.name, pkg.version, PKGER_DOT_INFOS)
  local bin_name = pkg.bin_name

  if not bin_name then
    pkg.is_libary = true
  end

  local infos = {
    pkger_version = PKGER_VERSION,
    os = sys.os,
    arch = sys.arch,
    -- aliases = pkg.aliases,
    name = pkg.name,
    version = pkg.version,
    pkgdir = dir,
    bin = pkg.bin,
    -- installed_as_dependency = flags.installed_as_dependency or false,
    is_dependency = flags.is_dependency or false,
    is_libary = pkg.is_libary or false,
    depends = pkg.depends or {},
    installed_at = os.date "%Y-%m-%d %H:%M:%S",
    script_infos = pkg.script_infos,
    prefix = dir,
    bin_name = bin_name,
    file = file,
  }

  local ok, _ = fs.write_file(file, "return " .. fn.inspect(infos))

  if not ok then
    log.err(("Failed to create `%s` file."):format(PKGER_DOT_INFOS))
  end
end

function M.gen_dotpkg_file(pkg, flags)
  flags = flags or {}

  local dir = pkg.pkgdir
  local file = fs.join(PKGER_PKGS, pkg.name, PKGER_DOT_PKG)
  local bin_name = pkg.bin_name

  if not bin_name then
    pkg.is_libary = true
  end

  local opt_name = pkg.is_libary and pkg.name or pkg.bin_name

  local infos = {
    pkgdir = dir,
    pkger_version = PKGER_VERSION,
    name = pkg.name,
    created_at = os.date "%Y-%m-%d %H:%M:%S",
    -- aliases = pkg.aliases,
    version = pkg.version,
    pinned = flags.pinned or false,
    is_libary = pkg.is_libary or false,
    bin_name = bin_name,
    prefix = fs.join(PKGER_OPT, opt_name),
    file = file,
  }

  local ok, _ = fs.write_file(file, "return " .. fn.inspect(infos))

  if not ok then
    log.err(("Failed to create `%s` file."):format(PKGER_DOT_PKG))
  end
end

function M.run_pkg(pkg)
  log.info "Starting script execution..."

  local order = {
    "pre_build",
    "build",
    "pos_build",
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
      log.err(c.yellow(n) .. " is not a function type.")
    end

    log.arrow("Executing step: " .. c.green(n), "blue")
    local ok, msg = pcall(func)

    if not ok then
      log.err(c.red(n) .. " cannot be executed: " .. msg)
    end

    ::continue::
  end

  if pkg.bin then
    pkg.bin_name = M.bin_name_parser(pkg.bin)
    pkg.bin_path = fs.join(pkg.pkgdir, pkg.bin)
  elseif not pkg.bin_name then
    local dir = fs.join(pkg.pkgdir, "bin")

    if fs.is_dir(dir) then
      local dirs = fs._list_all(dir)

      if #dirs == 1 then
        local i = next(dirs)
        local bin_name = fs.join(pkg.pkgdir, dirs[i])

        if fs.attributes(bin_name, "mode") == "file" then
          pkg.bin_name = M.bin_name_parser(bin_name)
          pkg.bin_path = bin_name
        end
      end

      local file = fs.join(pkg.pkgdir, "bin", pkg.name)

      if fs.is_file(file) then
        pkg.bin_name = pkg.name
        pkg.bin_path = file
      end
    end
  end

  return pkg
end

function M.get_bin_name(pkg)
  local dir = fs.join(pkg.pkgdir, "bin")

  if not fs.is_dir(dir) then
    return nil
  end

  local dirs = fs._list_all(dir)

  if #dirs == 1 then
    local i = next(dirs)
    local bin_name = fs.join(pkg.pkgdir, dirs[i])

    if fs.attributes(bin_name, "mode") == "file" then
      return M.bin_name_parser(bin_name)
    end
  end

  local file = fs.join(pkg.pkgdir, "bin", pkg.name)

  if fs.is_file(file) then
    return pkg.name
  end

  return nil
end

function M.bin_name_parser(name)
  return (name and name:match ".+/([^/]+)$") or name
end

function M.get_source_code(pkg)
  -- local dir = pkg.INSTALLATION_DIRECTORY

  -- TODO: add git suporte

  local url = M.replace(pkg.url, { name = pkg.name, version = pkg.version })

  local file = pkg.file_name or url:gsub("/$", ""):match ".*/(.*)$"

  log.info(("Downloading %s from %s"):format(file, url))
  local ok, _ = pcall(curl.download, url, file)

  if not ok then
    log.err("Error trying to download file: " .. url)
  end

  if pkg.hash then
    log.info "Starting a SHA1 check..."
    local sha1 = fn.sha1(file)
    if sha1 ~= pkg.hash then
      log.err "SHA1 of the files is different. It is not safe to continue the installation."
    end
  end

  local _ok, _ = fs.extract(file, pkg.compression_format)

  local soure_file = fs.is_file(file)

  if soure_file then
    pkg.source_file = soure_file
  end

  if _ok == false then
    log.err("Error trying to extract file: " .. file)
  end

  if _ok then
    fs.rm(file)
  end

  local dirs = fs._list_all(pkg.pkgdir)

  if #dirs == 1 then
    local i = next(dirs)
    local source_dir = fs.join(pkg.pkgdir, dirs[i])

    if fs.attributes(source_dir, "mode") == "directory" then
      fs.cd(source_dir)
      pkg.source_dir = source_dir
    end
  end

  return pkg
  -- fs.rm(dir .. "/" .. file)
end

function M.create_links(pkg)
  if not fs.is_dir(PKGER_BIN) then
    log.err "Couldn't get the directory for bin."
  end

  local dir = pkg.pkgdir

  if pkg.bin_name then
    local bin_path = fs.join(dir, pkg.bin_path)
    local dest_path = fs.join(PKGER_BIN, pkg.bin_name)

    local ok, msg = fs.link(bin_path, dest_path, true)

    if not ok then
      log.err("Error creating symbolic link to bin: " .. bin_path .. ". Error: " .. msg)
    end
  end

  local opt_name = pkg.bin_name or pkg.name

  local opt_dest_path = fs.join(PKGER_OPT, opt_name)

  local _ok, _msg = fs.link(dir, opt_dest_path, true)

  if not _ok then
    log.err("Error creating symbolic link to opt: " .. dir .. ". Error: " .. _msg)
  end

  --TODO: lib, include

  -- TODO: usar test
end

function M.show(pkg)
  local manteiners = type(pkg.manteiners) == "table" and table.concat(pkg.manteiners, ", ") or pkg.manteiners or "nil"
  local license = type(pkg.license) == "table" and table.concat(pkg.license, ", ") or pkg.license or "nil"
  local bar =
    c.red "───────────────────────────────────────"

  fn.print(fn.f(
    [[
%s
package: %s
description: %s
version: %s
sha1: %s
license: %s
manteiners: %s
homepage: %s
%s]],

    bar,
    c.green(pkg.name),
    c.cyan(pkg.description),
    c.cyan(pkg.version),
    c.cyan(pkg.hash or "nil"),
    c.blue(license),
    c.yellow(manteiners),
    c.blue(pkg.homepage),
    bar
    -- pkg.script_infos.url
  ))
end

function M.prefix(name, version)
  local pkg

  if not version or version == PKGER_SCRIPT_VERSION then
    pkg = M.get_current_pkg(name)
  else
    pkg = M.get_pkg_infos(name, version)
  end

  return pkg and pkg.prefix or nil
end

-- todo add @ suporte
function M.pkg(n)
  local infos = {}

  local pkg = M.parse { n }

  local name = next(pkg)
  local version = pkg[name]

  if version == PKGER_SCRIPT_VERSION then
    infos = M.get_current_pkg(name)
  else
    infos = M.get_pkg_infos(name, version)
  end

  if not infos then
    return {}
  end

  return {
    prefix = infos.prefix,
    bin_name = infos.bin_name,
    is_libary = infos.is_libary,
    version = infos.version,
    pkgdir = infos.pkgdir,
    file = infos.file,
    -- pkgetc = infos.pkgetc,
    -- pkgshare = infos.pkgshare,
    -- pkginclude = infos.pkginclude,
  }
end

-- setmetatable(M.pkg, {
--   __index = function(_, name)
--     local infos = M.get_current_pkg(name)

--     if not infos then
--       return {}
--     end

--     return {
--       prefix = infos.prefix,
--       bin_name = infos.bin_name,
--       INSTALLATION_DIRECTORY = infos.INSTALLATION_DIRECTORY,
--       version = infos.version,
--     }
--   end,
-- })

return M
