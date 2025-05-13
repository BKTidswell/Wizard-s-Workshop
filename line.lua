
-- orb.lua

Line = {}
Line.__index = Line

function Line:new(x, y, angle, dx, dy, kind, img)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    obj.dx = dx
    obj.dy = dy
    obj.kind = kind
    obj.img = img
    obj.rads = angle / 180 * math.pi

    return obj
end

-- Methods
function Line:move()
    self.x = self.x + self.dx * love.timer.getDelta()
    self.y = self.y + self.dy * love.timer.getDelta()
end

function Line:draw()
    love.graphics.draw(self.img, self.x, self.y, self.rads, 1, 1, 32, 32)
end

function Line:is(Type)
    local mt = getmetatable(self)
    if mt == Type then
        return true
    end
    return false  
end