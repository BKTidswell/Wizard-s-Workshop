
-- orb.lua

Orb = {}
Orb.__index = Orb

function Orb:new(x, y, dx, dy, lastSqr, kind, img)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    obj.dx = dx
    obj.dy = dy
    obj.lastSqr = lastSqr
    obj.kind = kind
    obj.img = img

    return obj
end

-- Methods
function Orb:move()
    self.x = self.x + self.dx * love.timer.getDelta()
    self.y = self.y + self.dy * love.timer.getDelta()

    -- if self.dx == 0 then
    --     self.x = myround(self.x - girdXOffset, gridSize) + girdXOffset
    -- elseif self.dy == 0 then
    --     self.y = myround(self.y - girdYOffset, gridSize) + girdYOffset
    -- end
end

function Orb:draw()
    love.graphics.draw(self.img, self.x, self.y)
end

function Orb:is(Type)
    local mt = getmetatable(self)
    if mt == Type then
        return true
    end
    return false  
end