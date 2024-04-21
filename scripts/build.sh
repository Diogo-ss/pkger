#!/usr/bin/env bash

set -eu

# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# brew install lua luarocks
# luarocks install luastatic
# luastatic main.lua $(brew --prefix lua)/lib/liblua.a -I$(brew --prefix lua)/include/lua

echo -n "Version: " && grep -o 'PKGER_VERSION = "[^"]*"' src/core/global.lua | cut -d '"' -f 2

cd src

luastatic main.lua $(find . -type f -name "*.lua") $(brew --prefix lua)/lib/liblua.a -I$(brew --prefix lua)/include/lua -o pkger

rm init.luastatic.c
mv pkger ../
