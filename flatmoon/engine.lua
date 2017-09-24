if not flatmoon then flatmoon = {} end
flatmoon.engine = {}

--============================================================--

flatmoon.utils = {}

flatmoon.utils.lowestAssertLevel = 3

local utils = flatmoon.utils

--an assert to make error msg appeare at correct line of code
function flatmoon.utils.assert(ensure, msg, addLevel)
    if not ensure then error(msg, utils.lowestAssertLevel + (addLevel or 0)) end
end

function flatmoon.utils.insertToHole(tb, what)
    assert(type(tb) == 'table', 'insertToHole expects a table for 1th arg')
    assert(type(what) ~= 'nil', 'insertToHole expects non-nil value for 2th arg')

    for i = 1, #tb, 1 do
        if tb[i] == flatmoon.utils.NOTHING then
            tb[i] = what
            break
        end

        if i == #tb then table.insert(tb, what) end
    end
    if #tb == 0 then table.insert(tb, what) end
end

--by default coroutine.resume(co) don't report error to main program
--it just return to re, err
--so we want to make it available to all
function flatmoon.utils.safeResume(co, ...)
    assert(type(co) == 'thread', 'safeResume expects a coroutine (thread) for 1th arg')

    local re
    local err
    re, err = coroutine.resume(co, ...)
    if not re then
        error('Error in coroutine:\n\n' .. err .. '\n\nCoroutine ' .. debug.traceback(co))
    end

    return err
end

function flatmoon.utils.makeInaccessible(tb, errorMsg)
    assert(type(tb) == 'table', 'makeInaccessible expects a table for 1st arg')
    assert(type(errorMsg) == 'string', 'makeInaccessible expects a string for 2nd arg')

    --make it nil, so the metatable below will work perfectly
    for k, v in pairs(tb) do
        tb[k] = nil
    end

    local mt = {}
    local err = function () error(errorMsg, 2) end --2 here to make the error description at right code line
    mt.__index = err
    mt.__newindex = err

    setmetatable(tb, mt)

    return tb
end

--NOTHING is different from nil
--NOTHING just should be use in table with key is number (array)
--nil is good for dictionary type (key is not number)
flatmoon.utils.NOTHING = flatmoon.utils.makeInaccessible({}, 'You can not access NOTHING')

local function createOnFirstAccess(tb, key)
    tb[key] = {}
    return tb[key]
end

function flatmoon.utils.newPrivate()
    return setmetatable({}, {__mode = 'k', __index = createOnFirstAccess})
end

--============================================================--

--local, for short
local assert = flatmoon.utils.assert
local insertToHole = flatmoon.utils.insertToHole
local safeResume = flatmoon.utils.safeResume
local makeInaccessible = flatmoon.utils.makeInaccessible
local NOTHING = flatmoon.utils.NOTHING

--============================================================--

--just a few global here, for easy to use this engine
--this also the special of this engine

dt = 0

g = love.graphics

--============================================================--

local engine = flatmoon.engine

engine.dtfactor = 1 --this factor just affect to value that use dt
                    --so key press or love.mouse.x, y got no affect
                    --carefull when use this

engine.yield = coroutine.yield

function engine.wait(amount, ensure)
    assert(tonumber(amount), 'wait expects a number for 1th arg')
    if ensure then
        assert(type(ensure) == 'function', 'wait expects a function or nil for 2nd arg')
    end

    local total = tonumber(amount)
    while total > 0 do
        total = total - dt
        coroutine.yield()
        if ensure and not ensure() then break end
    end
end

--============================================================--

engine.Thing = {}
local Thing = engine.Thing

local Tags = {}
Tags.__index = Tags

local Coms = {}
Coms.__index = Coms

--save all thing have been create, and the list to draw it
local things = {}
local drawList = {}
local privates = {}

function Tags:add(newtag)
    assert(type(newtag) ~= 'nil', 'tags:add expects a non-nil value for 1th arg')

    table.insert(self, newtag)
end

function Tags:remove(tag)
    assert(type(tag) ~= 'nil', 'tags:remove expects a non-nil value for 1th arg')

    for i, v in ipairs(self) do
        if v == tag then
            table.remove(self, i)

            return
        end
    end
