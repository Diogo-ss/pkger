local curl = require "utils.curl"

curl.download("https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-linux64.tar.gz", "nvim.gz")
