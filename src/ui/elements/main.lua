local ui = require("ui.main")

local uie = {}
ui.e = uie

-- Default element functions and values.
uie.__default = {
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    invalidated = 2,

    interactive = 0,

    parent = nil,
    id = nil,

    getPath = function(self)
        local id = self.id
        if not id then
            id = self.__type .. "[" .. self.__rawid .. "]"
        end

        local parent = self.parent
        if parent then
            return parent.path .. "." .. id
        end

        return id
    end,

    __screenPos = function(self, axis)
        local AXIS = axis:upper()
        local pos = 0
        local el = self
        while el ~= nil do
            pos = pos + el["real" .. AXIS]
            el = el.parent
            if el ~= nil then
                local padding = el["padding" .. AXIS] or el.padding
                if padding then
                    pos = pos + padding
                end
            end
        end
        return pos
    end,

    getRealX = function(self)
        return self.__realX or self.x
    end,

    setRealX = function(self, value)
        self.__realX = value
    end,

    getRealY = function(self)
        return self.__realY or self.y
    end,

    setRealY = function(self, value)
        self.__realY = value
    end,

    getScreenX = function(self)
        return uie.__default.__screenPos(self, "x")
    end,

    getScreenY = function(self)
        return uie.__default.__screenPos(self, "y")
    end,

    contains = function(self, mx, my)
        local ex = self.screenX
        local ey = self.screenY
        local ew = self.width
        local eh = self.height
    
        return
            ex <= mx and mx <= ex + ew and
            ey <= my and my <= ey + eh
    end,

    getHovered = function(self)
        return ui.hovering == self
    end,

    init = function(self)
    end,

    as = function(self, id)
        self.id = id
        return self
    end,

    with = function(self, props)
        for k, v in pairs(props) do
            self[k] = v
        end
        self:invalidate()
        return self
    end,

    invalidate = function(self)
        local el = self
        while el ~= nil do
            el.invalidated = 2
            el = el.parent
        end

        local children = self.children
        if children then
            for i = 1, #children do
                local c = children[i]
                c:invalidate()
            end
        end
    end,

    update = function(self)
        local children = self.children
        if children then
            for i = 1, #children do
                local c = children[i]
                c:update()
            end
        end
    end,

    updateLate = function(self)
        local children = self.children
        if children then
            for i = 1, #children do
                local c = children[i]
                c:updateLate()
            end
        end
    end,

    layout = function(self)
        if self.invalidated == 0 then
            return false
        end
        self.invalidated = 1

        self:layoutBeforeChildren()
        self:layoutChildren()
        self:layoutAfterChildren()

        return true
    end,

    layoutChildren = function(self)
        local children = self.children
        if children then
            for i = 1, #children do
                local c = children[i]
                c:layout()
            end
        end
    end,

    layoutBeforeChildren = function(self)
    end,

    layoutAfterChildren = function(self)
        self:recalc()
    end,

    recalc = function(self)
        local eltype = self.__type
        local eltypeBase = eltype
        local calcset = {}
        while eltypeBase ~= nil do
            local default = uie["__" .. eltypeBase].__default
            for k, v in pairs(default) do
                if k:sub(1, 4) == "calc" then
                    local calced = false
                    for i = 1, #calcset do
                        local c = calcset[i]
                        if c == k then
                            calced = true
                            break
                        end
                    end

                    if not calced then
                        table.insert(calcset, k)
                        self[k:sub(5, 5):lower() .. k:sub(6)] = v(self)
                    end
                end
            end
            eltypeBase = default.base
        end
    end,

    layoutLate = function(self)
        if self.invalidated == 0 then
            return false
        end
        self.invalidated = 0

        self:layoutLateBeforeChildren()
        self:layoutLateChildren()
        self:layoutLateAfterChildren()

        return true
    end,

    layoutLateChildren = function(self)
        local children = self.children
        if children then
            for i = 1, #children do
                local c = children[i]
                c:layoutLate()
            end
        end
    end,

    layoutLateBeforeChildren = function(self)
    end,

    layoutLateAfterChildren = function(self)
    end,

    draw = function(self)
        local children = self.children
        if children then
            for i = 1, #children do
                local c = children[i]
                c:draw()
            end
        end
    end,

    getChild = function(self, id)

    end,

    getChildAt = function(self, mx, my)
        local interactive = self.interactive
        if interactive == -1 then
            return nil
        end
    
        if not self:contains(mx, my) then
            return nil
        end
    
        local children = self.children
        if children then
            for i = #children, 1, -1 do
                local c = children[i]
                c = c:getChildAt(mx, my)
                if c then
                    return c
                end
            end
        end
    
        if interactive == 0 then
            return nil
        end
    
        return self
    end,

    onEnter = function(self)
    end,
    onLeave = function(self)
    end,
    onPress = function(self, x, y, button, dragging)
    end,
    onRelease = function(self, x, y, button, dragging)
    end,
    onClick = function(self, x, y, button)
    end,
    onDrag = function(self, x, y, dx, dy)
    end,
}

