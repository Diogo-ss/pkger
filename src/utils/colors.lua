local colors = {
  reset = "\27[0m",
  black = "\27[30m",
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  magenta = "\27[35m",
  cyan = "\27[36m",
  white = "\27[37m",
}

return setmetatable({}, {
  __index = function(_, name)
    return function(text)
      return colors[name] .. text .. colors.reset
    end
  end,
})
