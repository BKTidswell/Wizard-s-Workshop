
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
    obj.angle = angle
    obj.rotations = angle//90

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
    self.angle = (self.angle + 90) % 360

    rads = self.angle * math.pi / 180

    if self.kind == "arrow" then
        self.dx = math.cos(rads)*100 -- 100, 0, -100, 0
        self.dy = math.sin(rads)*100 -- 0, 100, 0, -100

    elseif self.kind == "cArrow1" then
        self.dx = math.cos(rads)*100 -- 100, 100, -100, -100
        self.dy = math.sin(rads)*100 -- -100, 100, 100, -100
    end

end

function Arrow:is(Type)
    local mt = getmetatable(self)
    if mt == Type then
        return true
    end
    return false  
end