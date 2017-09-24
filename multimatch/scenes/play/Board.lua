
Board = {}
Board.__index = Board

local instance = nil

function Board.new(isContinue, mode, onOut)
	if instance and instance:alive() then return instance end

    instance = Thing.new({'board'}):extend(Board)
    instance.zOrder = content.layers.board

    instance.isContinue = isContinue
    local continue = nil
    if isContinue then continue = Saved.instance():get('continue') end
    instance.mode = mode

    instance.ox = 352 --board's origin position
    instance.oy = 32
    instance.nRows = 8 --numbers of rows and columns of board
    instance.nCols = 8
    instance.cellSize = 72 --a cell's size (in pixel)
    instance.nKinds = mode.nKinds --number of kinds that gems have
    instance.minGemsToExplode = 3 --minimum amount of gems in same kind that stand next to others needs to be explode

    --special of this game
    instance.maxSwapBeforeExplode = 3
    instance.nSwaped = 0
    if isContinue then instance.nSwaped = continue.swaps end

    instance.gird = {}
    instance.gird.kinds = {} --gird of kinds (in number)
    if isContinue then instance.gird.kinds = continue.girdKinds end
    instance.gird.gems = {} --gird of gems (Thing)
    instance.gird.booms = {} --gird of marking for booming (boolean)
    local gk = instance.gird.kinds
    local gg = instance.gird.gems
    local gb = instance.gird.booms
    for i = 1, instance.nRows, 1 do
    	if not isContinue then gk[i] = {} end
    	gg[i] = {}
    	gb[i] = {}
    	--init the first face of the board
    	--create gems and save it to gird.gems
    	for j = 1, instance.nCols, 1 do
    		--make gems don't make explode at beginning
    		if not isContinue then
	    		local top = -1
	    		local left = -1
	    		if i > 2 and gk[i-1][j] == gk[i-2][j] then top = gk[i-1][j] end
	    		if j > 2 and gk[i][j-1] == gk[i][j-2] then left = gk[i][j-1] end
	    		repeat gk[i][j] = math.random(1, instance.nKinds) until gk[i][j] ~= top and gk[i][j] ~= left
	    	end

    		--create gems, but at the position above the board, for effect falling later
    		gg[i][j] = Gem.new(instance.ox + instance.cellSize*(j-0.5), instance.oy + instance.cellSize*(i-0.5-instance.nRows) - 100, gk[i][j])
    		--hide the gems first
    		gg[i][j]:setDraw(false)
    		gb[i][j] = false
    	end
    end

    instance.canSwap = false --flag about user can swap gems at this momment or not, at init is is false
    instance.swap = nil --save the setup for current swap, include where is these gems needs to swap

    instance.boardFactor = 0 --a factor(0..1) that help the board explain the excited of the exploed sequence
    instance.boardShake = 2 --the shaking value (in pixel) of the board when the progress (levelRatio) is overload (>1)

    --the progress of current level
    instance.levelRatio = 0

    --flag about show swaps left
    instance.isShowSwapsLeft = false
    --the cursor that show the numbers of swaps left
    local cursor = Thing.new()
    cursor.zOrder = content.layers.cursor
    cursor.draw = function ()
    	if instance.isShowSwapsLeft then
    		local mx, my = love.mouse.getPosition()
    		g.setColor(0, 255, 255, 150)
    		g.draw(content.images.boardCursor.img, mx - content.images.boardCursor.hw, my - content.images.boardCursor.hh)
    		g.setColor(0, 0, 0)
    		g.setFont(content.fonts.movesLeft)
    		if instance.canSwap then
    			g.printf(instance.maxSwapBeforeExplode - instance.nSwaped, mx, my-12, 0, 'center')
    		else
    			g.printf('X', mx, my-12, 0, 'center')
    		end
    	end
	end

	--a function that play scene have add to make this board notice when it's go out
	instance.onOut = onOut

    --setup listeners
    listener.add('mousepressed', 'l', function (x, y) instance:onStartSwap(x, y) end)
    listener.add('mousereleased', 'l', function (x, y) instance:onEndSwap(x, y) end)
    --just for testing, disable if not need
    --listener.add('keypressed', ' ', function () instance:explode(1) end)
    listener.add('keypressed', 'f1', function () instance:showBestMove() end)

    --setup done
    --do some effects
    instance:performStartEffect()

    return instance
