
Saved = {}
Saved.__index = Saved

local instance = nil

function Saved.new()
	instance = {}
	setmetatable(instance, Saved)

	instance.fileName = 'saved_1_0.lua'
	instance.all = {
		playerName = 'Player',
		backgroundIndex = 1,
		soundVolume = 1,
		gemFall = 'bounce',
		funHighest = 0,
		continue = nil,
		highScores = {
			easy = {
				{name = 'Phuc Vin', score = 44730},
				{name = 'An LHP', score = 42620}
			}, 
			normal = {
				{name = 'Phuc Vin', score = 21830},
				{name = 'Loc LHP', score = 11250}
			}, 
			hard = {
				{name = 'Phuc Vin', score = 13810},
				{name = 'Hg Nguyen', score = 14020}
			}
		}
	}

	instance:load()
end

function Saved.instance()
	return instance
end

function Saved:load()
	if love.filesystem.exists(self.fileName) then
		local chunk = love.filesystem.load(self.fileName)
		if chunk then self.all = chunk() end
	end
end

function Saved:save()
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
	
	local data = 'return ' .. simpleDump(self.all)
	love.filesystem.write(self.fileName, data, data:len())
end

function Saved:get(what)
	return self.all[what]
end

function Saved:set(what, value)
	self.all[what] = value
end