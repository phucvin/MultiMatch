local loader = require 'multimatch.stuffs.love-loader'

content = {}
content.settings = {}
content.layers = {}
content.images = {}
content.fonts = {}
content.sounds = {}

local settings = content.settings
local layers = content.layers
local images = content.images
local sounds = content.sounds
local fonts = content.fonts

settings.fun = {name = 'Fun', isChallenge = false, nKinds = 3}
settings.challenge = {}
settings.challenge.continue = nil
settings.challenge.easy = {name = 'easy', isChallenge = true, nKinds = 4, maxTurns = 10, baseScore = 800, increasingScore = 200}
settings.challenge.normal = {name = 'normal', isChallenge = true, nKinds = 5, maxTurns = 10, baseScore = 600, increasingScore = 200}
settings.challenge.hard = {name = 'hard', isChallenge = true, nKinds = 6, maxTurns = 15, baseScore = 500, increasingScore = 200}

layers.background = -1
layers.board = 0
layers.gem = 1
layers.effect = 2
layers.gui = 3
layers.cursor = 4

function content.load(finishCallback)
	images.backgrounds = {}
	loader.newImage(images.backgrounds, 1,'multimatch/content/background1.png')
	loader.newImage(images.backgrounds, 2,'multimatch/content/background2.png')
	loader.newImage(images.backgrounds, 3,'multimatch/content/background3.png')
	loader.newImage(images, 'tittle', 'multimatch/content/tittle.png')
	loader.newImage(images, 'how', 'multimatch/content/how.png')
	images.boardCursor = {img = nil, hw = 24, hh = 24}
	loader.newImage(images.boardCursor, 'img', 'multimatch/content/boardCursor.png')
	images.gems = {}
	images.gems[1] = {img = nil, r = 4, c = 5}
	loader.newImage(images.gems[1], 'img', 'multimatch/content/gems/red.png')
	images.gems[2] = {img = nil, r = 4, c = 5}
	loader.newImage(images.gems[2], 'img', 'multimatch/content/gems/green.png')
	images.gems[3] = {img = nil, r = 4, c = 5}
	loader.newImage(images.gems[3], 'img', 'multimatch/content/gems/blue.png')
	images.gems[4] = {img = nil, r = 4, c = 5}
	loader.newImage(images.gems[4], 'img', 'multimatch/content/gems/yellow.png')
	images.gems[5] = {img = nil, r = 4, c = 5}
	loader.newImage(images.gems[5], 'img', 'multimatch/content/gems/white.png')
	images.gems[6] = {img = nil, r = 4, c = 5}
	loader.newImage(images.gems[6], 'img', 'multimatch/content/gems/orange.png')
	images.gems[7] = {img = nil, r = 4, c = 5}
	loader.newImage(images.gems[7], 'img', 'multimatch/content/gems/purple.png')
	loader.newImage(images, 'particle', 'multimatch/content/particle.png')

	sounds.voices = {}
	loader.newSoundData(sounds.voices, 'welcomeBack', 'multimatch/content/voiceWelcomeBack.wav')
	loader.newSoundData(sounds.voices, 'go', 'multimatch/content/voiceGo.wav')
	loader.newSoundData(sounds.voices, 'levelComplete', 'multimatch/content/voiceLevelComplete.wav')
	loader.newSoundData(sounds.voices, 'levelFail', 'multimatch/content/voiceLevelFail.wav')
	loader.newSoundData(sounds, 'gemHit', 'multimatch/content/gemHit.ogg')
	loader.newSoundData(sounds, 'gemSelected', 'multimatch/content/gemSelected.wav')
	loader.newSoundData(sounds, 'gemsSwap', 'multimatch/content/gemsSwap.wav')
	sounds.gemsGones = {}
	loader.newSoundData(sounds.gemsGones, 1, 'multimatch/content/gemsGone1.wav')
	loader.newSoundData(sounds.gemsGones, 2, 'multimatch/content/gemsGone2.wav')
	loader.newSoundData(sounds.gemsGones, 3, 'multimatch/content/gemsGone3.wav')
	loader.newSoundData(sounds.gemsGones, 4, 'multimatch/content/gemsGone4.wav')
	loader.newSoundData(sounds.gemsGones, 5, 'multimatch/content/gemsGone5.wav')
	loader.newSoundData(sounds.gemsGones, 6, 'multimatch/content/gemsGone6.wav')
	loader.newSoundData(sounds, 'gemsFly', 'multimatch/content/gemsFly.wav')
	loader.newSoundData(sounds, 'gemsDrop', 'multimatch/content/gemsDrop.wav')
	sounds.comments = {}
	sounds.comments[1] = nil
	loader.newSoundData(sounds.comments, 2, 'multimatch/content/commentGood.wav')
	loader.newSoundData(sounds.comments, 3, 'multimatch/content/commentAwesome.wav')
	loader.newSoundData(sounds.comments, 4, 'multimatch/content/commentExcellent.wav')
	loader.newSoundData(sounds.comments, 5, 'multimatch/content/commentSpectacular.wav')
	loader.newSoundData(sounds.comments, 6, 'multimatch/content/commentExtraordinary.wav')
	loader.newSoundData(sounds.comments, 7, 'multimatch/content/commentUnbelievable.wav')

	content.isDone = false
	--small thing for updating the loader
	local t = Thing.new()
	t.always = function () loader.update() end
	--start the loader
	loader.start(function () --on completed callback
		t:destroy()
		content.isDone = true
		if finishCallback then finishCallback() end
	end)
