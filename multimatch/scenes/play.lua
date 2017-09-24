
local play = {}
play.__index = play

function play:init(isContinue, mode)
	Background.instance():seq(function ()
    wait(0.2)
    love.audio.newSource(content.sounds.voices.go):play()
    end)

    self.isContinue = isContinue
    self.mode = mode

    --gui that show scores, turns left, and menu button
    self.gui = GUI.new()
    self.gui.zOrder = content.layers.gui
    self.gui:addText('MultiMatch', 32, 32, 288, 50, content.fonts.smallTittle)
    self.txtScore = self.gui:addText(LevelManager.instance():getScore(), 80, 82, 192, 40, content.fonts.score)
    if mode.isChallenge then
    	self.txtTurnsLeft = self.gui:addText(LevelManager.instance():getTurnsLeft(), 96, 122, 160, 30, content.fonts.turnsLeft)
    	self.txtLevel = self.gui:addText(LevelManager.instance():getLevel(), 144, 300, 64, 64, content.fonts.level)
    else
        self.txtFunHighest = self.gui:addText(Saved.instance():get("funHighest"), 96, 122, 160, 30, content.fonts.funHighest)
    end
    self.gui:addButton('Menu', 128, 560, 96, 40, function () self:gotoMenu() end)
    --update the value of 2 texts
    self.gui:seq(function ()
    local prevScore = LevelManager.instance():getScore()
    while true do
    	--animating the score
    	local score = LevelManager.instance():getScore()
    	if prevScore < score then prevScore = prevScore + math.max(1, math.floor((score - prevScore)/50)) end
    	if prevScore > score then prevScore = score end
    	
    	--make the score easy to read, ex: 56887 -> 56,887
    	local a = prevScore
    	local s = tostring(a)
    	s = string.sub(s, -9, -7) .. ',' .. string.sub(s, -6, -4) .. ',' .. string.sub(s, -3)
    	if a < 1000 then s = s:sub(-#s+2)
    	elseif a < 1000000 then s = s:sub(-#s+1) end

    	--update
    	self.txtScore.text = s
    	if mode.isChallenge then self.txtTurnsLeft.text = LevelManager.instance():getTurnsLeft()
        else
            a = Saved.instance():get('funHighest')
            s = tostring(a)
            s = string.sub(s, -9, -7) .. ',' .. string.sub(s, -6, -4) .. ',' .. string.sub(s, -3)
            if a < 1000 then s = s:sub(-#s+2)
            elseif a < 1000000 then s = s:sub(-#s+1) end
            self.txtFunHighest.text = s
        end
    	yield()
    end
    end)
    --effecting the gui go in, if need
    if LevelManager.instance():getLevel() == 1 or LevelManager.instance():getMode().isChallenge == false or isContinue then
		self:moveIn()
	end

    --a function that will be call when the board is ended in lose
    local onBoardOut = function ()
    	self:moveOut()
    end

	Board.new(isContinue, mode, onBoardOut)
end

function play:moveIn()
    self.gui:seq(function ()
    stween(self.gui, 1, {ox = self.gui.ox}, {ox = self.gui.ox - 400})
    end)
end

function play:moveOut(after)
    self.gui:seq(function ()
    stween(self.gui, 1, {ox = self.gui.ox - 400})
    if after then after() end
    end)
end

function play:gotoMenu()
    if self.mode.isChallenge then
        self.gui:seq(function ()
        while not Board.instance():isAvaiable() do yield() end
        local continue = Board.instance():getSavedTable()
        for k, v in pairs(LevelManager.instance():getSavedTable()) do
            continue[k] = v
        end
        Saved.instance():set('continue', continue)
        Board.instance():moveOut()
        self:moveOut(function () director.changeScene('menu') end)
        end)
    else
        Board.instance():moveOut()
        self:moveOut(function () director.changeScene('menu') end)
    end
end

director.addScene('play', function (...) setmetatable({}, play):init(...) end)