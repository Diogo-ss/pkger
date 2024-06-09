#!/usr/bin/env bash

set -eu

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

eval "$(luarocks path --bin)"

# echo -n "Version: " && grep -o 'PKGER_VERSION = "[^"]*"' src/core/global.lua | cut -d '"' -f 2

make
