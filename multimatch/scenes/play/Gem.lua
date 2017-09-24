
Gem = {}
Gem.__index = Gem

function Gem.new(x, y, kind)
	local self = Thing.new({'gem'}):extend(Gem)
	self.zOrder = content.layers.gem

	self.x = x
	self.y = y
	self.r = 20
	self.kind = kind

	self.isSelected = false --if current gem is seletected
	self.anim = newAnimation(content.images.gems[kind].img, 64, 64, 0.03, 0)

	--particle system for explode effect
	self.particleSystem = g.newParticleSystem(content.images.particle, 1000)
	local p = self.particleSystem
	p:setEmissionRate(50)
	p:setSpeed(200, 300)
	p:setSizes(0.3, 0.5)
	p:setColors(255, 255, 255, 250, 255, 255, 255, 20)
	p:setPosition(0, 0)
	p:setLifetime(0.3) --it will appear in 0.3 sec
	p:setParticleLife(0.2)
	p:setDirection(0)
	p:setSpread(360)
	p:setTangentialAcceleration(1000)
	p:setRadialAcceleration(-1000)
	p:stop()

	return self
end

function Gem:always()
	--update animation
	self.anim:update(dt)
	--update particle system
	self.particleSystem:update(dt)
end

function Gem:draw()
	if self.isSelected then
		g.setColor(255, 255, 255)
		self.anim:draw(self.x - 32, self.y - 32)
	else
		local gem = content.images.gems[self.kind]
		local quad = g.newQuad(0, 0, 64, 64, 320, 256)
		g.setColor(255, 255, 255)
		g.drawq(gem.img, quad, self.x - 32, self.y - 32)
	end
end

function Gem:doSelected()
	--sound effect here
	love.audio.newSource(content.sounds.gemSelected):play()

	self.isSelected = true
	stween(self, 0.1, {r = 25})
end
function Gem:doUnselected()
	self.isSelected = false
	stween(self, 0.1, {r = 20})
end

function Gem:doSwapWith(other)
	local sx = self.x
	local sy = self.y
	local ox = other.x
	local oy = other.y

	ptween(self, 0.2, {x = ox, y = oy})
	stween(other, 0.2, {x = sx, y = sy})
end

function Gem:highlight()
	self.isSelected = true
end

function Gem:renew(newKind, x, y)
	self.kind = newKind
	self.x = x
	self.y = y
	self.isSelected = false
	self.isHighlight = false

	self.anim = newAnimation(content.images.gems[newKind].img, 64, 64, 0.03, 0)
end

function Gem:createExplode(after)
	--the particle sytem
	local p = self.particleSystem
	--the explosion
	local e = Thing.new()
	e.zOrder = content.layers.effect
	e.kind = self.kind
	e.x = self.x
	e.y = self.y
	e.angle = 0
	e.scale = 1
	--set particle's emmiter to gem's position
	p:setPosition(self.x, self.y)
	e.draw = function (self)
		local gem = content.images.gems[self.kind]
		local quad = g.newQuad(0, 0, 64, 64, 320, 256)
		g.setColor(255, 255, 255)
		g.drawq(gem.img, quad, self.x, self.y, self.angle, self.scale, self.scale, 32, 32)

		--g.setBlendMode("additive")
		--draw the particle in explosion too
		g.draw(p, 0, 0)
		--g.setBlendMode("alpha")
	end
	e:seq(function ()
	stween(e, 0.1, {scale = 1.5})
	p:start() --start the particle system
	stween(e, 0.4, {scale = 0})
	--make sure the draw function still alive to draw the particle system
	e:seq(function()
	wait(1)
	e:destroy()
	end)
	--notice the caller that we have done explode
	if after then after() end
	end)
end

function Gem:fallTo(x, y, delay, after)
	--just fall (consume time) when there is distance
	if self.x ~= x or self.y ~= y then
		self:seq(function ()
		if delay then wait(delay) end
		if Saved.instance():get('gemFall') == 'bounce' then
			stween(self, 1 + math.abs(y - self.y)*0.002, {x = x, y = y}, {}, 'outBounce')
		else
			stween(self, 0.35 + math.abs(y - self.y)*0.001, {x = x, y = y}, {}, 'outQuad')
		end
		if after then after() end
		end)
	elseif after then after () end
end

function Gem:hide()
	self:setDraw(false)
end
function Gem:show()
	self:setDraw(true)
end

function Gem:out(isWin)
	self:seq(function ()
	local t = 0.5
	local ox = self.x
	local oy = self.y
	while t > 0 do
		t = t - dt
		self.x = ox + math.random(-3, 3)
		self.y = oy + math.random(-1, 1)
		yield()
	end

	local vx = math.random(-100, 100) --velocity
	local vy = math.random(-700, -600) --for lose
	local a = 1200 --accl of gravity, for lose
	if isWin then
		vy = math.random(600, 700) --for win
		a = -1200
	end
	t = 0
	while t < 3 do
		t = t + dt
		self.x = ox + vx*t
		self.y = oy + vy*t + 1/2*a*t*t
		yield()
	end
	end)
end