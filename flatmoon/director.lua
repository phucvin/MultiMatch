assert(flatmoon and flatmoon.engine, 'flatmoon.engine must be required before flatmoon.director', 4)
flatmoon.director = {}

local assert = flatmoon.utils.assert
local Thing = flatmoon.engine.Thing
local yield = flatmoon.engine.yield
local listener = flatmoon.listener

--============================================================--

local director = flatmoon.director

local scenes = {}
local currentScene = nil

--a thing that don't belong to any scenes
local aThing = Thing.new({'flatmoon.director'})

local makeAllUseless = false --true to make all thing create in a scene to be useles (no update ,...)
local inChanging = false

--override the origin createThing function
local old_Thing_new = Thing.new
Thing.new = function (...)
    flatmoon.utils.lowestAssertLevel = flatmoon.utils.lowestAssertLevel + 1
    local t = old_Thing_new(...)
    flatmoon.utils.lowestAssertLevel = flatmoon.utils.lowestAssertLevel - 1

    if currentScene then
        table.insert(currentScene.things, t)

        if makeAllUseless then
            t:setUpdate(false)
            t:setDraw(false)
            t:destroy() --destroy after some frames
        end
    end
    return t
end


--override the origin addListener function
local old_listener_add = listener.add
listener.add = function (...)
    if makeAllUseless then return nil end

    flatmoon.utils.lowestAssertLevel = flatmoon.utils.lowestAssertLevel + 1
    local lis = old_listener_add(...)
    flatmoon.utils.lowestAssertLevel = flatmoon.utils.lowestAssertLevel - 1
    if currentScene then
        table.insert(currentScene.listeners, lis)
    end
    return lis
end

function director.addScene(id, creator)
    assert(type(id) ~= 'nil', 'director.addScene expects a non-nil value for 1st arg')
    assert(type(creator) == 'function', 'director.addScene expects a function for 2nd arg')

    local sc = {}
    sc.creator = creator
    sc.things = {}
    sc.listeners = {}
    sc.id = id
    scenes[id] = sc
end

function director.changeScene(id, ...)
    assert(type(id) ~= 'nil', 'director.changeScene expects a non-nil value for 1st arg')

    local arg = {...}

    if inChanging then
        aThing:seq(function ()
            while inChanging do yield() end
            director.changeScene(id)
        end)
        
        return
    end

    inChanging = true
    makeAllUseless = true --from this time, all thing create will be useless

    if currentScene then
        for i, t in ipairs(currentScene.things) do
            t:destroy() --whatever it be (marked as destroyed, needdestroy or destroyed)
            currentScene.things[i] = nil
        end
        currentScene.things = {}

        for i, l in ipairs(currentScene.listeners) do
            listener.remove2(l)
            currentScene.listeners[i] = nil
        end
        currentScene.listeners = {}
    end

    if scenes[id] then
        --TEMPORARY FIX for mouse pressed remain between switch of 2 scenes
        --A FIX for a unknow-fix ERROR, this fix could make some more unknow issuse in game
        --when you think scene has change, some code shouldn't exec, but it will exec
        --because it yield() here
        aThing:seq(function ()
            --disable if not need
            --[[
            yield()
            yield() --double yield to avoid create thing at milde of progess
            --]]

            makeAllUseless = false -- now, after all useless thing has been destroy, let it normal

            if flatmoon.camera then
                flatmoon.camera.reset()
            end
            currentScene = scenes[id]
            currentScene.creator(unpack(arg))

            inChanging = false
        end)
    else --if there is no scene id like this
        error('director.changeScene expects a registed scene id for 1st arg', 2)
    end
end

function director.getCurrentSceneId()
    if currentScene then return currentScene.id
    else return nil end
end