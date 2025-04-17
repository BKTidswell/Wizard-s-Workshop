
-- orb.lua

Arrow = {}
Arrow.__index = Arrow

function Arrow:new(x, y, dx, dy, kind, img, angle)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    obj.dx = dx
    obj.dy = dy
    obj.kind = kind
    obj.img = img
    obj.angle = 0

    return obj
end

-- Methods
function Arrow:move()
    self.x = self.x + self.dx * love.timer.getDelta()
    self.y = self.y + self.dy * love.timer.getDelta()
end

function Arrow:draw()
    love.graphics.draw(self.img, self.x, self.y, self.angle * math.pi / 180)
end

function Arrow:rotate()
    self.dx = 
    self.dy = 
    self.angle = (self.angle + 90) % 360
end

function Arrow:is(Type)
    local mt = getmetatable(self)
    if mt == Type then
        return true
    end
    return false  
end