end

function Board.instance()
	return Board.new()
end

function Board:always()
	--check if mouse in over the board
	local mx, my = love.mouse.getPosition()
	if mx >= self.ox and mx <= self.ox + self.nCols*self.cellSize and
	   my >= self.oy and my <= self.oy + self.nRows*self.cellSize then
	   	love.mouse.setVisible(false)
	   	self.isShowSwapsLeft = true
	else
		love.mouse.setVisible(true)
		self.isShowSwapsLeft = false
	end
end

function Board:draw()
	g.push()
	g.translate(self.ox, self.oy)
	local levelRatio = self.levelRatio
	if levelRatio > 1 then
		levelRatio = 1 --cover the ratio
		--and add some effects to make user know that the progress is overload
		g.translate(math.random(-self.boardShake, self.boardShake), math.random(-self.boardShake, self.boardShake))
	end

	local lineH = self.nRows*self.cellSize
	local lineW = self.nCols*self.cellSize
	--cover the factor
	if self.boardFactor > 1 then self.boardFactor = 1 end
	g.setColor(0, 0, 0, 150)
	g.rectangle('fill', 0, 0, lineW, lineH)
	g.setColor(self.boardFactor*255, 0, self.boardFactor*255, 200)
	--draw the progress
	g.rectangle('fill', 0, lineH, lineW, -lineH*levelRatio)
	g.setLineWidth(2)
	g.rectangle('line', 0, 0, lineW, lineH)
	g.setColor(self.boardFactor*255, 0, self.boardFactor*255, 80)
    for i = 1, self.nRows-1, 1 do
    	g.line(0, i*self.cellSize, lineW, i*self.cellSize)
    end
    for i = 1, self.nCols-1, 1 do
		g.line(i*self.cellSize, 0, i*self.cellSize, lineH)
	end
	g.pop()
end

function Board:performStartEffect()
	--falling the gems
	local after = function ()
		local gg = instance.gird.gems
		for i = 1, instance.nRows, 1 do
			for j = 1, instance.nCols, 1 do
				--show the gems because at init it was hided
    			gg[i][j]:setDraw(true)
    			--fall
				gg[i][j]:fallTo(instance.ox + instance.cellSize*(j-0.5), instance.oy + instance.cellSize*(i-0.5))
			end
		end
	    --some sound effect of gem hit at the beginning of the board
		instance:seq(function ()
		local src = love.audio.newSource(content.sounds.gemHit)
		if Saved.instance():get('gemFall') == 'bounce' then
			wait(1)
			src:play()
			wait(0.7)
			src:rewind()
			src:play()
			wait(0.4)
			src:rewind()
			src:play()
		else
			wait(1)
			src:play()
		end

		--resend the level ratio from prev level
		if LevelManager.instance():getLevelRatio() > 0 then
			stween(self, 0.5, {levelRatio = LevelManager.instance():getLevelRatio()})
		end

		--and let user can swap gems
		self.canSwap = true
		end)
	end

	--but first, if this board is at level 1 of fun mode or continue from last saved (that mean it come from play menu)
	--we do some effects
	if LevelManager.instance():getLevel() == 1 or LevelManager.instance():getMode().isChallenge == false or self.isContinue then
		self:moveIn(after)
	else --if not, do fall the gems as normal
		after()
	end
end

function Board:moveIn(after)
	self:seq(function ()
	stween(self, 1, {ox = self.ox}, {ox = self.ox + 600})
	if after then after() end
	end)
end

function Board:moveOut(after)
	self:seq(function ()
	--some sound about gem hide
	love.audio.newSource(content.sounds.gemsSwap):play()
	local gg = self.gird.gems
	for i = 1, self.nRows, 1 do
		for j = 1, self.nCols, 1 do
			gg[i][j]:hide()
			gg[i][j]:createExplode()
		end
	end
	wait(0.5)
	stween(self, 0.5, {ox = self.ox + 600})
	if aftern then after() end
	end)
