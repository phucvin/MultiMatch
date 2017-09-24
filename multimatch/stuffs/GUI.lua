
local function roundrect(mode, x, y, width, height, xround, yround)
    local points = {}
    local precision = (xround + yround) * .1
    local tI, hP = table.insert, .5*math.pi
    if xround > width*.5 then xround = width*.5 end
    if yround > height*.5 then yround = height*.5 end
    local X1, Y1, X2, Y2 = x + xround, y + yround, x + width - xround, y + height - yround
    local sin, cos = math.sin, math.cos
    for i = 0, precision do
        local a = (i/precision-1)*hP
        tI(points, X2 + xround*cos(a))
        tI(points, Y1 + yround*sin(a))
    end
    for i = 0, precision do
        local a = (i/precision)*hP
        tI(points, X2 + xround*cos(a))
        tI(points, Y2 + yround*sin(a))
    end
    for i = 0, precision do
        local a = (i/precision+1)*hP
        tI(points, X1 + xround*cos(a))
        tI(points, Y2 + yround*sin(a))
    end
    for i = 0, precision do
        local a = (i/precision+2)*hP
        tI(points, X1 + xround*cos(a))
        tI(points, Y1 + yround*sin(a))
    end
    love.graphics.polygon(mode, unpack(points))
end

GUI = {}

local gui = {}
gui.__index = gui

local fnt_default = content.fonts.button

function gui:draw()
    g.push()
    g.translate(self.ox, self.oy)
    g.setLineWidth(1)
    for i, b in ipairs(self.buttons) do
        if b.isShow then
            g.setColor(b.colorFill)
            g.rectangle('fill', b.x, b.y, b.w, b.h)
            --roundrect('fill', b.x, b.y, b.w, b.h, 10, 10)
            g.setColor(b.colorBorder)
            g.rectangle('line', b.x, b.y, b.w, b.h)
            --roundrect('line', b.x, b.y, b.w, b.h, 10, 10)
            g.setColor(b.colorText)
            g.setFont(b.font)
            g.printf(b.text, b.x, b.y + (b.h - b.font:getHeight())/2, b.w, 'center')
        end
    end
    for i, t in ipairs(self.texts) do
        g.setColor(t.colorFill)
        g.rectangle('fill', t.x, t.y, t.w, t.h)
        g.setColor(t.colorBorder)
        g.rectangle('line', t.x, t.y, t.w, t.h)
        g.setColor(t.colorText)
        g.setFont(t.font)
        if t.align == 'center' then
            g.printf(t.text, t.x, t.y + (t.h - t.font:getHeight())/2, t.w, 'center')
        else
            g.printf(t.text, t.x+20, t.y + (t.h - t.font:getHeight())/2, t.w - 40, t.align)
        end
    end
    for i, tf in ipairs(self.textFields) do
        g.setColor(tf.colorFill)
        g.rectangle('fill', tf.x, tf.y, tf.w, tf.h)
        g.setColor(tf.colorBorder)
        g.rectangle('line', tf.x, tf.y, tf.w, tf.h)
        g.setColor(tf.colorText)
        g.setFont(tf.font)
        tf.typingDashTime = tf.typingDashTime - dt
        if tf.listener and tf.typingDashTime > 0.5 then
            g.printf(tf.tittle .. ' ' .. tf.text .. '|', tf.x+20, tf.y + (tf.h - tf.font:getHeight())/2, tf.w - 40, 'left')
        else
            if tf.typingDashTime <= 0 then tf.typingDashTime = 1 end
            g.printf(tf.tittle .. ' ' .. tf.text, tf.x+20, tf.y + (tf.h - tf.font:getHeight())/2, tf.w - 40, 'left')
        end
    end
    g.pop()
end

function gui:addButton(text, x, y, w, h, onClick)
    local btn = {}

    btn.text, btn.x, btn.y, btn.w, btn.h, btn.onClick = text, x, y, w, h, onClick
    btn.font = fnt_default
    btn.colorFill = {50, 50, 50, 150}
    btn.colorBorder = {150, 150, 150, 50}
    btn.colorText = {255, 255, 255, 255}
    btn.isShow = true

    table.insert(self.buttons, btn)

    return btn