-- Shared metatable for all style helper tables.
local mtStyle = {
    __name = "ui.element.style",

    __index = function(self, key)
        local v = rawget(self, key)
        if v ~= nil then
            return v
        end

        local el = rawget(self, "el")
        local eltype = el.__type

        local default = el.__default
        if el ~= default then
            v = default.style[key]
            if v ~= nil then
                return v
            end
        end

        local template = el.__template
        if template then
            v = template.style[key]
            if v ~= nil then
                return v
            end
        end

        local baseStyle = el.__base.style
        if baseStyle then
            v = baseStyle[key]
            if v ~= nil then
                return v
            end
        end

        error("Unknown styling property: " .. eltype .. " [\"" .. tostring(key) .. "\"]")
    end
}

-- Shared metatable for all element tables.
local mtEl = {
    __name = "ui.element",

    __index = function(self, key)
        local v = rawget(self, key)
        if v ~= nil then
            return v
        end

        if key == "style" then
            return rawget(self, "__style")
        end

        local propcache = rawget(self, "__propcache")
        local cached = propcache[key]
        if cached then
            local ctype = cached.type
            
            if ctype == "get" then
                return cached.value(self)

            elseif ctype == "child" then
                local id = cached.id
                local children = self.children
                local c = children[cached.i]
                if c and c.id == id then
                    return c
                end
                for i = 1, #children do
                    local c = children[i]
                    if c.id == id then
                        cached.i = i
                        return c
                    end
                end
            end
        end

        local keyType = type(key)

        local keyGet = nil
        if keyType == "string" then
            local Key = key:sub(1, 1):upper() .. key:sub(2)
            keyGet = "get" .. Key
        end
            
        local default = rawget(self, "__default")
        if keyGet then
            v = default[keyGet]
            if v ~= nil then
                propcache[key] = { type = "get", value = v }
                return v(self)
            end
        end

        v = default[key]
        if v ~= nil then
            return v
        end

        local base = default.base
        if base then
            base = uie["__" .. default.base]

            if base then
                if keyGet then
                    v = base[keyGet]
                    if v ~= nil then
                        propcache[key] = { type = "get", value = v }
                        return v(self)
                    end
                end

                v = base[key]
                if v then
                    return v
                end
            end
        end

        if key == "children" then
            return nil
        end
        
        if keyGet then
            v = uie.__default[keyGet]
            if v then
                propcache[key] = { type = "get", value = v }
                return v(self)
            end
        end

        v = uie.__default[key]
        if v then
            return v
        end

        local children = self.children
        if children then
            if keyType == "string" and key:sub(1, 1) == "_" then
                local id = key:sub(2)
                for i = 1, #children do
                    local c = children[i]
                    local cid = c.id
                    if cid and cid == id then
                        propcache[key] = { type = "child", i = i, id = id }
                        return c
                    end
                end
            end
        end
    end,

    __newindex = function(self, key, value)
        if key == "style" then
            local style = rawget(self, "__style")
            for k, v in pairs(value) do
                style[k] = v
            end
            return self
        end

        local keySet = nil
        if type(key) == "string" then
            keySet = "set" .. key:sub(1, 1):upper() .. key:sub(2)
        end

        if keySet then
            local cb = self.__default[keySet]
            if cb ~= nil then
                return cb(self, value)
            end

            cb = uie.__default[keySet]
            if cb then
                return cb(self, value)
            end
        end

        return rawset(self, key, value)
    end,

    __call = function(self, ...)
        local __call = self.__call
        if __call then
            return __call(...)
        end
        return self:with(...)
    end,

    __tostring = function(self)
        return self.path
    end
}

-- Function to register a new UI element.
function uie.add(eltype, default)
    local template

    local function new()
        local el = {}
        el.__ui = ui
        el.__type = eltype
        el.__default = default
        el.__template = template
        el.__style = setmetatable({ el = el }, mtStyle)
        el.__base = uie["__" .. (default.base or "default")] or uie.__default
        el.__propcache = {}
        el.__rawid = tostring(el):sub(8)

        return setmetatable(el, mtEl)
    end

    template = new()
    uie["__" .. eltype] = template

    uie[eltype] = function(...)
        local el = new()
        el:init(...)
        return el
    end

    return new
end

return uie