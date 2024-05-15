local curl = require "lcurl"
local bar = require "src.utils.bar"
local c = require "src.utils.colors"
local log = require "src.utils.log"

local M = {}

function M.download(url, output_file)
  local ok, f = pcall(io.open, output_file, "wb")

  if not ok or not f then
    log.err("Error trying to open: " .. output_file)
  end

  local dbar = bar:new(30)

  local function write_function(str)
    f:write(str)
    return #str
  end

  local function progress_function(total, downloaded)
    local downloaded_mb = downloaded / 1024 / 1024
    local total_mb = total / 1024 / 1024

    if total > 0 then
      local progress = downloaded / total * 100
      local info = string.format("Download: %.2fMB/%.2fMB", downloaded_mb, total_mb)
      dbar:update(info, progress)
    end
  end

  local easy = curl.easy {
    url = url,
    writefunction = write_function,
    followlocation = true,
    noprogress = false,
    httpheader = {
      "User-Agent: test PKGER/" .. PKGER_VERSION,
    },
    progressfunction = progress_function,
  }

  easy:perform()

  local code = easy:getinfo(curl.INFO_RESPONSE_CODE)

  if code ~= 200 then
    log.err(string.format("Request error (%s): %s", url, code))
  end

  f:close()
  easy:close()

  return output_file
end

function M.get(url)
  local data = {}

  local easy = curl.easy {
    url = url,
    httpheader = {
      "User-Agent:" .. PKGER_USER_AGENT,
    },
    writefunction = function(str)
      table.insert(data, str)
      return #str
    end,
  }

  easy:perform()
  local code = easy:getinfo(curl.INFO_RESPONSE_CODE)

  easy:close()

  return code, table.concat(data)
end

function M.get_content(url)
  local code, data = M.get(url)

  if code == 200 then
    return data
  end

  return nil
end

return M
