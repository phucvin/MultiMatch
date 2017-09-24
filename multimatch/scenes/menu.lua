
local menu = {}
menu.__index = menu

function menu:init()
    Background.instance():seq(function ()
    wait(0.2)
    love.audio.newSource(content.sounds.voices.welcomeBack):play()
    end)

    self.gui = GUI.new()
    self.gui.zOrder = content.layers.gui
    --max lenght of name is 12
    --if user change it, the text field will notice us with a function, so we update it with Saved
    self.gui:addTextField('Name:', Saved.instance():get('playerName') ,40, 160, 280, 40, nil, 12, function (text)
            Saved.instance():set('playerName', text)
        end)
    self.gui:addText('Created by Phuc Vin', 640, 160, 280, 40, nil, 'left') --align text at left
    self.gui:addButton('Continue', 380, 220, 200, 60, function (btn) self:gotoContinue(btn) end)
    local playChallenge
    playChallenge = self.gui:addButton('Play Challenge', 380, 300, 200, 60, function(btn)
        --hide this buttton
        playChallenge.isShow = false
        --show 3 buttons that set the level: easy, normal, hard
        self.gui:addButton('Easy', 380, 300, 60, 60, function(btn) self:gotoPlayChallenge('easy') end)
        self.gui:addButton('Normal', 440, 300, 80, 60, function(btn) self:gotoPlayChallenge('normal') end)
        self.gui:addButton('Hard', 520, 300, 60, 60, function(btn) self:gotoPlayChallenge('hard') end)
    end)
    self.gui:addButton('Play Fun', 380, 380, 200, 60, function(btn) self:gotoPlayFun() end)
    self.gui:addButton('How To Play', 380, 460, 200, 60, function(btn) self:gotoHowToPlay() end)
    self.gui:addButton('High Scores', 380, 540, 200, 60, function(btn) self:gotoHighScores() end)
    self.gui:addButton('Settings', -40, 540, 200, 60, function(btn) self:gotoSettings() end)
    self.gui:addButton('Quit', 800, 540, 200, 60, function(btn) self:gotoQuit() end)

    self.tittle = Thing.new()
    self.tittle.y = 0
    self.tittle.draw = function (self)
        g.setColor(255, 255, 255)
        g.draw(content.images.tittle, 0, self.y)
    end

    --effecting the board come in
    self:moveIn()
end

function menu:moveIn(after)
    self.gui:seq(function ()
        self.tittle:seq(function ()
        stween(self.tittle, 1, {y = self.tittle.y}, {y = self.tittle.y - 200})
        end)
        stween(self.gui, 1, {oy = self.gui.oy}, {oy = self.gui.oy + g.getHeight()})
        if after then after() end
    end)
end

function menu:moveOut(after)
    self.gui:seq(function ()
        self.tittle:seq(function ()
        stween(self.tittle, 1, {y = self.tittle.y - 200})
        end)
        stween(self.gui, 1, {oy = self.gui.oy + g.getHeight()})
        if after then after() end
    end)
end

function menu:gotoContinue(btn)
--
    local continue = Saved.instance():get('continue')
    if continue then
        self:moveOut(function ()
            LevelManager.new(continue.mode)
            LevelManager.instance():continue(continue)
            director.changeScene('play', true, continue.mode) --true to notice play scence this is a continue game
        end)
    else
        btn.font = content.fonts.buttonSmall
        btn.text = 'Need unfinish challenge'
    end
--]]
end

function menu:gotoPlayChallenge(mode)
--
    self:moveOut(function ()
        --create a new Level Manager for each new game with mode
        --this levelManager exist until game is over or user cancel the current progress
        LevelManager.new(content.settings.challenge[mode]) --false for fun mode
        director.changeScene('play', false, content.settings.challenge[mode]) --false for fun mode
    end)
--]]
end

function menu:gotoPlayFun()
--
    self:moveOut(function ()
        --create a new Level Manager for each new game with mode
        --this levelManager exist until game is over or user cancel the current progress
        LevelManager.new(content.settings.fun) --false for fun mode
        director.changeScene('play', false, content.settings.fun) --false for fun mode
    end)
--]]
end

function menu:gotoHowToPlay()
    self:moveOut(function ()
        director.changeScene('how')
    end)
end

function menu:gotoHighScores()
    self:moveOut(function ()
        director.changeScene('highs')
    end)
end

function menu:gotoSettings()
    self:moveOut(function ()
        director.changeScene('settings')
    end)
end

function menu:gotoQuit()
    --save once, at quit
    Saved.instance():save()
    love.event.quit()
end

director.addScene('menu', function (...) setmetatable({}, menu):init(...) end)