end

function Tags:contain(tag)
    assert(type(tag) ~= 'nil', 'tags:contain expects a non-nil value for 1th arg')

    for i, v in ipairs(self) do
        if v == tag then return true end
    end
    return false
end

function Coms:add(newcom)
    assert(type(newcom) == 'table' , 'coms:add expects a component (table) for 1st arg')

    newcom.owner = self.owner
    if self.list[newcom.__id] == nil then
        self.list[newcom.__id] = newcom
    else
        error('coms:add just allow one type of compoent in a thing')
    end

    return newcom
end

function Coms:refresh()
    for id, c in pairs(self.list) do
        if c.refresh then c:refresh() end
    end
end

--remove is temporary disable
--[[
function Coms:remove(id)
    assert(id ~= nil, 'coms:remove expects id (string) for 1st arg')
    local c = self.list[id]

    assert(c and c.onAttached and c.onDeattached, 'coms:remove expects id (string) of a component for 1st arg')

    c:onDeattached(self.owner)
    self.list[id] = NOTHING --use NOTHING here because we want user to be notice when they access a removed com
end
--]]

function Coms:get(comclass)
    assert(type(comclass) == 'table' and comclass.__id ~= nil, 'coms:remove expects coponent (table) for 1st arg')
    local c = self.list[comclass.__id]

    return c
end

function Coms:registerSubDraw(subDraw, key, isPrev, ...)
    assert(type(subDraw) == 'function' and type(isPrev) == 'boolean', 'coms:registerSubDraw expects function for 1st arg and boolean for 3rd arg')
    if isPrev then
        privates[self.owner].listSubDrawPre[key] = {func = subDraw, args = arg}
    else
        privates[self.owner].listSubDrawPost[key] = {func = subDraw, args = arg}
    end
end

function Thing:seq(func)
    assert(type(func) == 'function', 'thing:seq expects a function for 1th arg')

    --should start at time we add, to prevent useless co and misunderstand the order of code
    local co = coroutine.create(func)
    safeResume(co)
    insertToHole(privates[self].listSeq, co)
end

local function thing_update(self)
    if self.always then self:always() end

    for id, c in pairs(self.coms.list) do
        if c.always then c:always() end
    end

    for i, s in ipairs(privates[self].listSeq) do
        if s ~= NOTHING and coroutine.status(s) ~= 'dead' then
            safeResume(s)
        else
            privates[self].listSeq[i] = NOTHING
        end
    end
end

function Thing:alive()
    --by default when it didn't destroyImmediately, it's alive
    return not privates[self].markDestroyed
end

local function thing_dead(self)
    --this just assign to thing.alive when it has destroyImmediately
    return false
end

function Thing:markAsDestroyed()
    privates[self].markDestroyed = true
end

--destroy at end of current frame
function Thing:destroy()
    privates[self].markDestroyed = true
    privates[self].needDestroy = true
end

