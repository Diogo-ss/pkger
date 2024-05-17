#!/usr/bin/env bash

set -eu

echo -n "Version: " && grep -o 'PKGER_VERSION = "[^"]*"' src/core/global.lua | cut -d '"' -f 2

if ! command -v brew &>/dev/null; then
    echo "Homebrew is not installed."
    exit 1
    # /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v luarocks &>/dev/null; then
    echo "Luarocks is not installed."
    exit 1
fi

if ! command -v luastatic &>/dev/null; then
    if ! luarocks install luastatic; then
        echo "Failed to install luastatic."
        exit 1
    fi
fi

SRC_DIR="src"

luastatic "$SRC_DIR/main.lua" $(find "$SRC_DIR" -type f -name "*.lua") "$(brew --prefix lua)/lib/liblua.a" -I"$(brew --prefix lua)/include/lua" -o "pkger"