end

function gui:addText(text, x, y, w, h, font, align)
    local txt = {}

    txt.text, txt.x, txt.y, txt.w, txt.h, txt.font, txt.align = text, x, y, w, h, font or fnt_default, align or 'center'
    txt.colorFill = {50, 50, 50, 150}
    txt.colorBorder = {150, 150, 150, 50}
    txt.colorText = {255, 255, 255, 255}

    table.insert(self.texts, txt)

    return txt
end

function gui:addTextField(tittle, text, x, y, w, h, font, maxLength, onChange)
    local txt = {}

    txt.tittle, txt.text, txt.x, txt.y, txt.w, txt.h, txt.font, txt.maxLength, txt.onChange = tittle, text, x, y, w, h, font, maxLength, onChange
    if not txt.font then txt.font = fnt_default end
    txt.colorFill = {50, 50, 50, 150}
    txt.colorBorder = {150, 150, 150, 50}
    txt.colorText = {255, 255, 255, 255}
    txt.listener = nil
    txt.typingDashTime = 0

    table.insert(self.textFields, txt)

    return txt
end

function gui:always()
    local mx, my = love.mouse.getX() - self.ox, love.mouse.getY() - self.oy

    for i, b in ipairs(self.buttons) do
        if b.isShow then
            if mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h and not b.inHovering then
                b.inHovering = true
                ptween(b, 0.5, {colorFill = {200, 200, 200, 150}}, nil, nil, function () return b.inHovering end)
            elseif b.inHovering then
                b.inHovering = false
                ptween(b, 0.5, {colorFill = {50, 50, 50, 150}}, nil, nil, function () return not b.inHovering end)
            end
        end
    end
end

function gui:onMouseDown(mx, my)
    mx = mx - self.ox
    my = my - self.oy
    
    for i, b in ipairs(self.buttons) do
        if b.isShow and mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
            b.inDown = true
        end
    end

    for i, tf in ipairs(self.textFields) do
        if mx >= tf.x and mx <= tf.x + tf.w and my >= tf.y and my <= tf.y + tf.h and tf.listener == nil then
            tf.listener = listener.add('keypressed', '', function (key)
                if key:len() == 1 then
                    local c = key
                    local isCaps = love.keyboard.isDown('capslock')
                    local isShift = love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')
                    if isCaps and not isShift then
                        c = string.upper(key)
                    elseif not isCaps and isShift then
                        c = string.upper(key)
                    end

                    tf.text = tf.text .. c
                elseif key == 'backspace' then
                    tf.text = tf.text:sub(1, tf.text:len()-1)
                end

                --make the length of new text is just as max, no more
                tf.text = tf.text:sub(1, tf.maxLength)
                --notice to creator if the text of this this textfield is changed
                if tf.onChange then tf.onChange(tf.text) end
            end)
        elseif tf.listener then
            listener.remove2(tf.listener)
            tf.listener = nil
            tf.typingDashTime = 0
        end
    end
end

function gui:onMouseUp(mx, my)
    mx = mx - self.ox
    my = my - self.oy
    
    for i, b in ipairs(self.buttons) do
        if b.isShow and mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h and b.inDown then
            b.inDown = false

            if b.onClick then b:onClick() end
        end
    end
end

function GUI.new(...)
    local self = Thing.new({'GUI'})

    setmetatable(gui, getmetatable(self))
    setmetatable(self, gui)

    self.ox = 0
    self.oy = 0

    self.buttons = {}
    self.texts = {}
    self.textFields = {}

    local l1 = listener.add('mousepressed', 'l', function (...) self:onMouseDown(...) end)
    local l2 = listener.add('mousereleased', 'l', function (...) self:onMouseUp(...) end)

    self.onDestroy = function (self)
        listener.remove2(l1)
        listener.remove2(l2)
    end

    return self
end