local curl = require "lcurl"
local bar = require "src.utils.bar"
local c = require "src.utils.colors"

local M = {}

-- local csize = M.easy:getinfo(curl.INFO_SIZE_DOWNLOAD)
-- local total_size = M.easy:getinfo(curl.INFO_CONTENT_LENGTH_DOWNLOAD)

function M.download(url, output_file)
  local ok, f = pcall(io.open, output_file, "wb")

  if not (ok or f) then
    error("Error trying to open: " .. output_file)
  end

  local dbar = bar:new(30)

  local function write_function(str)
    f:write(str)
    return #str
  end

  local function progress_function(dltotal, dlnow)
    local progress = dlnow / dltotal * 100

    if progress >= 0 then
      dbar:update("Download:", progress)
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
    error("Request error: " .. code)
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
