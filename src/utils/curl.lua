local curl = require "lcurl"
local bar = require "utils.bar"

local M = {}

-- local csize = M.easy:getinfo(curl.INFO_SIZE_DOWNLOAD)
-- local total_size = M.easy:getinfo(curl.INFO_CONTENT_LENGTH_DOWNLOAD)

function M.download(url, output_file)
  local f = io.open(output_file, "wb")
  local dbar = bar.create(30)

  local function write_function(str)
    f:write(str)
    return #str
  end

  local function progress_function(dltotal, dlnow)
    local progress = math.floor(dlnow / dltotal * 10000) / 100

    if progress >= 0 then
      dbar:update("Download: ", progress / 100)
    end
  end

  local easy = curl.easy {
    url = url,
    writefunction = write_function,
    followlocation = true,
    noprogress = false,
    progressfunction = progress_function,
  }

  easy:perform()

  f:close()
  easy:close()

  return true
end

function M.get(url)
  local data = {}

  local easy = curl.easy {
    url = url,
    writefunction = function(str)
      table.insert(data, str)
      return #str
    end,
  }

  easy:perform()
  easy:close()

  return table.concat(data)
end

return M
