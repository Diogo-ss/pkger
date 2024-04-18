local filter = require "utils.filter"
local fn = require "utils.fn"

-- local env = {
--   bot = {
--     update = {
--       ignore = true
--     }
--   },

--   ["9.0.1"] = {
--     vulnerable = false,
--     commit = "kkk",
--     -- url = "kkkk",
--     stable = true,
--     avaliabe = false,
--     note = "kkkkkkkkk"
--   },
-- }

-- fn.print(filter.lock(env))

local pkg = {
  version = "9.0.1",
  description = "kkkkkkkkkkk",
  homepage = "kkkkkkk",
  license = "sual icen",
  manteiners = { "Diogo-ss" },
  -- manteiners = {"Diogo-ss"},
  -- url = "kkkkk",
  -- hash = "903i459023askdfj",
  url = "kkkkk.git",
  -- branch = "main",
  conflicts = { "kkkkkk" },
  depends = { "sakfj", "ksakdfj" },
  make_depends = { "oasflk", "aslkfj" },
  checkver = {
    url = "Kkk",
    jsonpath = "aslfj",
    regex = "kjasldfj",
  },
}

fn.print(filter.pkg(pkg))

-- local repo = {
--   manteiners = { "Diogo-ss" },
--   template = {
--     lock = "kkkk",
--     pkg = "kaskdfj",
--   }
-- }

-- fn.print(filter.repo(repo))
