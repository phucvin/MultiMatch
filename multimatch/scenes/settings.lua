
local settings = {}
settings.__index = settings

function settings:init()
	self.backgrounds = Thing:new()
	local bgs = self.backgrounds
	bgs.x = 0
	bgs.currentIndex = Background.instance():getIndex()
	bgs.draw = function (self)
		g.push()
		g.translate(self.x, 0)
		g.setColor(0, 0, 0, 200)
		g.rectangle('fill', 10, 10, 940, 520)
		g.setColor(255, 255, 255)
		g.setFont(content.fonts.settingsItem)
		g.print('Chose background:', 20, 20)
		for i = 1, #content.images.backgrounds, 1 do
			if i == self.currentIndex then
				g.setColor(255, 0, 0, 150)
				g.setLineWidth(4)
				g.rectangle('line', 20 + 100*(i-1), 80, 96, 64)
			end
			g.setColor(255, 255, 255)
			g.draw(content.images.backgrounds[i], 20 + 100*(i-1), 80, 0, 0.1, 0.1)
		end
		
		--draw some description for button gemFall below
		g.setColor(255, 255, 255)
		g.print('Gem fall\'s style:', 20, 220)
		g.pop()
	end
	--listener when user click to choose background
	listener.add('mousepressed', 'l', function (mx, my)
		--translate the mouse position to these background's positions
		mx = mx + bgs.x
		for i = 1, #content.images.backgrounds, 1 do
			local ox = 20 + 100*(i-1)
			local oy = 80
			if mx >= ox and mx <= ox + 96 and my >= oy and my <= oy + 64 then
				bgs.currentIndex = i
				Background.instance():setIndex(i)
			end
		end
	end)

	--draw simple slider of volume
	local slider = Thing.new()
	slider.draw = function (self)
		g.push()
		g.translate(bgs.x, 0)
		g.setColor(255, 255, 255)
		g.setFont(content.fonts.settingsItem)
		g.print('Sound volume:', 20, 320)
		
		--the slide
		g.setColor(255, 255, 255, 200)
		g.rectangle('fill', 250, 335, 200, 5)
		g.setLineWidth(1)
		g.rectangle('line', 250, 335, 200, 5)

		--the button
		local x = 250 + Saved.instance():get('soundVolume') * 200
		g.setColor(0, 0, 0, 200)
		g.rectangle('fill', x-5, 330, 10, 15)
		g.setColor(255, 255, 255, 200)
		g.setLineWidth(2)
		g.rectangle('line', x-5, 330, 10, 15)
		g.pop()
	end
	listener.add('mousepressed', 'l', function (mx, my)
		--translate it to local postion
		mx = mx + bgs.x
		if mx >= 245 and mx <= 455 and my >= 330 and my <= 345 then
			slider.isDragging = true
		end
	end)
	slider.always = function (self)
		if slider.isDragging then
			local mx = love.mouse.getX()
			mx = mx + bgs.x
			if mx < 250 then mx = 250 end
			if mx > 450 then mx = 450 end
			local ratio = (mx - 250) / 200
			Saved.instance():set('soundVolume', ratio)
			love.audio.setVolume(ratio)
		end
	end
	listener.add('mousereleased', 'l', function () slider.isDragging = false end)

	self.gui = GUI.new()
	self.gui:addButton(Saved.instance():get('gemFall'), 280, 215, 100, 40, function (btn)
		if btn.text == 'linear' then
			btn.text = 'bounce'
			Saved.instance():set('gemFall', 'bounce')
		else
			btn.text = 'linear'
			Saved.instance():set('gemFall', 'linear')
		end
	end)
	self.gui:addButton('Back', -40, 540, 200, 60, function(btn) self:gotoMenu() end)

	self:moveIn()
end

function settings:moveIn(after)
    self.gui:seq(function ()
	self.backgrounds:seq(function ()
	stween(self.backgrounds, 1, {x = self.backgrounds.x}, {x = self.backgrounds.x - g.getWidth()})
	end)
    stween(self.gui, 1, {ox = self.gui.ox}, {ox = self.gui.ox - g.getWidth()})
    if after then after() end
    end)
end

function settings:moveOut(after)
    self.gui:seq(function ()
    self.backgrounds:seq(function ()
	stween(self.backgrounds, 1, {x = self.backgrounds.x - g.getWidth()})
	end)
    stween(self.gui, 1, {ox = self.gui.ox - g.getWidth()})
    if after then after() end
    end)
end

function settings:gotoMenu()
	self:moveOut(function () director.changeScene('menu') end)
end

director.addScene('settings', function (...) setmetatable({}, settings):init(...) end)