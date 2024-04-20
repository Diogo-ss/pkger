local fs = require "utils.fs"

print()

print(fs.cd(fs.cwd() .. "/test"))

print(fs.extract "nvim-linux64.tar.gz")
