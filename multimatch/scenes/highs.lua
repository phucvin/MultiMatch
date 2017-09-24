
local highs = {}
highs.__index = highs

function highs:init()
	self.gui = GUI.new()
	self.gui.ox = 0
	self.gui:addButton('Back', -40, 540, 200, 60, function(btn) self:gotoMenu() end)

	self.board = Thing.new()
	self.board.ox = 0
	local highScores = Saved.instance():get('highScores')
	--get the current score of continue if there is
	local continueScore = Saved.instance():get('continue')
	local continueModeName = nil
	if continueScore then
		continueModeName = continueScore.mode.name
		continueScore = continueScore.score
	end
	--deal with highScores first
	--sort it and save in to a different table
	--we dont modify the highScores
	local sorted = {}
	for k, l in pairs(highScores) do
		sorted[k] = {}
		for i = 1, #l, 1 do
			sorted[k][i] = l[i]
		end

		local current = sorted[k]
		for i = 1, #l-1, 1 do
			for j = i + 1, #l, 1 do
				if current[i].score <= current[j].score then
					current[i], current[j] = current[j], current[i]
				end
			end
		end

		--insert the current score of unfinish game to the list
		if continueModeName == k then
			for i = #current, 0, -1 do
				if i == 0 or (i > 0 and continueScore < current[i].score) then
					table.insert(current, i+1, {name = Saved.instance():get('playerName'), score = continueScore, isContinue = true})
					break
				end
			end
		end
	end

	self.board.draw = function (self)
		g.push()
		g.translate(self.ox, 0)
		g.setColor(0, 0, 0, 200)
		g.rectangle('fill', 10, 10, 940, 520)
		g.setColor(255, 255, 255, 200)
		g.setLineWidth(3)
		g.line(310, 30, 310, 520)
		g.line(640, 30, 640, 520)

		--a function for short code
		local drawCol = function (name, list, ox, w)
			g.setColor(255, 255, 255)
			g.setFont(content.fonts.highsTittle)
			g.printf(name, ox, 20, w, 'center')
			for i = 1, 15, 1 do
				--convert 1 -> 01, 12 -> 12
				local ii = tostring(i)
				if ii:len() == 1 then ii = '0'..ii end

				if list[i] then
					--convert 188900 -> 188,900
					local s = tostring(list[i].score)
					s = string.sub(s, -9, -7) .. ',' .. string.sub(s, -6, -4) .. ',' .. string.sub(s, -3)
					if list[i].score < 1000 then s = s:sub(-#s+2)
					elseif list[i].score < 1000000 then s = s:sub(-#s+1) end


					if list[i].isLast or list[i].isContinue then
						if list[i].isLast then g.setColor(255, 0 , 0)
						else g.setColor(0, 255, 0) end
						g.setLineWidth(2)
						g.rectangle('line', ox-2, 70 + 30*(i-1) - 4, w-20 + 4, 20+8)
					end
					g.setColor(255, 255, 255)
					g.setFont(content.fonts.highsItem)
					g.printf(ii..'.'..list[i].name, ox, 70 + 30*(i-1), w-20, 'left')
					g.printf(s, ox, 70 + 30*(i-1), w - 20, 'right')
				else
					g.setColor(255, 255, 255)
					g.setFont(content.fonts.highsItem)
					g.printf(ii..'.', ox, 70 + 30*(i-1), w-20, 'left')
				end
			end
		end

		--easy col
		drawCol('Easy', sorted.easy, 20, 300)
		--normal col
		drawCol('Normal', sorted.normal, 320, 330)
		--hard col
		drawCol('Hard', sorted.hard, 650, 300)
		g.pop()
	end

	self:moveIn()
end

function highs:moveIn()
	self.gui:seq(function ()
	self.board:seq(function ()
	stween(self.board, 1, {ox = self.board.ox}, {ox = self.board.ox + g.getWidth()})
	end)
    stween(self.gui, 1, {ox = self.gui.ox}, {ox = self.gui.ox - 200})
    end)
end

function highs:moveOut(after)
	self.gui:seq(function ()
	self.board:seq(function ()
	stween(self.board, 1, {ox = self.board.ox + g.getWidth()})
	end)
    stween(self.gui, 1, {ox = self.gui.ox - 200})
    if after then after() end
    end)
end

function highs:gotoMenu()
	self:moveOut(function () director.changeScene('menu') end)
end

director.addScene('highs', function (...) setmetatable({}, highs):init(...) end)