end

function Board:showBestMove()
	if self.canSwap and self.nSwaped == 0 then
		--getBestMove is from multimatch.stuffs.getBestMove
		--but we only show best move of maxSwapBeforeExplode-1, because player should image the situation
		--and make the remain swap more effecient
		getBestMoves(self.gird.kinds, self.nKinds, self.maxSwapBeforeExplode-1, function (linda)
			--the current function is a waiting function for a new thread have been create to find best moves
			--we do some effecting of waiting and then show player what is the best moves
			self:seq(function ()
			local gg = self.gird.gems

			--don't allow to swap now because it can make the best moves (in solving) wrong
			self.canSwap = false
			--make all gems be selected
			for i = 1, self.nRows, 1 do
				for j = 1, self.nRows, 1 do
					gg[i][j].isSelected = true
				end
			end
			--linda is a object that shared between threads
			--so if the solution in multimath.stuffs.getBestMoves is done
			--it will set a variable isDone in linda
			--so we wait for it
			while linda:get("isDone") == nil do yield() end
			--done now
			--make everything normal
			for i = 1, self.nRows, 1 do
				for j = 1, self.nRows, 1 do
					gg[i][j].isSelected = false
				end
			end
			self.canSwap = true
			
			--linda now should contain the bestmove (table but in string format so we translate it to table)
			local bm = loadstring('return '..linda:get("bestMoves"))()
			--and show the player these moves by hightlight these gems
			for i = 1, self.maxSwapBeforeExplode-1, 1 do
				gg[bm[i].a.r][bm[i].a.c]:highlight()
				gg[bm[i].b.r][bm[i].b.c]:highlight()
			end

			--clean up linda for later use of this function
			linda:set('isDone', nil)
			linda:set('bestMoves', nil)
			end)
		end)
	end
end

function Board:onStartSwap(x, y)
	if self.canSwap and x >= self.ox and x <= self.ox + self.nCols*self.cellSize and
	   y >= self.oy and y <= self.oy + self.nRows*self.cellSize then
	   	--save the position of the first gem that needs to swap
	   	self.swap = {}
	   	self.swap.ac = math.ceil((x - self.ox) / self.cellSize)
	   	self.swap.ar = math.ceil((y - self.oy) / self.cellSize)

	   	--some effect that the gem have been selected
	   	self:seq(function ()
		self.gird.gems[self.swap.ar][self.swap.ac]:doSelected()
		end)
	end
end

function Board:onEndSwap(x, y)
	if self.canSwap and self.swap ~= nil then
		if x >= self.ox and x <= self.ox + self.nCols*self.cellSize and
		   y >= self.oy and y <= self.oy + self.nRows*self.cellSize then
		   local swap = self.swap

		   --save the position of the second gem that needs to swap
		   swap.bc = math.ceil((x - self.ox) / self.cellSize)
		   swap.br = math.ceil((y - self.oy) / self.cellSize)

		   if (math.abs(swap.ac - swap.bc) == 1 and math.abs(swap.ar - swap.br) == 0) or
		   	  (math.abs(swap.ac - swap.bc) == 0 and math.abs(swap.ar - swap.br) == 1) then
		   	  	--doing swap in order
		   	  	--mark for user cannot swap any more during this current swap
		   	  	--unselect the first gem
		   	  	--swap (kind, gem)
		   	  	--clear the setup of swap
		   	  	--allow user to swap again
		   	 	self:seq(function ()
		   	 	self.canSwap = false

		   	 	--select effecto for the second gem
		   	  	self.gird.gems[self.swap.br][self.swap.bc]:doSelected()

		   	  	--swap in grid by kind
		   	  	local tmp = self.gird.kinds[self.swap.ar][self.swap.ac]
		   	  	self.gird.kinds[self.swap.ar][self.swap.ac] = self.gird.kinds[self.swap.br][self.swap.bc]
		   	  	self.gird.kinds[self.swap.br][self.swap.bc] = tmp

		   	  	--sound effect here
		   	  	love.audio.newSource(content.sounds.gemsSwap):play()
		   	  	--swap in screen
		   	  	self.gird.gems[self.swap.ar][self.swap.ac]:doSwapWith(self.gird.gems[self.swap.br][self.swap.bc])

		   	  	--swap in gird of gems
		   	  	tmp = self.gird.gems[self.swap.ar][self.swap.ac]
		   	  	self.gird.gems[self.swap.ar][self.swap.ac] = self.gird.gems[self.swap.br][self.swap.bc]
		   	  	self.gird.gems[self.swap.br][self.swap.bc] = tmp

		   	  	--unselect the two gems
		   	  	self.gird.gems[self.swap.ar][self.swap.ac]:doUnselected()
		   	  	self.gird.gems[self.swap.br][self.swap.bc]:doUnselected()

		   	  	self.swap = nil
		   	  	self.canSwap = true

		   	  	--count the times that user has swap
		   	  	--if it reach the limit, explode the board
		   	  	self.nSwaped = self.nSwaped + 1
		   		if self.nSwaped >= self.maxSwapBeforeExplode then
		   			self.nSwaped = 0
		   			self:explode(1) --explode at depth 1
		   		end
		   	  	end)
		   else --fail to select the second gem
		   		--unselect the first gem
		   		self:seq(function ()
		   		self.gird.gems[self.swap.ar][self.swap.ac]:doUnselected()
		   		end)
		   		self.swap = nil
		   end
		end
	end
