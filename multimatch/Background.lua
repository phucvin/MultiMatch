
Background = {}
Background.__index = Background

local instance = nil

function Background.new(mode)
	instance = Thing.new({'background'}):extend(Background)
	instance.zOrder = content.layers.background

	instance.index = Saved.instance():get('backgroundIndex')

	return instance
end

function Background.instance()
	return instance
end

function Background:draw()
	g.setColor(255, 255, 255)
	g.draw(content.images.backgrounds[self.index], 0, 0)
end

function Background:setIndex(index)
	self.index = index

	--save to Saved
	Saved.instance():set('backgroundIndex', index)
end

function Background:getIndex()
	return self.index
end