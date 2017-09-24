--
require 'flatmoon.engine'
require 'flatmoon.director'
require 'flatmoon.tweener'

--make some usually stuff global
Thing = flatmoon.engine.Thing
yield = flatmoon.engine.yield
wait = flatmoon.engine.wait
listener = flatmoon.listener
stween = flatmoon.tweener.stween
ptween = flatmoon.tweener.ptween
director = flatmoon.director

--load all the file
require 'multimatch.content'
require 'multimatch.Saved'
require 'multimatch.Background'
require 'multimatch.stuffs.GUI'
require 'multimatch.stuffs.AnAL'
require 'multimatch.stuffs.lanes'
require 'multimatch.scenes.menu'
require 'multimatch.scenes.play'
require 'multimatch.scenes.how'
require 'multimatch.scenes.highs'
require 'multimatch.scenes.settings'
require 'multimatch.scenes.play.Board'
require 'multimatch.scenes.play.Gem'
require 'multimatch.scenes.play.LevelManager'
require 'multimatch.scenes.play.getBestMoves'

--game's first function
function gmain()
	--load content first, it may be take a little secs, so show the progress
	local progress = Thing.new()
	local screenWidth, screenHeight = g.getWidth(), g.getHeight()
	progress.draw = function (self)
		--draw a progress bar that show what percent is the loading progress are going
		g.setColor(255, 255, 255)
		g.setLineWidth(4)
		g.rectangle('line', screenWidth/2 - 105, screenHeight/2 - 25, 210, 50)
		--content.getPercent() return value 0..1 represent the ratio of the loading progress (1 is all are loaded)
		g.rectangle('fill', screenWidth/2 - 100, screenHeight/2 - 20, 200 * content.getPercent(), 40)
	end
	--call the content to be load 
	content.load(function () --finish callback, wil be call when all resource are loaded
		progress:destroy() --kill the progress bar

		--real game start
		Saved.new()
    	Background.new()
    	director.changeScene('menu')
	end)
end