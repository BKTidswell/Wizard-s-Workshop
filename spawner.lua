
-- orb.lua

Spawner = {}
Spawner.__index = Spawner

function Spawner:new(x, y, kind, img)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    obj.kind = kind
    obj.img = img

    return obj
end

function Spawner:draw()
    love.graphics.draw(self.img, self.x, self.y)
end

function Spawner:is(Type)
    local mt = getmetatable(self)
    if mt == Type then
        return true
    end
    return false  
end