--careful when use this
--destroy it and make it inaccessable at it's call
function Thing:destroyImmediately()
    if self.onDestroy and self:onDestroy() == 'dont destroy' then
        privates[self].needDestroy = false

        return
    end

    for id, c in pairs(self.coms.list) do
        if c.onDeattach then c:onDeattach() end
    end

    for i, t in ipairs(things) do
        if self == t then
            things[i] = NOTHING
        end
    end

    for i, v in ipairs(drawList) do
        if self == v then
            drawList[i] = NOTHING
        end
    end

    privates[self] = nil --nil here because nothing can access it but me

    makeInaccessible(self, 'You can not access a DEAD thing')
    --after makeInaccessible, thing will be a empty table
    --so when an access to a key (now isnt exist) will show error
    --but it we rawset alive (mean step thru metatable)
    --thing:alive will work (because now it's have that alive key)
    --3 function of a dead thing can exec is: alive, destroy and destroyImmediately
    rawset(self, 'alive', thing_dead)
    rawset(self, 'destroy', thing_dead)
    rawset(self, 'destroyImmediately', thing_dead)
end

local function thing_getZOrder(self)
    return privates[self].zOrder
end
local function thing_setZOrder(self, value)
    assert(tonumber(value), 'thing:setZOrder expects a number for 1st arg')
    value = tonumber(value)

    local toZ = value
    privates[self].zOrder = toZ
    for i, v in ipairs(drawList) do
        if v == self then
            table.remove(drawList, i)

            local ok = false

            for j, vv in ipairs(drawList) do
                if toZ >= 0 and vv ~= NOTHING and privates[vv].zOrder > toZ then
                    table.insert(drawList, j, v)
                    ok = true
                    break
                elseif toZ < 0 and vv ~= NOTHING and privates[vv].zOrder < toZ then
                    table.insert(drawList, j + 1, v)
                    ok = true
                    break
                end
            end

            if not ok and toZ >= 0 then table.insert(drawList, v)
            elseif not ok then table.insert(drawList, 1, v) end

            break
        end
    end
end

function Thing:setUpdate(value)
    assert(type(value) == 'boolean', 'thing:setUpdate expects a boolean for 1st arg')

    privates[self].update = value
end
function Thing:setDraw(value)
    assert(type(value) == 'boolean', 'thing:setDraw expects a boolean for 1st arg')

    privates[self].draw = value
end
function Thing:setHUD(value)
    assert(type(value) == 'boolean', 'thing:setHUD expects a boolean for 1st arg')

    privates[self].isHUD = value
end

function Thing.__index(self, key)
    if key == 'zOrder' then
        return thing_getZOrder(self)
    else
        return Thing[key]
    end
end
function Thing.__newindex(self, key, value)
    if key == 'zOrder' then
        thing_setZOrder(self, value)
    else
        rawset(self, key, value)
    end
end

function Thing:extend(newclass)
    return setmetatable(self, setmetatable(newclass, getmetatable(self)))
end

function Thing.new(tags)
    assert(tags == nil or type(tags) == 'table', 'Thing.new expects a table of tag for 1st arg')

    local self = {}

    setmetatable(self, Thing)

    insertToHole(things, self)
    insertToHole(drawList, self)

    if tags then
        self.tags = {}
        for k, v in pairs(tags) do table.insert(self.tags, v) end
    else
        self.tags = {'default'}
    end
    setmetatable(self.tags, Tags)

    self.coms = {owner = self, list = {}}
    setmetatable(self.coms, Coms)

    privates[self] = {}
    local p = privates[self]
    p.listSeq = {}
    p.zOrder = 0
    p.update = true
    p.draw = true
    p.listSubDrawPre = {}   --pre and post drawing is for components
    p.listSubDrawPost = {}
    p.markDestroyed = false
    p.needDestroy = false
    p.isHUD = false

     --user override
    self.draw = nil
    self.always = nil
    self.onDestroy = nil

    --do some work before release it
    self.zOrder = 0

    return self
end

function Thing.getAll(tag, needAlive)
    assert(type(tag) == 'string', 'Thing.getAll expects a string or nil for 1st arg')
    if needAlive == nil then needAlive = true end
    assert(type(needAlive) == 'boolean', 'Thing.getAll expects a boolean or nil for 2nd arg')

    local list = {}

    for i, t in ipairs(things) do
        if things[i] ~= NOTHING and (not needAlive and true or t:alive()) and
           (not tag and true or t.tags:contain(tag)) then
            table.insert(list, t)
        end
    end

    return list
end

--a global non die thing
local system = Thing.new({'flatmoon_engine_system'})
--a global seq function
engine.seq = function (what)
    system:seq(what)
end

--============================================================--

flatmoon.listener = {}
local listener = flatmoon.listener

local listeners = {}

function listener.add(kind, data, func, id)
    assert(type(kind) == 'string', 'add expects a string (kind of listener) for 1th arg')
    assert(type(data) ~= nil, 'add expects a non-nil (data for listener) for 2th arg')
    assert(type(func) == 'function', 'add expects a function for 3th arg')
    --id can be any thing (include nil, because it will be transform to 'default')

    local lis = {}

    lis.kind = kind
    lis.data = data
    lis.func = func
    lis.enable = true
    if id then
        lis.id = id
    else
        lis.id = 'default'
    end

    insertToHole(listeners, lis)

    return lis
end

function listener.remove(kind, id)
    assert(type(kind) == 'string', 'remove expects a string (kind of listener) for 1th arg')
    assert(type(id) ~= 'nil', 'remove expects a non-nil (id of listener) for 2th arg')

    for i, l in ipairs(listeners) do
        if l ~= NOTHING and (l.kind == kind or kind == '') and l.id == id then
            listeners[i] = NOTHING
        end
    end
end

function listener.remove2(theReturned)
    assert(type(theReturned) == 'table', 'remove2 expects a table (return of addListener) for 1th arg')

    for i, l in ipairs(listeners) do
        if l == theReturned then
            listeners[i] = NOTHING
        end
    end
end

--============================================================--

function love.load()
    gmain()
end

local waitForInitWindow = true
function love.update(dt_)
    if waitForInitWindow and dt_ > 1/60 then
        return
    elseif waitForInitWindow then
        waitForInitWindow = false
    end

    dt = dt_*engine.dtfactor --update the real delta time, with delta time factor

    for i, t in ipairs(things) do
        if t ~= NOTHING and privates[t].update then thing_update(t) end
    end

    for i, t in ipairs(things) do
        if t ~= NOTHING and privates[t].needDestroy then
            t:destroyImmediately()
        end
    end

    --frame cap, disable if not need
    love.timer.sleep(1/60 - dt)

    --disable if not need
    --in love 0.8.0, love.timer.sleep(x), x is in second, not milisecond like in 0.7
    --love.timer.sleep(0.01)
end

function love.draw()
    if flatmoon.camera then
        local cp = flatmoon.camera._private
        local inCam = false

        for i = 1, #drawList, 1 do
            local t = drawList[i]
            local pt = privates[t]
            if t ~= NOTHING and t.draw and pt.draw then
                if pt.isHUD then
                    if inCam then
                        inCam = false
                        cp.postDraw()
                    end
                else
                    if not inCam then
                        inCam = true
                        cp.preDraw()
                    end
                end

                --pre and post drawing is for components
                for _, v in pairs(pt.listSubDrawPre) do v.func(unpack(v.args)) end
                t:draw()
                for _, v in pairs(pt.listSubDrawPost) do v.func(unpack(v.args)) end
            end
        end

        if inCam then cp.postDraw() end
    else
        for i = 1, #drawList, 1 do
            local t = drawList[i]
            local pt = privates[t]

            if t ~= NOTHING and t.draw and pt.draw then
                for _, v in pairs(pt.listSubDrawPre) do v.func(unpack(v.args)) end
                t:draw()
                for _, v in pairs(pt.listSubDrawPost) do v.func(unpack(v.args)) end
            end
        end
    end

    --disable if not need
    --love.graphics.print(love.timer.getFPS() .. '\n' .. gcinfo(), 0, 0)
    --collectgarbage('collect')
end

function love.keypressed(key, unicode)
    for i, l in ipairs(listeners) do
        if l ~= NOTHING and l.enable and l.kind == 'keypressed' then
            if l.data == key then l.func()
            elseif l.data == '' then l.func(key) end
        end
    end
end

function love.keyreleased(key, unicode)
    for i, l in ipairs(listeners) do
        if l ~= NOTHING and l.enable and l.kind == 'keyreleased' then
            if l.data == key then l.func()
            elseif l.data == '' then l.func(key) end
        end
    end
end

function love.mousepressed(x, y, button)
    for i, l in ipairs(listeners) do
        if l ~= NOTHING and l.enable and l.kind == 'mousepressed' then
            if l.data == '' then l.func(x, y, button)
            elseif l.data == button then l.func(x, y, button) end
        end
    end
end

function love.mousereleased(x, y, button)
    for i, l in ipairs(listeners) do
        if l ~= NOTHING and l.enable and l.kind == 'mousereleased' then
            if l.data == '' then l.func(x, y, button)
            elseif l.data == button then l.func(x, y, button) end
        end
    end
end
