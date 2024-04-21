#!/usr/bin/env bash

set -eu

echo -n "Version: " && grep -o 'PKGER_VERSION = "[^"]*"' src/core/global.lua | cut -d '"' -f 2

if ! command -v brew &>/dev/null; then
    echo "Homebrew is not installed. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v luarocks &>/dev/null; then
    echo "Luarocks is not installed. Installing..."
    brew install lua luarocks
fi

if ! command -v luastatic &>/dev/null; then
    luarocks install luastatic
fi

cd src

luastatic main.lua $(find . -type f -name "*.lua") $(brew --prefix lua)/lib/liblua.a -I$(brew --prefix lua)/include/lua -o pkger

rm main.luastatic.c
mv pkger ../
