local pkg = require "src.core.pkg"
local c = require "src.utils.colors"
local log = require "src.utils.log"
local fn = require "src.utils.fn"

local M = {}

function M.parser(args)
  fn.print(pkg.list_packages())

  -- fn.print(pkg.get_pkg_infos("neovim", "0.9.5"))

  -- local pkgs = pkg.list_packages()

  -- for _, _pkg in pairs(pkgs) do
  --   log(fn.inspect(_pkg))
  -- end
end

return M