end

function content.getPercent()
	return loader.loadedCount / loader.resourceCount
end

local consola15 = love.graphics.newFont('multimatch/content/consola.ttf', 15)
local consola20 = love.graphics.newFont('multimatch/content/consola.ttf', 20)
local consola25 = love.graphics.newFont('multimatch/content/consola.ttf', 25)
local consola30 = love.graphics.newFont('multimatch/content/consola.ttf', 30)
local consola35 = love.graphics.newFont('multimatch/content/consola.ttf', 35)
local consola40 = love.graphics.newFont('multimatch/content/consola.ttf', 40)
local consola60 = love.graphics.newFont('multimatch/content/consola.ttf', 60)

fonts.smallTittle = consola40
fonts.score = consola30
fonts.turnsLeft = consola25
fonts.movesLeft = consola20
fonts.level = consola60
fonts.funHighest = consola25
fonts.button = consola20
fonts.buttonSmall = consola15
fonts.highsTittle = consola30
fonts.highsItem = consola20
fonts.settingsItem = consola25

--[[images.backgrounds = {}
	images.backgrounds[1] = love.graphics.newImage('multimatch/content/background1.png')
	images.backgrounds[2] = love.graphics.newImage('multimatch/content/background2.png')
	images.backgrounds[3] = love.graphics.newImage('multimatch/content/background3.png')
	--images.backgrounds[4] = love.graphics.newImage('multimatch/content/background4.png')
	--images.backgrounds[5] = love.graphics.newImage('multimatch/content/background5.png')
	--images.backgrounds[6] = love.graphics.newImage('multimatch/content/background6.png')
	images.tittle = love.graphics.newImage('multimatch/content/tittle.png')
	images.how = love.graphics.newImage('multimatch/content/how.png')
	images.boardCursor = {img = love.graphics.newImage('multimatch/content/boardCursor2.png'), hw = 24, hh = 24}
	images.gems = {}
	images.gems[1] = {img = love.graphics.newImage('multimatch/content/gems/red.png'), r = 4, c = 5}
	images.gems[2] = {img = love.graphics.newImage('multimatch/content/gems/green.png'), r = 4, c = 5}
	images.gems[3] = {img = love.graphics.newImage('multimatch/content/gems/blue.png'), r = 4, c = 5}
	images.gems[4] = {img = love.graphics.newImage('multimatch/content/gems/yellow.png'), r = 4, c = 5}
	images.gems[5] = {img = love.graphics.newImage('multimatch/content/gems/white.png'), r = 4, c = 5}
	images.gems[6] = {img = love.graphics.newImage('multimatch/content/gems/orange.png'), r = 4, c = 5}
	images.gems[7] = {img = love.graphics.newImage('multimatch/content/gems/purple.png'), r = 4, c = 5}
	images.particle = love.graphics.newImage('multimatch/content/particle.png')

	sounds.voices = {}
	sounds.voices.welcomeBack = love.sound.newSoundData('multimatch/content/voiceWelcomeBack.wav')
	sounds.voices.go = love.sound.newSoundData('multimatch/content/voiceGo.wav')
	sounds.voices.levelComplete = love.sound.newSoundData('multimatch/content/voiceLevelComplete.wav')
	sounds.voices.levelFail = love.sound.newSoundData('multimatch/content/voiceLevelFail.wav')
	sounds.gemHit = love.sound.newSoundData('multimatch/content/gemHit.ogg')
	sounds.gemSelected = love.sound.newSoundData('multimatch/content/gemSelected.wav')
	sounds.gemsSwap = love.sound.newSoundData('multimatch/content/gemsSwap.wav')
	sounds.gemsGones = {}
	sounds.gemsGones[1] = love.sound.newSoundData('multimatch/content/gemsGone1.wav')
	sounds.gemsGones[2] = love.sound.newSoundData('multimatch/content/gemsGone2.wav')
	sounds.gemsGones[3] = love.sound.newSoundData('multimatch/content/gemsGone3.wav')
	sounds.gemsGones[4] = love.sound.newSoundData('multimatch/content/gemsGone4.wav')
	sounds.gemsGones[5] = love.sound.newSoundData('multimatch/content/gemsGone5.wav')
	sounds.gemsGones[6] = love.sound.newSoundData('multimatch/content/gemsGone6.wav')
	sounds.gemsFly = love.sound.newSoundData('multimatch/content/gemsFly.wav')
	sounds.gemsDrop = love.sound.newSoundData('multimatch/content/gemsDrop.wav')
	sounds.comments = {}
	sounds.comments[1] = nil
	sounds.comments[2] = love.sound.newSoundData('multimatch/content/commentGood.wav')
	sounds.comments[3] = love.sound.newSoundData('multimatch/content/commentAwesome.wav')
	sounds.comments[4] = love.sound.newSoundData('multimatch/content/commentExcellent.wav')
	sounds.comments[5] = love.sound.newSoundData('multimatch/content/commentSpectacular.wav')
	sounds.comments[6] = love.sound.newSoundData('multimatch/content/commentExtraordinary.wav')
	sounds.comments[7] = love.sound.newSoundData('multimatch/content/commentUnbelievable.wav')]]