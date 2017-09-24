
--a naive, simple algorithm (dfs)
--for getting maximum score in one turn of MultiMatch game

local linda = lanes.linda()

local nr, nc = 8, 8
local board = {}
local nKinds = 3
local maxSwaps = 2
local minGemsToExplode = 3

--the same with LevelManage.addScore
--but return the score
local function calcScore(totalGems, atDepth)
	if totalGems > 6 then totalGems = 6 + (totalGems - 6)*2 end
	return (atDepth-1)*100 + totalGems*10*atDepth
end

local function exlode(b, depth)
	local bb = {{}, {}, {}, {}, {}, {}, {}, {}}
	for r = 1, nr, 1 do
		for c = 1, nc, 1 do
			local ah = c --begining postion of horizontal sequence of same kind gems
			local zh = c --ending
			local av = r --	vertical
			local zv = r

			--searching for these a/z-h/v above
			--and dont make gems that have kind < 0 explde, because it not a gem
			--it just a hole that have a gems explode
			for k = c-1, 1, -1 do if b[r][k] ~= nil and b[r][k] == b[r][k+1] then ah = k else break end end
			for k = c+1, nc, 1 do if b[r][k] ~= nil and b[r][k] == b[r][k-1] then zh = k else break end end
			for k = r-1, 1, -1 do if b[k][c] ~= nil and b[k][c] == b[k+1][c] then av = k else break end end
			for k = r+1, nr, 1 do if b[k][c] ~= nil and b[k][c] == b[k-1][c] then zv = k else break end end

			--mark them (if exist) to be explode later
			if zh-ah+1 >= minGemsToExplode then
				for k = ah, zh, 1 do
					bb[r][k] = true
				end
			end
			if zv-av+1 >= minGemsToExplode then
				for k = av, zv, 1 do
					bb[k][c] = true
				end
			end
		end
	end

	--total gems will explode
	local gems = 0
	for c = 1, nc, 1 do
		for r = 1, nr, 1 do
			if bb[r][c] then
				b[r][c] = nil
				gems = gems + 1
			end
		end
	end

	if gems > 0 then
		for c = 1, nc, 1 do
			for r = nr-1, 1, -1 do
				if b[r][c] ~= nil then
					local k = r+1
					while k <= nr and b[k][c] == nil do
						b[k][c], b[k-1][c] = b[k-1][c], nil
						k = k + 1
					end
				end
			end
		end

		return calcScore(gems, depth) + exlode(b, depth+1)
	else
		return 0
	end
end

local function computeScore()
	local b = {}

	for r = 1, nr,1 do
		b[r] = {}
		for c = 1, nc, 1 do
			b[r][c] = board[r][c]
		end
	end

	return exlode(b, 1)
end

local maxScore = 0
local bestMoves = {}

local moves = {}

local function try(m, r, c, tr, tc, attemp)
	moves[m] = {a = {r = r, c = c}, b = {r = tr, c = tc}}
	board[r][c], board[tr][tc] = board[tr][tc], board[r][c]
	attemp(m+1)
	board[r][c], board[tr][tc] = board[tr][tc], board[r][c]
end

--naive attemp to find max score can make
local function attemp(m)
	if m > maxSwaps then
		local score = computeScore()
		if score > maxScore then
			maxScore = score
			for m = 1, maxSwaps, 1 do
				bestMoves[m] = {a = {r = moves[m].a.r, c = moves[m].a.c}, b = {r = moves[m].b.r, c = moves[m].b.c}}
			end
		end
	else
		for r = 1, nr-1,1 do
			for c = 1, nc-1, 1 do
				try(m, r, c, r + 1, c, attemp)
				try(m, r, c, r, c + 1, attemp)
			end
		end
	end
end

local function simpleDump(o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. simpleDump(v) .. ','
		end
		return s .. '} '
	else
		if type(o) == 'number' or type(o) == 'boolean' then return tostring(o)
		else return '\"'..tostring(o)..'\"' end
	end
end

local function run()
	attemp(1)
	linda:set("bestMoves", simpleDump(bestMoves))
	linda:set("isDone", true)
end

--global
function getBestMoves(b, nk, ms, waitFunc)
	board = {}
	for r = 1, nr,1 do
		board[r] = {}
		for c = 1, nc, 1 do
			board[r][c] = b[r][c]
		end
	end
	nKinds = nk
	maxSwaps = ms

	maxScore = 0
	lanes.gen('base', run)()
	
	waitFunc(linda)
end