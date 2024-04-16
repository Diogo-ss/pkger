local function clearLineAndPrint(text)
	io.write("\027[2K\r") -- Limpa a linha e retorna ao início
	io.write(text)
	io.flush()
end

local function moveCursorToNextLine()
	io.write("\n") -- Move o cursor para a próxima linha
	io.flush()
end

local function create(length)
	local bar = {
		length = length,
		filledChar = "■",
		emptyChar = "-",
		percentageWidth = 6,
		percentageSymbol = "%",
		currentProgress = 0,
	}

	function bar:update(info, progress)
		self.currentProgress = math.max(0, math.min(1, progress))
		self:render(info)
	end

	function bar:print(text)
		clearLineAndPrint(text)
		moveCursorToNextLine()
		self:render()
	end

	function bar:render(info)
		local filledLength = math.floor(self.currentProgress * self.length)
		local emptyLength = self.length - filledLength

		local progressBarStr = "["
			.. string.rep(self.filledChar, filledLength)
			.. string.rep(self.emptyChar, emptyLength)
			.. "] "
			.. string.format("%.2f", self.currentProgress * 100)
			.. self.percentageSymbol

		if info then
			progressBarStr = info .. " " .. progressBarStr
		end

		clearLineAndPrint(progressBarStr)
	end

	return bar
end

return { create = create }
