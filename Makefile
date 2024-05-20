LUASTATIC := luastatic
LUASTATIC_C := main.luastatic.c
OUTPUT_DIR := bin

SRC_DIR := src
PKGER_VERSION := $(shell grep -o 'PKGER_VERSION = "[^"]*"' $(SRC_DIR)/core/global.lua | cut -d '"' -f 2)
MAIN_FILE := $(SRC_DIR)/main.lua

LUADIR := lua
LUAINCLUDE := $(LUADIR)/include
LUALIB := $(LUADIR)/liblua54.a
OUTPUT := $(OUTPUT_DIR)/pkger

LUA_TAR := lua-5.4.2_Linux54_64_lib.tar.gz
LUA_URL := https://sourceforge.net/projects/luabinaries/files/5.4.2/Linux%20Libraries/lua-5.4.2_Linux54_64_lib.tar.gz/download

all: version install-lib build

version:
	@echo "Version: $(PKGER_VERSION)"

install-lib:
	@mkdir -p $(LUADIR)

	if [ ! -f $(LUADIR)/$(LUA_TAR) ]; then \
		wget $(LUA_URL) -O $(LUADIR)/$(LUA_TAR); \
	fi

	@tar -xf $(LUADIR)/$(LUA_TAR) -C $(LUADIR)

build:
	@mkdir -p $(OUTPUT_DIR)
	$(LUASTATIC) $(MAIN_FILE) $(shell find $(SRC_DIR) -type f -name "*.lua") $(LUALIB) -I$(LUAINCLUDE) -o $(OUTPUT)

clean:
	rm -f $(LUASTATIC_C)

.PHONY: all version install-lib build clean
