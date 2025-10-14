
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
end

function Orb:draw()
    -- Draw from center of sprite (orb images are 64x64)
    -- Last two params (32, 32) = origin offset to center
    love.graphics.draw(self.img, self.x, self.y, 0, 1, 1, 32, 32)
end

function Orb:is(Type)
    local mt = getmetatable(self)
    if mt == Type then
        return true
    end
    return false  
end