end

--depth is the level of explode that make from the begining of explode (when user done swap, depth = 1)
function Board:explode(depth)
	--when gems explode, user can not swap any gems
	self.canSwap = false

	local gk = self.gird.kinds
	local gg = self.gird.gems
	local gb = self.gird.booms

	local totalNeedsToDone = 0
	local totalDone = 0
	local totalGemsExploded = 0

	--mark these gems that will explode
	for i = 1, self.nRows, 1 do
		for j = 1, self.nCols, 1 do
			local ah = j --begining postion of horizontal sequence of same kind gems
			local zh = j --ending
			local av = i --	vertical
			local zv = i

			--searching for these a/z-h/v above
			--and dont make gems that have kind < 0 explde, because it not a gem
			--it just a hole that have a gems explode
			for k = j-1, 1, -1 do		  if gk[i][k] > 0 and gk[i][k] == gk[i][k+1] then ah = k else break end end
			for k = j+1, self.nCols, 1 do if gk[i][k] > 0 and gk[i][k] == gk[i][k-1] then zh = k else break end end
			for k = i-1, 1, -1 do		  if gk[k][j] > 0 and gk[k][j] == gk[k+1][j] then av = k else break end end
			for k = i+1, self.nRows, 1 do if gk[k][j] > 0 and gk[k][j] == gk[k-1][j] then zv = k else break end end

			--mark them (if exist) to be explode later
			if zh-ah+1 >= self.minGemsToExplode then
				for k = ah, zh, 1 do
					gb[i][k] = true
				end
			end
			if zv-av+1 >= self.minGemsToExplode then
				for k = av, zv, 1 do
					gb[k][j] = true
				end
			end
		end
	end

	--explode from left to right (col)
	local continue = false
	--left->right
	for j = 1, self.nCols, 1 do
		local n = 0
		local gones = {} --save gems which will be explode
		local m = 0
		local stills = {} --save gems which remains
		
		--bot->top
		n = 0
		for i = self.nRows, 1, -1 do
			if gb[i][j] then
				continue = true --mark that there is at least one gems explode, so when explode all, continue explode if exist

				n = n+1
				gones[n] = {k = gk[i][j], g = gg[i][j]}
				gb[i][j] = false --make it clear
			else
				m = m+1
				stills[m] = {k = gk[i][j], g = gg[i][j]}
			end
		end

		if n > 0 then
			--the total needs to done is the amount gems that still on the board
			--if this gem is done its effect then totalDone = totalDone +1
			--that needs for check if all effects are done yet or not
			totalNeedsToDone = totalNeedsToDone + m
			--count gems that exlode, for scoring
			totalGemsExploded = totalGemsExploded + n
			--explode gems
			local nExploded = 0 --the count of number of gems that have done explode

			--fall these still gems
			for k = 1, m, 1 do
				gk[self.nRows-k+1][j] = stills[k].k
				gg[self.nRows-k+1][j] = stills[k].g
				self:seq(function ()
				while nExploded < n do yield() end --just like bellow
				stills[k].g:fallTo(self.ox + self.cellSize*(j-0.5), self.oy + self.cellSize*(self.nRows-k+0.5), 0, 
					function () totalDone = totalDone + 1 end) --counting
				end)
			end

			--explode gone gems but not spawn it yet
			--just spawn new gems when there is no explosion can be create
			for k = 1, n, 1 do
				gones[k].g:hide() --hide if first, to show the explode
				gones[k].g:createExplode(function () nExploded = nExploded+1 end) --counting nExplode
				--marke gird of kind to known that this postion now is not a gem
				gk[self.nRows-(m+k-1)][j] = -1
				--but we also keep the Gem (thing), for reuse later
				gg[self.nRows-(m+k-1)][j] = gones[k].g
			end
		end
	end

	if continue then
		--contined that mean there are gems that will explode
		--so we play the sound here
		--now we just have 6 depth sound
		if depth < 6 then love.audio.newSource(content.sounds.gemsGones[depth]):play()
		else love.audio.newSource(content.sounds.gemsGones[6]):play() end
		--we also play the sound of gem that hit the position here, for save memory
		if Saved.instance():get('gemFall') == 'bounce' then
			self:seq(function ()
			local src = love.audio.newSource(content.sounds.gemHit)
			src:setVolume(0.5)
			wait(1.1)
			src:play()
			wait(0.5)
			src:rewind()
			src:play()
			wait(0.2)
			src:rewind()
			src:play()
			end)
		end

		--add score
		LevelManager.instance():addScore(depth, totalGemsExploded)
		self:seq(function ()
		stween(self, 1.5, {levelRatio = LevelManager.instance():getLevelRatio()})
		end)

		--do after gems exploded
		self:seq(function ()
		--make the board more excited
		self:seq(function ()
		stween(self, 0.5, {boardFactor = self.boardFactor + 0.1})
		end)

		--wait until all falling gems done their job
		while totalDone < totalNeedsToDone do yield() end

		--after all effect of gems are done
		--continue explode board
		self:explode(depth + 1)
		end)
	else --no more explosions
		self:seq(function ()
		while totalDone < totalNeedsToDone do yield() end --wait until all falling gems done their job
		--because at this depth, there is no more explode create, so the real depth user reach is the last depth
		depth = depth - 1
		--because the first depth is no comment, and we only have 6 (2->7) comments so
		if depth > 1 and depth < 7 then love.audio.newSource(content.sounds.comments[depth]):play()
		elseif depth > 1 then love.audio.newSource(content.sounds.comments[7]):play() end 
		--return the board to normal
		--and then add a turns
		self:seq(function ()
		stween(self, 0.5, {boardFactor = 0})
		LevelManager.instance():addTurn()
		end)
		--if in fun mode
		--we calc the total score in one turn of 3 swaps and then compare it with the highest ever made
		--and save it to Saved, it may be displayed at play screen
		if not self.mode.isChallenge then
			self:seq(function ()
			local oneTurnScore = LevelManager.instance():getScore()
			if oneTurnScore > Saved.instance():get('funHighest') then
				Saved.instance():set('funHighest', oneTurnScore)
			end
			--wait a litte for user see the last score
			wait(2)
			--clear the total score, because now it is the one turn score
			LevelManager.instance():setScore(0)
			end)
		end

		--allow to swap because there is no more explode can be create
		self.canSwap = true
		--spawn new gems (fall for top) here
		if not self.mode.isChallenge or LevelManager.instance():getLevelRatio() < 1 then self:spawnGems() end
		end)
	end	
