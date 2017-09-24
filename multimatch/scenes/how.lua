
local how = {}
how.__index = how

function how:init()
	self.gui = GUI.new()
	self.gui:addButton('Back', -40, 540, 200, 60, function(btn) self:gotoMenu() end)

	self.image = Thing.new()
	self.image.x = 0
	self.image.draw = function (self)
		g.setColor(255, 255, 255)
		g.draw(content.images.how, self.x, 0)
	end

	self:moveIn()
end

function how:moveIn()
	self.gui:seq(function ()
	self.image:seq(function ()
	stween(self.image, 1, {x = self.image.x}, {x = self.image.x - g.getWidth()})
	end)
    stween(self.gui, 1, {ox = self.gui.ox}, {ox = self.gui.ox - g.getWidth()})
    end)
end

function how:moveOut(after)
	self.gui:seq(function ()
	self.image:seq(function ()
	stween(self.image, 1, {x = self.image.x - g.getWidth()})
	end)
    stween(self.gui, 1, {ox = self.gui.ox - g.getWidth()})
    if after then after() end
    end)
end

function how:gotoMenu()
	self:moveOut(function () director.changeScene('menu') end)
end

director.addScene('how', function (...) setmetatable({}, how):init(...) end)