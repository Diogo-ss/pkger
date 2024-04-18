local path = require "path"

local M = {}

M.cwd = path.currentdir

M.normalize = path.normalize

M.mkdir = path.mkdir

M.rm_dir = path.rmdir

M.cd = path.chdir

M.exists = path.exists

M.is_dir = path.isdir

M.is_file = path.isfile

M.is_link = path.islink

M.rm = path.remove

M.join = path.join

M.home = path.user_home

M.cp = path.copy

M.mv = path.move

M.size = path.size

M.SEP = path.DIR_SEP

M.each = path.each

return M
