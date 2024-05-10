local HOME = os.getenv "HOME"
local sys = require "src.utils.sys"

PKGER_PREFIX = HOME .. "/.local/pkger"
PKGER_VERSION = "0.1.0"

PKGER_BIN = PKGER_PREFIX .. "/bin"
PKGER_ETC = PKGER_PREFIX .. "/etc"
PKGER_LIB = PKGER_PREFIX .. "/lib"
PKGER_DATA = PKGER_PREFIX .. "/data"
PKGER_CACHE = HOME .. "/.cache/pkger"
PKGER_LOCKED = PKGER_PREFIX .. "/lock"
PKGER_CONFIG = HOME .. "/.config/pkger"
PKGER_TMP_DIR = PKGER_PREFIX .. "/tmp"
PKGER_USER_AGENT = ("PKGER/%s (%s; %s %s)"):format(PKGER_VERSION, _VERSION, sys.os, sys.arch)
PKGER_REPOS_FILE = PKGER_CONFIG .. "/repos"
PKGER_CONFIG_FILE = PKGER_CONFIG .. "/config.lua"
-- PKGER_MODULES = PKGER_PREFIX .. "/modules"
-- PKGER_INSTANCE =