end

function Board:spawnGems()
	local gk = self.gird.kinds
	local gg = self.gird.gems

	--from left->right
	for j = 1, self.nCols, 1 do
		--bot->top
		for i = self.nRows, 1, -1 do
			--if found a hole
			if gk[i][j] < 0 then
				for k = i, 1, -1 do
					--setup the gird to new gems
					--and make sure new gems dont make explode
					--because we are on left->right, and bot->top
					local newKind = -1
					local bot = -1
		    		local left = -1
		    		local right = -1
		    		local left1 = -1
		    		local right1 = -1
		    		if k < self.nRows-1 and gk[k+1][j] == gk[k+2][j] then bot = gk[k+1][j] end
		    		if j > 2 and gk[k][j-1] == gk[k][j-2] then left = gk[k][j-1] end
		    		if j > 1 then left1 = gk[k][j-1] end
		    		if j < self.nCols-1 and gk[k][j+1] == gk[k][j+2] then right = gk[k][j+1] end
		    		if j < self.nCols then right1 = gk[k][j+1] end
		    		if self.nKinds < 4 and left ~= -1 and right ~= -1 and bot ~= -1 and left ~= right and right ~= bot and bot ~= left then 
		    			newKind = math.random(1, self.nKinds)
		    		elseif left1 ~= -1 and left1 == right1 and left == -1 and right == -1 then
		    			repeat newKind = math.random(1, self.nKinds) until newKind ~= bot and newKind ~= left1
		    		else
		    			repeat newKind = math.random(1, self.nKinds) until newKind ~= bot and newKind ~= left and newKind ~= right
		    		end
		    		gk[k][j] = newKind

					local gem = gg[k][j]
					--show the gems at the new position and fall it to the right pos too
					gem:show()
					gem:renew(gk[k][j], self.ox + self.cellSize*(j-0.5), self.oy - self.cellSize*(i-k+0.5))
					gem:fallTo(self.ox + self.cellSize*(j-0.5), self.oy + self.cellSize*(k-0.5), (i-k+1)*0.02)
				end
				--done with all hole about this col, so break to process next col
				break
			end
		end
	end

	--some sound effects
	--the time is a little bit different from the one in exlode function (of falling still gems)
	if Saved.instance():get('gemFall') == 'bounce' then
		self:seq(function ()
		local src = love.audio.newSource(content.sounds.gemHit)
		src:setVolume(0.5)
		wait(0.8)
		src:play()
		wait(0.6)
		src:rewind()
		src:play()
		wait(0.2)
		src:rewind()
		src:play()
		end)
	end
