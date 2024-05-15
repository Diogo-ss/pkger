local rep = string.rep
local format = string.format

local bar = {}

function bar:new(length)
  return setmetatable({
    length = length or 30,
    filled_char = "■",
    empty_char = "-",
    progress = 0,
    done = false,
    max = 100,
    info = "",
  }, { __index = self })
end

function bar:print(...)
  io.write("\027[2K\r", ...)
  io.flush()
end

function bar:update(info, progress)
  self.info = info or self.info
  self.progress = progress or self.progress
  self:render()
end

function bar:render()
  local filled_length = math.floor(self.length * self.progress / 100)
  local empty_length = self.length - filled_length

  local bar_str = format(
    "%s [%s%s] %.2f%% ",
    self.info,
    rep(self.filled_char, filled_length),
    rep(self.empty_char, empty_length),
    self.progress
  )

  if self.done then
    return
  end

  if self.progress == self.max then
    bar_str = bar_str .. "\n"
    self.done = true
  end

  self:print(bar_str)
end

return bar
