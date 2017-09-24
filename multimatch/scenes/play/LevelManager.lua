
LevelManager = {}
LevelManager.__index = LevelManager

local instance = nil

function LevelManager.new(mode)
	instance = {}
	setmetatable(instance, LevelManager)

	instance.mode = mode
	if mode.isChallenge then
		instance.level = 1
	else
		instance.level = 0
	end
	instance.score = 0
	instance.turns = 0

	return instance
end

function LevelManager.instance()
	return instance
end

function LevelManager:continue(continue)
	self.mode = continue.mode
	self.level = continue.level
	self.score = continue.score
	self.turns = continue.turns
end

function LevelManager:addScore(atDepth, totalGems)
	if totalGems > 6 then totalGems = 6 + (totalGems - 6)*2 end
	self.score = self.score + (atDepth-1)*100 + totalGems*10*atDepth
	
	--next level just for challenge mode
	if self.mode.isChallenge then self:checkForNextLevel() end
end

--add turn must be call at the end of sequence of explosions
--when all effects are done
function LevelManager:addTurn()
	self.turns = self.turns + 1

	--game over just for challenge mode
	if self.mode.isChallenge then self:checkForGameOver() end
end

function LevelManager:getScore()
	return self.score
end

function LevelManager:setScore(score)
	self.score = score
end

function LevelManager:getLevel()
	return self.level
end

function LevelManager:getMaxTurns()
	return self.mode.maxTurns
end

function LevelManager:getTurnsLeft()
	if self.mode.isChallenge then
		return self:getMaxTurns() - self.turns
	else
		return 0
	end
end

function LevelManager:getLevelRatio()
	if self.mode.isChallenge then
		local x = (self.score - (self.level-1)*(self.mode.baseScore + (self.level-2)*0.5*self.mode.increasingScore))/(self.mode.baseScore + self.mode.increasingScore*(self.level-1))
		return x
	else
		return 1
	end
end

function LevelManager:getMode()
	return self.mode
end

function LevelManager:getNextScore()
	if self.mode.isChallenge then
		return self.level*(self.mode.baseScore + (self.level-1)*0.5*self.mode.increasingScore)
	else
		return 0
	end
end

--just use in challenge mode
function LevelManager:checkForNextLevel()
	if self.score >= self:getNextScore() then
		--end board in win way
		Board.instance():endBoard(true, function ()
			--find the leve that suitable with the score
			while self.score >= self:getNextScore() do self.level = self.level + 1 end
			self.turns = 0 --reset the amount of turns to zero for a new level
			--restart the play scene, but but level manger remains, so next level is comming
			director.changeScene('play', false, self.mode)
		end)
	end
end

--just use in challenge mode
function LevelManager:checkForGameOver()
	if self.turns >= self:getMaxTurns() then
		--end board in lose way
		Board.instance():endBoard(false, function ()
			--do some stuff with saved
			local saved = Saved.instance()
			--remove the continue because this continue is finished now
			saved:set('continue', nil)
			--remove the  high scores that mark isLast because there is a new last high score now
			for k, l in pairs(saved:get('highScores')) do
				for i = 1, #l, 1 do
					if l[i].isLast then l[i].isLast = nil end
				end
			end
			table.insert(saved:get('highScores')[self.mode.name], {name = saved:get('playerName'), score = self.score, isLast = true})


			--change scene to high scores
			director.changeScene('highs')
		end)
	end
end

function LevelManager:getSavedTable()
	return {mode = self.mode, level = self.level, score = self.score, turns = self.turns}
end