end

function Board:endBoard(isWin, after)
	self:seq(function ()
	while self.canSwap == false do yield() end
	self.canSwap = false
	--wait a little bit for user see the board be for it effecting
	--and for the boardFactor going down (it is not important)
	wait(0.5)
	local gg = self.gird.gems
	for i = 1, self.nRows, 1 do
		for j = 1, self.nCols, 1 do
			gg[i][j]:out(isWin)
		end
	end
	
	if isWin then love.audio.newSource(content.sounds.gemsFly):play()
	else love.audio.newSource(content.sounds.gemsDrop):play() end
	wait(1)
	if isWin then love.audio.newSource(content.sounds.voices.levelComplete):play()
	else love.audio.newSource(content.sounds.voices.levelFail):play() end
	wait(1)

	if isWin then
		stween(self, 0.5, {boardFactor = 1})
		 --because when finishing level, the board is shaking because of score make it overload
		 --so we need to make it stop shaking at the end of effecting that end the board
		stween(self, 1, {boardFactor = 0, boardShake = 0, levelRatio = 0}, {levelRatio = 1})
	else
		wait(2) --wait for gems drop done
		--if we lose, and we have to end this board, notice to the creator (play scene) to know it
		if self.onOut then self.onOut() end
		--make effect that board go out, like the beginning that the board come to screen
		--we dont use Board:moveOut here because it this board is now losing
		--so it just want to move out, not to perform some effect of an unfinished board (like press menu while playing)
		stween(self, 1, {ox = self.ox + 800})
	end
	if after then after() end
	end)
end

--use to know if the board is available for usesr can swap gems or do something else (like press menu button)
function Board:isAvaiable()
	return self.canSwap
end

function Board:getSavedTable()
	return {girdKinds = self.gird.kinds, swaps = self.nSwaped}
end