-- cauldron.lua

Cauldron = {}
Cauldron.__index = Cauldron

function Cauldron:new(x, y, img)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    obj.img = img

    obj.valueTbl = {red = 1, green = 2, yellow = 5}

    return obj
end

function Cauldron:draw()
    love.graphics.draw(self.img, self.x, self.y)
end

function Cauldron:returnValue(orbType)
    return self.valueTbl[orbType]
end

function Cauldron:Iam()
    return "Cauldron"
end

function Cauldron:is(Type)
    local mt = getmetatable(self)
    if mt == Type then
        return true
    end
    return false
end 