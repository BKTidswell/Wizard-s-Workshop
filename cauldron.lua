-- cauldron.lua

Cauldron = {}
Cauldron.__index = Cauldron

function Cauldron:new(x, y, img)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    obj.img = img
    return obj
end

function Cauldron:draw()
    love.graphics.setColor(0, 0, 0) -- Black color
    love.graphics.circle("fill", self.x + gridSize/2, self.y + gridSize/2, gridSize/2)
    love.graphics.setColor(1, 1, 1) -- Reset color to white
end

function Cauldron:is(Type)
    local mt = getmetatable(self)
    if mt == Type then
        return true
    end
    return false
end 