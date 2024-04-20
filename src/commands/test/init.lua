local fs = require "utils.fs"

print()

print(fs.cwd())
print(fs.extract("nvim-linux64.tar.gz", "gz"))
