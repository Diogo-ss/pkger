LUASTATIC := luastatic
LUASTATIC_C := main.luastatic.c
OUTPUT_DIR := bin

SRC_DIR := src
MAIN_FILE := $(SRC_DIR)/main.lua
PKGER_VERSION := $(shell grep -o 'PKGER_VERSION = "[^"]*"' $(SRC_DIR)/core/global.lua | cut -d '"' -f 2)

LUADIR := $(shell brew --prefix lua)
LUAINCLUDE := $(LUADIR)/include/lua
LUALIB := $(LUADIR)/lib/liblua.a
OUTPUT := $(OUTPUT_DIR)/pkger

all: version build

version:
	@echo "Version: $(PKGER_VERSION)"

build:
	@mkdir -p $(OUTPUT_DIR)
	$(LUASTATIC) $(MAIN_FILE) $(shell find $(SRC_DIR) -type f -name "*.lua") $(LUALIB) -I$(LUAINCLUDE) -o $(OUTPUT)

clean:
	rm -f $(LUASTATIC_C)

.PHONY: all version build clean
