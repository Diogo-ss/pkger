local log = require "src.utils.log"
local lpkg = require "src.core.pkg"
local fn = require "src.utils.fn"
local fs = require "src.utils.fs"

local M = {}

local function __check_all_pkg()
  fs.each(fs.join(PKGER_DATA, "*"), function(pkg_dir)
    if fs.is_dir(pkg_dir) then
      local main_pkg_file = fs.join(pkg_dir, PKGER_DOT_PKG)
      if fs.is_file(main_pkg_file) then
        local ok, main_pkg = pcall(dofile, main_pkg_file)

        if not ok then
          log.error(("%s has loading problems: %s"):format(PKGER_DOT_PKG, main_pkg_file))
          return
        end

        local keys = {
          "bin_name",
          "created_at",
          "dir",
          "file",
          "name",
          "pinned",
          "pkger_version",
          "prefix",
          "version",
        }

        local r = false
        for _, key in pairs(keys) do
          if not main_pkg[key] then
            log.error(("%s field does not exist in the %s"):format(key, main_pkg_file))
            r = true
          end
        end
        if r then
          return
        end

        if not fs.is_dir(main_pkg.dir) then
          log.error(("The directory indicated by %s does not exist: %s"):format(PKGER_DOT_PKG, main_pkg.dir))
          return
        end

        if not fs.is_file(main_pkg.prefix) then
          log.error(
            ("The executable indicated by %s in the file does not exist: %s"):format(PKGER_DOT_PKG, main_pkg.prefix)
          )
          return
        end

        if not fs.is_file(fs.join(PKGER_BIN, main_pkg.bin_name)) then
          log.error(("Symbolic link to %s@%s doesn't exist."):format(main_pkg.name, main_pkg.version))
          return
        end

        local file = fs.join(PKGER_DATA, main_pkg.name, main_pkg.version, PKGER_DOT_INFOS)
        if not fs.is_file(file) then
          log.error(("%s does not exist in the package: %s"):format(PKGER_DOT_INFOS, main_pkg.name))
          return
        end
      end
    end
  end, {
    delay = true,
    recurse = false,
  })
end

local function __list_all(path)
  local all = {}

  fs.each(fs.join(path, "*"), function(P)
    table.insert(all, P)
  end, {
    delay = true,
    recurse = true,
  })

  return all
end

function M.check(args, flags)
  __check_all_pkg()
  -- fn.print(__list_all(PKGER_DATA))

  -- local all = __list_all(PKGER_DATA)

  -- for _, path in pairs(all) do
  --   if fs.is_file(path) then
  --     log.warn("File in the data folder, not safe: " .. path)
  --   end

  --   if fs.is_dir(path) then
  --     local _all = __list_all(path)

  --     for _, _path in pairs(_all) do
  --       -- TODO: add .pkg in list
  --       if fs.is_file(_path) then
  --         log.warn("File in the data folder, not safe: " .. _path)
  --       end
  --     end

  --   end
  -- end
end

function M.parser(args, flags)
  local ok, _ = pcall(M.check, args, flags)
  print(_)
end

return M
